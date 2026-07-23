#include "keyboard_hook.h"

#include <array>
#include <iterator>
#include <optional>
#include <string>

#include "key_event_channel.h"

namespace avro {
namespace {

HHOOK keyboard_hook = nullptr;
bool keyboard_enabled = false;
bool bangla_enabled = true;

// A blocked key down should have its matching key up blocked as well. Some
// controls react to the otherwise-unpaired key-up message.
std::array<bool, 256> suppressed_key_ups{};

bool IsModifierDown(int virtual_key) {
  return (GetAsyncKeyState(virtual_key) & 0x8000) != 0;
}

void MarkKeyUpSuppressed(DWORD virtual_key) {
  if (virtual_key < suppressed_key_ups.size()) {
    suppressed_key_ups[virtual_key] = true;
  }
}

bool ConsumeSuppressedKeyUp(DWORD virtual_key) {
  if (virtual_key >= suppressed_key_ups.size() ||
      !suppressed_key_ups[virtual_key]) {
    return false;
  }
  suppressed_key_ups[virtual_key] = false;
  return true;
}

std::optional<std::string> WideToUtf8(const wchar_t* text, int length) {
  const int required = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, text,
                                           length, nullptr, 0, nullptr, nullptr);
  if (required <= 0) {
    return std::nullopt;
  }

  std::string utf8(required, '\0');
  if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, text, length,
                          utf8.data(), required, nullptr, nullptr) != required) {
    return std::nullopt;
  }
  return utf8;
}

// Translate the actual key press instead of using MapVirtualKey. That keeps
// shifted punctuation intact when Dart commits it after a phonetic word.
std::optional<std::string> PrintableKey(const KBDLLHOOKSTRUCT& key_info) {
  BYTE keyboard_state[256]{};
  if (!GetKeyboardState(keyboard_state)) {
    return std::nullopt;
  }

  if (key_info.vkCode < std::size(keyboard_state)) {
    keyboard_state[key_info.vkCode] |= 0x80;
  }

  wchar_t characters[8]{};
  const int length = ToUnicodeEx(
      key_info.vkCode, key_info.scanCode, keyboard_state, characters,
      static_cast<int>(std::size(characters)), 0, GetKeyboardLayout(0));
  if (length <= 0) {
    // A dead key has no stable standalone text to send through the phonetic
    // engine, so leave it to Windows rather than swallowing it.
    return std::nullopt;
  }

  return WideToUtf8(characters, length);
}

bool DispatchAndSuppress(DWORD virtual_key, const std::string& key) {
  if (!SendKeyEvent(key)) {
    return false;
  }
  MarkKeyUpSuppressed(virtual_key);
  return true;
}

}  // namespace

bool StartKeyboardHook() {
  if (keyboard_hook != nullptr) {
    return true;
  }

  keyboard_hook = SetWindowsHookExW(WH_KEYBOARD_LL, KeyboardProc,
                                    GetModuleHandle(nullptr), 0);
  keyboard_enabled = keyboard_hook != nullptr;
  return keyboard_enabled;
}

bool StopKeyboardHook() {
  bool success = true;
  if (keyboard_hook != nullptr) {
    success = UnhookWindowsHookEx(keyboard_hook) != FALSE;
    keyboard_hook = nullptr;
  }
  keyboard_enabled = false;
  suppressed_key_ups.fill(false);
  return success;
}

void SetBanglaMode(bool enabled) {
  bangla_enabled = enabled;
}

LRESULT CALLBACK KeyboardProc(int n_code, WPARAM w_param, LPARAM l_param) {
  if (n_code != HC_ACTION || !keyboard_enabled) {
    return CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
  }

  const auto* key_info = reinterpret_cast<const KBDLLHOOKSTRUCT*>(l_param);

  // SendInput-generated events must remain visible to the target application;
  // intercepting them would create an injection loop.
  if ((key_info->flags & LLKHF_INJECTED) != 0) {
    return CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
  }

  if (w_param == WM_KEYUP || w_param == WM_SYSKEYUP) {
    return ConsumeSuppressedKeyUp(key_info->vkCode)
               ? 1
               : CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
  }

  if (w_param != WM_KEYDOWN && w_param != WM_SYSKEYDOWN) {
    return CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
  }

  // This switch is intentionally processed before the normal modifier escape
  // hatch so it works from both Bangla and English mode.
  if (key_info->vkCode == 'B' && IsModifierDown(VK_CONTROL) &&
      IsModifierDown(VK_MENU)) {
    return DispatchAndSuppress(key_info->vkCode, "__toggle_language__")
               ? 1
               : CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
  }

  // Do not capture OS and application shortcuts such as Alt+Tab or Ctrl+C.
  if (IsModifierDown(VK_CONTROL) || IsModifierDown(VK_MENU) ||
      IsModifierDown(VK_LWIN) || IsModifierDown(VK_RWIN) || !bangla_enabled) {
    return CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
  }

  switch (key_info->vkCode) {
    case VK_SPACE:
      return DispatchAndSuppress(key_info->vkCode, " ") ? 1
                                                        : CallNextHookEx(
                                                              keyboard_hook,
                                                              n_code, w_param,
                                                              l_param);
    case VK_BACK:
      return DispatchAndSuppress(key_info->vkCode, "\b") ? 1
                                                         : CallNextHookEx(
                                                               keyboard_hook,
                                                               n_code, w_param,
                                                               l_param);
    case VK_RETURN:
      return DispatchAndSuppress(key_info->vkCode, "\n") ? 1
                                                         : CallNextHookEx(
                                                               keyboard_hook,
                                                               n_code, w_param,
                                                               l_param);
    case VK_TAB:
      return DispatchAndSuppress(key_info->vkCode, "\t") ? 1
                                                         : CallNextHookEx(
                                                               keyboard_hook,
                                                               n_code, w_param,
                                                               l_param);
    case VK_ESCAPE:
      // Match normal IME behaviour: Escape first discards the uncommitted
      // phonetic word instead of leaking a provisional Bengali rendering.
      return DispatchAndSuppress(key_info->vkCode, "__cancel_composition__")
                 ? 1
                 : CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
    default:
      break;
  }

  const auto key = PrintableKey(*key_info);
  if (key && DispatchAndSuppress(key_info->vkCode, *key)) {
    return 1;
  }

  return CallNextHookEx(keyboard_hook, n_code, w_param, l_param);
}

}  // namespace avro
