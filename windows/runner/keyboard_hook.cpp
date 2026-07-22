#include "keyboard_hook.h"

#include <iostream>
#include <cctype>

#include "key_event_channel.h"

namespace avro {


HHOOK keyboardHook = nullptr;



bool keyboardEnabled = false;
bool banglaEnabled = true;





bool StartKeyboardHook()
{


    if(keyboardHook != nullptr)
    {
        return true;
    }




    keyboardHook =
        SetWindowsHookEx(
            WH_KEYBOARD_LL,
            KeyboardProc,
            GetModuleHandle(nullptr),
            0
        );



    keyboardEnabled =
        keyboardHook != nullptr;



    return keyboardEnabled;

}






bool StopKeyboardHook()
{


    if(keyboardHook)
    {

        UnhookWindowsHookEx(
            keyboardHook
        );


        keyboardHook = nullptr;

    }



    keyboardEnabled=false;


    return true;

}

void SetBanglaMode(bool enabled) { banglaEnabled = enabled; }







LRESULT CALLBACK KeyboardProc(

    int nCode,

    WPARAM wParam,

    LPARAM lParam

)
{


    if(
        nCode == HC_ACTION
        &&
        keyboardEnabled
    )
    {


        KBDLLHOOKSTRUCT*
        keyInfo =
        reinterpret_cast<
        KBDLLHOOKSTRUCT*
        >
        (lParam);



        // Never reprocess Unicode events that Avro itself injects.
        if ((keyInfo->flags & LLKHF_INJECTED) != 0) {
          return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
        }

        if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN)
        {


            DWORD key =
                keyInfo->vkCode;



            /*
                Temporary debug output.

                Later this will send
                the key to Dart.
            */


            // std::cout
            //     <<
            //     "Key: "
            //     <<
            //     key
            //     <<
            //     std::endl;
            char character =
                MapVirtualKeyA(
                    key,
                    MAPVK_VK_TO_CHAR
                );


            // The documented language switch is handled before the general
            // shortcut escape hatch, so the foreground app never receives it.
            if (key == 'B' &&
                (GetAsyncKeyState(VK_CONTROL) & 0x8000) &&
                (GetAsyncKeyState(VK_MENU) & 0x8000)) {
              SendKeyEvent("__toggle_language__");
              return 1;
            }

            // Preserve OS and application shortcuts. Capturing Ctrl+C, Alt+Tab
            // or Win shortcuts would make the desktop unusable while typing.
            if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) ||
                (GetAsyncKeyState(VK_MENU) & 0x8000) ||
                (GetAsyncKeyState(VK_LWIN) & 0x8000) ||
                (GetAsyncKeyState(VK_RWIN) & 0x8000)) {
              return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
            }

            // English mode must be completely transparent.  In particular, do
            // not forward keys to Dart: it could otherwise inject a second
            // (Bangla) copy when the user later presses a word boundary.
            if (!banglaEnabled) {
              return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
            }

            if (key == VK_SPACE) {
                SendKeyEvent(" ");
                return 1;
            } else if (key == VK_BACK) {
                SendKeyEvent("\b");
                return 1;
            } else if (key == VK_RETURN) {
                SendKeyEvent("\n");
                return 1;
            } else if(character)
            {
                SendKeyEvent(std::string(1, static_cast<char>(
                    std::tolower(static_cast<unsigned char>(character)))));
                // Dart commits the current phonetic buffer by calling SendInput.
                // Do not let the Latin source character reach the foreground app.
                return 1;
            }


        }


    }





    return CallNextHookEx(

        keyboardHook,

        nCode,

        wParam,

        lParam

    );


}



}
