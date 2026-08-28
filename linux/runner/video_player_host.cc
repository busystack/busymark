#include "video_player_host.h"

#include <webkit2/webkit2.h>

#include <cmath>
#include <cstdlib>
#include <cstring>

namespace {

constexpr char kChannelName[] = "com.busymark.app/video_player";
constexpr gdouble kMinimumPlayerSize = 24.0;
constexpr gdouble kMaximumPlayerSize = 8192.0;
constexpr gdouble kMaximumPlayerCoordinate = 32768.0;
constexpr gsize kMaximumPlayerIdLength = 128;
constexpr gsize kMaximumSourceLength = 8192;
constexpr gsize kMaximumLabelLength = 256;
// Hosted players require an HTTPS page identity. In particular, YouTube
// rejects embeds without an HTTP Referer (player error 153). BusyMark's
// published homepage is its source repository, so use that stable identity
// instead of the opaque about:blank origin produced by load_html().
constexpr char kHostedPlayerBaseUri[] =
    "https://github.com/busystack/busymark/";
constexpr char kHostedPlayerOriginParameter[] =
    "https%3A%2F%2Fgithub.com";

enum class PlayerKind { kLocalFile, kYoutube, kVimeo };

struct VideoPlayer {
  GtkWidget* web_view;
  PlayerKind kind;
  gchar* allowed_local_uri;
};

struct PlayerGeometry {
  gdouble x;
  gdouble y;
  gdouble width;
  gdouble height;
};

void video_player_free(gpointer data) {
  auto* player = static_cast<VideoPlayer*>(data);
  if (player == nullptr) {
    return;
  }
  if (player->web_view != nullptr && GTK_IS_WIDGET(player->web_view)) {
    gtk_widget_destroy(player->web_view);
  }
  g_free(player->allowed_local_uri);
  g_free(player);
}

const gchar* lookup_string(FlValue* args, const gchar* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : nullptr;
}

gboolean lookup_double(FlValue* args,
                       const gchar* key,
                       gdouble* value_out) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr) {
    return FALSE;
  }
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) {
    *value_out = fl_value_get_float(value);
    return TRUE;
  }
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) {
    *value_out = static_cast<gdouble>(fl_value_get_int(value));
    return TRUE;
  }
  return FALSE;
}

gboolean lookup_bool(FlValue* args,
                     const gchar* key,
                     gboolean* value_out) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
    return FALSE;
  }
  *value_out = fl_value_get_bool(value);
  return TRUE;
}

void respond_bool(FlMethodCall* method_call, gboolean value) {
  g_autoptr(FlValue) result = fl_value_new_bool(value);
  fl_method_call_respond_success(method_call, result, nullptr);
}

void respond_error(FlMethodCall* method_call,
                   const gchar* code,
                   const gchar* message) {
  fl_method_call_respond_error(method_call, code, message, nullptr, nullptr);
}

gboolean is_valid_player_id(const gchar* value) {
  if (value == nullptr || value[0] == '\0') {
    return FALSE;
  }
  const gsize length = strlen(value);
  if (length > kMaximumPlayerIdLength) {
    return FALSE;
  }
  for (gsize index = 0; index < length; index++) {
    if (!g_ascii_isalnum(value[index]) && value[index] != '-' &&
        value[index] != '_') {
      return FALSE;
    }
  }
  return TRUE;
}

gboolean is_valid_youtube_id(const gchar* value) {
  if (value == nullptr) {
    return FALSE;
  }
  const gsize length = strlen(value);
  if (length < 6 || length > 64) {
    return FALSE;
  }
  for (gsize index = 0; index < length; index++) {
    if (!g_ascii_isalnum(value[index]) && value[index] != '-' &&
        value[index] != '_') {
      return FALSE;
    }
  }
  return TRUE;
}

gboolean is_valid_vimeo_id(const gchar* value) {
  if (value == nullptr) {
    return FALSE;
  }
  const gsize length = strlen(value);
  if (length == 0 || length > 20) {
    return FALSE;
  }
  for (gsize index = 0; index < length; index++) {
    if (!g_ascii_isdigit(value[index])) {
      return FALSE;
    }
  }
  return TRUE;
}

gboolean has_video_extension(const gchar* path) {
  g_autofree gchar* lower = g_ascii_strdown(path, -1);
  return g_str_has_suffix(lower, ".avi") ||
         g_str_has_suffix(lower, ".m4v") ||
         g_str_has_suffix(lower, ".mkv") ||
         g_str_has_suffix(lower, ".mov") ||
         g_str_has_suffix(lower, ".mp4") ||
         g_str_has_suffix(lower, ".ogv") ||
         g_str_has_suffix(lower, ".webm");
}

gchar* validated_local_uri(const gchar* path) {
  if (path == nullptr || path[0] != '/' || strlen(path) > kMaximumSourceLength ||
      !has_video_extension(path)) {
    return nullptr;
  }
  char* resolved = realpath(path, nullptr);
  if (resolved == nullptr || !g_file_test(resolved, G_FILE_TEST_IS_REGULAR)) {
    std::free(resolved);
    return nullptr;
  }
  g_autoptr(GError) error = nullptr;
  gchar* uri = g_filename_to_uri(resolved, nullptr, &error);
  std::free(resolved);
  return error == nullptr ? uri : nullptr;
}

gboolean decode_geometry(FlValue* args, PlayerGeometry* geometry) {
  if (!lookup_double(args, "x", &geometry->x) ||
      !lookup_double(args, "y", &geometry->y) ||
      !lookup_double(args, "width", &geometry->width) ||
      !lookup_double(args, "height", &geometry->height)) {
    return FALSE;
  }
  return std::isfinite(geometry->x) && std::isfinite(geometry->y) &&
         std::isfinite(geometry->width) && std::isfinite(geometry->height) &&
         geometry->x >= 0 && geometry->y >= 0 &&
         geometry->x <= kMaximumPlayerCoordinate &&
         geometry->y <= kMaximumPlayerCoordinate &&
         geometry->width >= kMinimumPlayerSize &&
         geometry->height >= kMinimumPlayerSize &&
         geometry->width <= kMaximumPlayerSize &&
         geometry->height <= kMaximumPlayerSize;
}

void apply_geometry(GtkWidget* widget, const PlayerGeometry& geometry) {
  gtk_widget_set_halign(widget, GTK_ALIGN_START);
  gtk_widget_set_valign(widget, GTK_ALIGN_START);
  gtk_widget_set_margin_start(widget, static_cast<gint>(std::round(geometry.x)));
  gtk_widget_set_margin_top(widget, static_cast<gint>(std::round(geometry.y)));
  gtk_widget_set_size_request(widget,
                              static_cast<gint>(std::round(geometry.width)),
                              static_cast<gint>(std::round(geometry.height)));
}

gboolean host_matches(const gchar* host, const gchar* suffix) {
  if (host == nullptr || suffix == nullptr) {
    return FALSE;
  }
  if (g_ascii_strcasecmp(host, suffix) == 0) {
    return TRUE;
  }
  const gsize host_length = strlen(host);
  const gsize suffix_length = strlen(suffix);
  return host_length > suffix_length &&
         host[host_length - suffix_length - 1] == '.' &&
         g_ascii_strcasecmp(host + host_length - suffix_length, suffix) == 0;
}

gboolean is_embedded_service_host(PlayerKind kind, const gchar* host) {
  if (kind == PlayerKind::kYoutube) {
    return host_matches(host, "youtube-nocookie.com") ||
           host_matches(host, "youtube.com") ||
           host_matches(host, "googlevideo.com") ||
           host_matches(host, "ytimg.com") ||
           host_matches(host, "gstatic.com") ||
           host_matches(host, "google.com") ||
           g_ascii_strcasecmp(host, "jnn-pa.googleapis.com") == 0 ||
           g_ascii_strcasecmp(host, "yt3.ggpht.com") == 0;
  }
  if (kind == PlayerKind::kVimeo) {
    return host_matches(host, "vimeo.com") ||
           host_matches(host, "vimeocdn.com") ||
           host_matches(host, "akamaized.net") ||
           host_matches(host, "cloudfront.net");
  }
  return FALSE;
}

gboolean is_allowed_player_uri(PlayerKind kind,
                               const gchar* allowed_local_uri,
                               const gchar* uri) {
  if (uri == nullptr) {
    return FALSE;
  }
  if (g_str_has_prefix(uri, "about:blank") ||
      g_str_has_prefix(uri, "data:") || g_str_has_prefix(uri, "blob:")) {
    return TRUE;
  }
  if (kind == PlayerKind::kLocalFile) {
    // load_html() uses this exact URI for BusyMark's fixed local-player shell.
    // It does not grant access to any path below the filesystem root.
    if (g_strcmp0(uri, "file:///") == 0) {
      return TRUE;
    }
    return allowed_local_uri != nullptr &&
           g_strcmp0(uri, allowed_local_uri) == 0;
  }
  // This exact URI identifies BusyMark's in-memory hosted-player shell. No
  // network request is made for it by load_html().
  if (g_strcmp0(uri, kHostedPlayerBaseUri) == 0) {
    return TRUE;
  }
  g_autoptr(GError) error = nullptr;
  g_autoptr(GUri) parsed = g_uri_parse(uri, G_URI_FLAGS_NONE, &error);
  return parsed != nullptr &&
         g_ascii_strcasecmp(g_uri_get_scheme(parsed), "https") == 0 &&
         is_embedded_service_host(kind, g_uri_get_host(parsed));
}

void resource_load_started_cb(WebKitWebView*,
                              WebKitWebResource*,
                              WebKitURIRequest* request,
                              gpointer user_data) {
  auto* player = static_cast<VideoPlayer*>(user_data);
  const gchar* uri = webkit_uri_request_get_uri(request);
  if (!is_allowed_player_uri(player->kind, player->allowed_local_uri, uri)) {
    // resource-load-started exposes the request before it is sent. Replacing a
    // rejected request with about:blank keeps it inside the fixed player shell
    // without relying on a nonexistent WebKitWebResource::send-request signal.
    webkit_uri_request_set_uri(request, "about:blank");
    return;
  }
  if (player->kind != PlayerKind::kYoutube) {
    return;
  }
  g_autoptr(GError) error = nullptr;
  g_autoptr(GUri) parsed = g_uri_parse(uri, G_URI_FLAGS_NONE, &error);
  if (parsed == nullptr ||
      !host_matches(g_uri_get_host(parsed), "youtube-nocookie.com")) {
    return;
  }
  SoupMessageHeaders* headers = webkit_uri_request_get_http_headers(request);
  if (headers != nullptr) {
    soup_message_headers_replace(headers, "Referer", kHostedPlayerBaseUri);
  }
}

gboolean decide_policy_cb(WebKitWebView* web_view,
                          WebKitPolicyDecision* decision,
                          WebKitPolicyDecisionType type,
                          gpointer user_data) {
  if (type != WEBKIT_POLICY_DECISION_TYPE_NAVIGATION_ACTION) {
    return FALSE;
  }
  auto* player = static_cast<VideoPlayer*>(user_data);
  auto* navigation_decision = WEBKIT_NAVIGATION_POLICY_DECISION(decision);
  WebKitNavigationAction* action =
      webkit_navigation_policy_decision_get_navigation_action(
          navigation_decision);
  const WebKitNavigationType navigation_type =
      webkit_navigation_action_get_navigation_type(action);
  WebKitURIRequest* request =
      webkit_navigation_action_get_request(action);
  const gchar* uri = webkit_uri_request_get_uri(request);
  const gchar* current_uri = webkit_web_view_get_uri(web_view);
  const gboolean initial_load = current_uri == nullptr;
  if (!is_allowed_player_uri(player->kind, player->allowed_local_uri, uri) ||
      (!initial_load && navigation_type != WEBKIT_NAVIGATION_TYPE_RELOAD &&
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

WebKitSettings* create_player_settings() {
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
  webkit_settings_set_enable_mediasource(settings, TRUE);
  webkit_settings_set_enable_media(settings, TRUE);
  webkit_settings_set_enable_webrtc(settings, FALSE);
  // The host itself is created only after BusyMark's Flutter Play action.
  // Permit that already-authorized action to start playback without requiring
  // an artificial second click inside the newly created native child.
  webkit_settings_set_media_playback_requires_user_gesture(settings, FALSE);
  webkit_settings_set_enable_back_forward_navigation_gestures(settings,
                                                              FALSE);
  return settings;
}

gchar* player_html(PlayerKind kind,
                   const gchar* value,
                   const gchar* local_uri,
                   gboolean mini_player,
                   const gchar* play_label,
                   const gchar* pause_label,
                   const gchar* border_effect) {
  constexpr char kHeadTemplate[] =
      "<!doctype html><html><head><meta charset=\"utf-8\">"
      "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
      "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none';"
      "style-src 'unsafe-inline'; script-src 'unsafe-inline'; media-src file: blob:;"
      "frame-src https://www.youtube-nocookie.com https://player.vimeo.com;"
      "connect-src 'none'; img-src data: blob:\">"
      "<style>html,body{margin:0;width:100%%;height:100%%;overflow:hidden;"
      "background:#000;color:#fff}video,iframe{display:block;border:0;width:100%%;"
      "height:100%%}button{position:absolute;inset:0;margin:auto;width:64px;"
      "height:64px;border:1px solid #ffffff80;border-radius:50%%;background:#111d;"
      "color:#fff;font:28px sans-serif}body.line,body.rounded{box-sizing:border-box;"
      "border:1px solid #666}body.rounded{border-radius:8px}body.rounded video,"
      "body.rounded iframe{border-radius:7px}</style></head><body class=\"%s\">";
  constexpr char kTail[] = "</body></html>";
  g_autofree gchar* head = g_strdup_printf(kHeadTemplate, border_effect);
  if (kind == PlayerKind::kLocalFile) {
    g_autofree gchar* escaped_uri = g_markup_escape_text(local_uri, -1);
    if (mini_player) {
      g_autofree gchar* escaped_play_label =
          g_markup_escape_text(play_label, -1);
      g_autofree gchar* escaped_pause_label =
          g_markup_escape_text(pause_label, -1);
      return g_strdup_printf(
          "%s<video id=\"v\" autoplay playsinline preload=\"metadata\" src=\"%s\">"
          "</video><button id=\"p\" aria-label=\"%s\" data-play=\"%s\" "
          "data-pause=\"%s\">&#9654;</button>"
          "<script>const v=document.getElementById('v'),p=document.getElementById('p');"
          "p.onclick=()=>v.paused?v.play():v.pause();"
          "v.onplay=()=>{p.textContent='❚❚';p.setAttribute('aria-label',p.dataset.pause)};"
          "v.onpause=()=>{p.textContent='▶';p.setAttribute('aria-label',p.dataset.play)};"
          "</script>%s",
          head, escaped_uri, escaped_play_label, escaped_play_label,
          escaped_pause_label, kTail);
    }
    return g_strdup_printf(
        "%s<video autoplay controls playsinline preload=\"metadata\" src=\"%s\">"
        "</video>%s",
        head, escaped_uri, kTail);
  }
  if (kind == PlayerKind::kYoutube) {
    return g_strdup_printf(
        "%s<iframe allow=\"autoplay; encrypted-media; picture-in-picture\" "
        "referrerpolicy=\"strict-origin-when-cross-origin\" allowfullscreen "
        "src=\"https://www.youtube-nocookie.com/embed/%s?autoplay=1&playsinline=1&rel=0&"
        "controls=%d&origin=%s\"></iframe>%s",
        head, value, mini_player ? 0 : 1, kHostedPlayerOriginParameter, kTail);
  }
  return g_strdup_printf(
      "%s<iframe allow=\"autoplay; encrypted-media; picture-in-picture\" "
      "referrerpolicy=\"strict-origin-when-cross-origin\" allowfullscreen "
      "src=\"https://player.vimeo.com/video/%s?autoplay=1&dnt=1&controls=%d\"></iframe>%s",
      head, value, mini_player ? 0 : 1, kTail);
}

}  // namespace

struct _BusyMarkVideoPlayerHost {
  GObject parent_instance;
  GtkWidget* overlay;
  FlMethodChannel* channel;
  WebKitWebContext* context;
  GHashTable* players;
  gboolean shutting_down;
};

G_DEFINE_TYPE(BusyMarkVideoPlayerHost,
              busymark_video_player_host,
              G_TYPE_OBJECT)

namespace {

VideoPlayer* create_player(BusyMarkVideoPlayerHost* self,
                           PlayerKind kind,
                           const gchar* value,
                           gchar* local_uri,
                           gboolean mini_player,
                           const gchar* play_label,
                           const gchar* pause_label,
                           const gchar* border_effect) {
  auto* player = g_new0(VideoPlayer, 1);
  player->kind = kind;
  player->allowed_local_uri = local_uri;
  player->web_view = webkit_web_view_new_with_context(self->context);
  g_autoptr(WebKitSettings) settings = create_player_settings();
  webkit_web_view_set_settings(WEBKIT_WEB_VIEW(player->web_view), settings);
  GdkRGBA black = {};
  gdk_rgba_parse(&black, "#000000");
  webkit_web_view_set_background_color(WEBKIT_WEB_VIEW(player->web_view),
                                       &black);
  g_signal_connect(player->web_view, "decide-policy",
                   G_CALLBACK(decide_policy_cb), player);
  g_signal_connect(player->web_view, "create", G_CALLBACK(create_web_view_cb),
                   player);
  g_signal_connect(player->web_view, "permission-request",
                   G_CALLBACK(permission_request_cb), player);
  g_signal_connect(player->web_view, "context-menu",
                   G_CALLBACK(context_menu_cb), player);
  g_signal_connect(player->web_view, "resource-load-started",
                   G_CALLBACK(resource_load_started_cb), player);
  g_autofree gchar* html =
      player_html(kind, value, local_uri, mini_player, play_label, pause_label,
                  border_effect);
  webkit_web_view_load_html(WEBKIT_WEB_VIEW(player->web_view), html,
                            kind == PlayerKind::kLocalFile ? "file:///"
                                                          : kHostedPlayerBaseUri);
  return player;
}

gboolean show_player(BusyMarkVideoPlayerHost* self,
                     FlValue* args,
                     const gchar** error_message) {
  const gchar* player_id = lookup_string(args, "playerId");
  const gchar* kind_value = lookup_string(args, "kind");
  const gchar* value = lookup_string(args, "value");
  const gchar* play_label = lookup_string(args, "playLabel");
  const gchar* pause_label = lookup_string(args, "pauseLabel");
  const gchar* border_effect = lookup_string(args, "borderEffect");
  gboolean mini_player = FALSE;
  PlayerGeometry geometry = {};
  if (!is_valid_player_id(player_id) || kind_value == nullptr ||
      value == nullptr || strlen(value) > kMaximumSourceLength ||
      play_label == nullptr || play_label[0] == '\0' ||
      strlen(play_label) > kMaximumLabelLength ||
      !g_utf8_validate(play_label, -1, nullptr) || pause_label == nullptr ||
      pause_label[0] == '\0' || strlen(pause_label) > kMaximumLabelLength ||
      !g_utf8_validate(pause_label, -1, nullptr) ||
      border_effect == nullptr ||
      (g_strcmp0(border_effect, "none") != 0 &&
       g_strcmp0(border_effect, "line") != 0 &&
       g_strcmp0(border_effect, "rounded") != 0) ||
      !lookup_bool(args, "miniPlayer", &mini_player) ||
      !decode_geometry(args, &geometry)) {
    *error_message = "The video player request is invalid.";
    return FALSE;
  }

  PlayerKind kind;
  gchar* local_uri = nullptr;
  if (g_strcmp0(kind_value, "localFile") == 0) {
    kind = PlayerKind::kLocalFile;
    local_uri = validated_local_uri(value);
    if (local_uri == nullptr) {
      *error_message = "The local video path is unavailable or unsafe.";
      return FALSE;
    }
  } else if (g_strcmp0(kind_value, "youtube") == 0 &&
             is_valid_youtube_id(value)) {
    kind = PlayerKind::kYoutube;
  } else if (g_strcmp0(kind_value, "vimeo") == 0 &&
             is_valid_vimeo_id(value)) {
    kind = PlayerKind::kVimeo;
  } else {
    *error_message = "The hosted video identifier is invalid.";
    return FALSE;
  }

  g_hash_table_remove(self->players, player_id);
  VideoPlayer* player =
      create_player(self, kind, value, local_uri, mini_player, play_label,
                    pause_label, border_effect);
  apply_geometry(player->web_view, geometry);
  gtk_overlay_add_overlay(GTK_OVERLAY(self->overlay), player->web_view);
  gtk_overlay_set_overlay_pass_through(GTK_OVERLAY(self->overlay),
                                       player->web_view, FALSE);
  gtk_widget_show(player->web_view);
  g_hash_table_insert(self->players, g_strdup(player_id), player);
  return TRUE;
}

void method_call_cb(FlMethodChannel*,
                    FlMethodCall* method_call,
                    gpointer user_data) {
  auto* self = BUSYMARK_VIDEO_PLAYER_HOST(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  if (self->shutting_down) {
    respond_bool(method_call, FALSE);
    return;
  }
  if (g_strcmp0(method, "show") == 0) {
    const gchar* message = nullptr;
    if (!show_player(self, args, &message)) {
      respond_error(method_call, "video.invalidRequest", message);
      return;
    }
    respond_bool(method_call, TRUE);
    return;
  }
  const gchar* player_id = lookup_string(args, "playerId");
  if (!is_valid_player_id(player_id)) {
    respond_error(method_call, "video.invalidRequest",
                  "The video player identifier is invalid.");
    return;
  }
  if (g_strcmp0(method, "hide") == 0) {
    g_hash_table_remove(self->players, player_id);
    respond_bool(method_call, TRUE);
    return;
  }
  if (g_strcmp0(method, "update") == 0) {
    PlayerGeometry geometry = {};
    auto* player = static_cast<VideoPlayer*>(
        g_hash_table_lookup(self->players, player_id));
    if (player == nullptr || !decode_geometry(args, &geometry)) {
      respond_bool(method_call, FALSE);
      return;
    }
    apply_geometry(player->web_view, geometry);
    respond_bool(method_call, TRUE);
    return;
  }
  fl_method_call_respond_not_implemented(method_call, nullptr);
}

}  // namespace

BusyMarkVideoPlayerHost* busymark_video_player_host_new(GtkWidget* overlay) {
  g_return_val_if_fail(GTK_IS_OVERLAY(overlay), nullptr);
  auto* self = BUSYMARK_VIDEO_PLAYER_HOST(
      g_object_new(busymark_video_player_host_get_type(), nullptr));
  self->overlay = overlay;
  self->context = webkit_web_context_new_ephemeral();
  webkit_web_context_set_cache_model(self->context,
                                     WEBKIT_CACHE_MODEL_DOCUMENT_VIEWER);
  webkit_web_context_set_spell_checking_enabled(self->context, FALSE);
  webkit_web_context_set_sandbox_enabled(self->context, TRUE);
  WebKitCookieManager* cookie_manager =
      webkit_web_context_get_cookie_manager(self->context);
  webkit_cookie_manager_set_accept_policy(cookie_manager,
                                          WEBKIT_COOKIE_POLICY_ACCEPT_NEVER);
  return self;
}

void busymark_video_player_host_register_channel(
    BusyMarkVideoPlayerHost* self,
    FlView* view) {
  g_return_if_fail(BUSYMARK_IS_VIDEO_PLAYER_HOST(self));
  g_return_if_fail(FL_IS_VIEW(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), kChannelName,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            self, nullptr);
}

void busymark_video_player_host_shutdown(BusyMarkVideoPlayerHost* self) {
  g_return_if_fail(BUSYMARK_IS_VIDEO_PLAYER_HOST(self));
  if (self->shutting_down) {
    return;
  }
  self->shutting_down = TRUE;
  g_hash_table_remove_all(self->players);
}

static void busymark_video_player_host_dispose(GObject* object) {
  auto* self = BUSYMARK_VIDEO_PLAYER_HOST(object);
  busymark_video_player_host_shutdown(self);
  g_clear_object(&self->channel);
  g_clear_object(&self->context);
  self->overlay = nullptr;
  G_OBJECT_CLASS(busymark_video_player_host_parent_class)->dispose(object);
}

static void busymark_video_player_host_finalize(GObject* object) {
  auto* self = BUSYMARK_VIDEO_PLAYER_HOST(object);
  g_clear_pointer(&self->players, g_hash_table_unref);
  G_OBJECT_CLASS(busymark_video_player_host_parent_class)->finalize(object);
}

static void busymark_video_player_host_class_init(
    BusyMarkVideoPlayerHostClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = busymark_video_player_host_dispose;
  object_class->finalize = busymark_video_player_host_finalize;
}

static void busymark_video_player_host_init(BusyMarkVideoPlayerHost* self) {
  self->players =
      g_hash_table_new_full(g_str_hash, g_str_equal, g_free, video_player_free);
}
