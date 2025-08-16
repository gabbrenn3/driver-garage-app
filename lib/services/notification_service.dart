import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> initializeForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('user_tokens').doc(userId).set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _firestore.collection('user_tokens').doc(userId).set({
          'token': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error initializing notifications for user: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap when app is in background
    print('Notification tapped: ${message.data}');
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap
    print('Local notification tapped: ${response.payload}');
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'driver_garage_channel',
      'Driver Garage Notifications',
      channelDescription: 'Notifications for driver-garage interactions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> sendPushNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get recipient's FCM token
      final tokenDoc = await _firestore
          .collection('user_tokens')
          .doc(recipientId)
          .get();

      if (!tokenDoc.exists) return;

      final token = tokenDoc.data()?['token'];
      if (token == null) return;

      // In a real app, you would send this to your backend server
      // which would then send the push notification using FCM Admin SDK
      // For now, we'll just show a local notification
      await showLocalNotification(
        title: title,
        body: body,
        payload: data?.toString(),
      );
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}