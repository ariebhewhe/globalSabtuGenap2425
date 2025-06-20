// Create this class in a new file: notification_controller.dart
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
class NotificationController {
  /// Singleton pattern
  static final NotificationController _instance = NotificationController._();
  factory NotificationController() => _instance;
  NotificationController._();
  
  // Stream controller for notification actions
  static final StreamController<ReceivedAction> _streamController = 
      StreamController<ReceivedAction>.broadcast();
      
  // Stream for notification actions
  static Stream<ReceivedAction> get actionStream => _streamController.stream;
  
  // Method called when notification is created
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // You can add custom logic here
    debugPrint('Notification created: ${receivedNotification.id}');
  }
  
  // Method called when notification is displayed
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // You can add custom logic here
    debugPrint('Notification displayed: ${receivedNotification.id}');
  }
  
  // Method called when a notification action is received
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Add to stream
    _streamController.add(receivedAction);
    
    // You can add custom logic here
    debugPrint('Notification action received: ${receivedAction.id}');
    debugPrint('Action: ${receivedAction.buttonKeyPressed}');
  }
  
  // Method called when notification is dismissed
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // You can add custom logic here
    debugPrint('Notification dismissed: ${receivedAction.id}');
  }
  
  // Dispose the controller when done
  static void dispose() {
    _streamController.close();
  }
}