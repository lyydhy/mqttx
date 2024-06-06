import 'dart:convert';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import '../mqttx_config.dart';
import '../mqttx_interface.dart' hide MqttQos;

class MqttxWindowsMain implements MqttxInterface {
  late MqttServerClient _mqttServerClient;
  late MqttxConfig _config;

  @override
  Future<MqttxConnectionStatus?> connect() async {
    // TODO: implement connect
    _mqttServerClient.onConnected = connected;
    await _mqttServerClient.connect();
    return null;
  }

  @override
  void initConfig(MqttxConfig config) {
    // TODO: implement initConfig
    _config = config;
    _mqttServerClient =
        MqttServerClient.withPort(config.server, config.clientId, config.port);
    // _mqttServerClient.logging(on: true);
    _mqttServerClient.autoReconnect = config.autoReconnect;
    _mqttServerClient.keepAlivePeriod = config.keepAlive;
    _mqttServerClient.onSubscribed = onSubscribed;
    _mqttServerClient.onSubscribeFail = onSubscribeFail;
    _mqttServerClient.onUnsubscribed = onUnSubscribe;
    _mqttServerClient.onAutoReconnected = () {
      if (_config.onReconnected != null) {
        _config.onReconnected!();
      }
    };
    _mqttServerClient.onDisconnected = () {
      if (_config.onDisconnected != null) {
        _config.onDisconnected!();
      }
    };
  }

  @override
  Future<void> connected({dynamic data, String? code}) async {

    if (_config.onConnected != null) {
      _config.onConnected!();
    }
    _mqttServerClient.updates.listen(onMessageList);
  }

  @override
  Future<bool> isConnected() async {
    // TODO: implement isConnected
    return _mqttServerClient.connectionStatus!.state ==
        MqttConnectionState.connected;
  }

  @override
  Future<void> subscribe(List<SubscribeParam> subscribeParams) async {
    for (SubscribeParam topic in subscribeParams) {
      MqttQos qos = MqttQos.failure;
      if (topic.qos.value == 0) {
        qos = MqttQos.atMostOnce;
      } else if (topic.qos.value == 1) {
        qos = MqttQos.atLeastOnce;
      } else if (topic.qos.value == 2) {
        qos = MqttQos.exactlyOnce;
      }
      _mqttServerClient.subscribe(topic.topic, qos);
    }
  }

  @override
  Future<void> unSubscribe(List<String> topics) async {
    for (var element in topics) {
      _mqttServerClient.unsubscribeStringTopic(element);
    }
    return;
  }

  // 订阅成功
  void onSubscribed(MqttSubscription? subscription) {
    if (_config.onSubscribed != null) {
      int qos = 0;
      if (subscription?.maximumQos == MqttQos.atMostOnce) {
        qos = 0;
      } else if (subscription?.maximumQos == MqttQos.atLeastOnce) {
        qos = 1;
      } else if (subscription?.maximumQos == MqttQos.exactlyOnce) {
        qos = 2;
      }

      _config.onSubscribed!(SubscribeParam(
          topic: subscription?.topic.rawTopic ?? "",
          qos: MqttQosExtension.fromValue(qos)));
    }
  }

  // 订阅失败
  void onSubscribeFail(MqttSubscription? subscription) {
    if (_config.onSubscribeFail != null) {
      int qos = 0;
      if (subscription?.maximumQos == MqttQos.atMostOnce) {
        qos = 0;
      } else if (subscription?.maximumQos == MqttQos.atLeastOnce) {
        qos = 1;
      } else if (subscription?.maximumQos == MqttQos.exactlyOnce) {
        qos = 2;
      }

      _config.onSubscribeFail!(SubscribeParam(
          topic: subscription?.topic.rawTopic ?? "",
          qos: MqttQosExtension.fromValue(qos)));
    }
  }

  // 取消订阅

  void onUnSubscribe(MqttSubscription subscription) {
    if (_config.onUnSubscribed != null) {
      _config.onUnSubscribed!(subscription.topic.rawTopic ?? "");
    }

    return;
  }

  @override
  Future<void> reconnect({String? clientId}) async {
    _mqttServerClient.doAutoReconnect();
    return;
  }

  @override
  Future<void> disconnect() async {
    _mqttServerClient.disconnect();
    return;
  }

  @override
  Future<void> publish(String topic, String message,
      {MqttxQos qos = MqttxQos.atLeastOnce, bool isAutoToUtf8 = true}) async {
    var builder = MqttPayloadBuilder();
    if (isAutoToUtf8) {
      var b = const Utf8Encoder().convert(message);
      builder.addString(String.fromCharCodes(b));
    } else {
      builder.addString(message);
    }

    MqttQos qos1 = MqttQos.exactlyOnce;
    if (qos.value == 0) {
      qos1 = MqttQos.atMostOnce;
    } else if (qos.value == 1) {
      qos1 = MqttQos.atLeastOnce;
    }
    _mqttServerClient.publishMessage(topic, qos1, builder.payload!);
    return;
  }

  void onMessageList(List<MqttReceivedMessage<MqttMessage>> msgList) {

    try {
      print("收到消息");
      MqttPublishMessage msg = msgList[0].payload as MqttPublishMessage;
      String payload = const Utf8Decoder().convert(msg.payload.message!!);
      String topic = msgList[0].topic!!;
      if (_config.onMessage != null) {
        _config.onMessage!(topic, payload);
      }
    } catch (e) {
      print(e);
    }
  }
}
