import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/component4_api_service.dart';
import '../../domain/entities/transaction_models.dart';
import '../utils/map_utils.dart';
import 'my_deliveries_page.dart' show progressLabel;

/// One Seller Delivery, driven by the seller: route to the buyer, start,
/// share position while on the way, and mark delivered.
class DeliveryRunPage extends StatefulWidget {
  final SellerDeliveryJob job;
  const DeliveryRunPage({super.key, required this.job});

  @override
  State<DeliveryRunPage> createState() => _DeliveryRunPageState();
}

class _DeliveryRunPageState extends State<DeliveryRunPage> {
  static const _shareEvery = Duration(seconds: 30);
  final _api = Component4ApiService();
  final _map = MapController();
  late SellerDeliveryJob _job = widget.job;
  LatLng? _me;
  LatLng? _destination;
  List<LatLng> _route = [];
  String? _routeSummary;
  String? _lastShared;
  bool _busy = false;
  bool _mapReady = false;
  Timer? _shareTimer;

  @override
  void initState() {
    super.initState();
    _prepare();
    if (_job.progress == DeliveryProgress.onTheWay) _startSharing();
  }

  @override
  void dispose() {
    _shareTimer?.cancel();
    _map.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final text = _job.destination;
    var destination = parseCoordinates(text);
    if (destination == null && text != null && text.isNotEmpty) {
      try {
        final (lat, lng) = await _api.geocode(text);
        destination = LatLng(lat, lng);
      } catch (_) {
        // Unknown address: the seller still sees it as text.
      }
    }
    LatLng? me;
    try {
      final position = await currentPosition();
      me = LatLng(position.latitude, position.longitude);
    } catch (_) {
      // No GPS permission yet: the map just shows the destination.
    }
    if (!mounted) return;
    setState(() {
      _destination = destination;
      _me = me;
    });
    _fit();
    if (me != null && destination != null) await _loadRoute(me, destination);
  }

  Future<void> _loadRoute(LatLng from, LatLng to) async {
    try {
      final result = await _api.getRoute(
        formatCoordinates(from),
        formatCoordinates(to),
      );
      final seconds =
          double.tryParse((result['duration'] as String).replaceAll('s', '')) ??
          0;
      if (!mounted) return;
      setState(() {
        _route = decodePolyline(result['encodedPolyline'] as String);
        _routeSummary =
            '${((result['distanceMeters'] as num) / 1000).toStringAsFixed(1)} km, about ${(seconds / 60).ceil()} min';
      });
    } catch (_) {
      // Routing is a convenience; the delivery still works without it.
    }
  }

  void _fit() {
    if (!_mapReady) return;
    final points = [?_me, ?_destination];
    if (points.length == 2) {
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
        ),
      );
    } else if (points.length == 1) {
      _map.move(points.first, 14);
    }
  }

  void _startSharing() {
    _shareTimer?.cancel();
    _shareTimer = Timer.periodic(_shareEvery, (_) => _share(quiet: true));
  }

  Future<void> _share({bool quiet = false}) async {
    try {
      final position = await currentPosition();
      final job = await _api.shareDeliveryPosition(
        _job.id,
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _job = job;
        _me = LatLng(position.latitude, position.longitude);
        _lastShared = TimeOfDay.now().format(context);
      });
    } catch (e) {
      if (!quiet && mounted) _snack(e.toString());
    }
  }

  Future<void> _run(Future<SellerDeliveryJob> Function() action) async {
    setState(() => _busy = true);
    try {
      final job = await action();
      if (!mounted) return;
      setState(() => _job = job);
      if (job.progress == DeliveryProgress.onTheWay) {
        _startSharing();
        await _share(quiet: true);
      } else {
        _shareTimer?.cancel();
      }
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelivered() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as delivered?'),
        content: Text(
          'Confirm you handed the ${_job.isProductOrder ? 'order' : 'material'} to ${_job.buyer}. This completes it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delivered'),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => _api.markDelivered(_job.id));
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_job.title, overflow: TextOverflow.ellipsis)),
    body: Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: const LatLng(6.9271, 79.8612),
              initialZoom: 11,
              onMapReady: () {
                _mapReady = true;
                _fit();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.eco_loop',
              ),
              PolylineLayer(
                polylines: [
                  if (_route.isNotEmpty)
                    Polyline(
                      points: _route,
                      color: AppColors.ecoGreen,
                      strokeWidth: 5,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  if (_me != null)
                    Marker(
                      point: _me!,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.local_shipping,
                        color: AppColors.forestGreen,
                        size: 32,
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
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Deliver to ${_job.buyer}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      progressLabel(_job.progress),
                      style: const TextStyle(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _job.destination ?? 'No delivery address',
                  style: const TextStyle(color: AppColors.slateGray),
                ),
                if (_routeSummary != null) Text('Route: $_routeSummary'),
                if (_job.progress == DeliveryProgress.onTheWay)
                  Text(
                    _lastShared == null
                        ? 'Sharing your location every 30 s while this screen is open.'
                        : 'Location shared with the buyer at $_lastShared.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                ..._actions(),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _actions() {
    switch (_job.progress) {
      case DeliveryProgress.notStarted:
        return [
          if (!_job.canStart)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'This ${_job.isProductOrder ? 'order' : 'transaction'} is ${_job.parentStatus}. Mark it Ready in Orders before you set off.',
                style: const TextStyle(color: AppColors.slateGray),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _busy || !_job.canStart
                ? null
                : () => _run(() => _api.startDelivery(_job.id)),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start delivery'),
          ),
        ];
      case DeliveryProgress.onTheWay:
        return [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _share(),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Share location'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _confirmDelivered,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Delivered'),
                ),
              ),
            ],
          ),
        ];
      case DeliveryProgress.delivered:
        return [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle, color: AppColors.ecoGreen),
            title: Text('Delivered'),
          ),
        ];
    }
  }
}
