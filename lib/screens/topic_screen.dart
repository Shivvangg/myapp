import 'package:flutter/material.dart';
import '../mqtt/mqtt_manager.dart';

class TopicScreen extends StatefulWidget {
  final MQTTManager mqttManager;

  const TopicScreen({super.key, required this.mqttManager});

  @override
  _TopicScreenState createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final TextEditingController topicController = TextEditingController();
  String topic = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(labelText: 'Enter Topic'),
              onChanged: (value) {
                topic = value;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (topic.isNotEmpty) {
                  widget.mqttManager.subscribeToTopic(topic);
                  setState(() {}); // Refresh UI after subscribing
                }
              },
              child: const Text('Add Topic'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder(
                future: Future.delayed(const Duration(
                    milliseconds: 100)), // Delay to allow topics to load
                builder: (context, snapshot) {
                  List<String> topics = widget.mqttManager.topics;
                  return ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      String currentTopic = topics[index];
                      bool isSubscribed =
                          widget.mqttManager.isSubscribed(currentTopic);

                      return ListTile(
                        title: Text(currentTopic),
                        trailing: isSubscribed
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.unsubscribe),
                                    onPressed: () {
                                      widget.mqttManager
                                          .unsubscribeFromTopic(currentTopic);
                                      setState(
                                          () {}); // Refresh UI after unsubscribing
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      widget.mqttManager
                                          .deleteTopic(currentTopic);
                                      setState(
                                          () {}); // Refresh UI after deleting
                                    },
                                  ),
                                ],
                              )
                            : IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  widget.mqttManager
                                      .subscribeToTopic(currentTopic);
                                  setState(
                                      () {}); // Refresh UI after subscribing
                                },
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
