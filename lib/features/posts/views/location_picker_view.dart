import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Full-screen map to pick a location. Returns address string or "lat,lng" on confirm.
class LocationPickerView extends StatefulWidget {
  const LocationPickerView({super.key});

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  static const _defaultLat = 31.5204;
  static const _defaultLng = 74.3587;

  final Completer<GoogleMapController> _controller = Completer();
  LatLng _selectedPosition = const LatLng(_defaultLat, _defaultLng);
  bool _isLoadingLocation = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: _isLoadingLocation ? null : _confirm,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 14,
            ),
            onMapCreated: (c) => _controller.complete(c),
            onTap: (pos) => setState(() => _selectedPosition = pos),
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedPosition,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: _isLoadingLocation ? null : _useCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(_isLoadingLocation ? 'Getting location...' : 'Use current location'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _isLoadingLocation ? null : _confirm,
                  child: const Text('Confirm this location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _error = null;
    });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() {
              _error = 'Location permission denied';
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _selectedPosition = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
        });
        final c = await _controller.future;
        c.animateCamera(CameraUpdate.newLatLng(_selectedPosition));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not get location: $e';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _confirm() async {
    setState(() => _error = null);
    try {
      final placemarks = await placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );
      String result;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.street?.isNotEmpty ?? false) p.street,
          if (p.subLocality?.isNotEmpty ?? false) p.subLocality,
          if (p.locality?.isNotEmpty ?? false) p.locality,
          if (p.administrativeArea?.isNotEmpty ?? false) p.administrativeArea,
        ].whereType<String>();
        result = parts.isNotEmpty ? parts.join(', ') : '${_selectedPosition.latitude}, ${_selectedPosition.longitude}';
      } else {
        result = '${_selectedPosition.latitude}, ${_selectedPosition.longitude}';
      }
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not get address: $e');
      }
    }
  }
}
