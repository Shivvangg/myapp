import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../mqtt/mqtt_manager.dart';

class BrokerScreen extends StatefulWidget {
  final MQTTManager mqttManager;

  const BrokerScreen({super.key, required this.mqttManager});

  @override
  _BrokerScreenState createState() => _BrokerScreenState();
}

class _BrokerScreenState extends State<BrokerScreen> {
  final TextEditingController brokerController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwdController = TextEditingController();
  final TextEditingController identifierController = TextEditingController();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String broker = '';
  int port = 1883;
  String username = '';
  String passwd = '';
  String clientIdentifier = '';

  mqtt.MqttConnectionState get connectionState => widget.mqttManager.connectionState;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    broker = await secureStorage.read(key: 'broker') ?? '';
    port = int.tryParse(await secureStorage.read(key: 'port') ?? '1883') ?? 1883;
    username = await secureStorage.read(key: 'username') ?? '';
    passwd = await secureStorage.read(key: 'password') ?? '';
    clientIdentifier = await secureStorage.read(key: 'clientIdentifier') ?? '';

    // Update controllers with retrieved values
    brokerController.text = broker;
    portController.text = port.toString();
    usernameController.text = username;
    passwdController.text = passwd;
    identifierController.text = clientIdentifier;

    setState(() {});
  }

  Future<void> _storeData() async {
    await secureStorage.write(key: 'broker', value: broker);
    await secureStorage.write(key: 'port', value: port.toString());
    await secureStorage.write(key: 'username', value: username);
    await secureStorage.write(key: 'password', value: passwd);
    await secureStorage.write(key: 'clientIdentifier', value: clientIdentifier);
  }

  @override
  Widget build(BuildContext context) {
    IconData connectionStateIcon;
    switch (connectionState) {
      case mqtt.MqttConnectionState.connected:
        connectionStateIcon = Icons.cloud_done;
        break;
      case mqtt.MqttConnectionState.disconnected:
        connectionStateIcon = Icons.cloud_off;
        break;
      case mqtt.MqttConnectionState.connecting:
        connectionStateIcon = Icons.cloud_upload;
        break;
      case mqtt.MqttConnectionState.disconnecting:
        connectionStateIcon = Icons.cloud_download;
        break;
      case mqtt.MqttConnectionState.faulted:
        connectionStateIcon = Icons.error;
        break;
      default:
        connectionStateIcon = Icons.cloud_off;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('MQTT Broker Connection'),
            const SizedBox(width: 8.0),
            Icon(connectionStateIcon),
          ],
        ),
      ),
      body: SingleChildScrollView(  // Wrap the content in a scroll view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: brokerController,
                decoration: const InputDecoration(labelText: 'Broker'),
                onChanged: (value) {
                  broker = value;
                },
              ),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  port = int.tryParse(value) ?? port;
                },
              ),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (value) {
                  username = value;
                },
              ),
              TextField(
                controller: passwdController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) {
                  passwd = value;
                },
              ),
              TextField(
                controller: identifierController,
                decoration: const InputDecoration(labelText: 'Client Identifier'),
                onChanged: (value) {
                  clientIdentifier = value;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: connectionState == mqtt.MqttConnectionState.connected
                    ? _disconnect
                    : _connect,
                child: Text(
                  connectionState == mqtt.MqttConnectionState.connected
                      ? 'Disconnect'
                      : 'Connect',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (broker.isEmpty || clientIdentifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broker and Client Identifier are required')),
      );
      return;
    }
    try {
      await widget.mqttManager.connect(
        broker: broker,
        port: port,
        username: username,
        password: passwd,
        clientIdentifier: clientIdentifier,
      );
      await _storeData(); // Save the data securely after a successful connection
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  void _disconnect() {
    widget.mqttManager.disconnect();
    setState(() {});
  }
}
