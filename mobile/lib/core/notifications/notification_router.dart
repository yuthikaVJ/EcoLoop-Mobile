import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_matching/presentation/matches_page.dart';
import '../../features/ai_matching/presentation/matches_providers.dart';
import '../../features/business_hub/presentation/pages/business_hub_landing_page.dart';
import '../../features/business_hub/presentation/providers/business_hub_providers.dart';
import '../../features/materials_marketplace/presentation/pages/chat_page.dart';
import '../../features/materials_marketplace/presentation/pages/inbox_page.dart';
import '../../features/materials_marketplace/presentation/providers/material_listings_provider.dart';

/// Lets notification handlers navigate without a BuildContext.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Shows push notifications while the app is open (Android only displays them
/// itself in the background) and opens the matching screen when one is tapped.
/// The backend puts the screen to open in the message's `type` data field.
class NotificationRouter {
  NotificationRouter._();

  static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationDetails(
    'ecoloop_default',
    'EcoLoop',
    channelDescription: 'Matches, messages and business updates',
    importance: Importance.high,
    priority: Priority.high,
  );
  static bool _started = false;

  /// Call once the signed-in app shell is on screen (the navigator must exist).
  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        }
      },
    );

    FirebaseMessaging.onMessage.listen(_showWhileOpen);
    FirebaseMessaging.onMessageOpenedApp.listen((message) => open(message.data));
    // The app was closed and launched by tapping a notification.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) open(initial.data);
  }

  static Future<void> _showWhileOpen(RemoteMessage message) async {
    final data = message.data;
    _refreshData(data['type']);
    // Don't notify about a chat the user is already looking at.
    if (data['type'] == 'chat_message' && data['listingId'] == ChatPage.openListingId) return;
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(android: _channel),
      payload: jsonEncode(data),
    );
  }

  /// Opens the screen a notification is about.
  static Future<void> open(Map<String, dynamic> data) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    _refreshData(data['type']);
    switch (data['type']) {
      case 'material_match':
        navigator.push(MaterialPageRoute(builder: (_) => const MatchesPage()));
      case 'business_verification':
        navigator.push(MaterialPageRoute(builder: (_) => const BusinessHubLandingPage()));
      case 'chat_message':
        await _openChat(navigator, data['listingId']?.toString(), data['senderId']?.toString());
    }
  }

  static Future<void> _openChat(NavigatorState navigator, String? listingId, String? senderId) async {
    final context = navigator.context;
    if (listingId == null || senderId == null) {
      navigator.push(MaterialPageRoute(builder: (_) => const InboxPage()));
      return;
    }
    try {
      final listing = await ProviderScope.containerOf(context, listen: false)
          .read(materialListingRepositoryProvider)
          .getListingById(listingId);
      navigator.push(MaterialPageRoute(builder: (_) => ChatPage(listing: listing, receiverId: senderId)));
    } catch (_) {
      // Listing gone or offline: the inbox still shows the conversation.
      navigator.push(MaterialPageRoute(builder: (_) => const InboxPage()));
    }
  }

  /// New matches or verification results change what those screens show.
  static void _refreshData(Object? type) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    if (type == 'material_match') container.invalidate(myMatchesProvider);
    if (type == 'business_verification') container.invalidate(myBusinessProfilesProvider);
  }
}
