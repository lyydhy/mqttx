import './MethodChannelMqttxByIos.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../mqttx_config.dart';
import '../mqttx_interface.dart';

abstract class MqttxPlatformByIos extends PlatformInterface {
  MqttxPlatformByIos() : super(token: _token);

  static final Object _token = Object();

  static MqttxPlatformByIos _instance = MethodChannelMqttxByIos();

  static MqttxPlatformByIos get instance => _instance;

  static set instance(MqttxPlatformByIos instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> connect(MqttxConfig config) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> isConnected() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> subscribe(List<SubscribeParam> subscribeParams) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> unSubscribe(List<String> topics) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> reconnect() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> disconnect() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> publish(String topic, String message, int qos) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
