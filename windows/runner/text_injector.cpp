#include "text_injector.h"

#include <vector>

namespace avro {
namespace {

std::wstring live_composition;
HWND live_composition_target = nullptr;

bool Utf8ToWide(const std::string& text, std::wstring* wide) {
  if (text.empty()) {
    wide->clear();
    return true;
  }

  const int required = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, text.data(), static_cast<int>(text.size()),
      nullptr, 0);
  if (required <= 0) {
    return false;
  }

  wide->resize(required);
  return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(),
                             static_cast<int>(text.size()), wide->data(),
                             required) == required;
}

bool SendInputs(std::vector<INPUT>* inputs) {
  if (inputs->empty()) {
    return true;
  }

  // SendInput returns the number of records accepted. Reporting a partial
  // write matters: dropping half of a UTF-16 surrogate pair corrupts text.
  const UINT sent = SendInput(static_cast<UINT>(inputs->size()), inputs->data(),
                              sizeof(INPUT));
  return sent == inputs->size();
}

bool IsBengaliCombiningMark(wchar_t code_unit) {
  return code_unit == 0x0981 || code_unit == 0x0982 ||
         code_unit == 0x0983 || code_unit == 0x09BC ||
         (code_unit >= 0x09BE && code_unit <= 0x09C4) ||
         (code_unit >= 0x09C7 && code_unit <= 0x09C8) ||
         (code_unit >= 0x09CB && code_unit <= 0x09CD) ||
         code_unit == 0x09D7 ||
         (code_unit >= 0x09E2 && code_unit <= 0x09E3);
}

// The phonetic engine emits Bangla Unicode, where a visual syllable is a base
// letter followed by vowel signs, marks and optionally a virama-linked
// consonant. Most Windows controls delete one such cluster per Backspace, so
// replace exactly that many clusters rather than UTF-16 code units.
size_t BackspaceCount(const std::wstring& text) {
  size_t count = 0;
  bool join_next_base = false;

  for (const wchar_t code_unit : text) {
    if (code_unit == 0x09CD) {  // Bengali virama / hasanta
      join_next_base = true;
      continue;
    }
    if (IsBengaliCombiningMark(code_unit) || code_unit == 0x200C ||
        code_unit == 0x200D) {
      continue;
    }

    if (!join_next_base) {
      ++count;
    }
    join_next_base = false;
  }
  return count;
}

bool RemoveLiveComposition() {
  if (live_composition.empty()) {
    return true;
  }

  // Never backspace in a new foreground application. The previous text is
  // already visible and must be treated as committed when focus changes.
  if (GetForegroundWindow() != live_composition_target) {
    live_composition.clear();
    live_composition_target = nullptr;
    return true;
  }

  for (size_t index = 0; index < BackspaceCount(live_composition); ++index) {
    if (!SendVirtualKey(VK_BACK)) {
      return false;
    }
  }
  live_composition.clear();
  live_composition_target = nullptr;
  return true;
}

}  // namespace

bool SendUnicodeText(const std::string& text) {
  std::wstring unicode;
  if (!Utf8ToWide(text, &unicode)) {
    return false;
  }

  std::vector<INPUT> inputs;
  inputs.reserve(unicode.size() * 2);
  for (const wchar_t code_unit : unicode) {
    INPUT down{};
    down.type = INPUT_KEYBOARD;
    down.ki.wVk = 0;
    down.ki.wScan = static_cast<WORD>(code_unit);
    down.ki.dwFlags = KEYEVENTF_UNICODE;
    inputs.push_back(down);

    INPUT up = down;
    up.ki.dwFlags |= KEYEVENTF_KEYUP;
    inputs.push_back(up);
  }

  return SendInputs(&inputs);
}

bool SendVirtualKey(WORD virtual_key) {
  std::vector<INPUT> inputs(2);
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = virtual_key;

  inputs[1] = inputs[0];
  inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;
  return SendInputs(&inputs);
}

bool UpdateLiveComposition(const std::string& text) {
  std::wstring replacement;
  if (!Utf8ToWide(text, &replacement)) {
    return false;
  }

  if (!RemoveLiveComposition()) {
    return false;
  }
  if (replacement.empty()) {
    return true;
  }
  if (!SendUnicodeText(text)) {
    return false;
  }

  live_composition = std::move(replacement);
  live_composition_target = GetForegroundWindow();
  return true;
}

bool CommitLiveComposition(const std::string& text) {
  std::wstring final_text;
  if (!Utf8ToWide(text, &final_text)) {
    return false;
  }

  // The already-rendered provisional text is the final value in the common
  // case. Mark it committed without a delete/retype flicker.
  if (live_composition == final_text &&
      live_composition_target == GetForegroundWindow()) {
    ClearLiveComposition();
    return true;
  }
  if (!UpdateLiveComposition(text)) {
    return false;
  }
  ClearLiveComposition();
  return true;
}

bool CancelLiveComposition() {
  return RemoveLiveComposition();
}

void ClearLiveComposition() {
  live_composition.clear();
  live_composition_target = nullptr;
}

}  // namespace avro
