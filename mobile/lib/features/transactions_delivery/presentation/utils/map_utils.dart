import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

/// Current GPS position, asking for permission if needed.
Future<Position> currentPosition() async {
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
  return Geolocator.getCurrentPosition().timeout(const Duration(seconds: 15));
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
