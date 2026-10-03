import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as device;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/component4_api_service.dart';

/// Place name for [point]. Uses the EcoLoop backend (OpenStreetMap) first and,
/// if it can't be reached (e.g. a real phone that can't see the dev server),
/// the phone's built-in geocoder, which is free and needs no API key.
Future<String?> placeName(Component4ApiService api, LatLng point) async {
  try {
    return await api
        .reverseGeocode(point.latitude, point.longitude)
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    // Fall back to the device geocoder below.
  }
  try {
    final places = await device.Geocoding()
        .placemarkFromCoordinates(point.latitude, point.longitude)
        .timeout(const Duration(seconds: 8));
    if (places.isEmpty) return null;
    final p = places.first;
    final parts = <String>[];
    for (final part in [
      p.street ?? p.name,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.country,
    ]) {
      final text = part?.trim();
      if (text != null && text.isNotEmpty && !parts.contains(text)) {
        parts.add(text);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  } catch (_) {
    return null;
  }
}

/// Coordinates for a place name, with the same backend-then-device fallback.
Future<LatLng?> placeCoordinates(Component4ApiService api, String name) async {
  try {
    final (lat, lng) = await api
        .geocode(name)
        .timeout(const Duration(seconds: 6));
    return LatLng(lat, lng);
  } catch (_) {
    // Fall back to the device geocoder below.
  }
  try {
    final found = await device.Geocoding()
        .locationFromAddress(name)
        .timeout(const Duration(seconds: 8));
    return found.isEmpty
        ? null
        : LatLng(found.first.latitude, found.first.longitude);
  } catch (_) {
    return null;
  }
}

/// Parses "lat, lng" text (what GPS and map taps produce); null for addresses.
LatLng? parseCoordinates(String? value) {
  final parts = value?.split(',');
  if (parts == null || parts.length != 2) return null;
  final lat = double.tryParse(parts[0].trim()),
      lng = double.tryParse(parts[1].trim());
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat.abs() > 90 ||
      lng.abs() > 180) {
    return null;
  }
  return LatLng(lat, lng);
}

String formatCoordinates(LatLng point) =>
    '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

const _nativeLocation = MethodChannel('ecoloop/location');
Future<LatLng>? _pendingPosition;

/// Current position, asking for permission if needed.
///
/// 1. Android's cached fix when it is younger than [maxAge] (instant, no GPS).
/// 2. A real fix: on Android from Google Play Services via MainActivity
///    (geolocator's own request can freeze the app on some Android builds; see
///    MainActivity.getCurrentLocation), elsewhere from geolocator. The emulator
///    has no Wi-Fi/network location, so it needs a position set under
///    Extended controls → Location.
/// 3. If no fix arrives in time, an older cached fix, so the button never
///    spins forever; the user can still tap the map to adjust the pin.
///
/// Overlapping calls (double taps, periodic sharing) share one lookup.
Future<LatLng> currentPosition({
  Duration maxAge = const Duration(minutes: 2),
}) {
  return _pendingPosition ??=
      _locate(maxAge).whenComplete(() => _pendingPosition = null);
}

Future<LatLng> _locate(Duration maxAge) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Location services are disabled.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Location permission was not granted.');
  }
  final last = await Geolocator.getLastKnownPosition();
  final lastPoint =
      last == null ? null : LatLng(last.latitude, last.longitude);
  if (last != null && DateTime.now().difference(last.timestamp) <= maxAge) {
    return lastPoint!;
  }
  try {
    final fresh = await _freshPosition(maxAge);
    if (fresh != null) return fresh;
  } catch (_) {
    // Fall through to the cached position below.
  }
  // No fix in time: an older position is better than an endless spinner.
  if (lastPoint != null) return lastPoint;
  throw Exception(
    "Couldn't get your location. Turn on location, or on the emulator set one "
    'under Extended controls (⋯) → Location → Set location.',
  );
}

Future<LatLng?> _freshPosition(Duration maxAge) async {
  const timeLimit = Duration(seconds: 15);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final result = await _nativeLocation
        .invokeMapMethod<String, dynamic>('getCurrentLocation', {
          'timeoutMs': timeLimit.inMilliseconds,
          'maxAgeMs': maxAge.inMilliseconds,
        })
        // Play Services enforces the time limit too; this is a safety net.
        .timeout(timeLimit + const Duration(seconds: 5));
    if (result == null) return null;
    return LatLng(
      (result['latitude'] as num).toDouble(),
      (result['longitude'] as num).toDouble(),
    );
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: timeLimit,
    ),
  );
  return LatLng(position.latitude, position.longitude);
}

/// Decodes a precision-5 encoded polyline (the route geometry the backend returns).
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0, lat = 0, lng = 0;
  int next() {
    int result = 0, shift = 0, byte;
    do {
      if (index >= encoded.length || shift > 30) {
        throw const FormatException('Invalid route geometry');
      }
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 31) << shift;
      shift += 5;
    } while (byte >= 32);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
