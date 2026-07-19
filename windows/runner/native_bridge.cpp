#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "keyboard_hook.h"
#include "text_injector.h"

#include "key_event_channel.h"

namespace avro {


std::unique_ptr<
flutter::MethodChannel<flutter::EncodableValue>
> native_channel;



void RegisterNativeBridge(
    flutter::BinaryMessenger* messenger
)
{

    native_channel =
        std::make_unique<
        flutter::MethodChannel<
        flutter::EncodableValue
        >
        >(
            messenger,
            "avro/native",
            &flutter::StandardMethodCodec::GetInstance()
        );




    native_channel->SetMethodCallHandler(

        [](const auto& call,
           auto result)
        {


            const std::string method =
                call.method_name();



            // -----------------------------------
            // Enable keyboard hook
            // -----------------------------------

            if(method ==
               "enableKeyboard")
            {

                bool ok =
                    StartKeyboardHook();


                result(
                    flutter::EncodableValue(ok)
                );


                return;

            }





            // -----------------------------------
            // Disable keyboard hook
            // -----------------------------------

            if(method ==
               "disableKeyboard")
            {


                bool ok =
                    StopKeyboardHook();


                result(
                    flutter::EncodableValue(ok)
                );


                return;

            }






            // -----------------------------------
            // Unicode text injection
            // -----------------------------------

            if(method ==
               "sendText")
            {


                const auto* args =
                    std::get_if<
                    flutter::EncodableMap
                    >(
                        call.arguments()
                    );



                if(args)
                {

                    auto iterator =
                        args->find(
                            flutter::EncodableValue(
                                "text"
                            )
                        );



                    if(iterator != args->end())
                    {


                        std::string text =
                            std::get<std::string>(
                                iterator->second
                            );


                        SendUnicodeText(
                            text
                        );

                    }

                }



                result(
                    flutter::EncodableValue(true)
                );


                return;

            }






            // -----------------------------------
            // Layout switching
            // -----------------------------------

            if(method ==
               "changeLayout")
            {


                result(
                    flutter::EncodableValue(true)
                );


                return;

            }






            // -----------------------------------
            // Language toggle
            // -----------------------------------

            if(method ==
               "toggleLanguage")
            {
                const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
                bool enabled = true;
                if (args) {
                  auto it = args->find(flutter::EncodableValue("bangla"));
                  if (it != args->end()) enabled = std::get<bool>(it->second);
                }
                SetBanglaMode(enabled);
                result(
                    flutter::EncodableValue(true)
                );


                return;

            }






            // -----------------------------------
            // Status check
            // -----------------------------------

            if(method ==
               "status")
            {


                result(
                    flutter::EncodableValue(true)
                );


                return;

            }




            result(
                flutter::MethodNotImplemented()
            );


        }

    );
    InitializeKeyEventChannel(messenger);

}



}
