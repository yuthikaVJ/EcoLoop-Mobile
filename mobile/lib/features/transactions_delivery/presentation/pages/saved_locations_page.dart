import 'package:flutter/material.dart';
import '../../data/services/component4_api_service.dart';
import 'location_picker_page.dart';

class SavedLocationsPage extends StatefulWidget {
  final bool select;
  const SavedLocationsPage({super.key, this.select = false});
  @override
  State<SavedLocationsPage> createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  final _api = Component4ApiService();
  late Future<List<SavedLocation>> _locations;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _locations = _api.getLocations();
  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _edit([SavedLocation? existing]) async {
    final address = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialLocation: existing?.address),
      ),
    );
    if (!mounted || address == null) return;
    var name = existing?.label ?? '';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this location'),
        content: TextFormField(
          initialValue: name,
          onChanged: (value) => name = value,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: 'Home, warehouse, collection point',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (name.trim().isNotEmpty) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name = name.trim();
    if (!mounted || accepted != true) return;
    await _run(
      () =>
          _api.saveLocation(existing: existing, label: name, address: address),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(SavedLocation item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.label}?'),
        content: const Text(
          'Existing transactions and orders keep their delivery addresses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(() => _api.deleteLocation(item.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.select ? 'Choose a saved location' : 'Saved Locations',
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _busy ? null : () => _edit(),
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<SavedLocation>>(
      future: _locations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _busy) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString()),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final locations = snapshot.data ?? [];
        if (locations.isEmpty) {
          return const Center(
            child: Text('No saved locations. Tap + to add one.'),
          );
        }
        return ListView(
          children: locations
              .map(
                (item) => ListTile(
                  title: Text(item.label),
                  subtitle: Text(item.address),
                  onTap: widget.select
                      ? () => Navigator.pop(context, item.address)
                      : () => _edit(item),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(item),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(item),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}
