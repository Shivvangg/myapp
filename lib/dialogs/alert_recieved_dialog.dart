import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../media player/media_player.dart';
import '../models/alerts_repo.dart';
import '../models/topic_response_model.dart';

// For formatting timestamp
class AlertReceivedDialog extends StatelessWidget {
  final TopicResponseModel alert;
  final AlertsRepo alertsRepo;

  const AlertReceivedDialog({
    required this.alert,
    required this.alertsRepo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    MediaPlayer.playAlarm(alert.alert);

    return AlertDialog(
      backgroundColor: Colors.grey[900], // Dark background for the alert
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              alert.topic,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: Colors.white,
            onPressed: () {
              MediaPlayer.stopAlarm(); // Stop the alarm when dialog is closed
              Navigator.of(context).pop(); // Close dialog
            },
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            color: Colors.white,
            thickness: 2,
            height: 20,
          ),
          Row(
            children: [
              const Text(
                'Date:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(alert.timestamp)),
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
          if (alert.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: alert.imageUrl,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
              height: 200,
              width: 150,
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Message:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: _getAlertColor(alert.alert),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(); // Close the dialog
            MediaPlayer.stopAlarm(); // Stop the alarm when acknowledged
            try {
              await alertsRepo.acknowledgeAlert(alert.timestamp);
            } catch (e) {
              // Handle error, maybe show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error acknowledging alert')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blue,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          ),
          child: const Text('Acknowledge'),
        ),
      ],
    );
  }

  // Helper method to return color based on alert type
  Color _getAlertColor(int alertType) {
    switch (alertType) {
      case 1:
        return Colors.orange; // Warning
      case 2:
        return Colors.red; // Critical
      default:
        return Colors.green; // Normal
    }
  }
}
