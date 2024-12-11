import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'alerts_repo.dart';
import 'topic_response_model.dart';

class AlertsRepoImpl implements AlertsRepo {
  static const String _alertsKey = 'alerts';

  // Get all alerts stored in SharedPreferences
  @override
  Future<List<TopicResponseModel>> getAllAlerts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? alertsJson = prefs.getString(_alertsKey);

    if (alertsJson == null) {
      return [];
    }

    final List<dynamic> alertsList = json.decode(alertsJson);
    return alertsList
        .map((alertMap) => TopicResponseModel.fromMap(Map<String, dynamic>.from(alertMap)))
        .toList();
  }

  // Add a new alert to SharedPreferences
  @override
  Future<void> addReceivedAlert(TopicResponseModel alert) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<TopicResponseModel> currentAlerts = await getAllAlerts();

    // Add the new alert to the list
    currentAlerts.add(alert);

    // Convert list of alerts to JSON
    final String alertsJson = json.encode(currentAlerts.map((e) => e.toMap()).toList());

    // Save the updated list of alerts to SharedPreferences
    await prefs.setString(_alertsKey, alertsJson);
  }

  // Remove a specific alert by id from SharedPreferences
  @override
  Future<void> removeAlert(TopicResponseModel alert) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<TopicResponseModel> currentAlerts = await getAllAlerts();

    // Remove the alert from the list
    currentAlerts.removeWhere((existingAlert) => existingAlert.id == alert.id);

    // Convert list of alerts to JSON
    final String alertsJson = json.encode(currentAlerts.map((e) => e.toMap()).toList());

    // Save the updated list of alerts to SharedPreferences
    await prefs.setString(_alertsKey, alertsJson);
  }

  // Remove all alerts for a specific topic
  @override
  Future<void> removeTopic(String topic) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<TopicResponseModel> currentAlerts = await getAllAlerts();

    // Filter out the alerts for the specified topic
    currentAlerts.removeWhere((alert) => alert.topic == topic);

    // Convert list of alerts to JSON
    final String alertsJson = json.encode(currentAlerts.map((e) => e.toMap()).toList());

    // Save the updated list of alerts to SharedPreferences
    await prefs.setString(_alertsKey, alertsJson);
  }

  // Acknowledge an alert by timestamp
  @override
  Future<void> acknowledgeAlert(String timestamp) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<TopicResponseModel> currentAlerts = await getAllAlerts();

    // Find the alert with the matching timestamp and update the acknowledged field
    final alert = currentAlerts.firstWhere((alert) => alert.timestamp == timestamp);
    alert.acknowledge = true;

    // Convert list of alerts to JSON
    final String alertsJson = json.encode(currentAlerts.map((e) => e.toMap()).toList());

    // Save the updated list of alerts to SharedPreferences
    await prefs.setString(_alertsKey, alertsJson);
  }

  // Get the latest alert type for a specific topic
  @override
  Future<int> getLatestAlertType(String topic) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<TopicResponseModel> currentAlerts = await getAllAlerts();

    // Find the latest alert for the given topic
    final List<TopicResponseModel> topicAlerts = currentAlerts.where((alert) => alert.topic == topic).toList();

    if (topicAlerts.isEmpty) {
      return 0; // Default value (Normal)
    }

    // Get the most recent alert based on timestamp
    topicAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort descending by timestamp
    return topicAlerts.first.alertType;
  }
}
