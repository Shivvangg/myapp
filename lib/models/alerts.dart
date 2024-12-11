import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class Alerts {
  final String topic;
  final int alert;
  final String message;
  final String imageUrl;
  final mqtt.MqttQos qos;

  Alerts({required this.topic, required this.alert, required this.message, required this.imageUrl, required this.qos});
}