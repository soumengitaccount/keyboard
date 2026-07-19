#pragma once

#include <windows.h>


namespace avro {


bool StartKeyboardHook();


bool StopKeyboardHook();
void SetBanglaMode(bool enabled);


LRESULT CALLBACK KeyboardProc(
    int nCode,
    WPARAM wParam,
    LPARAM lParam
);


}
