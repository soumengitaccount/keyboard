#include "key_event_channel.h"

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <utility>

namespace avro {
namespace {

using Value = flutter::EncodableValue;

// Both objects must survive RegisterNativeBridge: EventChannel only registers
// its handler on the messenger and does not own its own lifetime there.
std::unique_ptr<flutter::EventSink<Value>> key_event_sink;
std::unique_ptr<flutter::EventChannel<Value>> key_event_channel;

}  // namespace

void InitializeKeyEventChannel(flutter::BinaryMessenger* messenger) {
  key_event_channel = std::make_unique<flutter::EventChannel<Value>>(
      messenger, "avro/key_events", &flutter::StandardMethodCodec::GetInstance());

  key_event_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<Value>>(
          [](const Value*, std::unique_ptr<flutter::EventSink<Value>> events)
              -> std::unique_ptr<flutter::StreamHandlerError<Value>> {
            key_event_sink = std::move(events);
            return nullptr;
          },
          [](const Value*)
              -> std::unique_ptr<flutter::StreamHandlerError<Value>> {
            key_event_sink.reset();
            return nullptr;
          }));
}

bool SendKeyEvent(const std::string& key) {
  if (!key_event_sink) {
    return false;
  }

  flutter::EncodableMap event;
  event[Value("key")] = Value(key);
  key_event_sink->Success(Value(event));
  return true;
}

}  // namespace avro
