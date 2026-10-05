#include "gtk_accent.h"

#include <cmath>
#include <utility>

namespace busymark {
namespace {
bool ValidChannel(double value) {
  return std::isfinite(value) && value >= 0 && value <= 1;
}

bool Lookup(GtkStyleContext* context, const char* name, GdkRGBA* color) {
  *color = {0, 0, 0, 0};
  return context != nullptr &&
         gtk_style_context_lookup_color(context, name, color) &&
         ValidChannel(color->red) && ValidChannel(color->green) &&
         ValidChannel(color->blue) && ValidChannel(color->alpha) &&
         color->alpha > 0;
}

int EffectiveChannel(double value) {
  return static_cast<int>(std::round(value * 255));
}
}  // namespace

GtkAccent LookupGtkAccent(GtkStyleContext* context) {
  GtkAccent accent;
  accent.available = Lookup(context, "accent_bg_color", &accent.rgba) ||
                     Lookup(context, "theme_selected_bg_color", &accent.rgba);
  if (!accent.available) accent.rgba = {0, 0, 0, 0};
  return accent;
}

bool SameEffectiveAccent(const GtkAccent& a, const GtkAccent& b) {
  return a.available == b.available &&
         (!a.available ||
          (EffectiveChannel(a.rgba.red) == EffectiveChannel(b.rgba.red) &&
           EffectiveChannel(a.rgba.green) == EffectiveChannel(b.rgba.green) &&
           EffectiveChannel(a.rgba.blue) == EffectiveChannel(b.rgba.blue)));
}

GtkAccentObserver::GtkAccentObserver(GtkWidget* widget)
    : context_(GTK_STYLE_CONTEXT(
          g_object_ref(gtk_widget_get_style_context(widget)))),
      settings_(GTK_SETTINGS(g_object_ref(gtk_widget_get_settings(widget)))) {
  theme_signal_ = g_signal_connect(settings_, "notify::gtk-theme-name",
                                  G_CALLBACK(SettingsChanged), this);
  dark_signal_ = g_signal_connect(
      settings_, "notify::gtk-application-prefer-dark-theme",
      G_CALLBACK(SettingsChanged), this);
  style_signal_ = g_signal_connect(context_, "changed",
                                  G_CALLBACK(StyleChanged), this);
}

GtkAccentObserver::~GtkAccentObserver() {
  Cancel();
  g_signal_handler_disconnect(settings_, theme_signal_);
  g_signal_handler_disconnect(settings_, dark_signal_);
  g_signal_handler_disconnect(context_, style_signal_);
  g_clear_object(&settings_);
  g_clear_object(&context_);
}

GtkAccent GtkAccentObserver::Read() const {
  return LookupGtkAccent(context_);
}

void GtkAccentObserver::Listen(std::function<void(const GtkAccent&)> send) {
  send_ = std::move(send);
  // Replay the current state on every attachment, including after cancellation.
  Publish(true);
}

void GtkAccentObserver::Cancel() {
  send_ = nullptr;
  if (refresh_id_ != 0) {
    g_source_remove(refresh_id_);
    refresh_id_ = 0;
  }
}

void GtkAccentObserver::SettingsChanged(GObject*, GParamSpec*, gpointer data) {
  static_cast<GtkAccentObserver*>(data)->Schedule();
}

void GtkAccentObserver::StyleChanged(GtkStyleContext*, gpointer data) {
  static_cast<GtkAccentObserver*>(data)->Schedule();
}

void GtkAccentObserver::Schedule() {
  // GTK reloads its theme and invalidates styles during settings notification.
  // Sample at idle after that work, and also observe style invalidation itself.
  if (send_ && refresh_id_ == 0) {
    refresh_id_ = g_idle_add_full(G_PRIORITY_DEFAULT_IDLE, Refresh, this, nullptr);
  }
}

gboolean GtkAccentObserver::Refresh(gpointer data) {
  auto* observer = static_cast<GtkAccentObserver*>(data);
  observer->refresh_id_ = 0;
  observer->Publish(false);
  return G_SOURCE_REMOVE;
}

void GtkAccentObserver::Publish(bool force) {
  const auto accent = Read();
  if (send_ && (force || !SameEffectiveAccent(last_, accent))) {
    last_ = accent;
    send_(accent);
  }
}
}  // namespace busymark
