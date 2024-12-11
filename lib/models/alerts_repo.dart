
import 'topic_response_model.dart';

abstract class AlertsRepo {
  // Fetch all alerts as a list
  Future<List<TopicResponseModel>> getAllAlerts();

  // Add a received alert to the database
  Future<void> addReceivedAlert(TopicResponseModel alert);

  // Remove a specific alert from the database
  Future<void> removeAlert(TopicResponseModel alert);

  // Remove all alerts for a specific topic
  Future<void> removeTopic(String topic);

  // Acknowledge a specific alert
  Future<void> acknowledgeAlert(String timestamp);

  // Get the type of the latest alert for a specific topic
  Future<int> getLatestAlertType(String topic);
}
