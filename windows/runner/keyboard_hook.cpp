#include "keyboard_hook.h"

#include <iostream>

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

        if(
            wParam ==
            WM_KEYDOWN
        )
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


            if (key == VK_SPACE) {
                SendKeyEvent(" ");
                if (banglaEnabled) return 1;
            } else if (key == VK_BACK) {
                SendKeyEvent("\\b");
                if (banglaEnabled) return 1;
            } else if (key == VK_RETURN) {
                SendKeyEvent("\\n");
                if (banglaEnabled) return 1;
            } else if(character)
            {
                SendKeyEvent(std::string(1, character));
                // Dart commits the current phonetic buffer by calling SendInput.
                // Do not let the Latin source character reach the foreground app.
                if (banglaEnabled) return 1;
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
