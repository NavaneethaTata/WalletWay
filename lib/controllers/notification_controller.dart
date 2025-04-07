import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationController {
  /// This method is triggered when a notification action is received (button click).
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    print("Notification Action Received: ${receivedAction.buttonKeyPressed}");

    // Handle the action here, for example, navigate based on the button pressed
    if (receivedAction.buttonKeyPressed == 'yes') {
      print("Yes button clicked!");
      // You can navigate or perform other actions based on the button clicked
      // MyApp.navigatorKey.currentState?.pushNamed('/yesPage');
    }
  }

  /// This method is triggered when a notification is created.
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    print("Notification Created: ${receivedNotification.title}");
  }

  /// This method is triggered when a notification is displayed.
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    print("Notification Displayed: ${receivedNotification.title}");
  }

  /// This method is triggered when the notification is dismissed.
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Access the notificationId from the ReceivedNotification (receivedAction.notification)
    print("Notification Dismissed: ${receivedAction.notification?.id ?? 'Unknown'}");
  }
}

extension on ReceivedAction {
  get notification => null;
}
