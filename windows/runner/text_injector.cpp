#include "text_injector.h"

#include <windows.h>

#include <codecvt>
#include <locale>



namespace avro {





std::wstring Utf8ToWide(
    const std::string& text
)
{


    std::wstring_convert<
        std::codecvt_utf8_utf16<wchar_t>
    > converter;



    return converter.from_bytes(
        text
    );

}








void SendUnicodeText(
    const std::string& text
)
{


    std::wstring unicode =
        Utf8ToWide(
            text
        );



    for(
        wchar_t character :
        unicode
    )
    {



        INPUT input{};



        input.type =
            INPUT_KEYBOARD;



        input.ki.wScan =
            character;



        input.ki.dwFlags =
            KEYEVENTF_UNICODE;




        SendInput(

            1,

            &input,

            sizeof(INPUT)

        );





        INPUT release{};



        release.type =
            INPUT_KEYBOARD;



        release.ki.wScan =
            character;



        release.ki.dwFlags =
            KEYEVENTF_UNICODE |
            KEYEVENTF_KEYUP;




        SendInput(

            1,

            &release,

            sizeof(INPUT)

        );



    }



}





}