import 'dart:isolate'; // Import this to use SendPort
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void startForegroundService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service_channel',
      channelName: 'Foreground Service Channel',
      channelDescription: 'This notification appears when the foreground service is running.',
      channelImportance: NotificationChannelImportance.DEFAULT,
      priority: NotificationPriority.DEFAULT,
      iconData: const NotificationIconData(
        resType: ResourceType.drawable,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000, // The interval at which the foreground task will be executed (in milliseconds)
      isOnceEvent: false, // Whether to execute the task only once
      autoRunOnBoot: true, // Whether to automatically run the task on boot
    ),
  );

  FlutterForegroundTask.startService(
    notificationTitle: 'EV App is running',
    notificationText: 'Your app is running in the background',
    callback: startCallback,
  );
}

void startCallback() {
  // This function is called when the foreground service starts
  FlutterForegroundTask.setTaskHandler(YourTaskHandler());
}

class YourTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Perform any initialization you need here.
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Your background task logic here
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup tasks when the foreground service is destroyed
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp(); // Bring your app to the foreground
  }
}
