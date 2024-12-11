import 'package:audioplayers/audioplayers.dart';

class MediaPlayer {
  static AudioPlayer? _audioPlayer;

  /// Function to play an alarm based on the alert type
  static Future<void> playAlarm(int alarmType) async {
    // Stop any currently playing alarm
    await stopAlarm();

    // Determine the audio file to play based on the alarm type
    String audioPath;
    switch (alarmType) {
      case 0:
        audioPath = 'assets/sounds/normal_alarm.mp3';
        break;
      case 1:
        audioPath = 'assets/sounds/warning_alert.mp3';
        break;
      case 2:
        audioPath = 'assets/sounds/critical_alarm.mp3';
        break;
      default:
        audioPath = 'assets/sounds/normal_alarm.mp3';
    }

    // Initialize the audio player
    _audioPlayer = AudioPlayer();
    _audioPlayer?.setReleaseMode(ReleaseMode.loop); // Loop the alarm

    // Play the audio
    await _audioPlayer?.play(AssetSource(audioPath));
  }

  /// Function to stop the currently playing alarm
  static Future<void> stopAlarm() async {
    if (_audioPlayer != null) {
      await _audioPlayer?.stop();
      _audioPlayer?.release();
      _audioPlayer = null;
    }
  }
}
