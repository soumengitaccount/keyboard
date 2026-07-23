#ifndef RUNNER_IBUS_BRIDGE_H_
#define RUNNER_IBUS_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>

// Registers the platform channels used by the headless Dart composition
// isolate and publishes the IBus engine factory on the current session bus.
// This is called only for the executable instance IBus launches with
// --ibus-engine.
bool avro_ibus_initialize(FlBinaryMessenger* messenger);

// Releases the IBus service and channel objects before the Flutter engine is
// torn down.
void avro_ibus_shutdown();

#endif  // RUNNER_IBUS_BRIDGE_H_
