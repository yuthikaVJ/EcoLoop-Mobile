import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class LocationPickerPage extends StatefulWidget {
  final String? initialLocation;
  const LocationPickerPage({super.key, this.initialLocation});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _colombo = LatLng(6.9271, 79.8612);
  late final TextEditingController _locationController;
  LatLng _selected = _colombo;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Location services are disabled.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selected = LatLng(position.latitude, position.longitude);
        _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Delivery Location')),
        body: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: _colombo, zoom: 12),
                markers: {Marker(markerId: const MarkerId('selected'), position: _selected)},
                onTap: (position) => setState(() {
                  _selected = position;
                  _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                }),
                myLocationButtonEnabled: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Address or map coordinates', prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _locating ? null : _useCurrentLocation,
                          icon: _locating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose or enter a location.')));
                              return;
                            }
                            Navigator.pop(context, value);
                          },
                          child: const Text('Use Location'),
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
