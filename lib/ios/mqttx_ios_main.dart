import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqttx/ios/MqttxPlatformByIos.dart';
import '../mqttx_config.dart';
import '../mqttx_interface.dart' hide MqttQos;

class MqttxIosMain implements MqttxInterface {
  static const EventChannel _eventChannel = EventChannel('mqttx/ios/event');
  late MqttxConfig _config;

  // 所有已经订阅的主题
  List<SubscribeParam> _subscribedTopics = [];

  // 接收来自原生代码的异步事件
  static Stream<dynamic> get receiveBroadcastStream =>
      _eventChannel.receiveBroadcastStream();

  MqttxIosMain() {
    receiveBroadcastStream.listen((event) {
      String type = event['type'];
      dynamic data = event['data'];
      String? code = event['code'];
      String? message = event['message'];
      switch (type) {
        case 'connect':
          connected(code: code, data: message);
          break;
        case 'subscribe':
          dynamic qos = event['qos'];
          subscribeCallback(code, data, message, qos);
          break;
        case 'unSubscribe':
          if (code == 'success' && _config.onUnSubscribed != null) {
            _config.onUnSubscribed!(data);
          }
          break;
        case 'message':
          if (_config.onMessage != null && data != null) {
            _config.onMessage!(data['topic'], data['message']);
          }
        case 'disconnect':
          if (_config.onDisconnected != null) {
            _config.onDisconnected!();
          }
        case 'reconnect':
          if (code == 'success') {
            if (_config.onReconnected != null) {
              _config.onReconnected!();
            }
            if (_subscribedTopics.isNotEmpty) {
              // 重新订阅
              MqttxPlatformByIos.instance.subscribe(_subscribedTopics);
            }
          }
          break;
      }
    }).onError((error) {
      print(error);
    });
  }

  @override
  Future<MqttxConnectionStatus?> connect() async {
    // TODO: implement connect
    MqttxPlatformByIos.instance.connect(_config);
    return null;
  }

  @override
  void initConfig(MqttxConfig config) {
    // TODO: implement initConfig
    _config = config;
  }

  @override
  Future<void> connected({dynamic data, String? code}) async {
    if (_config.onConnected != null) {
      _config.onConnected!();
    }
  }

  @override
  Future<bool> isConnected() async {
    bool isConnected = await MqttxPlatformByIos.instance.isConnected();
    return isConnected;
  }

  @override
  Future<void> subscribe(List<SubscribeParam> subscribeParams) async {
    subscribeParams.forEach((element) {
      if (_subscribedTopics
          .indexWhere((element1) => element.topic == element1.topic) ==
          -1) {
        _subscribedTopics.add(element);
      }
    });
    MqttxPlatformByIos.instance.subscribe(subscribeParams);
  }

  @override
  Future<void> unSubscribe(List<String> topics) async {
    _subscribedTopics.removeWhere((element) => topics.contains(element.topic));
    MqttxPlatformByIos.instance.unSubscribe(topics);
    return;
  }

  // 订阅成功或者失败
  void subscribeCallback(String? code, dynamic data, String? message,
      dynamic qos) {
    if (_config.onSubscribed != null) {
      if (code == 'success') {
        if (data != null && data is Map) {
          _config.onSubscribed!(
            SubscribeParam(
              topic: data['topic'],
              qos: MqttQosExtension.fromValue(data['qos']),
            ),
          );
        }
      }
    }
    if (_config.onSubscribeFail != null) {
      if (code == 'fail') {
        if (data != null && data is Map) {
          _config.onSubscribeFail!(
            SubscribeParam(
              topic: data['topic'],
              qos: MqttQosExtension.fromValue(data['qos']),
            ),
          );
        }
      }
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
  Future<void> reconnect() async {
    MqttxPlatformByIos.instance.reconnect();
    return;
  }

  @override
  Future<void> disconnect() async {
    MqttxPlatformByIos.instance.disconnect();
    return;
  }

  @override
  Future<void> publish(String topic, String message,
      {MqttxQos qos = MqttxQos.atLeastOnce, bool isAutoToUtf8 = true}) async {
    MqttxPlatformByIos.instance.publish(topic, message, qos.value);
    return;
  }

}
