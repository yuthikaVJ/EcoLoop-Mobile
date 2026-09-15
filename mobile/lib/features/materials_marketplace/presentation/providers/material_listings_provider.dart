import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/material_listing.dart';
import '../../data/repositories/material_listing_repository.dart';

final materialListingRepositoryProvider = Provider<MaterialListingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MaterialListingRepository(apiClient);
});

// A provider that fetches all active listings
final materialListingsProvider = FutureProvider<List<MaterialListing>>((ref) async {
  final repository = ref.read(materialListingRepositoryProvider);
  return repository.getListings();
});

// A provider for My Listings
final myListingsProvider = FutureProvider<List<MaterialListing>>((ref) async {
  final repository = ref.read(materialListingRepositoryProvider);
  final allListings = await repository.getListings();
  
  try {
    final profile = await ref.read(profileNotifierProvider.future);
    return allListings.where((l) => l.businessId == profile.id).toList();
  } catch (e) {
    // If profile fails, return empty
    return [];
  }
});

class MaterialListingsNotifier extends AsyncNotifier<List<MaterialListing>> {
  MaterialListingRepository get _repository => ref.read(materialListingRepositoryProvider);

  @override
  Future<List<MaterialListing>> build() async {
    return _repository.getListings();
  }

  Future<void> addListing(Map<String, dynamic> requestData, {File? imageFile}) async {
    try {
      final newListing = await _repository.createListing(requestData, imageFile: imageFile);
      state = state.whenData((currentListings) {
        return [newListing, ...currentListings];
      });
    } catch (e) {
      // Handle error (e.g. show a snackbar in UI)
      rethrow;
    }
  }

  Future<void> changeStatus(String id, int newStatus) async {
    try {
      final success = await _repository.changeStatus(id, newStatus);
      if (success) {
        // If status > 0 (completed or deleted), remove it from the active list
        if (newStatus > 0) {
          state = state.whenData((currentListings) {
            return currentListings.where((l) => l.id != id).toList();
          });
        } else {
          // If we are updating an active listing status, fetch it again or update locally
          ref.invalidateSelf();
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

final activeListingsNotifierProvider = AsyncNotifierProvider<MaterialListingsNotifier, List<MaterialListing>>(() {
  return MaterialListingsNotifier();
});
