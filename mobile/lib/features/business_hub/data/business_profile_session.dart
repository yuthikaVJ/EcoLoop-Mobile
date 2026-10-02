import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/business_profile.dart';

class BusinessProfileSession {
  static const String _keyActiveProfile = 'active_business_profile';

  static final BusinessProfileSession _instance =
      BusinessProfileSession._internal();

  factory BusinessProfileSession() => _instance;

  BusinessProfileSession._internal();

  BusinessProfile? _cachedProfile;
  final ValueNotifier<BusinessProfile?> activeProfileNotifier =
      ValueNotifier<BusinessProfile?>(null);

  BusinessProfile? get currentProfile => _cachedProfile;
  bool get hasActiveProfile => _cachedProfile != null;
  String? get activeProfileId => _cachedProfile?.id;
  String? get activeBusinessName => _cachedProfile?.businessName;

  /// Restores the saved active profile. When [ownerId] is given, a profile
  /// owned by a different account (e.g. after switching Google accounts) is
  /// discarded instead.
  Future<void> initialize({String? ownerId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyActiveProfile);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        final saved = BusinessProfile.fromJson(data);
        if (ownerId != null && saved.userId != ownerId) {
          await clearActiveProfile();
          return;
        }
        _cachedProfile = saved;
        activeProfileNotifier.value = _cachedProfile;
      }
    } catch (e) {
      debugPrint('Error initializing BusinessProfileSession: $e');
    }
  }

  Future<void> setActiveProfile(BusinessProfile profile) async {
    _cachedProfile = profile;
    activeProfileNotifier.value = profile;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(profile.toJson());
      await prefs.setString(_keyActiveProfile, jsonStr);
    } catch (e) {
      debugPrint('Error saving active profile to SharedPreferences: $e');
    }
  }

  Future<void> clearActiveProfile() async {
    _cachedProfile = null;
    activeProfileNotifier.value = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveProfile);
    } catch (e) {
      debugPrint('Error clearing active profile from SharedPreferences: $e');
    }
  }
}
