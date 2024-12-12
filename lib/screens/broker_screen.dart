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
            const Text('MQTT Broker Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8.0),
            Icon(connectionStateIcon, size: 24),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Connection Settings',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: brokerController,
                        decoration: InputDecoration(
                          labelText: 'Broker',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.dns),
                        ),
                        onChanged: (value) {
                          broker = value;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: portController,
                        decoration: InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.settings_input_composite),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          port = int.tryParse(value) ?? port;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        onChanged: (value) {
                          username = value;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwdController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          passwd = value;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: identifierController,
                        decoration: InputDecoration(
                          labelText: 'Client Identifier',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.perm_identity),
                        ),
                        onChanged: (value) {
                          clientIdentifier = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: connectionState == mqtt.MqttConnectionState.connected
                      ? Colors.red
                      : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: connectionState == mqtt.MqttConnectionState.connected
                    ? _disconnect
                    : _connect,
                child: Text(
                  connectionState == mqtt.MqttConnectionState.connected ? 'Disconnect' : 'Connect',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
