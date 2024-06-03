import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mqttx/mqttx.dart';
import 'package:mqttx/mqttx_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool isConnected = false;
  final _mqttxPlugin = Mqttx();

  @override
  void initState() {
    super.initState();
    _mqttxPlugin.createClient(MqttxConfig(
        server: 'mqtt.dev.xl.lezhiwl.top',
        port: 13269,
        clientId: 'flutter_mqttx_example',
        keepAlive: 120));
    _mqttxPlugin.onMessage = (topic, message) {
      print("接收到消息  ${topic} --- ${message}");
    };
    _mqttxPlugin.onConnected = () {
      print("连接成功 ");
      setState(() {
        isConnected = true;
      });
    };
    _mqttxPlugin.onConnectFail = () {
      print("连接失败 ");
    };
    _mqttxPlugin.onSubscribed = (subscription) {
      print("订阅成功 ${subscription.topic} --- ${subscription.qos}");
    };
    _mqttxPlugin.onSubscribeFail = (subscription) {
      print("订阅失败 ${subscription.topic} --- ${subscription.qos}");
    };
    _mqttxPlugin.onUnSubscribed = (topic) {
      print("取消订阅成功 ${topic}");
    };
    _mqttxPlugin.onDisconnected = () {
      print("断开链接");
      setState(() {
        isConnected = false;
      });
    };

    _mqttxPlugin.connect().then((value) {});
  }

  Future<void> subscribe() async {
    _mqttxPlugin.subscribe([
      SubscribeParam(topic: 'homeShowGiftTopic'),
      SubscribeParam(topic: 'roomGlobalMsgTopic'),
      SubscribeParam(topic: 'GameAll'),
      SubscribeParam(topic: 'GameRoomChat:143'),
      SubscribeParam(topic: 'GameRoomHorse:143'),
      SubscribeParam(
          topic: 'userInsideMsgTopic:c8d391483dad4954b88fcab8597e1540'),
    ]);
  }

  Future<void> unSubribe() async {
    _mqttxPlugin.unSubscribe([
      'homeShowGiftTopic',
      'roomGlobalMsgTopic',
      'GameAll',
      'GameRoomChat:143',
      'GameRoomHorse:143',
      'userInsideMsgTopic:c8d391483dad4954b88fcab8597e1540',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text("当前连接状态: ${isConnected ? '已连接' : '为连接'}"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      subscribe();
                    },
                    child: Text("订阅主题"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      unSubribe();
                    },
                    child: Text("取消订阅"),
                  )
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  var a = {"load": "测试"};
                  var b = jsonEncode(a);
                  _mqttxPlugin.publish('GameAll', b, qos: MqttxQos.exactlyOnce);
                },
                child: Text("发布消息"),
              ),
              ElevatedButton(
                onPressed: () {
                  _mqttxPlugin.disconnect();
                },
                child: Text("断开连接"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
