import 'dart:io';

import 'package:mqttx/windows/mqttx_windows_main.dart';
import 'android/mqttx_android_main.dart';
import 'ios/mqttx_ios_main.dart';
import 'mqttx_config.dart';
import 'mqttx_interface.dart';

class Mqttx {
  late MqttxConfig _clientConfig;
  late MqttxInterface? client = null;
  static final Mqttx _instance = Mqttx._internal();

  factory Mqttx() => _instance;

  static Mqttx get instance => _instance;

  Mqttx._internal() {
    // 这里可以初始化_client等资源
    // _client = /* 初始化_client的逻辑 */;
  }

  Mqttx createClient(MqttxConfig config) {
    _clientConfig = config;
    if (Platform.isIOS) {
      client = MqttxIosMain();
    } else if (Platform.isAndroid) {
      client = MqttxAndroidMain();
    } else if (Platform.isWindows) {
      client = MqttxWindowsMain();
    }
    client!.initConfig(config);
    return this;
  }

  Future<void> connect() async {
    if (client != null) {
      client!.connect();
    }
  }

  Future<void> subscribe(List<SubscribeParam> subscribeParams) async {
    if (client != null) {
      client!.subscribe(subscribeParams);
    }
  }

  Future<void> unSubscribe(List<String> topics) async {
    if (client != null) {
      client!.unSubscribe(topics);
    }
  }

  Future<void> reconnect({String? clientId}) async {
    client?.reconnect(clientId: clientId);
  }

  Future<void> disconnect() async {
    client?.disconnect();
  }

  Future<bool> isConnected() async {
    if (client == null) return false;
    return await client!.isConnected();
  }

  Future<void> publish(String topic, String message,
      {MqttxQos qos = MqttxQos.atLeastOnce}) async {
    client?.publish(topic, message, qos: qos);
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

  set onReconnected(Function reconnected) {
    _clientConfig.onReconnected = reconnected;
  }
}
