import 'dart:io';

import 'android/mqttx_android_main.dart';
import 'ios/mqttx_ios_main.dart';
import 'mqttx_config.dart';
import 'mqttx_interface.dart';

class Mqttx {
  late MqttxConfig _clientConfig;
  late MqttxInterface client;

  Mqttx createClient(MqttxConfig config) {
    _clientConfig = config;
    if (Platform.isIOS) {
      client = MqttxIosMain();
    } else if (Platform.isAndroid) {
      client = MqttxAndroidMain();
    } else if (Platform.isWindows) {
      // 因为现在 window 和 ios 都是使用的 dart层的mqtt 所以直接使用ios的实现
      client = MqttxIosMain();
    }
    client.initConfig(config);
    return this;
  }

  Future<void> connect() async {
    client.connect();
  }

  Future<void> subscribe(List<SubscribeParam> subscribeParams) async {
    client.subscribe(subscribeParams);
  }

  Future<void> unSubscribe(List<String> topics) async {
    client.unSubscribe(topics);
  }

  Future<void> reconnect() async {
    client.reconnect();
  }

  Future<void> disconnect() async {
    client.disconnect();
  }

  Future<bool> isConnected() async {
    return client.isConnected();
  }

  Future<void> publish(String topic, String message,
      {MqttxQos qos = MqttxQos.atLeastOnce}) async {
    client.publish(topic, message, qos: qos);
  }

  set clientId(String clientId) {
    _clientConfig.clientId = clientId;
  }

  set onConnected(Function connected) {
    _clientConfig.onConnected = connected;
  }

  set onConnectFail(Function connectFail) {
    _clientConfig.onConnectFail = connectFail;
  }

  set onSubscribed(MqttxSubscribeCallback subscribe) {
    _clientConfig.onSubscribed = subscribe;
  }

  set onSubscribeFail(MqttxSubscribeCallback subscribeFail) {
    _clientConfig.onSubscribeFail = subscribeFail;
  }

  set onUnSubscribed(MqttxUnsubscribeCallback unSubscribed) {
    _clientConfig.onUnSubscribed = unSubscribed;
  }

  set onMessage(MqttxMessageCallback message) {
    _clientConfig.onMessage = message;
  }

  set onDisconnected(Function disconnected) {
    _clientConfig.onDisconnected = disconnected;
  }
}
