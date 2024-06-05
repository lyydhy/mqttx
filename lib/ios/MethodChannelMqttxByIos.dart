import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../mqttx_config.dart';
import '../mqttx_interface.dart';
import './MqttxPlatformByIos.dart';

class MethodChannelMqttxByIos extends MqttxPlatformByIos {
  @visibleForTesting
  final methodChannel = const MethodChannel('mqttx/ios');

  @override
  Future<String?> connect(MqttxConfig config) async {
    final version =
        await methodChannel.invokeMethod<String>('connect', config.toJson());
    return version;
  }

  @override
  Future<bool> isConnected() async {
    bool? isConnected = await methodChannel.invokeMethod<bool>('is_connected');
    return isConnected == true;
  }

  @override
  Future<void> subscribe(List<SubscribeParam> subscribeParams) async {
    List<String> topic = subscribeParams.map((e) => e.topic).toList();
    List<int> qos = subscribeParams.map((e) => e.qos.value).toList();
    methodChannel.invokeMethod('subscribe', {"topic": topic, "qos": qos});
    return;
  }

  @override
  Future<void> unSubscribe(List<String> topics) async {
    methodChannel.invokeMethod('un_subscribe', {"topic": topics});

    return;
  }

  @override
  Future<void> disconnect() async {
    methodChannel.invokeMethod('disconnect');
    return;
  }

  @override
  Future<void> reconnect() async {
    methodChannel.invokeMethod('reconnect');
    return;
  }

  @override
  Future<void> publish(String topic, String message, int qos) async {
    methodChannel.invokeMethod('publish', {
      "topic": topic,
      "message": message,
      "qos": qos,
    });
    return;
  }
}
