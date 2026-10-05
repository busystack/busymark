#ifndef RUNNER_GTK_WINDOW_PREFERENCES_H_
#define RUNNER_GTK_WINDOW_PREFERENCES_H_

#include <gtk/gtk.h>

#include <array>
#include <functional>
#include <string>

struct BusyMarkGtkWindowPreferences {
  std::string decoration_layout;
  std::string double_click;
  std::string middle_click;
  std::string right_click;
};

class BusyMarkGtkWindowPreferencesWatcher {
 public:
  using ChangedCallback =
      std::function<void(const BusyMarkGtkWindowPreferences&)>;

  explicit BusyMarkGtkWindowPreferencesWatcher(GtkSettings* settings = nullptr);
  ~BusyMarkGtkWindowPreferencesWatcher();

  BusyMarkGtkWindowPreferencesWatcher(
      const BusyMarkGtkWindowPreferencesWatcher&) = delete;
  BusyMarkGtkWindowPreferencesWatcher& operator=(
      const BusyMarkGtkWindowPreferencesWatcher&) = delete;

  BusyMarkGtkWindowPreferences Read() const;
  static BusyMarkGtkWindowPreferences Defaults();
  bool Start(ChangedCallback callback);
  void Stop();

  std::array<gulong, 4> signal_ids() const;

 private:
  static void OnSettingChanged(GObject* object,
                               GParamSpec* specification,
                               gpointer user_data);
  GtkSettings* ResolveSettings() const;

  GtkSettings* settings_;
  ChangedCallback callback_;
  std::array<gulong, 4> signal_ids_ = {0, 0, 0, 0};
};

#endif  // RUNNER_GTK_WINDOW_PREFERENCES_H_
