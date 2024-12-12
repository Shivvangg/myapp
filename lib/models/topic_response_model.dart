import 'dart:convert';

class TopicResponseModel {
  final int id;
  final String topic;
  final String timestamp;
  final int alert;
  final String message;
  final String imageUrl;
  late final bool acknowledge;

  TopicResponseModel({
    this.id = 0,
    required this.topic,
    required this.timestamp,
    required this.alert,
    required this.message,
    required this.imageUrl,
    this.acknowledge = false,
  });

  // Convert TopicResponseModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'timestamp': timestamp,
      'alertType': alert,
      'message': message,
      'imageUrl': imageUrl,
      'acknowledged': acknowledge,
    };
  }

  // Convert Map to TopicResponseModel
  factory TopicResponseModel.fromMap(Map<String, dynamic> map) {
    return TopicResponseModel(
      id: map['id'],
      topic: map['topic'],
      timestamp: map['timestamp'],
      alert: map['alert'],
      message: map['message'],
      imageUrl: map['imageUrl'],
      acknowledge: map['acknowledged'] ?? false,
    );
  }

  // Convert TopicResponseModel to JSON string
  String toJson() => json.encode(toMap());

  // Convert JSON string to TopicResponseModel
  factory TopicResponseModel.fromJson(String source) =>
      TopicResponseModel.fromMap(json.decode(source));
}
