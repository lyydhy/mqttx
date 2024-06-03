#ifndef FLUTTER_PLUGIN_MQTTX_PLUGIN_H_
#define FLUTTER_PLUGIN_MQTTX_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace mqttx {

class MqttxPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MqttxPlugin();

  virtual ~MqttxPlugin();

  // Disallow copy and assign.
  MqttxPlugin(const MqttxPlugin&) = delete;
  MqttxPlugin& operator=(const MqttxPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mqttx

#endif  // FLUTTER_PLUGIN_MQTTX_PLUGIN_H_
