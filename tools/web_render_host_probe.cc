// Runs the production native channel and real WebKit; only Flutter transport
// and a one-shot context-allocation failure are injected. No Dart mock host.
#include <cstdio>
#include <functional>
#include <map>
#include <string>

#include "../linux/runner/web_render_host.cc"
#include "../linux/runner/video_player_host.h"

constexpr char kMethods[] = "io.busystack.busymark/visualization";
// Synthetic 16x16 red VP8/WebM: ffmpeg lavfi color, 1 fps, two seconds.
// Embedded so the decoder regression needs no ffmpeg executable or download.
constexpr char kLocalVideoBase64[] =
    "GkXfo59ChoEBQveBAULygQRC84EIQoKEd2VibUKHgQJChYECGFOAZwEAAAAAAAITEU2bdLpNu4tT"
    "q4QVSalmU6yBoU27i1OrhBZUrmtTrIHYTbuMU6uEElTDZ1OsggEeTbuMU6uEHFO7a1OsggH97AEA"
    "AAAAAABZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVSalmsirXsYMPQkBNgI1MYXZm"
    "NjAuMTYuMTAwV0GNTGF2ZjYwLjE2LjEwMESJiECfQAAAAAAAFlSua8GuAQAAAAAAADjXgQFzxYg2"
    "ixILCHEv6pyBACK1nIN1bmSIgQCGhVZfVlA4g4EBI+ODhDuaygDgibCBELqBEJqBAhJUw2f8c3Og"
    "Y8CAZ8iaRaOHRU5DT0RFUkSHjUxhdmY2MC4xNi4xMDBzc9ZjwItjxYg2ixILCHEv6mfIoUWjh0VO"
    "Q09ERVJEh5RMYXZjNjAuMzEuMTAyIGxpYnZweGfIoUWjiERVUkFUSU9ORIeTMDA6MDA6MDIuMDAw"
    "MDAwMDAwAB9DtnXZ54EAo72BAACA8AIAnQEqEAAQAABHCIWFiIWEiAICAnWqA/gD+gINTRgA/v1u"
    "8//jmTcwxP+Obf/xYTwOKMj/8VEAo5WBA+gAsQEAARAQABgAGFgv9AAIAAAcU7trkbuPs4EAt4r3"
    "gQHxggGf8IED";
struct Handler {
  FlBinaryMessengerMessageHandler callback;
  gpointer data;
  GDestroyNotify destroy;
};

struct TestMessenger {
  GObject parent;
  GHashTable* handlers;
  GPtrArray* events;
};
struct TestMessengerClass {
  GObjectClass parent;
};
static void messenger_interface_init(FlBinaryMessengerInterface* iface);
G_DEFINE_TYPE_WITH_CODE(TestMessenger, test_messenger, G_TYPE_OBJECT,
                        G_IMPLEMENT_INTERFACE(fl_binary_messenger_get_type(),
                                              messenger_interface_init))

struct TestResponse {
  FlBinaryMessengerResponseHandle parent;
  GBytes* bytes;
  bool responded;
};
struct TestResponseClass {
  FlBinaryMessengerResponseHandleClass parent;
};
G_DEFINE_TYPE(TestResponse, test_response,
              fl_binary_messenger_response_handle_get_type())

static void test_response_finalize(GObject* object) {
  g_clear_pointer(&reinterpret_cast<TestResponse*>(object)->bytes,
                  g_bytes_unref);
  G_OBJECT_CLASS(test_response_parent_class)->finalize(object);
}
static void test_response_class_init(TestResponseClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = test_response_finalize;
}
static void test_response_init(TestResponse*) {}
G_DEFINE_AUTOPTR_CLEANUP_FUNC(TestResponse, g_object_unref)

static void free_handler(gpointer data) {
  auto* handler = static_cast<Handler*>(data);
  if (handler->destroy != nullptr) handler->destroy(handler->data);
  delete handler;
}
static void set_handler(FlBinaryMessenger* messenger, const gchar* channel,
                        FlBinaryMessengerMessageHandler callback, gpointer data,
                        GDestroyNotify destroy) {
  auto* self = reinterpret_cast<TestMessenger*>(messenger);
  g_hash_table_remove(self->handlers, channel);
  if (callback != nullptr) {
    g_hash_table_insert(self->handlers, g_strdup(channel),
                        new Handler{callback, data, destroy});
  } else if (destroy != nullptr) {
    destroy(data);
  }
}
static gboolean send_response(FlBinaryMessenger*,
                              FlBinaryMessengerResponseHandle* handle,
                              GBytes* bytes, GError**) {
  auto* response = reinterpret_cast<TestResponse*>(handle);
  g_assert_false(response->responded);
  response->responded = true;
  response->bytes =
      bytes != nullptr ? g_bytes_ref(bytes) : g_bytes_new(nullptr, 0);
  return TRUE;
}
static void send_event(FlBinaryMessenger* messenger, const gchar* channel,
                       GBytes* message, GCancellable*,
                       GAsyncReadyCallback callback, gpointer) {
  (void)channel;
  g_assert_null(callback);  // FlEventChannel sends unacknowledged envelopes.
  g_assert_nonnull(message);
  g_ptr_array_add(reinterpret_cast<TestMessenger*>(messenger)->events,
                  g_bytes_ref(message));
}
static void shutdown_messenger(FlBinaryMessenger* messenger) {
  g_hash_table_remove_all(
      reinterpret_cast<TestMessenger*>(messenger)->handlers);
}
static void messenger_interface_init(FlBinaryMessengerInterface* iface) {
  iface->set_message_handler_on_channel = set_handler;
  iface->send_response = send_response;
  iface->send_on_channel = send_event;
  iface->shutdown = shutdown_messenger;
}
static void test_messenger_finalize(GObject* object) {
  auto* self = reinterpret_cast<TestMessenger*>(object);
  g_hash_table_unref(self->handlers);
  g_ptr_array_unref(self->events);
  G_OBJECT_CLASS(test_messenger_parent_class)->finalize(object);
}
static void test_messenger_class_init(TestMessengerClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = test_messenger_finalize;
}
static void test_messenger_init(TestMessenger* self) {
  self->handlers =
      g_hash_table_new_full(g_str_hash, g_str_equal, g_free, free_handler);
  self->events = g_ptr_array_new_with_free_func(
      reinterpret_cast<GDestroyNotify>(g_bytes_unref));
}

static TestMessenger* active_messenger = nullptr;
// --wrap affects the production host's call, not calls inside Flutter's shared
// library. This is the sole injected I/O boundary; channel handlers are real.
extern "C" FlBinaryMessenger* __wrap_fl_engine_get_binary_messenger(
    FlEngine* engine) {
  g_assert_true(FL_IS_ENGINE(engine));
  g_assert_nonnull(active_messenger);
  return FL_BINARY_MESSENGER(active_messenger);
}

static void drain() {
  int iterations = 0;
  while (g_main_context_pending(nullptr)) {
    g_main_context_iteration(nullptr, FALSE);
    g_assert_cmpint(++iterations, <, 10000);
  }
}

extern "C" WebKitWebContext* __real_webkit_web_context_new_ephemeral();
static unsigned contexts = 0;
static unsigned views = 0;
static unsigned harness_loads = 0;
static bool fail_view = false;
extern "C" GtkWidget* __real_webkit_web_view_new_with_context(
    WebKitWebContext*);
extern "C" GtkWidget* __wrap_webkit_web_view_new_with_context(
    WebKitWebContext* context) {
  ++views;
  if (fail_view) {
    fail_view = false;
    return nullptr;
  }
  return __real_webkit_web_view_new_with_context(context);
}
extern "C" void __real_webkit_web_view_load_uri(WebKitWebView*, const gchar*);
extern "C" void __wrap_webkit_web_view_load_uri(WebKitWebView* view,
                                                const gchar* uri) {
  if (g_strcmp0(uri, kHarnessUri) == 0) ++harness_loads;
  __real_webkit_web_view_load_uri(view, uri);
}
static bool fail_context = false;
extern "C" WebKitWebContext* __wrap_webkit_web_context_new_ephemeral() {
  ++contexts;
  if (fail_context) {
    fail_context = false;
    return nullptr;
  }
  return __real_webkit_web_context_new_ephemeral();
}

static std::map<std::string, unsigned> resource_reads;
static bool fail_engine_read = false;
static const char* failed_engine_resource = "mermaid-engine.js";
extern "C" gboolean __real_g_file_get_contents(const gchar*, gchar**, gsize*,
                                               GError**);
extern "C" gboolean __wrap_g_file_get_contents(const gchar* path,
                                               gchar** contents, gsize* length,
                                               GError** error) {
  const char* name = strrchr(path, '/');
  if (name != nullptr) {
    ++resource_reads[name + 1];
    if (fail_engine_read && strcmp(name + 1, failed_engine_resource) == 0) {
      fail_engine_read = false;
      g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND,
                          "Injected missing engine bundle");
      return FALSE;
    }
  }
  return __real_g_file_get_contents(path, contents, length, error);
}

static void only_engine(const char* expected) {
  for (const char* engine : {"mermaid", "plantuml", "math", "openapi"}) {
    const std::string name = std::string(engine) + "-engine.js";
    g_assert_cmpuint(
        resource_reads[name], ==,
        expected != nullptr && strcmp(expected, engine) == 0 ? 1 : 0);
  }
  g_assert_cmpuint(
      resource_reads["viz-global.js"], ==,
      expected != nullptr && strcmp(expected, "plantuml") == 0 ? 1 : 0);
}

static void until(const std::function<bool()>& predicate) {
  const gint64 deadline = g_get_monotonic_time() + 20000000;
  while (!predicate() && g_get_monotonic_time() < deadline) {
    g_main_context_iteration(nullptr, FALSE);
    g_usleep(1000);
  }
  g_assert_true(predicate());
}

static FlMethodResponse* decode(FlMethodCodec* codec, GBytes* bytes) {
  g_autoptr(GError) error = nullptr;
  auto* response =
      FL_METHOD_CODEC_GET_CLASS(codec)->decode_response(codec, bytes, &error);
  g_assert_no_error(error);
  g_assert_nonnull(response);
  return response;
}

struct Harness {
  TestMessenger* messenger;
  FlStandardMethodCodec* codec;
  GtkApplication* application;
  FlView* view;
  BusyMarkWebRenderHost* host;
  Harness() {
    contexts = views = harness_loads = 0;
    resource_reads.clear();
    messenger = static_cast<TestMessenger*>(
        g_object_new(test_messenger_get_type(), nullptr));
    active_messenger = messenger;
    codec = fl_standard_method_codec_new();
    application = gtk_application_new("io.busystack.busymark.nativeprobe",
                                      G_APPLICATION_NON_UNIQUE);
    g_assert_true(
        g_application_register(G_APPLICATION(application), nullptr, nullptr));
    g_autoptr(FlDartProject) project = fl_dart_project_new();
    view = fl_view_new(project);
    g_object_ref_sink(view);
    host = busymark_web_render_host_new(application, nullptr);
    busymark_web_render_host_register_channel(host, view);
    dormant();
  }
  void dormant() {
    g_assert_cmpuint(contexts, ==, 0);
    g_assert_cmpuint(views, ==, 0);
    g_assert_cmpuint(harness_loads, ==, 0);
    g_assert_null(host->context);
    g_assert_null(host->web_view);
    g_assert_null(host->offscreen_window);
    g_assert_true(resource_reads.empty());
  }
  ~Harness() {
    busymark_web_render_host_shutdown(host);
    until([&] { return host->active == nullptr; });
    BusyMarkWebRenderHost* remaining = host;
    g_object_add_weak_pointer(G_OBJECT(host),
                              reinterpret_cast<gpointer*>(&remaining));
    g_object_unref(host);
    until([&] { return remaining == nullptr; });
    shutdown_messenger(FL_BINARY_MESSENGER(messenger));
    gtk_widget_destroy(GTK_WIDGET(view));
    g_object_unref(view);
    g_object_unref(application);
    g_object_unref(codec);
    g_object_unref(messenger);
    active_messenger = nullptr;
    drain();
  }
  TestResponse* call(const char* method, FlValue* args,
                     const char* channel = kMethods) {
    auto* handler = static_cast<Handler*>(
        g_hash_table_lookup(messenger->handlers, channel));
    g_assert_nonnull(handler);
    g_autoptr(GError) error = nullptr;
    auto* method_codec = FL_METHOD_CODEC(codec);
    g_autoptr(GBytes) bytes =
        FL_METHOD_CODEC_GET_CLASS(method_codec)
            ->encode_method_call(method_codec, method, args, &error);
    g_assert_no_error(error);
    auto* response = static_cast<TestResponse*>(
        g_object_new(test_response_get_type(), nullptr));
    handler->callback(FL_BINARY_MESSENGER(messenger), channel, bytes,
                      FL_BINARY_MESSENGER_RESPONSE_HANDLE(response),
                      handler->data);
    return response;
  }
  FlValue* success(TestResponse* response) {
    until([&] { return response->responded; });
    g_autoptr(FlMethodResponse) decoded =
        decode(FL_METHOD_CODEC(codec), response->bytes);
    if (FL_IS_METHOD_ERROR_RESPONSE(decoded)) {
      auto* e = FL_METHOD_ERROR_RESPONSE(decoded);
      g_error("%s: %s", fl_method_error_response_get_code(e),
              fl_method_error_response_get_message(e));
    }
    g_assert_true(FL_IS_METHOD_SUCCESS_RESPONSE(decoded));
    return fl_value_ref(fl_method_success_response_get_result(
        FL_METHOD_SUCCESS_RESPONSE(decoded)));
  }
  void error(TestResponse* response, const char* code) {
    until([&] { return response->responded; });
    g_autoptr(FlMethodResponse) decoded =
        decode(FL_METHOD_CODEC(codec), response->bytes);
    g_assert_true(FL_IS_METHOD_ERROR_RESPONSE(decoded));
    g_assert_cmpstr(
        fl_method_error_response_get_code(FL_METHOD_ERROR_RESPONSE(decoded)),
        ==, code);
  }
};

constexpr char kApi[] =
    R"({"openapi":"3.0.3","info":{"title":"First reference","version":"1"},"paths":{"/health":{"get":{"responses":{"200":{"description":"Healthy"}}}}}})";
constexpr char kSvg[] =
    R"(<svg xmlns="http://www.w3.org/2000/svg" width="120" height="80"><rect width="60" height="80" fill="red"/><rect x="60" width="60" height="80" fill="blue"/></svg>)";
static FlValue* args(const char* operation, const char* id = "first") {
  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  std::string json;
  if (strcmp(operation, "renderMathBatch") == 0) {
    json =
        R"({"expressions":[{"id":"one","expression":"x^2","display":true}]})";
  } else if (strcmp(operation, "renderPlantUml") == 0) {
    json =
        R"({"source":"@startuml\nAlice -> Bob: First\n@enduml","theme":"light"})";
  } else if (strcmp(operation, "renderMermaid") == 0) {
    json = R"({"source":"graph LR; First-->Output","theme":"light"})";
  } else {
    json = "{}";
  }
  FlValue* result = fl_json_message_codec_decode(codec, json.c_str(), nullptr);
  g_assert_nonnull(result);
  fl_value_set_string_take(result, "requestId", fl_value_new_string(id));
  if (strstr(operation, "OpenApi") != nullptr) {
    fl_value_set_string_take(result, "source", fl_value_new_string(kApi));
    fl_value_set_string_take(result, "entryId",
                             fl_value_new_string("first.json"));
    fl_value_set_string_take(result, "title",
                             fl_value_new_string("First reference"));
    fl_value_set_string_take(result, "theme", fl_value_new_string("light"));
  }
  if (strcmp(operation, "rasterizeSvg") == 0) {
    fl_value_set_string_take(result, "svg", fl_value_new_string(kSvg));
    fl_value_set_string_take(result, "width", fl_value_new_float(120));
    fl_value_set_string_take(result, "height", fl_value_new_float(80));
    fl_value_set_string_take(result, "scale", fl_value_new_float(1));
  }
  return result;
}
static void verify(const char* operation, FlValue* result) {
  if (strcmp(operation, "rasterizeSvg") == 0) {
    g_assert_cmpint(fl_value_get_type(result), ==, FL_VALUE_TYPE_UINT8_LIST);
    g_autoptr(GdkPixbufLoader) loader =
        gdk_pixbuf_loader_new_with_type("png", nullptr);
    g_assert_true(
        gdk_pixbuf_loader_write(loader, fl_value_get_uint8_list(result),
                                fl_value_get_length(result), nullptr));
    g_assert_true(gdk_pixbuf_loader_close(loader, nullptr));
    GdkPixbuf* pixbuf = gdk_pixbuf_loader_get_pixbuf(loader);
    g_assert_cmpint(gdk_pixbuf_get_width(pixbuf), ==, 120);
    g_assert_cmpint(gdk_pixbuf_get_height(pixbuf), ==, 80);
    const auto* pixels = gdk_pixbuf_get_pixels(pixbuf);
    const int channels = gdk_pixbuf_get_n_channels(pixbuf);
    g_assert_cmpint(pixels[0], >, 200);
    g_assert_cmpint(pixels[100 * channels + 2], >, 200);
  } else if (strcmp(operation, "renderMathBatch") == 0) {
    FlValue* results = fl_value_lookup_string(result, "results");
    g_assert_cmpuint(fl_value_get_length(results), ==, 1);
    FlValue* svg =
        fl_value_lookup_string(fl_value_get_list_value(results, 0), "svg");
    g_assert_nonnull(svg);
    g_assert_nonnull(strstr(fl_value_get_string(svg), "<path"));
  } else if (strcmp(operation, "inspectOpenApi") == 0) {
    g_assert_nonnull(fl_value_lookup_string(result, "references"));
  } else if (strcmp(operation, "parseOpenApi") == 0) {
    g_assert_nonnull(fl_value_lookup_string(result, "reference"));
  } else {
    FlValue* svg = fl_value_lookup_string(result, "svg");
    g_assert_nonnull(svg);
    g_assert_nonnull(strstr(fl_value_get_string(svg), "<svg"));
    g_assert_nonnull(
        strstr(fl_value_get_string(svg),
               strcmp(operation, "renderMermaid") == 0 ? "First" : "Alice"));
  }
}

static void assert_local_video_playback(WebKitWebView* view, bool mini,
                                        bool expect_error = false) {
  until([&] {
    return webkit_web_view_get_uri(view) != nullptr &&
           !webkit_web_view_is_loading(view);
  });
  const std::string script = expect_error ?
      "return await new Promise(resolve => { const poll = () => { "
      "if (document.querySelector('video')?.error) resolve(true); "
      "else setTimeout(poll, 20); }; poll(); });" :
      "const mini = " + std::string(mini ? "true" : "false") + "; "
      "await new Promise((resolve, reject) => { const poll = () => { "
      "const v = document.querySelector('video'); "
      "if (v?.error) { reject(new Error('Video error ' + v.error.code)); return; } "
      "if (v?.readyState >= 2) resolve(); else setTimeout(poll, 20); "
      "}; poll(); }); "
      "const v = document.querySelector('video'); "
      "const input = document.getElementById('busymark-local-media'); "
      "const correct = v.videoWidth === 16 && v.videoHeight === 16 && "
      "v.currentSrc.startsWith('blob:') && input.files.length === 1 && "
      "input.files[0].name === 'video.webm' && v.controls === !mini && "
      "!!document.getElementById('p') === mini; "
      "v.pause(); const paused = v.paused; await v.play(); "
      "return correct && paused && !v.paused;";
  bool finished = false;
  webkit_web_view_call_async_javascript_function(
      view, script.c_str(), script.size(), nullptr, nullptr, nullptr, nullptr,
      [](GObject* object, GAsyncResult* result, gpointer data) {
        g_autoptr(GError) error = nullptr;
        g_autoptr(JSCValue) value =
            webkit_web_view_call_async_javascript_function_finish(
                WEBKIT_WEB_VIEW(object), result, &error);
        g_assert_no_error(error);
        g_assert_nonnull(value);
        g_assert_true(jsc_value_to_boolean(value));
        *static_cast<bool*>(data) = true;
      },
      &finished);
  until([&] { return finished; });
}

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  g_assert_cmpint(argc, ==, 2);
  const char* mode = argv[1];
  Harness h;
  if (g_str_has_prefix(mode, "video-")) {
    constexpr char video_channel[] = "com.busymark.app/video_player";
    const bool source_failure = strcmp(mode, "video-source-failure") == 0;
    const bool playback = strcmp(mode, "video-playback") == 0 ||
                          strcmp(mode, "video-mini-playback") == 0 || source_failure;
    const bool mini = strcmp(mode, "video-mini-playback") == 0;
    g_autoptr(GtkWidget) overlay = gtk_overlay_new();
    g_object_ref_sink(overlay);
    g_autoptr(GtkWidget) video_window = nullptr;
    if (playback) {
      video_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
      g_object_ref_sink(video_window);
      gtk_window_set_default_size(GTK_WINDOW(video_window), 320, 240);
      gtk_container_add(GTK_CONTAINER(video_window), overlay);
      gtk_widget_show_all(video_window);
    }
    g_autoptr(BusyMarkVideoPlayerHost) video =
        busymark_video_player_host_new(overlay);
    busymark_video_player_host_register_channel(video, h.view);
    h.dormant();
    g_autoptr(FlValue) request = fl_value_new_map();
    fl_value_set_string_take(request, "playerId", fl_value_new_string("first"));
    for (const char* operation : {"hide", "update", "unknown"}) {
      g_autoptr(TestResponse) response = h.call(operation, request, video_channel);
      g_assert_true(response->responded);
      h.dormant();
    }
    g_autoptr(TestResponse) invalid = h.call("show", request, video_channel);
    h.error(invalid, "video.invalidRequest");
    h.dormant();
    if (strcmp(mode, "video-no-init") != 0) {
      g_autofree gchar* fixture = g_build_filename(g_get_tmp_dir(), "video.webm", nullptr);
      if (playback) {
        gsize length = 0;
        g_autofree guchar* data = g_base64_decode(kLocalVideoBase64, &length);
        g_assert_true(g_file_set_contents(
            fixture, reinterpret_cast<const gchar*>(data), length, nullptr));
      } else {
        g_assert_true(g_file_set_contents(fixture, "invalid-media-for-lifecycle-test", -1, nullptr));
      }
      fl_value_set_string_take(request, "kind", fl_value_new_string("localFile"));
      fl_value_set_string_take(request, "value", fl_value_new_string(fixture));
      fl_value_set_string_take(request, "playLabel", fl_value_new_string("Play"));
      fl_value_set_string_take(request, "pauseLabel", fl_value_new_string("Pause"));
      fl_value_set_string_take(request, "borderEffect", fl_value_new_string("rounded"));
      fl_value_set_string_take(request, "miniPlayer", fl_value_new_bool(mini));
      for (const char* key : {"x", "y", "width", "height"}) {
        fl_value_set_string_take(request, key, fl_value_new_float(100));
      }
      if (strcmp(mode, "video-failure") == 0) {
        fail_context = true;
        g_autoptr(TestResponse) failed = h.call("show", request, video_channel);
        h.error(failed, "video.invalidRequest");
        g_assert_cmpuint(views, ==, 0);
      }
      g_autoptr(TestResponse) first = h.call("show", request, video_channel);
      g_autoptr(FlValue) shown = h.success(first);
      g_assert_true(fl_value_get_bool(shown));
      const unsigned expected_contexts = strcmp(mode, "video-failure") == 0 ? 2 : 1;
      g_assert_cmpuint(contexts, ==, expected_contexts);
      g_assert_cmpuint(views, ==, 1);
      if (source_failure) g_assert_cmpint(std::remove(fixture), ==, 0);
      GList* children = gtk_container_get_children(GTK_CONTAINER(overlay));
      auto* first_view = WEBKIT_WEB_VIEW(children->data);
      auto* context = webkit_web_view_get_context(first_view);
      g_assert_true(webkit_web_context_is_ephemeral(context));
      g_assert_true(webkit_web_context_get_sandbox_enabled(context));
      g_list_free(children);
      if (playback) assert_local_video_playback(first_view, mini, source_failure);
      if (source_failure) {
        gsize length = 0;
        g_autofree guchar* data = g_base64_decode(kLocalVideoBase64, &length);
        g_assert_true(g_file_set_contents(
            fixture, reinterpret_cast<const gchar*>(data), length, nullptr));
      }
      const unsigned failed_views =
          strcmp(mode, "video-view-failure") == 0 ? 1 : 0;
      if (failed_views != 0) {
        fail_view = true;
        g_autoptr(TestResponse) failed = h.call("show", request, video_channel);
        h.error(failed, "video.invalidRequest");
        children = gtk_container_get_children(GTK_CONTAINER(overlay));
        g_assert_cmpuint(g_list_length(children), ==, 1);
        g_assert_true(children->data == first_view);
        g_list_free(children);
      }
      fl_value_set_string_take(request, "playerId", fl_value_new_string("second"));
      g_autoptr(TestResponse) second = h.call("show", request, video_channel);
      g_autoptr(FlValue) shown_second = h.success(second);
      g_assert_true(fl_value_get_bool(shown_second));
      g_assert_cmpuint(contexts, ==, expected_contexts);
      g_assert_cmpuint(views, ==, 2 + failed_views);
      g_autoptr(TestResponse) update = h.call("update", request, video_channel);
      g_autoptr(FlValue) updated = h.success(update);
      g_assert_true(fl_value_get_bool(updated));
      g_autoptr(TestResponse) hide = h.call("hide", request, video_channel);
      g_autoptr(FlValue) hidden = h.success(hide);
      g_assert_true(fl_value_get_bool(hidden));
    }
    GtkWidget* remaining_video_view = nullptr;
    gboolean only_toggle_reference = FALSE;
    const auto player_reference_changed =
        +[](gpointer data, GObject*, gboolean is_last_reference) {
          *static_cast<gboolean*>(data) = is_last_reference;
        };
    if (strcmp(mode, "video-parent-destroy") == 0) {
      // A real top-level close destroys the overlay before application disposal
      // shuts down its video host. Exercise that order with an active player.
      GList* children = gtk_container_get_children(GTK_CONTAINER(overlay));
      g_assert_nonnull(children);
      remaining_video_view = GTK_WIDGET(children->data);
      // Observe actual ownership without dereferencing freed memory in the
      // failing implementation. The observer's toggle reference is removed
      // after shutdown; it must never be the player's only reference earlier.
      g_object_add_toggle_ref(G_OBJECT(remaining_video_view),
                              player_reference_changed, &only_toggle_reference);
      g_list_free(children);
      gtk_widget_destroy(overlay);
      g_assert_false(only_toggle_reference);
    }
    busymark_video_player_host_shutdown(video);
    if (remaining_video_view != nullptr) {
      g_assert_true(only_toggle_reference);
      g_object_remove_toggle_ref(G_OBJECT(remaining_video_view),
                                 player_reference_changed, &only_toggle_reference);
    }
    g_autoptr(TestResponse) stopped = h.call("show", request, video_channel);
    g_autoptr(FlValue) unavailable = h.success(stopped);
    g_assert_false(fl_value_get_bool(unavailable));
    g_assert_cmpuint(harness_loads, ==, 0);
    only_engine(nullptr);
    gtk_widget_destroy(overlay);
    if (video_window != nullptr) gtk_widget_destroy(video_window);
  } else if (strcmp(mode, "no-init") == 0) {
    for (const char* name : {"/mermaid-engine.js", "/plantuml-engine.js",
                             "/math-engine.js", "/openapi-engine.js"}) {
      g_assert_true(is_allowed_resource_name(name));
    }
    for (const char* name :
         {"/../math-engine.js", "//math-engine.js", "/math-engine.js/other",
          "/engine-extra.js", "/licenses/package-lock.json"}) {
      g_assert_false(is_allowed_resource_name(name));
    }
    g_autoptr(FlValue) cancel = args("cancelRender");
    g_autoptr(TestResponse) response = h.call("cancelRender", cancel);
    g_autoptr(FlValue) result = h.success(response);
    g_assert_false(fl_value_get_bool(result));
    g_autoptr(TestResponse) disabled =
        h.call("terminateWebProcessForReleaseSmoke", nullptr);
    h.error(disabled, "visualization.releaseSmokeDisabled");
    g_autoptr(TestResponse) unknown = h.call("unknown", nullptr);
    g_assert_true(unknown->responded);
    g_autoptr(TestResponse) invalid_render = h.call("renderMermaid", nullptr);
    h.error(invalid_render, "visualization.invalidArguments");
    g_autoptr(TestResponse) invalid = h.call("copyVisualizationImage", nullptr);
    h.error(invalid, "visualization.invalidArguments");
    g_autoptr(FlValue) too_large = args("renderMermaid");
    std::string large(kMaximumRequestBytes + 1, 'x');
    fl_value_set_string_take(too_large, "source",
                             fl_value_new_string(large.c_str()));
    g_autoptr(TestResponse) rejected = h.call("renderMermaid", too_large);
    h.error(rejected, "visualization.sourceTooLarge");
    g_autoptr(GdkPixbuf) pixbuf =
        gdk_pixbuf_new(GDK_COLORSPACE_RGB, FALSE, 8, 2, 2);
    gdk_pixbuf_fill(pixbuf, 0xff0000ff);
    gchar* png = nullptr;
    gsize length = 0;
    g_assert_true(gdk_pixbuf_save_to_buffer(pixbuf, &png, &length, "png",
                                            nullptr, nullptr));
    g_autoptr(FlValue) clipboard = fl_value_new_map();
    fl_value_set_string_take(
        clipboard, "png",
        fl_value_new_uint8_list(reinterpret_cast<const guint8*>(png), length));
    g_free(png);
    g_autoptr(TestResponse) copied =
        h.call("copyVisualizationImage", clipboard);
    g_autoptr(FlValue) copy_result = h.success(copied);
    g_autoptr(GdkPixbuf) readback = gtk_clipboard_wait_for_image(
        gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    g_assert_nonnull(readback);
    h.dormant();
  } else if (strcmp(mode, "shutdown-channel") == 0) {
    busymark_web_render_host_shutdown(h.host);
    g_autoptr(FlValue) request = args("renderMermaid");
    g_autoptr(TestResponse) response = h.call("renderMermaid", request);
    h.error(response, "visualization.hostUnavailable");
    h.dormant();
  } else if (strcmp(mode, "reference-shutdown") == 0) {
    g_autoptr(FlValue) request = args("openOpenApiReference");
    g_autoptr(TestResponse) response = h.call("openOpenApiReference", request);
    g_autoptr(FlValue) result = h.success(response);
    busymark_web_render_host_shutdown(h.host);
    drain();
    g_assert_null(h.host->reference_windows);
    g_assert_null(h.host->context);
  } else if (strcmp(mode, "openOpenApiReference") == 0) {
    g_autoptr(FlValue) request = args(mode);
    g_autoptr(TestResponse) response = h.call(mode, request);
    g_autoptr(FlValue) result = h.success(response);
    g_assert_cmpuint(contexts, ==, 1);
    g_assert_null(h.host->web_view);
    g_assert_null(h.host->offscreen_window);
    g_assert_cmpuint(views, ==, 1);
    g_assert_cmpuint(harness_loads, ==, 0);
    g_assert_nonnull(h.host->reference_windows);
    auto* window = GTK_WIDGET(h.host->reference_windows->data);
    auto* view = WEBKIT_WEB_VIEW(gtk_bin_get_child(GTK_BIN(window)));
    until([&] { return !webkit_web_view_is_loading(view); });
    // Verify actual Scalar DOM, rather than only the window-opening response.
    bool finished = false;
    webkit_web_view_call_async_javascript_function(
        view,
        "return await new Promise(resolve => { const poll = () => "
        "document.body.innerText.includes('Healthy') ? resolve(true) : "
        "setTimeout(poll, 20); poll(); });",
        -1, nullptr, nullptr, nullptr, nullptr,
        [](GObject* object, GAsyncResult* result, gpointer data) {
          g_autoptr(GError) error = nullptr;
          g_autoptr(JSCValue) value =
              webkit_web_view_call_async_javascript_function_finish(
                  WEBKIT_WEB_VIEW(object), result, &error);
          g_assert_no_error(error);
          g_assert_nonnull(value);
          *static_cast<bool*>(data) = true;
        },
        &finished);
    until([&] { return finished; });
    // WebKit's platform default may itself be NEVER. Reference windows must
    // retain that default rather than inherit the offscreen override.
    g_autoptr(WebKitSettings) defaults = create_restricted_settings();
    g_assert_cmpint(webkit_settings_get_hardware_acceleration_policy(
                        webkit_web_view_get_settings(view)),
                    ==,
                    webkit_settings_get_hardware_acceleration_policy(defaults));
    only_engine("openapi");
    g_autoptr(FlValue) render = args("renderMermaid");
    g_autoptr(TestResponse) rendered = h.call("renderMermaid", render);
    g_autoptr(FlValue) rendered_result = h.success(rendered);
    verify("renderMermaid", rendered_result);
    g_assert_cmpuint(contexts, ==, 1);
    g_assert_cmpuint(views, ==, 2);
    g_assert_cmpuint(harness_loads, ==, 1);
  } else {
    g_autoptr(FlValue) request = args("renderMermaid");
    const gint64 started = g_get_monotonic_time();
    if (is_render_operation(mode)) {
      g_clear_pointer(&request, fl_value_unref);
      request = args(mode);
      g_autoptr(TestResponse) response = h.call(mode, request);
      g_assert_cmpuint(contexts, ==, 0);
      g_autoptr(FlValue) result = h.success(response);
      verify(mode, result);
      only_engine(strcmp(mode, "renderMermaid") == 0     ? "mermaid"
                  : strcmp(mode, "renderPlantUml") == 0  ? "plantuml"
                  : strcmp(mode, "renderMathBatch") == 0 ? "math"
                  : strstr(mode, "OpenApi") != nullptr   ? "openapi"
                                                         : nullptr);
      g_assert_cmpuint(contexts, ==, 1);
      std::printf("first-use %s duration_us=%" G_GINT64_FORMAT "\n", mode,
                  g_get_monotonic_time() - started);
      g_autoptr(FlValue) repeat = args(mode, "second");
      g_autoptr(TestResponse) repeated = h.call(mode, repeat);
      g_autoptr(FlValue) repeated_result = h.success(repeated);
      verify(mode, repeated_result);
      g_assert_cmpuint(resource_reads["render-engines.js"], ==, 1);
      only_engine(strcmp(mode, "renderMermaid") == 0     ? "mermaid"
                  : strcmp(mode, "renderPlantUml") == 0  ? "plantuml"
                  : strcmp(mode, "renderMathBatch") == 0 ? "math"
                  : strstr(mode, "OpenApi") != nullptr   ? "openapi"
                                                         : nullptr);
      g_assert_cmpuint(views, ==, 1);
      g_assert_cmpuint(harness_loads, ==, 1);
      g_assert_true(webkit_web_context_is_ephemeral(h.host->context));
      g_assert_true(webkit_web_context_get_sandbox_enabled(h.host->context));
      auto* settings = webkit_web_view_get_settings(h.host->web_view);
      g_assert_false(webkit_settings_get_enable_html5_local_storage(settings));
      g_assert_false(webkit_settings_get_enable_html5_database(settings));
      g_assert_cmpint(
          webkit_settings_get_hardware_acceleration_policy(settings), ==,
          WEBKIT_HARDWARE_ACCELERATION_POLICY_NEVER);
      g_assert_cmpuint(contexts, ==, 1);
    } else if (strcmp(mode, "engine-failure") == 0 ||
               strcmp(mode, "graphviz-failure") == 0) {
      const char* operation = strcmp(mode, "graphviz-failure") == 0
                                  ? "renderPlantUml"
                                  : "renderMermaid";
      failed_engine_resource = strcmp(mode, "graphviz-failure") == 0
                                   ? "viz-global.js"
                                   : "mermaid-engine.js";
      fail_engine_read = true;
      g_clear_pointer(&request, fl_value_unref);
      request = args(operation);
      g_autoptr(TestResponse) first = h.call(operation, request);
      g_autoptr(FlValue) math = args("renderMathBatch", "math");
      g_autoptr(TestResponse) second = h.call("renderMathBatch", math);
      h.error(first, "visualization.hostUnavailable");
      g_autoptr(FlValue) math_result = h.success(second);
      verify("renderMathBatch", math_result);
      // Retry without the release-only process-termination hook. A failed
      // module registry must not permanently poison this renderer operation.
      g_autoptr(TestResponse) retry = h.call(operation, request);
      g_autoptr(FlValue) result = h.success(retry);
      verify(operation, result);
      g_assert_cmpuint(contexts, ==, 1);
      g_assert_cmpuint(harness_loads, ==, 2);
      g_assert_cmpuint(views, ==, 2);
    } else if (strcmp(mode, "failure") == 0 ||
               strcmp(mode, "load-failure") == 0 ||
               strcmp(mode, "harness-failure") == 0) {
      if (strcmp(mode, "failure") == 0) {
        fail_context = true;
      } else {
        g_free(h.host->resource_root);
        if (strcmp(mode, "harness-failure") == 0) {
          h.host->resource_root =
              g_dir_make_tmp("bm-harness-failure-XXXXXX", nullptr);
          g_autofree gchar* path =
              g_build_filename(h.host->resource_root, "harness.html", nullptr);
          g_assert_true(g_file_set_contents(
              path, "<html><body>Missing engine</body></html>", -1, nullptr));
        } else {
          h.host->resource_root = g_strdup("/nonexistent/busymark-probe");
        }
      }
      g_autoptr(TestResponse) first = h.call("renderMermaid", request);
      g_autoptr(TestResponse) second = h.call("renderMermaid", request);
      h.error(first, "visualization.hostUnavailable");
      h.error(second, "visualization.hostUnavailable");
      until([&] { return h.host->recreate_source_id == 0; });
      g_assert_null(h.host->web_view);
      g_assert_null(h.host->context);
      g_free(h.host->resource_root);
      h.host->resource_root = locate_resource_root();
      g_autoptr(TestResponse) retry = h.call("renderMermaid", request);
      g_autoptr(FlValue) result = h.success(retry);
      verify("renderMermaid", result);
    } else if (strcmp(mode, "concurrent-cancel") == 0 ||
               strcmp(mode, "pre-cancel") == 0) {
      g_autoptr(TestResponse) first = h.call("renderMermaid", request);
      if (strcmp(mode, "concurrent-cancel") == 0) {
        until([&] { return h.host->state == RenderState::loading; });
      }
      g_autoptr(FlValue) cancel = args("cancelRender");
      g_autoptr(TestResponse) cancelled = h.call("cancelRender", cancel);
      g_autoptr(FlValue) result = h.success(cancelled);
      g_assert_true(fl_value_get_bool(result));
      h.error(first, "visualization.cancelled");
      if (strcmp(mode, "pre-cancel") == 0) {
        until([&] { return h.host->recreate_source_id == 0; });
        h.dormant();
      } else {
        g_autoptr(FlValue) math = args("renderMathBatch", "math");
        g_autoptr(FlValue) plant = args("renderPlantUml", "plant");
        g_autoptr(TestResponse) second = h.call("renderMathBatch", math);
        g_autoptr(TestResponse) third = h.call("renderPlantUml", plant);
        g_autoptr(FlValue) math_result = h.success(second);
        g_autoptr(FlValue) plant_result = h.success(third);
        verify("renderMathBatch", math_result);
        verify("renderPlantUml", plant_result);
        g_assert_cmpuint(contexts, ==, 1);
        g_assert_cmpuint(views, ==, 1);
        g_assert_cmpuint(harness_loads, ==, 1);
      }
    } else if (strcmp(mode, "active-cancel") == 0 ||
               strcmp(mode, "snapshot-cancel") == 0 ||
               strcmp(mode, "engine-cancel") == 0) {
      if (strcmp(mode, "snapshot-cancel") == 0) {
        g_clear_pointer(&request, fl_value_unref);
        request = args("rasterizeSvg");
      }
      g_autoptr(TestResponse) first =
          h.call(strcmp(mode, "snapshot-cancel") == 0 ? "rasterizeSvg"
                                                      : "renderMermaid",
                 request);
      until([&] {
        return h.host->active != nullptr &&
               (strcmp(mode, "snapshot-cancel") != 0 ||
                h.host->active->snapshot_wait_source_id != 0);
      });
      if (strcmp(mode, "engine-cancel") == 0)
        until([&] { return resource_reads["mermaid-engine.js"] != 0; });
      g_autoptr(FlValue) cancel = args("cancelRender");
      g_autoptr(TestResponse) cancelled = h.call("cancelRender", cancel);
      h.error(first, "visualization.cancelled");
      until([&] { return h.host->active == nullptr; });
      g_clear_pointer(&request, fl_value_unref);
      request = args("renderMermaid");
      g_autoptr(TestResponse) repeated = h.call("renderMermaid", request);
      g_autoptr(FlValue) result = h.success(repeated);
      verify("renderMermaid", result);
    } else if (strstr(mode, "shutdown-") == mode) {
      g_autoptr(TestResponse) first = h.call("renderMermaid", request);
      if (strcmp(mode, "shutdown-loading") == 0)
        until([&] { return h.host->state == RenderState::loading; });
      if (strcmp(mode, "shutdown-readiness") == 0)
        until([&] { return h.host->initialization_cancellable != nullptr; });
      if (strcmp(mode, "shutdown-active") == 0)
        until([&] { return h.host->active != nullptr; });
      if (strcmp(mode, "shutdown-engine") == 0)
        until([&] { return resource_reads["mermaid-engine.js"] != 0; });
      busymark_web_render_host_shutdown(h.host);
      h.error(first, "visualization.hostUnavailable");
      until([&] { return h.host->active == nullptr; });
      drain();
      g_assert_null(h.host->context);
      g_assert_null(h.host->web_view);
      g_assert_true(h.host->state == RenderState::stopped);
    } else if (strcmp(mode, "recovery") == 0) {
      g_autoptr(TestResponse) first = h.call("renderMermaid", request);
      g_autoptr(FlValue) result = h.success(first);
      g_setenv("BUSYMARK_RELEASE_SMOKE", "1", TRUE);
      g_autoptr(TestResponse) recovery =
          h.call("terminateWebProcessForReleaseSmoke", nullptr);
      g_autoptr(FlValue) recovered = h.success(recovery);
      g_autoptr(TestResponse) repeated = h.call("renderMermaid", request);
      g_autoptr(FlValue) repeat = h.success(repeated);
      verify("renderMermaid", repeat);
      g_assert_cmpuint(views, ==, 2);
      g_assert_cmpuint(harness_loads, ==, 2);
      g_assert_cmpint(webkit_settings_get_hardware_acceleration_policy(
                          webkit_web_view_get_settings(h.host->web_view)),
                      ==, WEBKIT_HARDWARE_ACCELERATION_POLICY_NEVER);
      g_assert_cmpuint(contexts, ==, 1);
    } else {
      g_error("Unknown probe %s", mode);
    }
  }
  std::printf("PASS %s\n", mode);
}
