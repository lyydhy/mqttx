package com.mqttx.com.mqttx

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** MqttxPlugin */
class MqttxPlugin : FlutterPlugin, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android

    /// 方法通道
    private lateinit var methodChannel: MethodChannel

    // 事件通道
    private lateinit var eventChannel: EventChannel;

    // 插件代理
    private var mqttxPluginDelegate: MqttxPluginDelegate? = null;

    // 插件连接器
    private var bind: FlutterPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        bind = flutterPluginBinding;
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "mqttx")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "mqttx/android/event")
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        CustomMqttClient.instance.destroy()
    }


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.mqttxPluginDelegate = MqttxPluginDelegate(binding.activity, this.bind!!);
        methodChannel.setMethodCallHandler(this.mqttxPluginDelegate)
        eventChannel.setStreamHandler(this.mqttxPluginDelegate)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding);
    }

    override fun onDetachedFromActivity() {
        CustomMqttClient.instance.destroy()
        this.mqttxPluginDelegate = null;
    }
}
