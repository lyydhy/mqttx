#include "include/mqttx/mqttx_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "mqttx_plugin.h"

void MqttxPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mqttx::MqttxPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
