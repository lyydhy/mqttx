import 'mqttx_config.dart';

abstract class MqttxInterface {
  late MqttxConfig _config;

  /// 初始化配置
  void initConfig(MqttxConfig config);

  /// 连接mqtt
  Future<MqttxConnectionStatus?> connect();

  /// mqtt连接成功
  Future<void> connected({String? code, dynamic? data});

  /// 是否连接中
  Future<bool> isConnected();

  /// 订阅主题
  Future<void> subscribe(List<SubscribeParam> subscribeParams);

  /// 取消订阅
  Future<void> unSubscribe(List<String> topics);

  /// 断开连接
  Future<void> disconnect();

  /// 重连
  Future<void> reconnect();

  /// 发送消息
  Future<void> publish(String topic, String message,
      {MqttxQos qos = MqttxQos.atLeastOnce});
}

class MqttxConnectionStatus {}

enum MqttxQos {
  // 0
  atMostOne,

  // 1
  atLeastOnce,

  // 2
  exactlyOnce
}

extension MqttQosExtension on MqttxQos {
  int get value {
    switch (this) {
      case MqttxQos.atMostOne:
        return 0;
      case MqttxQos.atLeastOnce:
        return 1;
      case MqttxQos.exactlyOnce:
        return 2;
    }
  }

  static MqttxQos fromValue(int value) {
    switch (value) {
      case 0:
        return MqttxQos.atMostOne;
      case 1:
        return MqttxQos.atLeastOnce;
      case 2:
        return MqttxQos.exactlyOnce;
      default:
        return MqttxQos.atMostOne;
    }
  }
}

// 订阅主题参数
class SubscribeParam {
  final String topic;
  final MqttxQos qos;

  SubscribeParam({required this.topic, this.qos = MqttxQos.atLeastOnce});
}
