#ifndef BUSYMARK_GTK_ACCENT_H_
#define BUSYMARK_GTK_ACCENT_H_

#include <gtk/gtk.h>
#include <functional>

namespace busymark {
struct GtkAccent {
  bool available = false;
  GdkRGBA rgba = {0, 0, 0, 0};
};

// The production lookup is shared with the GTK-backed regression probe.
GtkAccent LookupGtkAccent(GtkStyleContext* context);
bool SameEffectiveAccent(const GtkAccent& a, const GtkAccent& b);

class GtkAccentObserver {
 public:
  explicit GtkAccentObserver(GtkWidget* widget);
  ~GtkAccentObserver();
  GtkAccent Read() const;
  void Listen(std::function<void(const GtkAccent&)> send);
  void Cancel();

 private:
  static void SettingsChanged(GObject*, GParamSpec*, gpointer data);
  static void StyleChanged(GtkStyleContext*, gpointer data);
  static gboolean Refresh(gpointer data);
  void Schedule();
  void Publish(bool force);

  GtkStyleContext* context_;
  GtkSettings* settings_;
  gulong theme_signal_ = 0;
  gulong dark_signal_ = 0;
  gulong style_signal_ = 0;
  guint refresh_id_ = 0;
  GtkAccent last_;
  std::function<void(const GtkAccent&)> send_;
};
}  // namespace busymark
#endif  // BUSYMARK_GTK_ACCENT_H_
