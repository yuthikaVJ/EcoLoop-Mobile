import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eco_loop/features/materials_marketplace/domain/entities/material_listing.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/providers/material_listings_provider.dart';
import 'package:eco_loop/features/profile/domain/entities/account_profile.dart';
import 'package:eco_loop/features/profile/presentation/providers/profile_provider.dart';

MaterialListing testListing({
  String id = 'l1',
  String title = 'PET bottles',
  bool iHave = true,
  String? businessId = 'me',
}) =>
    MaterialListing(
      id: id,
      businessId: businessId,
      title: title,
      category: 'Plastics',
      description: 'Clean and baled',
      quantity: '500',
      unit: 'Kgs',
      location: 'Colombo',
      price: 120,
      priceUnit: 'Kg',
      companyName: 'GreenCycle',
      isVerifiedSeller: true,
      isIHave: iHave,
      status: 0,
      datePosted: DateTime(2026, 10, 1),
    );

final testAccount = AccountProfile(
  id: 'me',
  businessName: 'Haritha',
  email: 'haritha@example.com',
  phoneNumber: '0771234567',
  address: 'Colombo',
  createdAt: DateTime(2026, 9, 12),
  isVerified: false,
);

/// Marketplace listings without a server; records what the screens submit.
class FakeListingsNotifier extends MaterialListingsNotifier {
  FakeListingsNotifier([this.initial = const []]);

  final List<MaterialListing> initial;
  final List<Map<String, dynamic>> added = [];
  final List<Map<String, dynamic>> updated = [];

  @override
  Future<List<MaterialListing>> build() async => initial;

  @override
  Future<void> addListing(Map<String, dynamic> requestData, {List<File> imageFiles = const []}) async {
    added.add(requestData);
  }

  @override
  Future<void> updateListing(String id, Map<String, dynamic> requestData, {List<File> newImages = const []}) async {
    updated.add(requestData);
  }
}

/// The signed-in account without a server; records saves.
class FakeProfileNotifier extends ProfileNotifier {
  final List<AccountProfile> saved = [];

  @override
  Future<AccountProfile> build() async => testAccount;

  @override
  Future<void> updateProfile(AccountProfile updatedProfile) async {
    saved.add(updatedProfile);
    state = AsyncData(updatedProfile);
  }
}
