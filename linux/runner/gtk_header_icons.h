#ifndef RUNNER_GTK_HEADER_ICONS_H_
#define RUNNER_GTK_HEADER_ICONS_H_

#include <gtk/gtk.h>

#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <vector>

constexpr int kBusyMarkGtkHeaderIconLogicalSize = 16;

enum class BusyMarkGtkIconDirection { kLtr, kRtl };

struct BusyMarkGtkHeaderIconAsset {
  std::vector<std::uint8_t> png_bytes;
  std::string resolved_name;
  int scale;
  int pixel_width;
  int pixel_height;
};

/// Resolves GTK icon-theme artwork and watches the configuration that makes
/// those raster results stale. Header geometry and interaction remain in Dart.
class BusyMarkGtkHeaderIcons {
 public:
  using InvalidatedCallback = std::function<void()>;

  explicit BusyMarkGtkHeaderIcons(GtkWidget* flutter_view,
                                 GtkIconTheme* icon_theme = nullptr);
  ~BusyMarkGtkHeaderIcons();

  BusyMarkGtkHeaderIcons(const BusyMarkGtkHeaderIcons&) = delete;
  BusyMarkGtkHeaderIcons& operator=(const BusyMarkGtkHeaderIcons&) = delete;

  std::optional<BusyMarkGtkHeaderIconAsset> Load(
      const std::vector<std::string>& candidate_names,
      BusyMarkGtkIconDirection direction,
      int scale_override = 0,
      bool allow_missing = false) const;

  bool Start(InvalidatedCallback callback);
  void Stop();

  int scale() const;
  gulong theme_changed_signal_id() const;
  gulong scale_changed_signal_id() const;
  gulong screen_changed_signal_id() const;

 private:
  static void OnThemeChanged(GtkIconTheme* theme, gpointer user_data);
  static void OnScaleChanged(GObject* object,
                             GParamSpec* specification,
                             gpointer user_data);
  static void OnScreenChanged(GtkWidget* widget,
                              GdkScreen* previous_screen,
                              gpointer user_data);

  GtkIconTheme* ResolveTheme() const;
  void RebindTheme();
  void Invalidate();

  GtkWidget* flutter_view_;
  GtkIconTheme* injected_theme_;
  GtkIconTheme* icon_theme_ = nullptr;
  InvalidatedCallback callback_;
  gulong theme_changed_signal_id_ = 0;
  gulong scale_changed_signal_id_ = 0;
  gulong screen_changed_signal_id_ = 0;
};

#endif  // RUNNER_GTK_HEADER_ICONS_H_
