#pragma once


namespace flutter {
class PluginRegistrarWindows;
}


namespace avro {


void RegisterNativeBridge(
    flutter::PluginRegistrarWindows*
    registrar
);


}