import Flutter
import UIKit

public class MqttxPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    var eventSink:FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("eventSink")
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
    
    
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "mqttx/ios", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "mqttx/ios/event", binaryMessenger: registrar.messenger())
    let instance = MqttxPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connect":
        MqttClient.instance.connect(call: call,eventSink: self.eventSink)
        break
    case "is_connected":
        MqttClient.instance.getStatus(result: result)
        break
    case "subscribe":
        MqttClient.instance.subscribe(call: call, eventSink: self.eventSink)
        break
    case "un_subscribe":
        MqttClient.instance.unSubscribe(call: call, eventSink: self.eventSink)
        break
    case "reconnect":
        MqttClient.instance.reconnect(call: call, eventSink: self.eventSink)
        break
    case "disconnect":
        MqttClient.instance.disconnect(eventSink: self.eventSink)
    case "publish":
        MqttClient.instance.publish(call: call, eventSink: self.eventSink)
        break
    case "unSubscribeByReSubscribe":
        MqttClient.instance.unSubscribeByReSubscribe(call: call, eventSink: self.eventSink)
        break
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
}
