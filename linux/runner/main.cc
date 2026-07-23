#include "my_application.h"

#ifdef BANGLA_KEYBOARD_ENABLE_IBUS
#include <ibus.h>
#endif

namespace {

bool HasIbusEngineFlag(int argc, char** argv) {
  for (int index = 1; index < argc; ++index) {
    if (g_strcmp0(argv[index], "--ibus-engine") == 0) {
      return true;
    }
  }
  return false;
}

}  // namespace

int main(int argc, char** argv) {
  const bool ibus_engine_mode = HasIbusEngineFlag(argc, argv);
#ifdef BANGLA_KEYBOARD_ENABLE_IBUS
  if (ibus_engine_mode) {
    ibus_init();
  }
#else
  if (ibus_engine_mode) {
    g_printerr("This build does not include IBus support. Rebuild with "
               "-DBANGLA_KEYBOARD_ENABLE_IBUS=ON.\n");
    return 1;
  }
#endif

  g_autoptr(MyApplication) app = my_application_new(ibus_engine_mode);
  return g_application_run(G_APPLICATION(app), argc, argv);
}
