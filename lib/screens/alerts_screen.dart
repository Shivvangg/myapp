import 'package:flutter/material.dart';
import '../models/alerts_repo_impl.dart';
import '../models/topic_response_model.dart';
import '../mqtt/mqtt_manager.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class AlertsScreen extends StatefulWidget {
  final MQTTManager mqttManager;

  const AlertsScreen({super.key, required this.mqttManager});

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<TopicResponseModel> _alerts = [];
  final AlertsRepoImpl _alertsRepo = AlertsRepoImpl();

  @override
  void initState() {
    super.initState();
    _loadAlerts();

    if (widget.mqttManager.connectionState ==
        mqtt.MqttConnectionState.connected) {
      if (widget.mqttManager.onAlertReceived == null) {
        widget.mqttManager.onAlertReceived = (alert) => _onNewAlert(alert);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MQTT is not connected')),
        );
      });
    }
  }

  @override
  void dispose() {
    widget.mqttManager.onAlertReceived = null; // Reset callback
    // widget.mqttManager.disconnect();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    final storedAlerts = await _alertsRepo.getAllAlerts();
    setState(() {
      _alerts = storedAlerts;
    });
  }

  void _onNewAlert(TopicResponseModel alert) async {
    setState(() {
      _alerts.add(alert);
    });
    await _alertsRepo.addReceivedAlert(alert);
    _showAlertWindow(alert);
  }

  void _showAlertWindow(TopicResponseModel alert) {
    print('New alert: ${alert.message}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: _alerts.isEmpty
          ? const Center(child: Text('No alerts yet'))
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return _AlertListItem(
                  alert: alert,
                  onAcknowledge: () async {
                    await _alertsRepo.acknowledgeAlert(alert.timestamp);
                    setState(() {
                      alert.acknowledge = true;
                    });
                  },
                  onDelete: () async {
                    await _alertsRepo.removeAlert(alert);
                    setState(() {
                      _alerts.removeAt(index);
                    });
                  },
                );
              },
            ),
    );
  }
}

class _AlertListItem extends StatelessWidget {
  final TopicResponseModel alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onDelete;

  const _AlertListItem({
    required this.alert,
    required this.onAcknowledge,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  alert.topic,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDelete,
                ),
              ],
            ),
            const Divider(color: Colors.black),
            const SizedBox(height: 8),
            Text(
              'Date: ${alert.timestamp}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (alert.imageUrl.isNotEmpty)
              Image.network(
                alert.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: TextStyle(
                fontSize: 15,
                color: _getAlertTextColor(alert.alert),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: alert.acknowledge ? null : onAcknowledge,
              child: Text(alert.acknowledge ? 'Acknowledged' : 'Acknowledge'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertTextColor(int? alertType) {
    switch (alertType) {
      case 1:
        return Colors.orange; // Warning
      case 2:
        return Colors.red; // Danger
      default:
        return Colors.black; // Normal
    }
  }
}
