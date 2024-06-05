//
//  MqttxMethodCall.swift
//  mqttx
//
//  Created by ios on 2024/6/4.
//

import Foundation
import Flutter

class MqttxPluginDelegate: FlutterMethodChannel, FlutterStreamHandler {
    
    // 插件代理对象
    private let _instance: MqttxPluginDelegate?
    
    // 事件通道
    private let eventSink: FlutterEventSink?
    
    override init() {
        _instance = self
        <#code#>
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        <#code#>
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        <#code#>
    }
}
