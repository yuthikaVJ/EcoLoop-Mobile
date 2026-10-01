import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../utils/map_utils.dart';
import 'package:latlong2/latlong.dart';
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
  final _mapController = MapController();
  bool _mapReady = false;
  bool _routing = false;
  String? _routeSummary;
  String? _locationError;
  List<LatLng> _routePoints = [];
  bool _resolvingName = false;

  void _moveMap(LatLng point, double zoom) {
    if (_mapReady) _mapController.move(point, zoom);
  }

  String _formatCoordinates(LatLng point) => formatCoordinates(point);

  /// Pins [point] and shows its coordinates right away, then replaces them with
  /// the place name once the lookup returns. The pin keeps the exact point.
  Future<void> _selectPoint(LatLng point) async {
    final placeholder = _formatCoordinates(point);
    setState(() {
      _routeSummary = null;
      _routePoints = [];
      _hasCoordinates = true;
      _selected = point;
      _locationError = null;
      _locationController.text = placeholder;
      _resolvingName = true;
    });
    String? name;
    try {
      name = await _api.reverseGeocode(point.latitude, point.longitude);
    } catch (_) {
      // No address (e.g. the sea) or lookup unavailable: keep the coordinates.
    }
    if (!mounted || _selected != point) return;
    setState(() {
      _resolvingName = false;
      // Don't overwrite anything the user typed while the lookup was running.
      if (name != null && _locationController.text == placeholder) {
        _locationController.text = name;
      }
    });
  }

  /// Puts a saved place name (not coordinates) back on the map.
  Future<void> _locateInitial(String name) async {
    try {
      final (lat, lng) = await _api.geocode(name);
      if (!mounted || _locationController.text.trim() != name) return;
      setState(() {
        _selected = LatLng(lat, lng);
        _hasCoordinates = true;
      });
      _moveMap(_selected, 15);
    } catch (_) {
      // Unknown place: the text is still usable, just without a pin.
    }
  }

  LatLng? _coordinates(String? value) => parseCoordinates(value);

  Future<void> _route() async {
    final text = _locationController.text.trim();
    if (text.isEmpty) return;
    // Route to the exact pin when there is one; the name is only for display.
    final destination = _hasCoordinates ? _formatCoordinates(_selected) : text;
    setState(() {
      _routing = true;
      _routeSummary = null;
      _routePoints = [];
    });
    try {
      final position = await currentPosition();
      final result = await _api.getRoute(
        '${position.latitude}, ${position.longitude}',
        destination,
      );
      if (!mounted || text != _locationController.text.trim()) return;
      final seconds =
          double.tryParse((result['duration'] as String).replaceAll('s', '')) ??
          0;
      final points = decodePolyline(result['encodedPolyline'] as String);
      setState(() {
        _routeSummary =
            'Driving from your location: ${(result['distanceMeters'] / 1000).toStringAsFixed(1)} km, about ${(seconds / 60).ceil()} min';
        _routePoints = points;
      });
      if (points.isNotEmpty) _moveMap(points.first, 11);
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
    final text = widget.initialLocation?.trim() ?? '';
    if (initial == null && text.isNotEmpty) _locateInitial(text);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _api.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await currentPosition();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      _moveMap(point, 15);
      await _selectPoint(point);
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
        // Free OpenStreetMap tiles via flutter_map: no API key or billing needed.
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 12,
              onMapReady: () => _mapReady = true,
              onTap: widget.readOnly
                  ? null
                  : (_, position) => _selectPoint(position),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // Required by the OpenStreetMap tile usage policy.
                userAgentPackageName: 'com.example.eco_loop',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      color: Colors.green,
                      strokeWidth: 5,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_hasCoordinates)
                    Marker(
                      point: _selected,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
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
                  _resolvingName = false;
                  final point = _coordinates(value);
                  _hasCoordinates = point != null;
                  if (point != null) _selected = point;
                  _routeSummary = null;
                  _routePoints = [];
                }),
                decoration: InputDecoration(
                  labelText: 'Address or map coordinates',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  helperText: _resolvingName ? 'Finding address...' : null,
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
                      // Wait for the place name so the confirm page shows it,
                      // not the temporary coordinates.
                      onPressed: _resolvingName
                          ? null
                          : () {
                              final value = _locationController.text.trim();
                              if (value.isEmpty) {
                                setState(
                                  () => _locationError =
                                      'Choose or enter a location.',
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
