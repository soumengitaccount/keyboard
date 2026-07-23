#include "native_bridge.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <utility>
#include <variant>

#include "key_event_channel.h"
#include "keyboard_hook.h"
#include "text_injector.h"

namespace avro {
namespace {

using Value = flutter::EncodableValue;
using MethodResult = flutter::MethodResult<Value>;

std::unique_ptr<flutter::MethodChannel<Value>> native_channel;

const flutter::EncodableMap* ArgumentsAsMap(
    const flutter::MethodCall<Value>& call) {
  return std::get_if<flutter::EncodableMap>(call.arguments());
}

const Value* Argument(const flutter::EncodableMap* arguments,
                      const char* name) {
  if (arguments == nullptr) {
    return nullptr;
  }
  const auto iterator = arguments->find(Value(name));
  return iterator == arguments->end() ? nullptr : &iterator->second;
}

const std::string* StringArgument(const flutter::EncodableMap* arguments,
                                  const char* name) {
  const Value* value = Argument(arguments, name);
  return value == nullptr ? nullptr : std::get_if<std::string>(value);
}

const bool* BoolArgument(const flutter::EncodableMap* arguments,
                         const char* name) {
  const Value* value = Argument(arguments, name);
  return value == nullptr ? nullptr : std::get_if<bool>(value);
}

bool SendNamedVirtualKey(const std::string& key) {
  if (key == "space") {
    return SendVirtualKey(VK_SPACE);
  }
  if (key == "enter") {
    return SendVirtualKey(VK_RETURN);
  }
  if (key == "tab") {
    return SendVirtualKey(VK_TAB);
  }
  if (key == "backspace") {
    return SendVirtualKey(VK_BACK);
  }
  return false;
}

void ReplySuccess(std::unique_ptr<MethodResult> result, bool value) {
  result->Success(Value(value));
}

}  // namespace

void RegisterNativeBridge(flutter::BinaryMessenger* messenger) {
  native_channel = std::make_unique<flutter::MethodChannel<Value>>(
      messenger, "avro/native", &flutter::StandardMethodCodec::GetInstance());

  native_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<Value>& call,
         std::unique_ptr<MethodResult> result) {
        const std::string& method = call.method_name();

        if (method == "enableKeyboard") {
          ReplySuccess(std::move(result), StartKeyboardHook());
          return;
        }

        if (method == "disableKeyboard") {
          ClearLiveComposition();
          ReplySuccess(std::move(result), StopKeyboardHook());
          return;
        }

        if (method == "sendText") {
          const std::string* text = StringArgument(ArgumentsAsMap(call), "text");
          if (text == nullptr) {
            result->Error("invalid_arguments",
                          "sendText expects a UTF-8 string named 'text'.");
            return;
          }
          ReplySuccess(std::move(result), SendUnicodeText(*text));
          return;
        }

        if (method == "updateComposition") {
          const std::string* text = StringArgument(ArgumentsAsMap(call), "text");
          if (text == nullptr) {
            result->Error(
                "invalid_arguments",
                "updateComposition expects a UTF-8 string named 'text'.");
            return;
          }
          ReplySuccess(std::move(result), UpdateLiveComposition(*text));
          return;
        }

        if (method == "commitComposition") {
          const std::string* text = StringArgument(ArgumentsAsMap(call), "text");
          if (text == nullptr) {
            result->Error(
                "invalid_arguments",
                "commitComposition expects a UTF-8 string named 'text'.");
            return;
          }
          ReplySuccess(std::move(result), CommitLiveComposition(*text));
          return;
        }

        if (method == "cancelComposition") {
          ReplySuccess(std::move(result), CancelLiveComposition());
          return;
        }

        if (method == "sendKey") {
          const std::string* key = StringArgument(ArgumentsAsMap(call), "key");
          if (key == nullptr) {
            result->Error("invalid_arguments",
                          "sendKey expects a key name named 'key'.");
            return;
          }
          ReplySuccess(std::move(result), SendNamedVirtualKey(*key));
          return;
        }

        if (method == "sendBackspace") {
          ReplySuccess(std::move(result), SendVirtualKey(VK_BACK));
          return;
        }

        if (method == "changeLayout") {
          // Layout selection is implemented by Dart's phonetic engine. Keep
          // this message as a successful no-op for the shared desktop API.
          if (StringArgument(ArgumentsAsMap(call), "layout") == nullptr) {
            result->Error("invalid_arguments",
                          "changeLayout expects a layout name named 'layout'.");
            return;
          }
          ReplySuccess(std::move(result), true);
          return;
        }

        if (method == "toggleLanguage") {
          const bool* enabled = BoolArgument(ArgumentsAsMap(call), "bangla");
          if (enabled == nullptr) {
            result->Error("invalid_arguments",
                          "toggleLanguage expects a boolean named 'bangla'.");
            return;
          }
          SetBanglaMode(*enabled);
          if (!*enabled) {
            ClearLiveComposition();
          }
          ReplySuccess(std::move(result), true);
          return;
        }

        if (method == "status") {
          // This reports that the runner bridge is registered. Hook state is
          // intentionally controlled through enableKeyboard/disableKeyboard.
          ReplySuccess(std::move(result), true);
          return;
        }

        result->NotImplemented();
      });

  InitializeKeyEventChannel(messenger);
}

}  // namespace avro
