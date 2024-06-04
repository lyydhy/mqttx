package com.mqttx.com.mqttx

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat.startForegroundService
import info.mqtt.android.service.Ack
import info.mqtt.android.service.MqttAndroidClient
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.eclipse.paho.client.mqttv3.IMqttActionListener
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken
import org.eclipse.paho.client.mqttv3.IMqttToken
import org.eclipse.paho.client.mqttv3.MqttCallback
import org.eclipse.paho.client.mqttv3.MqttCallbackExtended
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.eclipse.paho.client.mqttv3.MqttException
import org.eclipse.paho.client.mqttv3.MqttMessage

class MqttClient {

    // mqtt实利
    private var mqttClient: MqttAndroidClient? = null

    // 当前 Activity
    private var _activity: Activity? = null

    private var server: String? = null
    private var port: Int? = null
    private var clientId: String? = null

    companion object {
        val instance: MqttClient by lazy { MqttClient() }
    }

    fun init(activity: Activity) {
        _activity = activity;
    }

    /**
     * 连接mqtt 服务
     */
    fun connect(call: MethodCall, eventSink: EventSink?) {
        if (mqttClient != null && mqttClient!!.isConnected) {
            return
        }
        server = call.argument("server")
        port = call.argument("port")
        clientId = call.argument("clientId")
        val keepAlive: Int? = call.argument("keepAlive")
        val connectionTimeout: Int? = call.argument("connectionTimeout")
        val autoReconnect: Boolean? = call.argument("autoReconnect")

        mqttClient = MqttAndroidClient(
            _activity?.applicationContext!!,
            "$server:$port",
            clientId!!,
            Ack.AUTO_ACK
        )
//            .apply {
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                setForegroundService(buildNotification(_activity!!.applicationContext))
//            }
//
//        }


        val options = MqttConnectOptions()
        options.keepAliveInterval = keepAlive!!
        options.connectionTimeout = connectionTimeout!!
        options.isAutomaticReconnect = autoReconnect == true
//        options.isCleanSession = true

        try {
            mqttClient!!.setCallback(object : MqttCallbackExtended {

                override fun connectionLost(cause: Throwable?) {
                    println("断开异");
                    val result = mapOf<String, Any?>(
                        "type" to "disconnect",
                        "code" to "success",
                        "data" to null,
                        "message" to "mqtt disconnected msg: ${cause?.message}"
                    )
                    // 断开连接
                    _activity!!.runOnUiThread {
                        eventSink?.success(
                            result
                        )
                    }
                }

                override fun messageArrived(topic: String?, message: MqttMessage?) {
//                    println("消息接收失败2")
//
//                    println("收到消息1 ${topic} ---- ${  message?.toString()}")
                    val msg: String = message?.toString() ?: "";
                    val result: Map<String, Any> = mapOf(
                        "type" to "message", "code" to "success", "data" to mapOf<String, Any?>(
                            "topic" to topic,
                            "message" to msg
                        )
                    )
                    _activity!!.runOnUiThread {
                        eventSink?.success(result);
                    }
                }

                override fun deliveryComplete(token: IMqttDeliveryToken?) {
                }

                override fun connectComplete(reconnect: Boolean, serverURI: String?) {
                    if (mqttClient?.isConnected == true) {
                        if (reconnect) {
                            _activity!!.runOnUiThread {
                                eventSink?.success(
                                    mapOf<String, Any?>(
                                        "type" to "reconnect",
                                        "code" to "success",
                                        "data" to null,
                                        "message" to "mqtt reconnected"
                                    )
                                )

                            }
                            println("重连成功")
                        }

                    } else if (reconnect) {
                        println("重连失败")
                    }
                }

            })
            mqttClient!!.connect(options, null, object : IMqttActionListener {
                override fun onSuccess(asyncActionToken: IMqttToken?) {
                    val result: Map<String, Any> = mapOf("type" to "connect", "code" to "success");
                    _activity!!.runOnUiThread {
                        eventSink?.success(result);
                    }

                }

                override fun onFailure(asyncActionToken: IMqttToken?, exception: Throwable?) {

                    val errMessage: String = exception?.message ?: "connect fail"
                    val result: Map<String, Any> =
                        mapOf("type" to "connect", "code" to "fail", "message" to errMessage)
                    _activity!!.runOnUiThread {
                        eventSink?.success(result);
                    }

                }
            })


        } catch (e: MqttException) {
            e.printStackTrace()
        }
    }

    /**
     * 获取当前连接状态
     */
    fun getStatus(result: MethodChannel.Result) {
        if (mqttClient != null) {
            result.success(mqttClient!!.isConnected)
        } else {
            result.success(false)
        }
    }

    /**
     * 订阅主题
     */
    fun subscribe(call: MethodCall, eventSink: EventSink?) {
        val topic = call.argument<List<String>>("topic")
        val qos = call.argument<List<Int>>("qos")
        if (mqttClient != null) {

            try {
                topic!!.forEachIndexed { index, t: String ->
                    mqttClient!!.subscribe(
                        t,
                        qos?.get(index)!!,
                        null,
                        object : IMqttActionListener {
                            override fun onSuccess(asyncActionToken: IMqttToken?) {
                                val result: Map<String, Any?> =
                                    mapOf(
                                        "type" to "subscribe",
                                        "code" to "success",
                                        "data" to mapOf<String, Any?>(
                                            "topic" to t,
                                            "qos" to qos[index]
                                        )
                                    )

                                _activity!!.runOnUiThread {
                                    eventSink!!.success(result)
                                }
                            }

                            override fun onFailure(
                                asyncActionToken: IMqttToken?,
                                exception: Throwable?
                            ) {
                                val result: Map<String, Any?> =
                                    mapOf(
                                        "type" to "subscribe",
                                        "code" to "fail",
                                        "data" to mapOf<String, Any?>(
                                            "topic" to t,
                                            "qos" to qos[index]
                                        )
                                    );
                                _activity!!.runOnUiThread {
                                    eventSink!!.success(result)
                                }
                            }

                        })

                }
            } catch (e: MqttException) {
                e.printStackTrace()
                val result: Map<String, Any?> =
                    mapOf(
                        "type" to "subscribe",
                        "code" to "fail",
                        "message" to e.message
                    );
                _activity!!.runOnUiThread {
                    eventSink!!.success(result)
                }
            }


        }

    }

    /**
     * 取消订阅
     */
    fun unSubscribe(call: MethodCall, eventSink: EventSink?) {
        val topics = call.argument<List<String>>("topic") ?: emptyList()
        if (mqttClient != null) {

            topics.forEachIndexed { index, s ->
                mqttClient!!.unsubscribe(s, null, object : IMqttActionListener {
                    override fun onSuccess(asyncActionToken: IMqttToken?) {
                        val result: Map<String, Any?> =
                            mapOf(
                                "type" to "unSubscribe",
                                "code" to "success",
                                "data" to s
                            );
                        _activity!!.runOnUiThread {
                            eventSink!!.success(result)
                        }
                    }

                    override fun onFailure(asyncActionToken: IMqttToken?, exception: Throwable?) {
                        val result: Map<String, Any?> =
                            mapOf(
                                "type" to "unSubscribe",
                                "code" to "fail",
                                "data" to s
                            );
                        _activity!!.runOnUiThread {
                            eventSink!!.success(result)
                        }
                    }

                })
            }
        } else {
            val result: Map<String, Any?> =
                mapOf(
                    "type" to "unSubscribe",
                    "code" to "fail",
                    "message" to "client is null"
                );
            _activity!!.runOnUiThread {
                eventSink!!.success(result)
            }
        }
    }

    /**
     * 重连
     */
    fun reconnect(result: MethodChannel.Result) {
        if (mqttClient != null) {
            try {
                mqttClient!!.reconnect()
//                result.success(true)
            } catch (e: MqttException) {
                e.printStackTrace()
//                result.success(false)
            }
        } else {
//            result.success(false)
        }
    }


    /**
     * 断开连接
     */
    fun disconnect(eventSink: EventSink?) {
        if (mqttClient != null && mqttClient?.isConnected == true) {
            try {
                mqttClient!!.disconnect(null, object : IMqttActionListener {
                    override fun onSuccess(asyncActionToken: IMqttToken?) {
                        mqttClient = null
                        _activity!!.runOnUiThread {
                            eventSink!!.success(
                                mapOf<String, Any?>(
                                    "type" to "disconnect",
                                    "code" to "success",
                                    "message" to "mqtt disconnected"
                                )
                            )
                        }
                    }

                    override fun onFailure(asyncActionToken: IMqttToken?, exception: Throwable?) {
                        _activity!!.runOnUiThread {
                            eventSink!!.success(
                                mapOf<String, Any?>(
                                    "type" to "disconnect",
                                    "code" to "fail",
                                    "message" to exception?.message
                                )
                            )
                        }
                    }

                })
//                mqttClient!!.close()
            } catch (e: MqttException) {
                e.printStackTrace()
            }
        } else {
            _activity!!.runOnUiThread() {
                eventSink!!.success(
                    mapOf<String, Any>(
                        "type" to "disconnect",
                        "code" to "fail",
                        "message" to "mqtt客户端未初始化或者未连接"
                    )
                )
            }
        }
    }

    /**
     * 发送消息
     */
    fun publish(call: MethodCall, eventSink: EventSink?) {
        val topic = call.argument<String>("topic")
        val message = call.argument<String>("message")
        val qos = call.argument<Int>("qos") ?: 0
        if (mqttClient != null) {
            try {


                mqttClient!!.publish(topic!!, message!!.toByteArray(), qos, true)
            } catch (e: MqttException) {
                e.printStackTrace()
            }
        }

    }

    // 构建一个notification
    @SuppressLint("NewApi")
    private fun buildNotification(context: Context): Notification {
        val notificationManager: NotificationManager = context.getSystemService(
            Context.NOTIFICATION_SERVICE
        ) as NotificationManager
        val channel: NotificationChannel = NotificationChannel(
            "mqttx",
            "蜗蜗语音",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        notificationManager.createNotificationChannel(channel)
//
//        val notification: Notification = new NotificationCompat.Builder(context, "mqttx")
//            .setSmallIcon(  context.resources.getIdentifier(
//            "ic_launcher",
//            "mipmap",
//            context.packageName
//        ))
//            .setContentTitle("蜗蜗语音")
//            .setContentText("正在后台运行")
//            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
//            .setContentIntent(pit)
//            .build()

        val it: Intent = Intent(context, _activity!!.javaClass)
        val pit = PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_MUTABLE)
        val mBuilder: Notification.Builder = Notification.Builder(context, "mqttx");
        mBuilder
            .setSubText("正在后台运行")
            .setContentTitle("蜗蜗语音")
            .setContentIntent(pit)
            .setSmallIcon(
                context.resources.getIdentifier(
                    "ic_launcher",
                    "mipmap",
                    context.packageName
                )
            )

        return mBuilder.build()
    }
}
