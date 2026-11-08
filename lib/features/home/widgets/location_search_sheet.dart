import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/device_location.dart';
import '../../posts/models/location_pick_result.dart';

/// Full-screen sheet to search and pick a home/feed location.
class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({
    super.key,
    this.initialQuery,
  });

  final String? initialQuery;

  static Future<LocationPickResult?> show(
    BuildContext context, {
    String? initialQuery,
  }) {
    return showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => LocationSearchSheet(initialQuery: initialQuery),
    );
  }

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _searching = false;
  bool _usingCurrent = false;
  String? _error;
  List<_SearchHit> _results = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _searchController.text = initial;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _results = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String query) async {
    try {
      final locations = await locationFromAddress(query);
      final hits = <_SearchHit>[];
      for (final loc in locations.take(8)) {
        String label = query;
        try {
          final marks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (marks.isNotEmpty) {
            label = formatPlacemarkLabel(marks.first) ?? query;
          }
        } catch (_) {
          // Keep query as label if reverse geocode fails.
        }
        hits.add(
          _SearchHit(
            label: label,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _results = hits;
        _searching = false;
        _error = hits.isEmpty ? 'No places found for “$query”.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
        _error = 'Could not search places. Try a different name.';
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _usingCurrent = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _usingCurrent = false;
          _error = 'Location permission is required.';
        });
        return;
      }
      final pos = await DeviceLocation.current();
      if (pos == null) {
        if (!mounted) return;
        setState(() {
          _usingCurrent = false;
          _error = 'Location is unavailable. Search for a place instead.';
        });
        return;
      }
      final marks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 5));
      final label = marks.isNotEmpty
          ? (formatPlacemarkLabel(marks.first) ?? 'Current location')
          : 'Current location';
      if (!mounted) return;
      Navigator.of(context).pop(
        LocationPickResult(
          address: label,
          latitude: pos.latitude,
          longitude: pos.longitude,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _usingCurrent = false;
        _error = 'Could not get your current location.';
      });
    }
  }

  void _select(_SearchHit hit) {
    Navigator.of(context).pop(
      LocationPickResult(
        address: hit.label,
        latitude: hit.latitude,
        longitude: hit.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: height * 0.94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Set location',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchBar(
              controller: _searchController,
              focusNode: _focusNode,
              hintText: 'Search city, area, or address…',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                      setState(() {});
                    },
                  ),
              ],
              onChanged: (v) {
                setState(() {});
                _onQueryChanged(v);
              },
              onSubmitted: (v) {
                _debounce?.cancel();
                final q = v.trim();
                if (q.length >= 2) {
                  setState(() => _searching = true);
                  _search(q);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              leading: Icon(
                Icons.my_location_rounded,
                color: theme.colorScheme.secondary,
              ),
              title: const Text('Use current location'),
              subtitle: const Text('Detect where you are now'),
              trailing: _usingCurrent
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              onTap: _usingCurrent ? null : _useCurrentLocation,
            ),
          ),
          const Divider(height: 1),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Search for a place to set your home location.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final hit = _results[i];
                          return ListTile(
                            leading: Icon(
                              Icons.location_on_rounded,
                              color: theme.colorScheme.secondary,
                            ),
                            title: Text(hit.label),
                            subtitle: Text(
                              '${hit.latitude.toStringAsFixed(4)}, '
                              '${hit.longitude.toStringAsFixed(4)}',
                            ),
                            onTap: () => _select(hit),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchHit {
  const _SearchHit({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

/// Short place label, preferring city / locality (e.g. "Faisalabad").
String? formatPlacemarkLabel(Placemark p) {
  final locality = p.locality?.trim();
  if (locality != null && locality.isNotEmpty) return locality;

  final subAdmin = p.subAdministrativeArea?.trim();
  if (subAdmin != null && subAdmin.isNotEmpty) return subAdmin;

  final admin = p.administrativeArea?.trim();
  if (admin != null && admin.isNotEmpty) return admin;

  final subLocality = p.subLocality?.trim();
  if (subLocality != null && subLocality.isNotEmpty) return subLocality;

  final parts = [
    if (p.street?.isNotEmpty ?? false) p.street,
    if (p.name?.isNotEmpty ?? false) p.name,
  ].whereType<String>().toList();
  if (parts.isEmpty) return null;
  return parts.join(', ');
}

/// Reverse-geocode coordinates into a short display label.
Future<String> labelForCoordinates(double latitude, double longitude) async {
  try {
    final marks = await placemarkFromCoordinates(latitude, longitude).timeout(
      const Duration(seconds: 5),
    );
    if (marks.isNotEmpty) {
      return formatPlacemarkLabel(marks.first) ?? 'Selected location';
    }
  } catch (_) {
    // Fall through.
  }
  return 'Selected location';
}
