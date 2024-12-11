import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dialogs/alert_recieved_dialog.dart';
import 'models/alerts_repo.dart';
import 'models/alerts_repo_impl.dart';
import 'mqtt/mqtt_manager.dart';
import 'screens/alerts_screen.dart';
import 'screens/broker_screen.dart';
import 'screens/topic_screen.dart';
import 'package:flutter_background/flutter_background.dart';
import 'models/topic_response_model.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
          '@mipmap/ic_launcher'); // Replace with your notification icon

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await _notificationsPlugin.initialize(initializationSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late MQTTManager mqttManager;
  final AlertsRepo alertsRepo = AlertsRepoImpl(); // Provide your implementation

  int _currentIndex = 0;

  // Screens list to manage navigation
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize MQTTManager with a callback for alert reception
    mqttManager = MQTTManager.getInstance(
      onAlertReceived: (alert) => _showAlertDialog(alert),
    );

    // Initialize screens with the shared MQTTManager
    _screens = [
      BrokerScreen(mqttManager: mqttManager),
      TopicScreen(mqttManager: mqttManager),
      AlertsScreen(mqttManager: mqttManager),
    ];

    // Start the background service to maintain MQTT connection
    _startBackgroundService();
  }

  // Function to display the alert dialog
  void _showAlertDialog(TopicResponseModel alert) async {
    await alertsRepo.addReceivedAlert(alert);

    if (!mounted) return;

    if (ModalRoute.of(context)?.isCurrent ?? false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertReceivedDialog(
          alert: alert,
          alertsRepo: alertsRepo,
        ),
      );
    } else {
      _showNotificationWithImage(alert); // Updated to include the image
    }
  }

  Future<void> _showNotificationWithImage(TopicResponseModel alert) async {
    try {
      // Download the image from the URL
      final http.Response response = await http.get(Uri.parse(alert.imageUrl));
      if (response.statusCode == 200) {
        // Save the image to the device's temporary directory
        final String tempPath = (await getTemporaryDirectory()).path;
        final File imageFile = File('$tempPath/alert_image.png');
        await imageFile.writeAsBytes(response.bodyBytes);

        // Set up the notification details with a big picture style
        final BigPictureStyleInformation bigPictureStyleInformation =
            BigPictureStyleInformation(
          FilePathAndroidBitmap(imageFile.path), // The downloaded image
          contentTitle: '<b>${alert.topic}</b>',
          htmlFormatContentTitle: true,
          summaryText: alert.message,
          htmlFormatSummaryText: true,
        );

        AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'alerts_channel', // Channel ID
          'Alerts', // Channel Name
          channelDescription: 'Notifications for incoming MQTT alerts',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
        );

        NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);

        await _notificationsPlugin.show(
          0, // Notification ID
          alert.topic, // Title
          alert.message, // Body
          platformChannelSpecifics,
        );
      } else {
        print('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error displaying notification with image: $e');
    }
  }

  // Function to start background service for maintaining MQTT connection
  Future<void> _startBackgroundService() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "MQTT Service",
      notificationText: "MQTT client is running in the background",
      notificationIcon:
          AndroidResource(name: 'background_icon', defType: 'drawable'),
    );
    await FlutterBackground.initialize(androidConfig: androidConfig);
    await FlutterBackground.enableBackgroundExecution();

    // Start MQTT connection
    // await mqttManager.connect(
    //   broker: 'your_broker',
    //   port: 1883,
    //   username: 'your_username',
    //   password: 'your_password',
    //   clientIdentifier: 'your_client_id',
    // );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MQTT App',
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud),
              label: 'Broker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.topic),
              label: 'Topics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notification_important),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
