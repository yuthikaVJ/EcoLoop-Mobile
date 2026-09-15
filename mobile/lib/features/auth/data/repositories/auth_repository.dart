import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = 'http://10.0.2.2:5252/api/auth';
  
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID']!,
      );
      _initialized = true;
    }
  }

  Future<String?> getSavedToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getSavedRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        // User canceled the sign-in flow
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google.');
      }

      // Send ID token to our backend
      final response = await http.post(
        Uri.parse('$_baseUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token'];
        final String refreshToken = data['refreshToken'];
        
        // Save the tokens securely
        await _storage.write(key: 'access_token', value: token);
        await _storage.write(key: 'refresh_token', value: refreshToken);
      } else {
        throw Exception('Backend authentication failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      // Disconnect might fail if already disconnected, fallback to signout
      await GoogleSignIn.instance.signOut();
    }
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> refreshToken() async {
    final accessToken = await getSavedToken();
    final refreshToken = await getSavedRefreshToken();

    if (accessToken == null || refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String newToken = data['token'];
        final String newRefreshToken = data['refreshToken'];
        
        await _storage.write(key: 'access_token', value: newToken);
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
        return true;
      } else {
        // Tokens are invalid/expired, require re-login
        await signOut();
        return false;
      }
    } catch (e) {
      print('Token Refresh Error: $e');
      return false;
    }
  }
}
