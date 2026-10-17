#ifndef BUSYMARK_PERFORMANCE_TRACE_H_
#define BUSYMARK_PERFORMANCE_TRACE_H_

#include <glib.h>

// Opt-in diagnostic events use CLOCK_MONOTONIC, as does GLib. Emit the begin
// before entering a synchronous library call so an external watchdog can
// collect stacks while the GTK thread is blocked. No timers on that thread.
class BusyMarkPerformanceSpan {
 public:
  static void Event(const char* operation, const char* phase = "point") {
    if (g_strcmp0(g_getenv("BUSYMARK_NATIVE_TRACE"), "1") == 0) {
      g_printerr("busymark-native %s %s time_us=%" G_GINT64_FORMAT "\n",
                 operation, phase, g_get_monotonic_time());
    }
  }

  explicit BusyMarkPerformanceSpan(const char* operation)
      : operation_(operation),
        enabled_(g_strcmp0(g_getenv("BUSYMARK_NATIVE_TRACE"), "1") == 0) {
    if (enabled_) Emit("begin");
  }
  ~BusyMarkPerformanceSpan() {
    if (enabled_) Emit("end");
  }

 private:
  void Emit(const char* phase) {
    g_printerr("busymark-native %s %s time_us=%" G_GINT64_FORMAT "\n",
               operation_, phase, g_get_monotonic_time());
  }
  const char* operation_;
  bool enabled_;
};

#endif  // BUSYMARK_PERFORMANCE_TRACE_H_
