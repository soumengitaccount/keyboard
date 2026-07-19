#pragma once


namespace flutter { class BinaryMessenger; }


namespace avro {


void RegisterNativeBridge(
    flutter::BinaryMessenger* messenger
);


}
