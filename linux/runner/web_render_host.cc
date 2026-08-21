#include "web_render_host.h"

#include <cairo.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <jsc/jsc.h>
#include <webkit2/webkit2.h>

#include <cstring>

namespace {

constexpr char kChannelName[] = "io.busystack.busymark/visualization";
constexpr char kScheme[] = "busymark-render";
constexpr char kHarnessUri[] = "busymark-render://app/harness.html";
constexpr char kReferenceUri[] = "busymark-render://app/reference.html";
constexpr gsize kMaximumRequestBytes = 20 * 1024 * 1024;
constexpr gsize kMaximumPngBytes = 64 * 1024 * 1024;

struct PendingRequest {
  BusyMarkWebRenderHost* host;
  FlMethodCall* method_call;
  gchar* operation;
  gchar* request_id;
  gchar* arguments_json;
  gint snapshot_width;
  gint snapshot_height;
  guint snapshot_allocation_attempts;
  guint snapshot_wait_source_id;
  gboolean responded;
};

struct ReferenceLoadData {
  gchar* arguments_json;
  gboolean started;
};

struct ReferenceAsyncData {
  WebKitWebView* web_view;
};

}  // namespace

struct _BusyMarkWebRenderHost {
  GObject parent_instance;
  GtkApplication* application;
  GtkWindow* parent_window;
  FlMethodChannel* channel;
  FlMethodCall* release_smoke_recovery_call;
  guint release_smoke_terminate_source_id;
  WebKitWebContext* context;
  GtkWidget* offscreen_window;
  WebKitWebView* web_view;
  GCancellable* active_cancellable;
  GQueue* queue;
  PendingRequest* active;
  guint recreate_source_id;
  gchar* resource_root;
  gboolean ready;
  gboolean recreate_requested;
  gboolean shutting_down;
};

G_DEFINE_TYPE(BusyMarkWebRenderHost,
              busymark_web_render_host,
              G_TYPE_OBJECT)

namespace {

void pump_requests(BusyMarkWebRenderHost* self);
void recreate_render_view(BusyMarkWebRenderHost* self);
void schedule_render_view_recreation(BusyMarkWebRenderHost* self);

void respond_error(FlMethodCall* method_call,
                   const gchar* code,
                   const gchar* message) {
  fl_method_call_respond_error(method_call, code, message, nullptr, nullptr);
}

void pending_request_free(PendingRequest* request) {
  if (request == nullptr) {
    return;
  }
  if (request->snapshot_wait_source_id != 0) {
    g_source_remove(request->snapshot_wait_source_id);
    request->snapshot_wait_source_id = 0;
  }
  g_clear_object(&request->method_call);
  g_clear_object(&request->host);
  g_clear_pointer(&request->operation, g_free);
  g_clear_pointer(&request->request_id, g_free);
  g_clear_pointer(&request->arguments_json, g_free);
  g_free(request);
}

void respond_pending_error(PendingRequest* request,
                           const gchar* code,
                           const gchar* message) {
  if (!request->responded) {
    request->responded = TRUE;
    respond_error(request->method_call, code, message);
  }
}

gchar* locate_resource_root() {
  const gchar* override_path = g_getenv("BUSYMARK_VISUALIZATION_ASSETS");
  if (override_path != nullptr && override_path[0] != '\0' &&
      g_file_test(override_path, G_FILE_TEST_IS_DIR)) {
    return g_canonicalize_filename(override_path, nullptr);
  }

  const gchar* snap_root = g_getenv("SNAP");
  if (snap_root != nullptr && snap_root[0] != '\0') {
    g_autofree gchar* candidate = g_build_filename(
        snap_root, "share", "busymark", "visualization", nullptr);
    if (g_file_test(candidate, G_FILE_TEST_IS_DIR)) {
      return g_canonicalize_filename(candidate, nullptr);
    }
  }

  g_autofree gchar* executable_path =
      g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path == nullptr) {
    return nullptr;
  }
  g_autofree gchar* executable_directory =
      g_path_get_dirname(executable_path);
  g_autofree gchar* candidate =
      g_build_filename(executable_directory, "share", "busymark",
                       "visualization", nullptr);
  return g_file_test(candidate, G_FILE_TEST_IS_DIR)
             ? g_canonicalize_filename(candidate, nullptr)
             : nullptr;
}

const gchar* content_type_for_resource(const gchar* filename) {
  if (g_str_has_suffix(filename, ".html")) {
    return "text/html; charset=utf-8";
  }
  if (g_str_has_suffix(filename, ".js")) {
    return "text/javascript; charset=utf-8";
  }
  return "application/octet-stream";
}

gboolean is_allowed_resource_name(const gchar* path) {
  if (path == nullptr) {
    return FALSE;
  }
  const gchar* name = path[0] == '/' ? path + 1 : path;
  return g_strcmp0(name, "harness.html") == 0 ||
         g_strcmp0(name, "reference.html") == 0 ||
         g_strcmp0(name, "bootstrap.js") == 0 ||
         g_strcmp0(name, "render-engines.js") == 0 ||
         g_strcmp0(name, "reference.js") == 0 ||
         g_strcmp0(name, "scalar.js") == 0 ||
         g_strcmp0(name, "viz-global.js") == 0;
}

void uri_scheme_request_cb(WebKitURISchemeRequest* request,
                           gpointer user_data) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(user_data);
  const gchar* path = webkit_uri_scheme_request_get_path(request);
  if (self->resource_root == nullptr || !is_allowed_resource_name(path)) {
    g_autoptr(GError) error = g_error_new_literal(
        G_IO_ERROR, G_IO_ERROR_PERMISSION_DENIED,
        "Visualization resource is not available.");
    webkit_uri_scheme_request_finish_error(request, error);
    return;
  }
  const gchar* name = path[0] == '/' ? path + 1 : path;
  g_autofree gchar* filename =
      g_build_filename(self->resource_root, name, nullptr);
  gchar* contents = nullptr;
  gsize length = 0;
  g_autoptr(GError) error = nullptr;
  if (!g_file_get_contents(filename, &contents, &length, &error)) {
    webkit_uri_scheme_request_finish_error(request, error);
    return;
  }
  GInputStream* stream = g_memory_input_stream_new_from_data(
      contents, static_cast<gssize>(length), g_free);
  webkit_uri_scheme_request_finish(
      request, stream, static_cast<gint64>(length),
      content_type_for_resource(filename));
  g_object_unref(stream);
}

gboolean is_allowed_uri(const gchar* uri) {
  return uri != nullptr &&
         (g_str_has_prefix(uri, "busymark-render:") ||
          g_str_has_prefix(uri, "data:") ||
          g_str_has_prefix(uri, "blob:") ||
          g_str_has_prefix(uri, "about:blank"));
}

gboolean decide_policy_cb(WebKitWebView* web_view,
                          WebKitPolicyDecision* decision,
                          WebKitPolicyDecisionType type,
                          gpointer) {
  if (type != WEBKIT_POLICY_DECISION_TYPE_NAVIGATION_ACTION) {
    return FALSE;
  }
  auto* navigation_decision = WEBKIT_NAVIGATION_POLICY_DECISION(decision);
  WebKitNavigationAction* action =
      webkit_navigation_policy_decision_get_navigation_action(
          navigation_decision);
  WebKitURIRequest* request =
      webkit_navigation_action_get_request(action);
  const gchar* uri = webkit_uri_request_get_uri(request);
  const gchar* current_uri = webkit_web_view_get_uri(web_view);
  const WebKitNavigationType navigation_type =
      webkit_navigation_action_get_navigation_type(action);
  const gboolean initial_load = current_uri == nullptr;
  if (!is_allowed_uri(uri) ||
      (!initial_load &&
       navigation_type != WEBKIT_NAVIGATION_TYPE_RELOAD &&
       navigation_type != WEBKIT_NAVIGATION_TYPE_OTHER)) {
    webkit_policy_decision_ignore(decision);
    return TRUE;
  }
  return FALSE;
}

GtkWidget* create_web_view_cb(WebKitWebView*,
                              WebKitNavigationAction*,
                              gpointer) {
  return nullptr;
}

gboolean permission_request_cb(WebKitWebView*,
                               WebKitPermissionRequest* request,
                               gpointer) {
  webkit_permission_request_deny(request);
  return TRUE;
}

gboolean context_menu_cb(WebKitWebView*,
                         WebKitContextMenu*,
                         GdkEvent*,
                         WebKitHitTestResult*,
                         gpointer) {
  return TRUE;
}

WebKitSettings* create_restricted_settings() {
  WebKitSettings* settings = webkit_settings_new();
  webkit_settings_set_enable_javascript(settings, TRUE);
  webkit_settings_set_enable_html5_local_storage(settings, FALSE);
  webkit_settings_set_enable_html5_database(settings, FALSE);
  webkit_settings_set_javascript_can_open_windows_automatically(settings,
                                                                FALSE);
  webkit_settings_set_enable_developer_extras(settings, FALSE);
  webkit_settings_set_enable_page_cache(settings, FALSE);
  webkit_settings_set_enable_site_specific_quirks(settings, FALSE);
  webkit_settings_set_enable_media_stream(settings, FALSE);
  webkit_settings_set_enable_mediasource(settings, FALSE);
  webkit_settings_set_enable_media(settings, FALSE);
  webkit_settings_set_enable_webrtc(settings, FALSE);
  webkit_settings_set_enable_back_forward_navigation_gestures(settings,
                                                              FALSE);
  return settings;
}

void configure_web_view(WebKitWebView* web_view) {
  g_autoptr(WebKitSettings) settings = create_restricted_settings();
  webkit_web_view_set_settings(web_view, settings);
  GdkRGBA transparent = {};
  gdk_rgba_parse(&transparent, "rgba(0,0,0,0)");
  webkit_web_view_set_background_color(web_view, &transparent);
  g_signal_connect(web_view, "decide-policy", G_CALLBACK(decide_policy_cb),
                   nullptr);
  g_signal_connect(web_view, "create", G_CALLBACK(create_web_view_cb),
                   nullptr);
  g_signal_connect(web_view, "permission-request",
                   G_CALLBACK(permission_request_cb), nullptr);
  g_signal_connect(web_view, "context-menu", G_CALLBACK(context_menu_cb),
                   nullptr);
}

GVariant* javascript_arguments(const gchar* operation,
                               const gchar* arguments_json) {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE_VARDICT);
  g_variant_builder_add(&builder, "{sv}", "operation",
                        g_variant_new_string(operation));
  g_variant_builder_add(&builder, "{sv}", "requestJson",
                        g_variant_new_string(arguments_json));
  return g_variant_builder_end(&builder);
}

void complete_active(BusyMarkWebRenderHost* self) {
  g_object_ref(self);
  PendingRequest* request = self->active;
  self->active = nullptr;
  g_clear_object(&self->active_cancellable);
  pending_request_free(request);
  if (self->recreate_requested && !self->shutting_down) {
    schedule_render_view_recreation(self);
  }
  pump_requests(self);
  g_object_unref(self);
}

void respond_json(PendingRequest* request, const gchar* json) {
  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) value =
      fl_json_message_codec_decode(codec, json, &error);
  if (value == nullptr) {
    respond_pending_error(request, "visualization.invalidHostResponse",
                          error != nullptr ? error->message
                                           : "WebKit returned invalid JSON.");
    return;
  }
  request->responded = TRUE;
  fl_method_call_respond_success(request->method_call, value, nullptr);
}

cairo_status_t write_png_cb(void* closure,
                            const unsigned char* data,
                            unsigned int length) {
  auto* bytes = static_cast<GByteArray*>(closure);
  if (bytes->len + length > kMaximumPngBytes) {
    return CAIRO_STATUS_WRITE_ERROR;
  }
  g_byte_array_append(bytes, data, length);
  return CAIRO_STATUS_SUCCESS;
}

void snapshot_finished_cb(GObject* object,
                          GAsyncResult* result,
                          gpointer user_data) {
  auto* request = static_cast<PendingRequest*>(user_data);
  BusyMarkWebRenderHost* self = request->host;
  g_autoptr(GError) error = nullptr;
  cairo_surface_t* surface = webkit_web_view_get_snapshot_finish(
      WEBKIT_WEB_VIEW(object), result, &error);
  if (surface == nullptr) {
    respond_pending_error(request, "visualization.rasterFailed",
                          error != nullptr ? error->message
                                           : "WebKit could not rasterize SVG.");
    complete_active(self);
    return;
  }
  GByteArray* bytes = g_byte_array_new();
  const cairo_status_t status =
      cairo_surface_write_to_png_stream(surface, write_png_cb, bytes);
  cairo_surface_destroy(surface);
  if (status != CAIRO_STATUS_SUCCESS) {
    g_byte_array_unref(bytes);
    respond_pending_error(request, "visualization.rasterFailed",
                          "WebKit PNG output exceeded its limit or failed.");
    complete_active(self);
    return;
  }
  g_autoptr(GBytes) owned_bytes = g_byte_array_free_to_bytes(bytes);
  g_autoptr(FlValue) value = fl_value_new_uint8_list_from_bytes(owned_bytes);
  request->responded = TRUE;
  fl_method_call_respond_success(request->method_call, value, nullptr);
  gtk_widget_set_size_request(GTK_WIDGET(self->web_view), 1, 1);
  gtk_widget_set_size_request(self->offscreen_window, 1, 1);
  gtk_window_set_default_size(GTK_WINDOW(self->offscreen_window), 1, 1);
  gtk_window_resize(GTK_WINDOW(self->offscreen_window), 1, 1);
  complete_active(self);
}

gboolean begin_snapshot_cb(gpointer user_data) {
  auto* request = static_cast<PendingRequest*>(user_data);
  BusyMarkWebRenderHost* self = request->host;
  if (self->shutting_down || self->web_view == nullptr) {
    request->snapshot_wait_source_id = 0;
    respond_pending_error(request, "visualization.hostUnavailable",
                          "The WebKit host is shutting down.");
    complete_active(self);
    return G_SOURCE_REMOVE;
  }
  const gint allocated_width =
      gtk_widget_get_allocated_width(GTK_WIDGET(self->web_view));
  const gint allocated_height =
      gtk_widget_get_allocated_height(GTK_WIDGET(self->web_view));
  if (allocated_width < request->snapshot_width ||
      allocated_height < request->snapshot_height) {
    request->snapshot_allocation_attempts++;
    if (request->snapshot_allocation_attempts < 100) {
      gtk_widget_queue_resize(self->offscreen_window);
      return G_SOURCE_CONTINUE;
    }
    respond_pending_error(
        request, "visualization.rasterFailed",
        "GTK did not allocate the requested WebKit raster dimensions.");
    request->snapshot_wait_source_id = 0;
    complete_active(self);
    return G_SOURCE_REMOVE;
  }
  request->snapshot_wait_source_id = 0;
  webkit_web_view_get_snapshot(
      self->web_view, WEBKIT_SNAPSHOT_REGION_FULL_DOCUMENT,
      WEBKIT_SNAPSHOT_OPTIONS_TRANSPARENT_BACKGROUND,
      self->active_cancellable, snapshot_finished_cb, request);
  return G_SOURCE_REMOVE;
}

gboolean prepare_snapshot(PendingRequest* request, const gchar* json) {
  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) value =
      fl_json_message_codec_decode(codec, json, &error);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_MAP) {
    respond_pending_error(request, "visualization.invalidHostResponse",
                          "WebKit returned invalid raster metadata.");
    return FALSE;
  }
  FlValue* width_value = fl_value_lookup_string(value, "pixelWidth");
  FlValue* height_value = fl_value_lookup_string(value, "pixelHeight");
  if (width_value == nullptr || height_value == nullptr ||
      fl_value_get_type(width_value) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(height_value) != FL_VALUE_TYPE_INT) {
    respond_pending_error(request, "visualization.invalidHostResponse",
                          "WebKit returned invalid raster dimensions.");
    return FALSE;
  }
  const gint64 width = fl_value_get_int(width_value);
  const gint64 height = fl_value_get_int(height_value);
  if (width < 1 || height < 1 || width > 8192 || height > 8192 ||
      width * height > 64000000) {
    respond_pending_error(request, "visualization.rasterTooLarge",
                          "Raster dimensions exceed the WebKit limit.");
    return FALSE;
  }
  BusyMarkWebRenderHost* self = request->host;
  request->snapshot_width = static_cast<gint>(width);
  request->snapshot_height = static_cast<gint>(height);
  request->snapshot_allocation_attempts = 0;
  gtk_widget_set_size_request(GTK_WIDGET(self->web_view),
                              static_cast<gint>(width),
                              static_cast<gint>(height));
  gtk_widget_set_size_request(self->offscreen_window, static_cast<gint>(width),
                              static_cast<gint>(height));
  gtk_window_set_default_size(GTK_WINDOW(self->offscreen_window),
                              static_cast<gint>(width),
                              static_cast<gint>(height));
  gtk_window_resize(GTK_WINDOW(self->offscreen_window),
                    static_cast<gint>(width), static_cast<gint>(height));
  gtk_widget_queue_resize(self->offscreen_window);
  request->snapshot_wait_source_id =
      g_timeout_add(10, begin_snapshot_cb, request);
  return TRUE;
}

void javascript_finished_cb(GObject* object,
                            GAsyncResult* result,
                            gpointer user_data) {
  auto* request = static_cast<PendingRequest*>(user_data);
  BusyMarkWebRenderHost* self = request->host;
  g_autoptr(GError) error = nullptr;
  JSCValue* value = webkit_web_view_call_async_javascript_function_finish(
      WEBKIT_WEB_VIEW(object), result, &error);
  if (value == nullptr) {
    respond_pending_error(request, "visualization.webRenderFailed",
                          error != nullptr ? error->message
                                           : "The WebKit renderer failed.");
    complete_active(self);
    return;
  }
  g_autofree gchar* json = jsc_value_to_string(value);
  g_object_unref(value);
  if (json == nullptr) {
    respond_pending_error(request, "visualization.invalidHostResponse",
                          "The WebKit renderer returned no result.");
    complete_active(self);
    return;
  }
  if (g_strcmp0(request->operation, "rasterizeSvg") == 0) {
    if (!prepare_snapshot(request, json)) {
      complete_active(self);
    }
    return;
  }
  respond_json(request, json);
  complete_active(self);
}

void start_request(BusyMarkWebRenderHost* self, PendingRequest* request) {
  self->active = request;
  request->host = BUSYMARK_WEB_RENDER_HOST(g_object_ref(self));
  self->active_cancellable = g_cancellable_new();
  g_autoptr(GVariant) arguments =
      javascript_arguments(request->operation, request->arguments_json);
  constexpr char kBody[] =
      "if (typeof window.busymarkRender !== 'function') {"
      "await new Promise((resolve, reject) => {"
      "const timer = window.setTimeout(() => reject(new Error("
      "'The visualization harness did not initialize.')), 15000);"
      "window.addEventListener('busymark-render-ready', () => {"
      "window.clearTimeout(timer); resolve();"
      "}, { once: true });"
      "});"
      "}"
      "const request = JSON.parse(requestJson);"
      "request.operation = operation;"
      "return JSON.stringify(await window.busymarkRender(request));";
  webkit_web_view_call_async_javascript_function(
      self->web_view, kBody, -1, arguments, nullptr, kHarnessUri,
      self->active_cancellable, javascript_finished_cb, request);
}

void pump_requests(BusyMarkWebRenderHost* self) {
  if (self->shutting_down || !self->ready || self->active != nullptr ||
      self->web_view == nullptr || g_queue_is_empty(self->queue)) {
    return;
  }
  start_request(
      self, static_cast<PendingRequest*>(g_queue_pop_head(self->queue)));
}

void render_load_changed_cb(WebKitWebView*,
                            WebKitLoadEvent event,
                            gpointer user_data) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(user_data);
  if (event == WEBKIT_LOAD_FINISHED) {
    self->ready = TRUE;
    if (self->release_smoke_recovery_call != nullptr) {
      g_autoptr(FlValue) result = fl_value_new_null();
      fl_method_call_respond_success(self->release_smoke_recovery_call, result,
                                     nullptr);
      g_clear_object(&self->release_smoke_recovery_call);
    }
    pump_requests(self);
  }
}

void render_process_terminated_cb(WebKitWebView*,
                                  WebKitWebProcessTerminationReason,
                                  gpointer user_data) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(user_data);
  self->ready = FALSE;
  self->recreate_requested = TRUE;
  if (self->active_cancellable != nullptr) {
    g_cancellable_cancel(self->active_cancellable);
  } else if (!self->shutting_down) {
    schedule_render_view_recreation(self);
  }
}

void destroy_render_view(BusyMarkWebRenderHost* self) {
  self->ready = FALSE;
  self->web_view = nullptr;
  if (self->offscreen_window != nullptr) {
    gtk_widget_destroy(self->offscreen_window);
    self->offscreen_window = nullptr;
  }
}

void recreate_render_view(BusyMarkWebRenderHost* self) {
  destroy_render_view(self);
  if (self->shutting_down || self->resource_root == nullptr) {
    return;
  }
  self->offscreen_window = gtk_offscreen_window_new();
  gtk_window_set_default_size(GTK_WINDOW(self->offscreen_window), 1, 1);
  self->web_view = WEBKIT_WEB_VIEW(
      webkit_web_view_new_with_context(self->context));
  configure_web_view(self->web_view);
  g_signal_connect(self->web_view, "load-changed",
                   G_CALLBACK(render_load_changed_cb), self);
  g_signal_connect(self->web_view, "web-process-terminated",
                   G_CALLBACK(render_process_terminated_cb), self);
  gtk_container_add(GTK_CONTAINER(self->offscreen_window),
                    GTK_WIDGET(self->web_view));
  gtk_widget_set_size_request(GTK_WIDGET(self->web_view), 1, 1);
  gtk_widget_show_all(self->offscreen_window);
  webkit_web_view_load_uri(self->web_view, kHarnessUri);
}

gboolean recreate_render_view_cb(gpointer user_data) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(user_data);
  self->recreate_source_id = 0;
  if (!self->shutting_down && self->recreate_requested) {
    self->recreate_requested = FALSE;
    recreate_render_view(self);
  }
  return G_SOURCE_REMOVE;
}

void schedule_render_view_recreation(BusyMarkWebRenderHost* self) {
  if (self->shutting_down || self->recreate_source_id != 0) {
    return;
  }
  self->recreate_source_id = g_idle_add_full(
      G_PRIORITY_DEFAULT_IDLE, recreate_render_view_cb, g_object_ref(self),
      g_object_unref);
}

void reference_async_finished_cb(GObject* object,
                                 GAsyncResult* result,
                                 gpointer user_data) {
  auto* data = static_cast<ReferenceAsyncData*>(user_data);
  g_autoptr(GError) error = nullptr;
  JSCValue* value = webkit_web_view_call_async_javascript_function_finish(
      WEBKIT_WEB_VIEW(object), result, &error);
  if (value == nullptr) {
    g_warning("Failed to initialize Scalar API Reference: %s",
              error != nullptr ? error->message : "unknown error");
  } else {
    g_object_unref(value);
  }
  g_clear_object(&data->web_view);
  g_free(data);
}

void reference_load_changed_cb(WebKitWebView* web_view,
                               WebKitLoadEvent event,
                               gpointer user_data) {
  auto* data = static_cast<ReferenceLoadData*>(user_data);
  if (event != WEBKIT_LOAD_FINISHED || data->started) {
    return;
  }
  data->started = TRUE;
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE_VARDICT);
  g_variant_builder_add(&builder, "{sv}", "requestJson",
                        g_variant_new_string(data->arguments_json));
  g_autoptr(GVariant) arguments = g_variant_builder_end(&builder);
  constexpr char kBody[] =
      "if (typeof window.busymarkOpenReference !== 'function') {"
      "await new Promise((resolve, reject) => {"
      "const timer = window.setTimeout(() => reject(new Error("
      "'The API Reference harness did not initialize.')), 15000);"
      "window.addEventListener('busymark-reference-ready', () => {"
      "window.clearTimeout(timer); resolve();"
      "}, { once: true });"
      "});"
      "}"
      "return JSON.stringify(await "
      "window.busymarkOpenReference(JSON.parse(requestJson)));";
  auto* async_data = g_new0(ReferenceAsyncData, 1);
  async_data->web_view = WEBKIT_WEB_VIEW(g_object_ref(web_view));
  webkit_web_view_call_async_javascript_function(
      web_view, kBody, -1, arguments, nullptr, kReferenceUri, nullptr,
      reference_async_finished_cb, async_data);
}

void reference_load_data_free(gpointer user_data, GClosure*) {
  auto* data = static_cast<ReferenceLoadData*>(user_data);
  g_clear_pointer(&data->arguments_json, g_free);
  g_free(data);
}

void reference_process_terminated_cb(WebKitWebView* web_view,
                                     WebKitWebProcessTerminationReason,
                                     gpointer user_data) {
  auto* data = static_cast<ReferenceLoadData*>(user_data);
  data->started = FALSE;
  webkit_web_view_reload(web_view);
}

void open_reference_window(BusyMarkWebRenderHost* self,
                           FlMethodCall* method_call,
                           FlValue* args,
                           const gchar* arguments_json) {
  if (self->resource_root == nullptr || self->application == nullptr) {
    respond_error(method_call, "visualization.hostUnavailable",
                  "The bundled visualization resources could not be found.");
    return;
  }
  GtkWidget* window = gtk_application_window_new(self->application);
  gtk_window_set_default_size(GTK_WINDOW(window), 1100, 760);
  if (self->parent_window != nullptr) {
    gtk_window_set_transient_for(GTK_WINDOW(window), self->parent_window);
  }
  const gchar* title = nullptr;
  if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* title_value = fl_value_lookup_string(args, "title");
    if (title_value != nullptr &&
        fl_value_get_type(title_value) == FL_VALUE_TYPE_STRING) {
      title = fl_value_get_string(title_value);
    }
  }
  g_autofree gchar* window_title = g_strdup_printf(
      "%s — BusyMark", title != nullptr && title[0] != '\0'
                            ? title
                            : "API Reference");
  gtk_window_set_title(GTK_WINDOW(window), window_title);

  WebKitWebView* web_view = WEBKIT_WEB_VIEW(
      webkit_web_view_new_with_context(self->context));
  configure_web_view(web_view);
  auto* load_data = g_new0(ReferenceLoadData, 1);
  load_data->arguments_json = g_strdup(arguments_json);
  g_signal_connect(web_view, "web-process-terminated",
                   G_CALLBACK(reference_process_terminated_cb), load_data);
  g_signal_connect_data(web_view, "load-changed",
                        G_CALLBACK(reference_load_changed_cb), load_data,
                        reference_load_data_free,
                        static_cast<GConnectFlags>(0));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(web_view));
  gtk_widget_show_all(window);
  webkit_web_view_load_uri(web_view, kReferenceUri);
  g_autoptr(FlValue) result = fl_value_new_null();
  fl_method_call_respond_success(method_call, result, nullptr);
}

gchar* encode_arguments(FlValue* args, GError** error) {
  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  g_autoptr(FlValue) null_value = nullptr;
  if (args == nullptr) {
    null_value = fl_value_new_null();
    args = null_value;
  }
  return fl_json_message_codec_encode(codec, args, error);
}

gboolean is_render_operation(const gchar* method) {
  return g_strcmp0(method, "renderMermaid") == 0 ||
         g_strcmp0(method, "renderPlantUml") == 0 ||
         g_strcmp0(method, "inspectOpenApi") == 0 ||
         g_strcmp0(method, "parseOpenApi") == 0 ||
         g_strcmp0(method, "rasterizeSvg") == 0;
}

void cancel_render_request(BusyMarkWebRenderHost* self,
                           FlMethodCall* method_call,
                           FlValue* args) {
  FlValue* request_id_value =
      args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP
          ? fl_value_lookup_string(args, "requestId")
          : nullptr;
  if (request_id_value == nullptr ||
      fl_value_get_type(request_id_value) != FL_VALUE_TYPE_STRING) {
    respond_error(method_call, "visualization.invalidArguments",
                  "A visualization request ID is required.");
    return;
  }
  const gchar* request_id = fl_value_get_string(request_id_value);
  gboolean cancelled = FALSE;
  if (self->active != nullptr &&
      g_strcmp0(self->active->request_id, request_id) == 0) {
    cancelled = TRUE;
    if (self->active_cancellable != nullptr) {
      g_cancellable_cancel(self->active_cancellable);
    }
  } else {
    for (GList* link = self->queue->head; link != nullptr;
         link = link->next) {
      auto* request = static_cast<PendingRequest*>(link->data);
      if (g_strcmp0(request->request_id, request_id) != 0) {
        continue;
      }
      g_queue_delete_link(self->queue, link);
      respond_pending_error(request, "visualization.cancelled",
                            "The visualization render was cancelled.");
      pending_request_free(request);
      cancelled = TRUE;
      break;
    }
  }
  g_autoptr(FlValue) result = fl_value_new_bool(cancelled);
  fl_method_call_respond_success(method_call, result, nullptr);
}

void copy_visualization_image(FlMethodCall* method_call, FlValue* args) {
  FlValue* png_value =
      args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP
          ? fl_value_lookup_string(args, "png")
          : nullptr;
  if (png_value == nullptr ||
      fl_value_get_type(png_value) != FL_VALUE_TYPE_UINT8_LIST) {
    respond_error(method_call, "visualization.invalidArguments",
                  "PNG clipboard data is required.");
    return;
  }
  const size_t length = fl_value_get_length(png_value);
  if (length == 0 || length > kMaximumPngBytes) {
    respond_error(method_call, "visualization.imageTooLarge",
                  "Clipboard image data is empty or exceeds the size limit.");
    return;
  }

  g_autoptr(GError) error = nullptr;
  g_autoptr(GdkPixbufLoader) loader =
      gdk_pixbuf_loader_new_with_type("png", &error);
  const guint8* bytes = fl_value_get_uint8_list(png_value);
  if (loader == nullptr ||
      !gdk_pixbuf_loader_write(loader, bytes, length, &error) ||
      !gdk_pixbuf_loader_close(loader, &error)) {
    respond_error(method_call, "visualization.invalidClipboardImage",
                  error != nullptr ? error->message
                                   : "Clipboard PNG data is invalid.");
    return;
  }
  GdkPixbuf* pixbuf = gdk_pixbuf_loader_get_pixbuf(loader);
  if (pixbuf == nullptr) {
    respond_error(method_call, "visualization.invalidClipboardImage",
                  "Clipboard PNG data could not be decoded.");
    return;
  }
  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  gtk_clipboard_set_image(clipboard, pixbuf);
  g_autoptr(FlValue) result = fl_value_new_null();
  fl_method_call_respond_success(method_call, result, nullptr);
}

gboolean terminate_web_process_for_release_smoke_cb(gpointer user_data) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(user_data);
  self->release_smoke_terminate_source_id = 0;
  if (self->shutting_down || self->web_view == nullptr ||
      self->release_smoke_recovery_call == nullptr) {
    return G_SOURCE_REMOVE;
  }
  self->ready = FALSE;
  webkit_web_view_terminate_web_process(self->web_view);
  return G_SOURCE_REMOVE;
}

void terminate_web_process_for_release_smoke(BusyMarkWebRenderHost* self,
                                             FlMethodCall* method_call) {
  const gchar* enabled = g_getenv("BUSYMARK_RELEASE_SMOKE");
  if (g_strcmp0(enabled, "1") != 0) {
    respond_error(method_call, "visualization.releaseSmokeDisabled",
                  "The release visualization smoke hook is disabled.");
    return;
  }
  if (!self->ready || self->web_view == nullptr || self->active != nullptr ||
      !g_queue_is_empty(self->queue) ||
      self->release_smoke_recovery_call != nullptr) {
    respond_error(method_call, "visualization.hostBusy",
                  "The WebKit host is not idle for its recovery check.");
    return;
  }
  self->release_smoke_recovery_call =
      FL_METHOD_CALL(g_object_ref(method_call));
  self->release_smoke_terminate_source_id = g_idle_add_full(
      G_PRIORITY_DEFAULT_IDLE, terminate_web_process_for_release_smoke_cb,
      g_object_ref(self), g_object_unref);
}

void method_call_cb(FlMethodChannel*,
                    FlMethodCall* method_call,
                    gpointer user_data) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(user_data);
  if (self->shutting_down) {
    respond_error(method_call, "visualization.hostUnavailable",
                  "The WebKit host is shutting down.");
    return;
  }
  const gchar* method = fl_method_call_get_name(method_call);
  if (g_strcmp0(method, "cancelRender") == 0) {
    cancel_render_request(self, method_call,
                          fl_method_call_get_args(method_call));
    return;
  }
  if (g_strcmp0(method, "copyVisualizationImage") == 0) {
    copy_visualization_image(method_call,
                             fl_method_call_get_args(method_call));
    return;
  }
  if (g_strcmp0(method, "terminateWebProcessForReleaseSmoke") == 0) {
    terminate_web_process_for_release_smoke(self, method_call);
    return;
  }
  if (!is_render_operation(method) &&
      g_strcmp0(method, "openOpenApiReference") != 0) {
    fl_method_call_respond_not_implemented(method_call, nullptr);
    return;
  }
  g_autoptr(GError) error = nullptr;
  g_autofree gchar* arguments_json =
      encode_arguments(fl_method_call_get_args(method_call), &error);
  if (arguments_json == nullptr) {
    respond_error(method_call, "visualization.invalidArguments",
                  error != nullptr ? error->message
                                   : "Visualization arguments are invalid.");
    return;
  }
  if (strlen(arguments_json) > kMaximumRequestBytes) {
    respond_error(method_call, "visualization.sourceTooLarge",
                  "Visualization arguments exceed the size limit.");
    return;
  }
  if (g_strcmp0(method, "openOpenApiReference") == 0) {
    open_reference_window(self, method_call,
                          fl_method_call_get_args(method_call),
                          arguments_json);
    return;
  }
  if (self->resource_root == nullptr) {
    respond_error(method_call, "visualization.hostUnavailable",
                  "The bundled visualization resources could not be found.");
    return;
  }
  auto* request = g_new0(PendingRequest, 1);
  request->method_call = FL_METHOD_CALL(g_object_ref(method_call));
  request->operation = g_strdup(method);
  FlValue* method_args = fl_method_call_get_args(method_call);
  FlValue* request_id_value =
      method_args != nullptr &&
              fl_value_get_type(method_args) == FL_VALUE_TYPE_MAP
          ? fl_value_lookup_string(method_args, "requestId")
          : nullptr;
  request->request_id =
      request_id_value != nullptr &&
              fl_value_get_type(request_id_value) == FL_VALUE_TYPE_STRING
          ? g_strdup(fl_value_get_string(request_id_value))
          : g_uuid_string_random();
  request->arguments_json = g_strdup(arguments_json);
  g_queue_push_tail(self->queue, request);
  pump_requests(self);
}

}  // namespace

void busymark_web_render_host_shutdown(BusyMarkWebRenderHost* self) {
  g_return_if_fail(BUSYMARK_IS_WEB_RENDER_HOST(self));
  if (self->shutting_down) {
    return;
  }
  self->shutting_down = TRUE;
  if (self->release_smoke_terminate_source_id != 0) {
    g_source_remove(self->release_smoke_terminate_source_id);
    self->release_smoke_terminate_source_id = 0;
  }
  if (self->recreate_source_id != 0) {
    g_source_remove(self->recreate_source_id);
    self->recreate_source_id = 0;
  }
  if (self->release_smoke_recovery_call != nullptr) {
    respond_error(self->release_smoke_recovery_call,
                  "visualization.hostUnavailable",
                  "The WebKit host is shutting down.");
    g_clear_object(&self->release_smoke_recovery_call);
  }
  if (self->active_cancellable != nullptr) {
    g_cancellable_cancel(self->active_cancellable);
  }
  while (!g_queue_is_empty(self->queue)) {
    auto* request =
        static_cast<PendingRequest*>(g_queue_pop_head(self->queue));
    respond_pending_error(request, "visualization.hostUnavailable",
                          "The WebKit host is shutting down.");
    pending_request_free(request);
  }
  destroy_render_view(self);
}

void busymark_web_render_host_register_channel(BusyMarkWebRenderHost* self,
                                               FlView* view) {
  g_return_if_fail(BUSYMARK_IS_WEB_RENDER_HOST(self));
  g_return_if_fail(FL_IS_VIEW(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), kChannelName,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            self, nullptr);
}

BusyMarkWebRenderHost* busymark_web_render_host_new(
    GtkApplication* application,
    GtkWindow* parent_window) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(
      g_object_new(busymark_web_render_host_get_type(), nullptr));
  self->application = application;
  self->parent_window = parent_window;
  self->resource_root = locate_resource_root();
  self->context = webkit_web_context_new_ephemeral();
  webkit_web_context_set_cache_model(self->context,
                                     WEBKIT_CACHE_MODEL_DOCUMENT_VIEWER);
  webkit_web_context_set_spell_checking_enabled(self->context, FALSE);
  // The auto-connected Snap browser-support interface uses allow-sandbox:
  // false. Inside that package, snapd's strict AppArmor/seccomp confinement is
  // the outer sandbox; everywhere else retain WebKit's subprocess sandbox.
  const gchar* snap_root = g_getenv("SNAP");
  const gboolean strictly_confined_snap =
      snap_root != nullptr && snap_root[0] != '\0';
  webkit_web_context_set_sandbox_enabled(self->context,
                                         !strictly_confined_snap);
  webkit_web_context_register_uri_scheme(self->context, kScheme,
                                         uri_scheme_request_cb, self,
                                         nullptr);
  WebKitSecurityManager* security_manager =
      webkit_web_context_get_security_manager(self->context);
  webkit_security_manager_register_uri_scheme_as_secure(security_manager,
                                                         kScheme);
  webkit_security_manager_register_uri_scheme_as_cors_enabled(
      security_manager, kScheme);
  WebKitCookieManager* cookie_manager =
      webkit_web_context_get_cookie_manager(self->context);
  webkit_cookie_manager_set_accept_policy(
      cookie_manager, WEBKIT_COOKIE_POLICY_ACCEPT_NEVER);
  recreate_render_view(self);
  return self;
}

static void busymark_web_render_host_dispose(GObject* object) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(object);
  busymark_web_render_host_shutdown(self);
  g_clear_object(&self->channel);
  g_clear_object(&self->release_smoke_recovery_call);
  g_clear_object(&self->active_cancellable);
  g_clear_object(&self->context);
  G_OBJECT_CLASS(busymark_web_render_host_parent_class)->dispose(object);
}

static void busymark_web_render_host_finalize(GObject* object) {
  auto* self = BUSYMARK_WEB_RENDER_HOST(object);
  g_clear_pointer(&self->queue, g_queue_free);
  g_clear_pointer(&self->resource_root, g_free);
  G_OBJECT_CLASS(busymark_web_render_host_parent_class)->finalize(object);
}

static void busymark_web_render_host_class_init(
    BusyMarkWebRenderHostClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = busymark_web_render_host_dispose;
  object_class->finalize = busymark_web_render_host_finalize;
}

static void busymark_web_render_host_init(BusyMarkWebRenderHost* self) {
  self->queue = g_queue_new();
}
