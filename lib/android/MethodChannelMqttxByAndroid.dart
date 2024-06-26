import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../mqttx_config.dart';
import '../mqttx_interface.dart';
import 'MqttxPlatformByAndoird.dart';

class MethodChannelMqttxByAndroid extends MqttxPlatformByAndroid {
  @visibleForTesting
  final methodChannel = const MethodChannel('mqttx');

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
    methodChannel.invokeListMethod('disconnect');
    return;
  }

  @override
  Future<void> reconnect({String? clientId}) async {
    methodChannel.invokeListMethod('reconnect', {"clientId": clientId});
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

  @override
  Future<void> unSubscribeByReSubscribe(
      List<SubscribeParam> subscribeParams) async {
    List<Map<String, dynamic>> topics = subscribeParams
        .map((e) => {"topic": e.topic, "qos": e.qos.value})
        .toList();
    methodChannel.invokeMapMethod('unSubscribeByReSubscribe', {"topics": topics});
  }
}
