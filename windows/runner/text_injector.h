#pragma once

#include <windows.h>

#include <string>


namespace avro {


/// Injects UTF-8 text into the current foreground application using Unicode
/// keyboard packets. False means Windows did not accept the complete input.
bool SendUnicodeText(
    const std::string& text
);

/// Injects a non-text key (for example Enter or Backspace). Text belongs on
/// the Unicode path above so it stays independent of the active keyboard
/// layout.
bool SendVirtualKey(
    WORD virtual_key
);

/// Replaces the provisional Bangla text that was injected for the current
/// phonetic word. The replacement is scoped to the foreground window that
/// originally received the composition.
bool UpdateLiveComposition(const std::string& text);

/// Makes [text] the final value of the live composition, then forgets it so
/// later Backspace presses edit the target application's committed text.
bool CommitLiveComposition(const std::string& text);

/// Removes the currently provisional text, if its original target still has
/// focus. This is used for IME cancellation.
bool CancelLiveComposition();

/// Forgets the provisional range without editing it. Use this when a live
/// composition has already been committed or the target changed focus.
void ClearLiveComposition();

}
