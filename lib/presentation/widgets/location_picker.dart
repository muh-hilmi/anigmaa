import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/utils/app_logger.dart';
import '../../core/services/foursquare_service.dart';

class LocationData {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? fsqId; // Foursquare place ID (optional)

  LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.fsqId,
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
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FoursquareService _foursquareService = FoursquareService();

  LatLng _currentPosition = const LatLng(
    -7.5568,
    110.8316,
  ); // Default: Solo, Indonesia
  String _currentAddress = 'Memuat lokasi...';
  String _locationName = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  bool _showSearchResults = false;
  List<FoursquarePlace> _searchResults = [];
  List<FoursquarePlace> _nearbyPlaces = [];
  String? _selectedFsqId;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Move map to current location with animation
      _animateMapToPosition(_currentPosition, zoom: 16.0);

      // Get address for current position
      await _updateAddress(_currentPosition);

      // Load nearby places from Foursquare
      await _loadNearbyPlaces();

      AppLogger().info(
        'Initial location: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      AppLogger().error('Error getting initial location: $e');
      setState(() => _isLoadingLocation = false);
      _showError('Gagal mendapatkan lokasi: ${e.toString()}');
    }
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      final places = await _foursquareService.getNearbyPlaces(
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude,
        radius: 1000,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
        });
      }

      AppLogger().info('Loaded ${places.length} nearby places from Foursquare');
    } catch (e) {
      AppLogger().error('Error loading nearby places: $e');
    }
  }

  // Helper function for animated map movement
  void _animateMapToPosition(LatLng position, {double zoom = 16.0}) {
    if (mounted) {
      // Move map with smooth transition
      _mapController.move(position, zoom);
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
    if (place.name != null &&
        place.name!.isNotEmpty &&
        place.name!.length < 50) {
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
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Alamat tidak tersedia';
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoadingAddress = true);

    try {
      // Use Foursquare autocomplete for better results
      final places = await _foursquareService.getAutocompleteSuggestions(
        query: query,
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude,
        limit: 10,
      );

      setState(() {
        _searchResults = places;
        _showSearchResults = true;
        _isLoadingAddress = false;
      });

      AppLogger().info('Search found ${places.length} results');
    } catch (e) {
      AppLogger().error('Error searching location: $e');
      _showError('Gagal mencari lokasi. Coba lagi.');
      setState(() => _isLoadingAddress = false);
    }
  }

  void _selectSearchResult(FoursquarePlace place) {
    final newPosition = LatLng(place.latitude, place.longitude);

    // Update state first to ensure UI is in sync
    setState(() {
      _currentPosition = newPosition;
      _locationName = place.name;
      _currentAddress = place.address;
      _selectedFsqId = place.fsqId;
      _showSearchResults = false;
      _searchController.clear();
    });

    // Move map to selected location after state update
    // Use Future.delayed to ensure map move happens after rebuild
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animateMapToPosition(newPosition, zoom: 16.0);
        // Load nearby places for the new location
        _loadNearbyPlaces();
      }
    });

    AppLogger().info('Selected place: ${place.name} at ${place.latitude}, ${place.longitude}');
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      _currentPosition = position;
      _selectedFsqId = null; // Clear Foursquare ID when manually selecting
    });

    // Update address for manually selected position
    _updateAddress(position);

    // Load nearby places for the new position
    _loadNearbyPlaces();

    AppLogger().info('Map tapped at: ${position.latitude}, ${position.longitude}');
  }

  void _confirmLocation() {
    final locationData = LocationData(
      name: _locationName,
      address: _currentAddress,
      latitude: _currentPosition.latitude,
      longitude: _currentPosition.longitude,
      fsqId: _selectedFsqId,
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
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'Pilih Lokasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                hintText: 'Cari tempat (contoh: Manahan Stadium, Cafe)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _showSearchResults = false;
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length >= 3) {
                  _searchLocation(value);
                }
              },
              onSubmitted: _searchLocation,
            ),
          ),

          // Search Results or Map
          Expanded(
            child: _showSearchResults ? _buildSearchResults() : _buildMapView(),
          ),

          // Address display and confirm button (only show when not searching)
          if (!_showSearchResults)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                          color: Color(0xFFBBC863),
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
                                        color: Color(0xFFBBC863),
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
                          backgroundColor: const Color(0xFFBBC863),
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

  Widget _buildSearchResults() {
    if (_isLoadingAddress) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFBBC863)),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on, color: Color(0xFFBBC863)),
          ),
          title: Text(
            place.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (place.category != null)
                Text(
                  place.category!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          trailing: place.distance != null
              ? Text(
                  '${(place.distance! / 1000).toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                )
              : null,
          onTap: () => _selectSearchResult(place),
        );
      },
    );
  }

  Widget _buildMapView() {
    if (_isLoadingLocation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFBBC863)),
            const SizedBox(height: 16),
            Text(
              'Mendapatkan lokasi Anda...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Flutter Map with OpenStreetMap tiles
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition,
            initialZoom: 16,
            onTap: _onMapTap,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.anigmaa',
              maxZoom: 19,
            ),
            // Highlight circle for selected position
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _currentPosition,
                  radius: 80, // radius in pixels
                  useRadiusInMeter: false,
                  color: const Color(0xFFBBC863).withValues(alpha: 0.2),
                  borderStrokeWidth: 2,
                  borderColor: const Color(0xFFBBC863).withValues(alpha: 0.5),
                ),
              ],
            ),
            // Markers for nearby places
            MarkerLayer(
              markers: [
                // Current position marker
                Marker(
                  point: _currentPosition,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFBBC863).withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      size: 60,
                      color: Color(0xFFBBC863),
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Nearby places markers
                ..._nearbyPlaces.map((place) {
                  return Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: 30,
                    height: 30,
                    child: GestureDetector(
                      onTap: () => _selectSearchResult(place),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.place,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // My Location Button (bottom right)
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _initializeLocation,
            child: const Icon(Icons.my_location, color: Color(0xFFBBC863)),
          ),
        ),
      ],
    );
  }
}
