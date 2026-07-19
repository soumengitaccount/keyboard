#pragma once


#include <flutter/event_channel.h>
#include <flutter/event_sink.h>

#include <memory>
#include <string>



namespace avro {


void InitializeKeyEventChannel(
    flutter::BinaryMessenger* messenger
);



void SendKeyEvent(const std::string& key);



}
