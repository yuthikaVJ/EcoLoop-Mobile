import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/materials_marketplace/presentation/pages/inbox_page.dart';
import '../../features/transactions_delivery/presentation/pages/transactions_hub_page.dart';
import 'marketplace_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import '../../core/notifications/notification_router.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
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
    // Transactions, product orders and (for sellers) My Deliveries.
    const TransactionsHubPage(),
    const InboxPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _registerDeviceToken();
    // After the first frame the navigator exists, so taps can open screens.
    WidgetsBinding.instance.addPostFrameCallback((_) => NotificationRouter.start());
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(apiClientProvider).post(
          '/api/notifications/register-device',
          body: jsonEncode({'token': token}),
        );
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
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
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
