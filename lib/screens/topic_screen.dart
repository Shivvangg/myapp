import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mqtt/mqtt_manager.dart';

class TopicScreen extends StatefulWidget {
  final MQTTManager mqttManager;

  const TopicScreen({super.key, required this.mqttManager});

  @override
  _TopicScreenState createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final TextEditingController topicController = TextEditingController();
  List<String> topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      topics = prefs.getStringList('topics') ?? [];
    });
  }

  Future<void> _saveTopics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('topics', topics);
  }

  void _addTopic(String topic) {
    if (topic.isNotEmpty && !topics.contains(topic)) {
      setState(() {
        topics.add(topic);
      });
      _saveTopics();
    }
  }

  void _deleteTopic(String topic) {
    if (topics.contains(topic)) {
      setState(() {
        topics.remove(topic);
      });
      widget.mqttManager.unsubscribeFromTopic(topic);
      _saveTopics();
    }
  }

  void _toggleSubscription(String topic) {
    if (widget.mqttManager.isSubscribed(topic)) {
      widget.mqttManager.unsubscribeFromTopic(topic);
    } else {
      widget.mqttManager.subscribeToTopic(topic);
    }
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Topics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
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
                    TextField(
                      controller: topicController,
                      decoration: InputDecoration(
                        labelText: 'Enter Topic',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.topic),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.deepPurple
                        ),
                        onPressed: () {
                          final newTopic = topicController.text.trim();
                          _addTopic(newTopic);
                          topicController.clear();
                        },
                        child: const Text(
                          'Add Topic',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: topics.isEmpty
                  ? const Center(
                      child: Text(
                        'No topics available',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final currentTopic = topics[index];
                        final isSubscribed = widget.mqttManager.isSubscribed(currentTopic);

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(
                              currentTopic,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTopic(currentTopic),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isSubscribed ? Icons.unsubscribe : Icons.add,
                                    color: isSubscribed ? Colors.orange : Colors.green,
                                  ),
                                  onPressed: () => _toggleSubscription(currentTopic),
                                ),
                              ],
                            ),
                          ),
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
