import 'package:flutter_test/flutter_test.dart';
import 'package:mqttx/mqttx.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockMqttxPlatform
//     with MockPlatformInterfaceMixin
//     implements MqttxPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

void main() {


  test('getPlatformVersion', () async {
    Mqttx mqttxPlugin = Mqttx();
    // MockMqttxPlatform fakePlatform = MockMqttxPlatform();
    // MqttxPlatform.instance = fakePlatform;

    // expect(await mqttxPlugin.getPlatformVersion(), '42');
  });
}
