import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/materials_marketplace/presentation/providers/material_listings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // Request permissions for notifications
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: EcoLoopApp(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class EcoLoopApp extends ConsumerWidget {
  const EcoLoopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // These providers cache data for the signed-in user and are not
    // auto-disposed, so drop them whenever someone signs in or out; otherwise
    // the next account sees the previous account's profile and listings.
    ref.listen(authNotifierProvider, (_, next) {
      if (next is! AsyncData) return;
      ref.invalidate(profileNotifierProvider);
      ref.invalidate(myListingsProvider);
      ref.invalidate(materialListingsProvider);
      ref.invalidate(activeListingsNotifierProvider);
    });

    return MaterialApp(
      title: 'EcoLoop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (isLoggedIn) => isLoggedIn ? const AppShell() : const LoginPage(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(body: Center(child: Text('Auth Error: $err'))),
      ),
    );
  }
}
