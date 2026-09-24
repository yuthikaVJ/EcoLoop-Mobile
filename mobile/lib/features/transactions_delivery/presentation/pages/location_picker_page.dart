import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/component4_api_service.dart';

class LocationPickerPage extends StatefulWidget {
  final String? initialLocation;
  final bool readOnly;
  const LocationPickerPage({
    super.key,
    this.initialLocation,
    this.readOnly = false,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _colombo = LatLng(6.9271, 79.8612);
  late final TextEditingController _locationController;
  LatLng _selected = _colombo;
  bool _locating = false;
  bool _hasCoordinates = false;
  final _api = Component4ApiService();
  GoogleMapController? _map;
  bool _routing = false;
  String? _routeSummary;
  String? _locationError;
  Set<Polyline> _polylines = {};
  static const _mapsEnabled = bool.fromEnvironment(
    'ECOLOOP_MAPS_ENABLED',
    defaultValue: false,
  );

  LatLng? _coordinates(String? value) {
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

  Future<Position> _position() async {
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

  List<LatLng> _decodePolyline(String encoded) {
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

  Future<void> _route() async {
    final destination = _locationController.text.trim();
    if (destination.isEmpty) return;
    setState(() {
      _routing = true;
      _routeSummary = null;
      _polylines = {};
    });
    try {
      final position = await _position();
      final result = await _api.getRoute(
        '${position.latitude}, ${position.longitude}',
        destination,
      );
      if (!mounted || destination != _locationController.text.trim()) return;
      final seconds =
          double.tryParse((result['duration'] as String).replaceAll('s', '')) ??
          0;
      final points = _decodePolyline(result['encodedPolyline'] as String);
      setState(() {
        _routeSummary =
            'Driving from your location: ${(result['distanceMeters'] / 1000).toStringAsFixed(1)} km, about ${(seconds / 60).ceil()} min';
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.green,
            width: 5,
          ),
        };
      });
      if (points.isNotEmpty) {
        await _map?.animateCamera(CameraUpdate.newLatLngZoom(points.first, 11));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation);
    final initial = _coordinates(widget.initialLocation);
    _selected = initial ?? _colombo;
    _hasCoordinates = initial != null;
  }

  @override
  void dispose() {
    _map?.dispose();
    _api.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await _position();
      if (!mounted) return;
      setState(() {
        _routeSummary = null;
        _polylines = {};
        _hasCoordinates = true;
        _selected = LatLng(position.latitude, position.longitude);
        _locationController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_selected, 15));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Delivery Location')),
    body: Column(
      children: [
        if (_mapsEnabled)
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selected,
                zoom: 12,
              ),
              onMapCreated: (controller) => _map = controller,
              polylines: _polylines,
              markers: {
                if (_hasCoordinates)
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selected,
                  ),
              },
              onTap: widget.readOnly
                  ? null
                  : (position) => setState(() {
                      _routeSummary = null;
                      _polylines = {};
                      _hasCoordinates = true;
                      _selected = position;
                      _locationController.text =
                          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                    }),
              myLocationButtonEnabled: false,
            ),
          ),
        if (!_mapsEnabled)
          const Expanded(
            child: Center(
              child: Text('Enter an address or use your current location.'),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _locationController,
                readOnly: widget.readOnly,
                maxLength: 500,
                onChanged: (value) => setState(() {
                  _locationError = null;
                  final point = _coordinates(value);
                  _hasCoordinates = point != null;
                  if (point != null) _selected = point;
                  _routeSummary = null;
                  _polylines = {};
                }),
                decoration: InputDecoration(
                  labelText: 'Address or map coordinates',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  errorText: _locationError,
                ),
              ),
              if (_routeSummary != null) Text(_routeSummary!),
              TextButton.icon(
                onPressed: _routing ? null : _route,
                icon: const Icon(Icons.route),
                label: Text(
                  _routing ? 'Calculating...' : 'Driving distance from me',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locating || widget.readOnly
                          ? null
                          : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text('Current Location'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = _locationController.text.trim();
                        if (value.isEmpty) {
                          setState(
                            () =>
                                _locationError = 'Choose or enter a location.',
                          );
                          return;
                        }
                        Navigator.pop(context, value);
                      },
                      child: Text(widget.readOnly ? 'Done' : 'Use Location'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
