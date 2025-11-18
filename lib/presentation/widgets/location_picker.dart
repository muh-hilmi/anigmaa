import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/utils/app_logger.dart';

class LocationData {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPicker extends StatefulWidget {
  final Function(LocationData) onLocationSelected;
  final LocationData? initialLocation;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  LocationData? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _nameController.text = widget.initialLocation!.name;
      _addressController.text = widget.initialLocation!.address;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Layanan lokasi tidak aktif. Aktifkan GPS terlebih dahulu.');
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permission lokasi ditolak');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permission lokasi ditolak permanen. Aktifkan di Settings.');
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      AppLogger().info('Current location: ${position.latitude}, ${position.longitude}');

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = _formatAddress(place);

        setState(() {
          _addressController.text = address;
          _nameController.text = place.name ?? place.street ?? 'Lokasi Saya';
          _selectedLocation = LocationData(
            name: _nameController.text,
            address: address,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        });

        widget.onLocationSelected(_selectedLocation!);
        AppLogger().info('Location selected: ${_selectedLocation!.name} at ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
      }
    } catch (e) {
      AppLogger().error('Error getting current location: $e');
      _showError('Gagal mendapatkan lokasi: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchAddress() async {
    if (_addressController.text.trim().isEmpty) {
      _showError('Masukkan alamat terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Geocode address to get coordinates
      List<Location> locations = await locationFromAddress(_addressController.text);

      if (locations.isNotEmpty) {
        final location = locations.first;

        // Reverse geocode to get complete address
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        final place = placemarks.first;
        final formattedAddress = _formatAddress(place);

        setState(() {
          _addressController.text = formattedAddress;
          if (_nameController.text.isEmpty) {
            _nameController.text = place.name ?? place.street ?? _addressController.text;
          }
          _selectedLocation = LocationData(
            name: _nameController.text,
            address: formattedAddress,
            latitude: location.latitude,
            longitude: location.longitude,
          );
        });

        widget.onLocationSelected(_selectedLocation!);
        AppLogger().info('Location found: ${_selectedLocation!.name} at ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Lokasi ditemukan'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger().error('Error searching address: $e');
      _showError('Alamat tidak ditemukan. Coba alamat yang lebih spesifik.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];
    if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
    if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
    if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) parts.add(place.postalCode!);

    return parts.join(', ');
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Name Field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nama Lokasi',
            hintText: 'Contoh: Kafe Central Park',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            if (_selectedLocation != null) {
              _selectedLocation = LocationData(
                name: value,
                address: _selectedLocation!.address,
                latitude: _selectedLocation!.latitude,
                longitude: _selectedLocation!.longitude,
              );
              widget.onLocationSelected(_selectedLocation!);
            }
          },
        ),
        const SizedBox(height: 16),

        // Address Field with Search Button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Masukkan alamat lengkap',
                  prefixIcon: const Icon(Icons.place),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 2,
                onSubmitted: (_) => _searchAddress(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isLoading ? null : _searchAddress,
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              tooltip: 'Cari Alamat',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF84994F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Get Current Location Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _getCurrentLocation,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Gunakan Lokasi Saya'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFF84994F)),
              foregroundColor: const Color(0xFF84994F),
            ),
          ),
        ),

        // Location Preview
        if (_selectedLocation != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi Dipilih',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
