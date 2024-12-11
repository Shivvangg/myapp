import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt1;
import '../models/topic_response_model.dart';

class MQTTManager {
  static const MethodChannel platform = MethodChannel('com.example.myapp/mqtt');
  static MQTTManager? _instance;

  late mqtt1.MqttServerClient client; // Use MqttServerClient here
  mqtt.MqttConnectionState connectionState =
      mqtt.MqttConnectionState.disconnected;

  String broker = '';
  int port = 1883;
  String username = '';
  String password = '';
  String clientIdentifier = '';

  final List<String> subscribedTopics = [];
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final List<String> topics = [];
  late final Function(TopicResponseModel) onAlertReceived;

  MQTTManager._internal({required this.onAlertReceived});

  static MQTTManager getInstance(
      {required Function(TopicResponseModel) onAlertReceived}) {
    _instance ??= MQTTManager._internal(onAlertReceived: onAlertReceived);
    return _instance!;
  }

  Future<void> connect({
    required String broker,
    required int port,
    required String username,
    required String password,
    required String clientIdentifier,
  }) async {
    this.broker = broker;
    this.port = port;
    this.username = username;
    this.password = password;
    this.clientIdentifier = clientIdentifier;

    // Initialize the MqttServerClient
    client = mqtt1.MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;

    final mqtt.MqttConnectMessage connMessage = mqtt.MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .keepAliveFor(30)
        .startClean()
        .withWillTopic('will/topic')
        .withWillMessage('MQTT Client disconnected')
        .withWillQos(mqtt.MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect(username, password);
      connectionState = client.connectionState!;
      if (connectionState == mqtt.MqttConnectionState.connected) {
        print('Connected to MQTT broker.');
        await _loadTopics();
        _startListeningToMessages();
      } else {
        print('Failed to connect to MQTT broker.');
      }
    } catch (e) {
      print('Error connecting to MQTT broker: $e');
      disconnect();
    }
  }

  void disconnect() {
    client.disconnect();
    connectionState = mqtt.MqttConnectionState.disconnected;
    print('Disconnected from MQTT broker.');
  }

  void _onDisconnected() {
    connectionState = mqtt.MqttConnectionState.disconnected;
    print('MQTT client disconnected.');
  }

  Future<void> _loadTopics() async {
    final storedTopics = await secureStorage.read(key: 'topics');
    if (storedTopics != null) {
      topics.addAll(storedTopics.split(','));
    }
  }

  Future<void> _saveTopics() async {
    await secureStorage.write(key: 'topics', value: topics.join(','));
  }

  void subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      if (!subscribedTopics.contains(topic)) {
        subscribedTopics.add(topic);
        client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
        print('Subscribing to $topic');
        _saveTopics();
      }
    }
  }

  void unsubscribeFromTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      if (subscribedTopics.contains(topic)) {
        client.unsubscribe(topic);
        subscribedTopics.remove(topic);
        print('Unsubscribing from $topic');
        _saveTopics();
      }
    }
  }

  void deleteTopic(String topic) {
    topics.remove(topic);
    _saveTopics();
    print('Deleted topic $topic');
  }

  bool isSubscribed(String topic) {
    return subscribedTopics.contains(topic);
  }

  void _startListeningToMessages() {
    client.updates!
        .listen((List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> c) {
      final mqtt.MqttPublishMessage message =
          c[0].payload as mqtt.MqttPublishMessage;
      final messageString = mqtt.MqttPublishPayload.bytesToStringAsString(
          message.payload.message);

      final alert = TopicResponseModel.fromJson(json.decode(messageString));
      onAlertReceived(alert);

      platform.invokeMethod('newAlert', {
        'topic': alert.topic,
        'timestamp': alert.timestamp,
        'message': alert.message,
        'imageUrl': alert.imageUrl,
        'alertType': alert.alertType,
      });
    });
  }

  void _handleAlert(TopicResponseModel alert) {
    // You could do something here with the alert, e.g., show a notification or alert in the UI
    print('New Alert received: ${alert.message}');
  }
}
