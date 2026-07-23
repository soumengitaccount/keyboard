#include "ibus_bridge.h"

#include <ibus.h>

#include <string>

namespace {

constexpr char kEngineName[] = "bangla-avro";
constexpr char kServiceName[] = "org.freedesktop.IBus.BanglaAvro";

struct AvroIbusEngine {
  IBusEngine parent_instance;
};

struct AvroIbusEngineClass {
  IBusEngineClass parent_class;
};

G_DEFINE_TYPE(AvroIbusEngine, avro_ibus_engine, IBUS_TYPE_ENGINE)

IBusBus* bus = nullptr;
IBusFactory* factory = nullptr;
IBusEngine* active_engine = nullptr;
FlEventChannel* event_channel = nullptr;
FlMethodChannel* native_channel = nullptr;
bool event_stream_active = false;
bool keyboard_enabled = true;
bool bangla_mode = true;

void Respond(FlMethodCall* method_call, bool value) {
  g_autoptr(FlValue) result = fl_value_new_bool(value);
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond_success(method_call, result, &error)) {
    g_warning("Could not respond to Flutter method call: %s", error->message);
  }
}

void RespondInvalidArguments(FlMethodCall* method_call, const gchar* message) {
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond_error(method_call, "invalid_arguments", message,
                                    nullptr, &error)) {
    g_warning("Could not respond to Flutter method call: %s", error->message);
  }
}

const gchar* StringArgument(FlMethodCall* method_call, const gchar* name) {
  FlValue* arguments = fl_method_call_get_args(method_call);
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(arguments, name);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return nullptr;
  }
  return fl_value_get_string(value);
}

bool BoolArgumentValue(FlMethodCall* method_call, const gchar* name,
                       bool* output) {
  FlValue* arguments = fl_method_call_get_args(method_call);
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    return false;
  }
  FlValue* value = fl_value_lookup_string(arguments, name);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
    return false;
  }
  *output = fl_value_get_bool(value);
  return true;
}

bool SendEvent(const gchar* key) {
  if (!event_stream_active || event_channel == nullptr) {
    return false;
  }

  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(event, "key", fl_value_new_string(key));
  g_autoptr(GError) error = nullptr;
  if (!fl_event_channel_send(event_channel, event, nullptr, &error)) {
    g_warning("Could not send IBus key to Dart: %s", error->message);
    return false;
  }
  return true;
}

void SendResetEvent() {
  if (!event_stream_active || event_channel == nullptr) {
    return;
  }

  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(event, "action", fl_value_new_string("reset"));
  g_autoptr(GError) error = nullptr;
  if (!fl_event_channel_send(event_channel, event, nullptr, &error)) {
    g_warning("Could not reset Dart composition: %s", error->message);
  }
}

bool HidePreedit() {
  if (active_engine == nullptr) {
    return false;
  }
  ibus_engine_hide_preedit_text(active_engine);
  return true;
}

bool UpdatePreedit(const gchar* text) {
  if (active_engine == nullptr || text == nullptr ||
      !g_utf8_validate(text, -1, nullptr)) {
    return false;
  }

  if (*text == '\0') {
    return HidePreedit();
  }

  IBusText* preedit = ibus_text_new_from_string(text);
  ibus_engine_update_preedit_text(active_engine, preedit,
                                  g_utf8_strlen(text, -1), TRUE);
  return true;
}

bool CommitText(const gchar* text) {
  if (active_engine == nullptr || text == nullptr ||
      !g_utf8_validate(text, -1, nullptr)) {
    return false;
  }

  if (*text != '\0') {
    IBusText* commit = ibus_text_new_from_string(text);
    ibus_engine_commit_text(active_engine, commit);
  }
  HidePreedit();
  return true;
}

guint KeyForName(const gchar* name) {
  if (g_strcmp0(name, "space") == 0) return IBUS_KEY_space;
  if (g_strcmp0(name, "enter") == 0) return IBUS_KEY_Return;
  if (g_strcmp0(name, "tab") == 0) return IBUS_KEY_Tab;
  if (g_strcmp0(name, "backspace") == 0) return IBUS_KEY_BackSpace;
  return IBUS_KEY_VoidSymbol;
}

bool ForwardNamedKey(const gchar* name) {
  if (active_engine == nullptr) {
    return false;
  }
  const guint keyval = KeyForName(name);
  if (keyval == IBUS_KEY_VoidSymbol) {
    return false;
  }
  ibus_engine_forward_key_event(active_engine, keyval, 0, 0);
  return true;
}

FlMethodErrorResponse* OnListen(FlEventChannel*, FlValue*, gpointer) {
  event_stream_active = true;
  return nullptr;
}

FlMethodErrorResponse* OnCancel(FlEventChannel*, FlValue*, gpointer) {
  event_stream_active = false;
  return nullptr;
}

void OnMethodCall(FlMethodChannel*, FlMethodCall* method_call, gpointer) {
  const gchar* method = fl_method_call_get_name(method_call);

  if (g_strcmp0(method, "enableKeyboard") == 0) {
    keyboard_enabled = true;
    Respond(method_call, true);
    return;
  }
  if (g_strcmp0(method, "disableKeyboard") == 0) {
    keyboard_enabled = false;
    HidePreedit();
    SendResetEvent();
    Respond(method_call, true);
    return;
  }
  if (g_strcmp0(method, "sendText") == 0) {
    const gchar* text = StringArgument(method_call, "text");
    if (text == nullptr) {
      RespondInvalidArguments(method_call,
                              "sendText expects a UTF-8 string named text.");
      return;
    }
    Respond(method_call, CommitText(text));
    return;
  }
  if (g_strcmp0(method, "sendKey") == 0) {
    const gchar* key = StringArgument(method_call, "key");
    if (key == nullptr) {
      RespondInvalidArguments(method_call,
                              "sendKey expects a key name named key.");
      return;
    }
    Respond(method_call, ForwardNamedKey(key));
    return;
  }
  if (g_strcmp0(method, "sendBackspace") == 0) {
    Respond(method_call, ForwardNamedKey("backspace"));
    return;
  }
  if (g_strcmp0(method, "updateComposition") == 0 ||
      g_strcmp0(method, "updatePreedit") == 0) {
    const gchar* text = StringArgument(method_call, "text");
    if (text == nullptr) {
      RespondInvalidArguments(
          method_call,
          "updateComposition expects a UTF-8 string named text.");
      return;
    }
    Respond(method_call, UpdatePreedit(text));
    return;
  }
  if (g_strcmp0(method, "commitComposition") == 0) {
    const gchar* text = StringArgument(method_call, "text");
    if (text == nullptr) {
      RespondInvalidArguments(
          method_call,
          "commitComposition expects a UTF-8 string named text.");
      return;
    }
    Respond(method_call, CommitText(text));
    return;
  }
  if (g_strcmp0(method, "cancelComposition") == 0) {
    Respond(method_call, HidePreedit());
    return;
  }
  if (g_strcmp0(method, "toggleLanguage") == 0) {
    bool enabled = false;
    if (!BoolArgumentValue(method_call, "bangla", &enabled)) {
      RespondInvalidArguments(
          method_call, "toggleLanguage expects a boolean named bangla.");
      return;
    }
    bangla_mode = enabled;
    if (!bangla_mode) {
      HidePreedit();
      SendResetEvent();
    }
    Respond(method_call, true);
    return;
  }
  if (g_strcmp0(method, "changeLayout") == 0) {
    Respond(method_call, StringArgument(method_call, "layout") != nullptr);
    return;
  }
  if (g_strcmp0(method, "status") == 0) {
    Respond(method_call, true);
    return;
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond_not_implemented(method_call, &error)) {
    g_warning("Could not respond to Flutter method call: %s", error->message);
  }
}

gboolean ProcessKeyEvent(IBusEngine* engine, guint keyval, guint,
                         guint state) {
  active_engine = engine;
  if (!keyboard_enabled || !bangla_mode ||
      (state & (IBUS_RELEASE_MASK | IBUS_CONTROL_MASK | IBUS_MOD1_MASK |
                IBUS_MOD4_MASK | IBUS_SUPER_MASK | IBUS_HYPER_MASK |
                IBUS_META_MASK))) {
    return FALSE;
  }

  if (keyval == IBUS_KEY_BackSpace) return SendEvent("\b");
  if (keyval == IBUS_KEY_space) return SendEvent(" ");
  if (keyval == IBUS_KEY_Return || keyval == IBUS_KEY_KP_Enter) {
    return SendEvent("\n");
  }
  if (keyval == IBUS_KEY_Tab || keyval == IBUS_KEY_ISO_Left_Tab) {
    return SendEvent("\t");
  }
  if (keyval == IBUS_KEY_Escape) {
    return SendEvent("__cancel_composition__");
  }

  const gunichar character = ibus_keyval_to_unicode(keyval);
  if (character == 0 || character > 0x7f || !g_unichar_isprint(character)) {
    return FALSE;
  }

  gchar utf8[7] = {};
  const gint length = g_unichar_to_utf8(character, utf8);
  utf8[length] = '\0';
  return SendEvent(utf8);
}

void Reset(IBusEngine*) {
  HidePreedit();
  SendResetEvent();
}

void FocusIn(IBusEngine* engine) { active_engine = engine; }

void FocusOut(IBusEngine* engine) {
  if (active_engine == engine) {
    HidePreedit();
    SendResetEvent();
    active_engine = nullptr;
  }
}

void avro_ibus_engine_class_init(AvroIbusEngineClass* klass) {
  IBusEngineClass* engine_class = IBUS_ENGINE_CLASS(klass);
  engine_class->process_key_event = ProcessKeyEvent;
  engine_class->reset = Reset;
  engine_class->focus_in = FocusIn;
  engine_class->focus_out = FocusOut;
}

void avro_ibus_engine_init(AvroIbusEngine*) {}

}  // namespace

bool avro_ibus_initialize(FlBinaryMessenger* messenger) {
  if (messenger == nullptr) {
    return false;
  }

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  native_channel = fl_method_channel_new(messenger, "avro/native",
                                         FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(native_channel, OnMethodCall,
                                            nullptr, nullptr);

  event_channel = fl_event_channel_new(messenger, "avro/key_events",
                                       FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(event_channel, OnListen, OnCancel,
                                       nullptr, nullptr);

  bus = ibus_bus_new();
  if (!ibus_bus_is_connected(bus)) {
    g_warning("IBus is not running; cannot start the Bangla Avro engine.");
    return false;
  }

  if (ibus_bus_request_name(bus, kServiceName, 0) == 0) {
    g_warning("Could not register the Bangla Avro IBus service name.");
    return false;
  }

  factory = ibus_factory_new(ibus_bus_get_connection(bus));
  ibus_factory_add_engine(factory, kEngineName, avro_ibus_engine_get_type());
  return true;
}

void avro_ibus_shutdown() {
  event_stream_active = false;
  active_engine = nullptr;
  g_clear_object(&event_channel);
  g_clear_object(&native_channel);
  g_clear_object(&factory);
  g_clear_object(&bus);
}
