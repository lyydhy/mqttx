package com.mqttx.com.mqttx

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent

import android.content.Context
import android.content.Intent
import android.os.Looper
import info.mqtt.android.service.Ack
import info.mqtt.android.service.MqttAndroidClient
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.eclipse.paho.client.mqttv3.IMqttActionListener
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken
import org.eclipse.paho.client.mqttv3.IMqttToken
import org.eclipse.paho.client.mqttv3.MqttCallbackExtended
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.eclipse.paho.client.mqttv3.MqttException
import org.eclipse.paho.client.mqttv3.MqttMessage
import java.util.logging.Handler

class CustomMqttClient {

    // mqtt实利
    private var _mqttAndroidClient: MqttAndroidClient? = null

    // 当前 Activity
    private var _activity: Activity? = null

    private var connectData = mutableMapOf<String, Any?>()

    private var isReconnect: Boolean = false

    private var isConnect: Boolean = false

    // 当前是否在重连进行中
    private var isReconnecting: Boolean = false

    companion object {
        val instance: CustomMqttClient by lazy { CustomMqttClient() }
    }

    fun init(activity: Activity) {
        _activity = activity;
    }

    /**
     * 连接mqtt 服务
     */
    fun connect(call: MethodCall, eventSink: EventSink?) {
        if (instance._mqttAndroidClient != null && instance._mqttAndroidClient?.isConnected == true) {
            return
        }
        val server: String? = call.argument("server")
        val port: Int? = call.argument("port")
        val clientId: String? = call.argument("clientId")
        val keepAlive: Int? = call.argument("keepAlive")
        val connectionTimeout: Int? = call.argument("connectionTimeout")
        val autoReconnect: Boolean? = call.argument("autoReconnect")
        connectData = mutableMapOf(
            "server" to server,
            "port" to port,
            "clientId" to clientId,
            "keepAlive" to keepAlive,
            "connectionTimeout" to connectionTimeout,
            "autoReconnect" to autoReconnect
        )
        _connect(eventSink)
    }

    /**
     * 处理连接mqtt
     */
    private fun _connect(eventSink: EventSink?) {
        val server = connectData["server"] as String?
        val port = connectData["port"] as Int?
        val clientId = connectData["clientId"] as String?
        val keepAlive = connectData["keepAlive"] as Int?
        val connectionTimeout = connectData["connectionTimeout"] as Int?
        val autoReconnect = connectData["autoReconnect"] as Boolean?

        instance._mqttAndroidClient = MqttAndroidClient(
            _activity?.applicationContext!!,
            "$server:$port",
            clientId!!,
            Ack.AUTO_ACK
        )
        val options = MqttConnectOptions()
        options.keepAliveInterval = keepAlive!!
        options.connectionTimeout = connectionTimeout!!
        options.isAutomaticReconnect = false
//        options.isCleanSession = true

        try {
            instance._mqttAndroidClient!!.setCallback(object : MqttCallbackExtended {

                override fun connectionLost(cause: Throwable?) {
                    instance._reconnect(eventSink)
                    isConnect = false
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
                    if (instance._mqttAndroidClient?.isConnected == true) {
                        isConnect = true;
                        if (reconnect || isReconnect) {
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
                        }

                    } else if (reconnect) {
                        isReconnect = false
                        println("重连失败")
                    } else {
                        isReconnect = false
                    }

                }

            })
            instance._mqttAndroidClient!!.connect(options, null, object : IMqttActionListener {
                override fun onSuccess(asyncActionToken: IMqttToken?) {
                    isConnect = true;
                    val result: Map<String, Any> = mapOf("type" to "connect", "code" to "success");
                    _activity!!.runOnUiThread {
                        eventSink?.success(result);
                    }

                }

                override fun onFailure(asyncActionToken: IMqttToken?, exception: Throwable?) {
                    isConnect = false;
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
     * 手动实现重连
     */
    fun _reconnect(eventSink: EventSink?) {
        val reconnectTask = object : Runnable {
            override fun run() {
                try {
                    val that = this
                    val options = MqttConnectOptions().apply {
                        isAutomaticReconnect = false // 关闭自动重连，因为我们手动处理
                    }
                    instance.isReconnecting = true
                    instance._mqttAndroidClient!!.connect(options, object : IMqttActionListener {
                        override fun onSuccess(asyncActionToken: IMqttToken) {
                            instance.isReconnecting = false
                            isReconnect = true

                        }

                        override fun onFailure(
                            asyncActionToken: IMqttToken?,
                            exception: Throwable?
                        ) {
                            instance.isReconnecting = false
//                            Log.e("MqttService", "Failed to reconnect, retrying in 5 seconds", exception)
                            // 重试间隔，这里使用5秒
                            println("间隔两秒 再次重连")
                            _activity!!.runOnUiThread {
                                val handler = android.os.Handler(Looper.getMainLooper())
                                handler.postDelayed(that, 2 * 1000)
                            }
                        }
                    })
                } catch (e: MqttException) {
                    println("重连失败")
                }
            }

        }
        _activity!!.runOnUiThread(reconnectTask)

    }

    /**
     * 获取当前连接状态
     */
    fun getStatus(result: MethodChannel.Result) {
        if (instance._mqttAndroidClient != null) {
            result.success(isConnect)
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
        if (instance._mqttAndroidClient != null) {

            try {
                topic!!.forEachIndexed { index, t: String ->
                    val q: Int = qos?.get(index) ?: 1
                    _subscribe(t, q, eventSink)
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
        if (instance._mqttAndroidClient != null) {

            topics.forEachIndexed { index, s ->
                instance._mqttAndroidClient!!.unsubscribe(s, null, object : IMqttActionListener {
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


    fun _subscribe(topic: String, qos: Int, eventSink: EventSink?) {
        instance._mqttAndroidClient!!.subscribe(
            topic,
            qos,
            null,
            object : IMqttActionListener {
                override fun onSuccess(asyncActionToken: IMqttToken?) {
                    val result: Map<String, Any?> =
                        mapOf(
                            "type" to "subscribe",
                            "code" to "success",
                            "data" to mapOf<String, Any?>(
                                "topic" to topic,
                                "qos" to qos
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
                                "topic" to topic,
                                "qos" to qos
                            )
                        );
                    _activity!!.runOnUiThread {
                        eventSink!!.success(result)
                    }
                }

            })
    }

    /**
     * 取消并订阅
     */
    fun unSubscribeByReSubscribe(call: MethodCall, eventSink: EventSink?) {
        val topics = call.argument<List<Map<String, Any>>>("topics")
        if (topics != null && instance._mqttAndroidClient != null) {
            topics.forEachIndexed { index, s ->
                val topic = s["topic"] as String
                instance._mqttAndroidClient!!.unsubscribe(
                    topic,
                    null,
                    object : IMqttActionListener {
                        override fun onSuccess(asyncActionToken: IMqttToken?) {
                            val result: Map<String, Any?> =
                                mapOf(
                                    "type" to "unSubscribe",
                                    "code" to "success",
                                    "data" to topic
                                )
                            _subscribe(topic, s["qos"] as Int, eventSink)
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
                                    "type" to "unSubscribe",
                                    "code" to "fail",
                                    "data" to topic
                                );
                            _activity!!.runOnUiThread {
                                eventSink!!.success(result)
                            }
                        }

                    })
            }
        }
    }

    /**
     * 重连
     */
    fun reconnect(call: MethodCall, eventSink: EventSink?) {
        if (instance._mqttAndroidClient != null && !isConnect && !isReconnecting) {
            try {
                val clientId: String? = call.argument("clientId")
                if (clientId != null) {
                    if (instance._mqttAndroidClient != null) {
                        instance._mqttAndroidClient?.close()
                    }
                    instance._mqttAndroidClient = null
                    this.isReconnect = true
                    connectData["clientId"] = clientId
                    _connect(eventSink)
                    return;
                }

                instance._mqttAndroidClient!!.reconnect()
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
        if (instance._mqttAndroidClient != null) {
            try {
                isConnect = false
                instance._mqttAndroidClient!!.close()
                instance._mqttAndroidClient = null

                _activity!!.runOnUiThread {
                    eventSink!!.success(
                        mapOf<String, Any?>(
                            "type" to "disconnect",
                            "code" to "success",
                            "message" to "mqtt disconnected"
                        )
                    )
                }
//                mqttClient!!.disconnect(null, object : IMqttActionListener {
//                    override fun onSuccess(asyncActionToken: IMqttToken?) {
//
//                    }
//
//                    override fun onFailure(asyncActionToken: IMqttToken?, exception: Throwable?) {
//                        _activity!!.runOnUiThread {
//                            eventSink!!.success(
//                                mapOf<String, Any?>(
//                                    "type" to "disconnect",
//                                    "code" to "fail",
//                                    "message" to exception?.message
//                                )
//                            )
//                        }
//                    }
//
//                })
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
        if (instance._mqttAndroidClient != null) {
            try {


                instance._mqttAndroidClient!!.publish(topic!!, message!!.toByteArray(), qos, true)
            } catch (e: MqttException) {
                e.printStackTrace()
            }
        }

    }


    /**
     * 销毁
     */
    fun destroy() {
        isConnect = false
        isReconnect = false
        if (instance._mqttAndroidClient != null) {
            try {
                instance._mqttAndroidClient!!.unregisterResources()
                instance._mqttAndroidClient!!.close()
                instance._mqttAndroidClient = null
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
