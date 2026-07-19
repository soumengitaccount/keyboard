#include "key_event_channel.h"


#include <flutter/standard_method_codec.h>



namespace avro {



std::unique_ptr<
flutter::EventSink<
flutter::EncodableValue
>
> keyEventSink;





void InitializeKeyEventChannel(
    flutter::BinaryMessenger* messenger
)
{


    auto channel =
        std::make_unique<
        flutter::EventChannel<
        flutter::EncodableValue
        >
        >(

            messenger,

            "avro/key_events",

            &flutter::StandardMethodCodec::GetInstance()

        );




    channel->SetStreamHandler(

        std::make_unique<
        flutter::StreamHandlerFunctions<
        flutter::EncodableValue
        >
        >(

            [](const auto* arguments,
               auto events)

            {

                keyEventSink =
                    std::move(events);


                return nullptr;

            },


            [](const auto* arguments)

            {

                keyEventSink.reset();


                return nullptr;

            }

        )

    );


}





void SendKeyEvent(const std::string& key)
{


    if(!keyEventSink)
    {
        return;
    }





    flutter::EncodableMap data;



    data[
        flutter::EncodableValue("key")
    ]
    =
    flutter::EncodableValue(
        key
    );



    keyEventSink->Success(
        flutter::EncodableValue(
            data
        )
    );


}




}
