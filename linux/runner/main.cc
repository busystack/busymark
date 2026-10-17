#include "my_application.h"
#include "performance_trace.h"

int main(int argc, char** argv) {
  BusyMarkPerformanceSpan::Event("native-entry");
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
