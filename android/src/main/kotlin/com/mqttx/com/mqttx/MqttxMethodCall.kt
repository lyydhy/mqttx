package com.mqttx.com.mqttx

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class MqttxPluginDelegate(activity: Activity, pluginBinding: FlutterPluginBinding) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    // Flutter 插件绑定对象
    var bind: FlutterPluginBinding? = null

    // 当前 Activity
    var activity: Activity? = null

    // 插件代理对象
    private var _instance: MqttxPluginDelegate? = null

    // 事件通道
    private var eventSink: EventSink? = null
    fun getInstance(): MqttxPluginDelegate? {
        return _instance
    }

    init {
        MqttClient.instance.init(activity)
        this.activity = activity;
        this.bind = pluginBinding;
        _instance = this;
    }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        when (call.method) {
            "connect" -> {
                MqttClient.instance.connect(call, eventSink!!)
            }

            "is_connected" -> {
                MqttClient.instance.getStatus(result)
            }

            "subscribe" -> {
                MqttClient.instance.subscribe(call, eventSink!!)
            }

            "un_subscribe" -> {
                MqttClient.instance.unSubscribe(call, eventSink!!)
            }

            "reconnect" -> {
                MqttClient.instance.reconnect(call,eventSink!!)
            }

            "disconnect" -> {
                MqttClient.instance.disconnect( eventSink!!)
            }
            "publish" -> {
                MqttClient.instance.publish(call, eventSink!!)
            }
            "unSubscribeByReSubscribe" -> {
                MqttClient.instance.unSubscribeByReSubscribe(call, eventSink!!)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {

        eventSink = events;
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null;
    }


}