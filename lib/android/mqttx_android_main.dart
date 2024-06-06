import 'package:flutter/services.dart';

import '../mqttx_config.dart';
import '../mqttx_interface.dart';
import 'MqttxPlatformByAndoird.dart';

class MqttxAndroidMain implements MqttxInterface {
  static const EventChannel _eventChannel = EventChannel('mqttx/android/event');

  // 所有已经订阅的主题
  List<SubscribeParam> _subscribedTopics = [];

  // 接收来自原生代码的异步事件
  static Stream<dynamic> get receiveBroadcastStream =>
      _eventChannel.receiveBroadcastStream();

  late MqttxConfig _config;

  MqttxAndroidMain() {
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
              // var topics = _subscribedTopics.map((e) {
              //   return e.topic;
              // }).toList();
              MqttxPlatformByAndroid.instance.unSubscribeByReSubscribe(_subscribedTopics);

              // // 重新订阅
              // MqttxPlatformByAndroid.instance.subscribe(_subscribedTopics);
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
    MqttxPlatformByAndroid.instance.connect(_config);
    return null;
  }

  @override
  void initConfig(MqttxConfig config) {
    _config = config;
  }

  @override
  Future<void> connected({dynamic data, String? code}) async {
    if (_config.onConnected != null) {
      if (code == 'success') {
        _config.onConnected!();
      }
    }
    if (_config.onConnectFail != null) {
      if (code == 'fail') {
        _config.onConnectFail!();
      }
    }
  }

  @override
  Future<bool> isConnected() async {
    bool isConnected = await MqttxPlatformByAndroid.instance.isConnected();
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

    MqttxPlatformByAndroid.instance.subscribe(subscribeParams);
  }

  // 订阅成功或者失败
  void subscribeCallback(
      String? code, dynamic data, String? message, dynamic qos) {
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

  @override
  Future<void> unSubscribe(List<String> topics) async {
    _subscribedTopics.removeWhere((element) => topics.contains(element.topic));
    MqttxPlatformByAndroid.instance.unSubscribe(topics);
    return;
  }

  @override
  Future<void> reconnect({String? clientId}) async {
    MqttxPlatformByAndroid.instance.reconnect(clientId: clientId);
    return;
  }

  @override
  Future<void> disconnect() async {
    _subscribedTopics = [];
    MqttxPlatformByAndroid.instance.disconnect();
    return;
  }

  @override
  Future<void> publish(String topic, String message,
      {MqttxQos qos = MqttxQos.atLeastOnce}) async {
    MqttxPlatformByAndroid.instance.publish(topic, message, qos.value);
  }
}
