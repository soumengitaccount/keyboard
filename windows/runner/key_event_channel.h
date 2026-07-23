#pragma once


#include <flutter/event_channel.h>
#include <flutter/event_sink.h>

#include <memory>
#include <string>



namespace avro {


void InitializeKeyEventChannel(
    flutter::BinaryMessenger* messenger
);



/// Returns false until Dart subscribes to the EventChannel. The hook uses that
/// to let source input through during startup instead of dropping it.
bool SendKeyEvent(const std::string& key);



}
