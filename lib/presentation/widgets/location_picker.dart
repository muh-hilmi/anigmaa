import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentPosition = const LatLng(-7.5568, 110.8316); // Default: Solo, Indonesia
  String _currentAddress = 'Memuat lokasi...';
  String _locationName = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // Auto-request GPS permission and get current location
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _showError('Layanan lokasi tidak aktif. Aktifkan GPS terlebih dahulu.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _showError('Permission lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _showError('Permission lokasi ditolak permanen. Aktifkan di Settings.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 16),
      );

      // Get address for current position
      await _updateAddress(_currentPosition);

      AppLogger().info('Initial location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      AppLogger().error('Error getting initial location: $e');
      setState(() => _isLoadingLocation = false);
      _showError('Gagal mendapatkan lokasi: ${e.toString()}');
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() => _isLoadingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _locationName = _getLocationName(place);
          _currentAddress = _formatAddress(place);
          _isLoadingAddress = false;
        });
        AppLogger().info('Address updated: $_currentAddress');
      }
    } catch (e) {
      AppLogger().error('Error updating address: $e');
      setState(() {
        _currentAddress = 'Alamat tidak ditemukan';
        _locationName = 'Lokasi Terpilih';
        _isLoadingAddress = false;
      });
    }
  }

  String _getLocationName(Placemark place) {
    // Priority: name > street > subLocality > locality
    if (place.name != null && place.name!.isNotEmpty && place.name!.length < 50) {
      return place.name!;
    }
    if (place.street != null && place.street!.isNotEmpty) {
      return place.street!;
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      return place.subLocality!;
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      return place.locality!;
    }
    return 'Lokasi Terpilih';
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

    return parts.isNotEmpty ? parts.join(', ') : 'Alamat tidak tersedia';
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoadingAddress = true);

    try {
      // Geocode address to get location
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);

        // Animate camera to searched location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 16),
        );

        setState(() {
          _currentPosition = newPosition;
        });

        // Update address
        await _updateAddress(newPosition);
      } else {
        _showError('Lokasi tidak ditemukan');
        setState(() => _isLoadingAddress = false);
      }
    } catch (e) {
      AppLogger().error('Error searching location: $e');
      _showError('Lokasi tidak ditemukan. Coba kata kunci yang lebih spesifik.');
      setState(() => _isLoadingAddress = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    // Update current position as camera moves
    setState(() {
      _currentPosition = position.target;
    });
  }

  void _onCameraIdle() {
    // Update address when camera stops moving
    _updateAddress(_currentPosition);
  }

  void _confirmLocation() {
    final locationData = LocationData(
      name: _locationName,
      address: _currentAddress,
      latitude: _currentPosition.latitude,
      longitude: _currentPosition.longitude,
    );

    widget.onLocationSelected(locationData);
    Navigator.pop(context);
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Pilih Lokasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari area/kota (contoh: Manahan, Solo)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _searchLocation,
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Map with center pin
          Expanded(
            child: Stack(
              children: [
                // Google Map
                _isLoadingLocation
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF84994F),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Mendapatkan lokasi Anda...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition,
                          zoom: 16,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onCameraMove: _onCameraMove,
                        onCameraIdle: _onCameraIdle,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                      ),

                // Center Pin (fixed in center of map)
                if (!_isLoadingLocation)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_pin,
                          size: 50,
                          color: Color(0xFF84994F),
                        ),
                        // Shadow circle below pin
                        Container(
                          width: 20,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),

                // My Location Button (bottom right)
                if (!_isLoadingLocation)
                  Positioned(
                    bottom: 180,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _initializeLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF84994F),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Address display and confirm button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address title
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF84994F),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoadingAddress
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF84994F),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Memuat alamat...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _locationName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentAddress,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84994F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Gunakan Lokasi Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
