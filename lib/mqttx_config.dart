import 'package:mqttx/mqttx_interface.dart';

typedef MqttxSubscribeCallback = void Function(SubscribeParam subscription);
typedef MqttxSubscribeFailCallback = void Function(SubscribeParam subscription);
typedef MqttxUnsubscribeCallback = void Function(String topic);
typedef MqttxMessageCallback = void Function(String topic, dynamic message);

class MqttxConfig {
  /// 客户端 identifier  注意一定要保持唯一
  late String _clientId;

  /// 服务器ip地址
  late String _server;

  /// 端口
  late int _port;

  /// 账号
  late String? _username;

  /// 密码
  late String? _password;

  /// 保持活动间隔(以秒为单位)。 默认60s
  late int _keepAlive;

  /// 超时时间(以秒为单位)
  late int _connectionTimeout;

  /// 是否自动重连 默认为true
  late bool _autoReconnect;

  /// 连接成功回调
  late Function? onConnected = null;

  /// 连接失败回调
  late Function? onConnectFail = null;

  /// 主题订阅成功
  late MqttxSubscribeCallback? onSubscribed = null;

  /// 主题订阅失败
  late MqttxSubscribeFailCallback? onSubscribeFail = null;

  /// 取消订阅
  late MqttxUnsubscribeCallback? onUnSubscribed = null;

  /// 消息监听
  late MqttxMessageCallback? onMessage = null;

  /// 断开连接
  late Function? onDisconnected = null;

  /// 重连成功
  late Function? onReconnected = null;

  MqttxConfig({
    required String clientId,
    required String server,
    required int port,
    String? username,
    String? password,
    int keepAlive = 60,
    int connectionTimeout = 120,
    bool autoReconnect = true,
  }) {
    this.clientId = clientId;
    this.server = server;
    this.port = port;
    this.username = username;
    this.password = password;
    this.keepAlive = keepAlive;
    this.connectionTimeout = connectionTimeout;
    _autoReconnect = autoReconnect;
  }

  String get clientId => _clientId;

  set clientId(String value) {
    _clientId = value;
  }

  String get server => _server;

  int get connectionTimeout => _connectionTimeout;

  set connectionTimeout(int value) {
    _connectionTimeout = value;
  }

  int get keepAlive => _keepAlive;

  set keepAlive(int value) {
    _keepAlive = value;
  }

  String? get password => _password;

  set password(String? value) {
    _password = value;
  }

  String? get username => _username;

  set username(String? value) {
    _username = value;
  }

  int get port => _port;

  set port(int value) {
    _port = value;
  }

  set server(String value) {
    _server = value;
  }

  bool get autoReconnect => _autoReconnect;

  set autoReconnect(bool value) {
    _autoReconnect = value;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clientId'] = _clientId;
    data['server'] = _server;
    data['port'] = _port;
    data['username'] = _username;
    data['password'] = _password;
    data['keepAlive'] = _keepAlive;
    data['connectionTimeout'] = _connectionTimeout;
    data['autoReconnect'] = _autoReconnect;
    return data;
  }
}
