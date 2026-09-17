import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/materials_marketplace/presentation/pages/inbox_page.dart';
import 'marketplace_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  int _marketplaceTabIndex = 0;

  List<Widget> get _pages => [
    HomePage(
      onNavigate: (bottomIndex, {topIndex}) {
        setState(() {
          _currentIndex = bottomIndex;
          if (topIndex != null) _marketplaceTabIndex = topIndex;
        });
      },
    ),
    MarketplacePage(
      key: ValueKey('marketplace_$_marketplaceTabIndex'),
      initialTabIndex: _marketplaceTabIndex,
    ),
    const InboxPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _registerDeviceToken();
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final authToken =
            await const FlutterSecureStorage().read(key: 'access_token');
        if (authToken != null) {
          await http.post(
            Uri.parse(
                'http://10.0.2.2:5252/api/notifications/register-device'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'token': token}),
          );
        }
      }
    } catch (_) {
      // Non-fatal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
