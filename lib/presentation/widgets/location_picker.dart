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

class LocationSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  LocationSearchResult({
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isSearching = false;
  LocationData? _selectedLocation;
  List<LocationSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _searchController.text = widget.initialLocation!.name;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        final name = place.name ?? place.street ?? 'Lokasi Saya';
        final address = _formatAddress(place);

        setState(() {
          _searchController.text = name;
          _selectedLocation = LocationData(
            name: name,
            address: address,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          _searchResults = [];
          _isSearching = false;
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

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      // Geocode address to get multiple possible locations
      List<Location> locations = await locationFromAddress(query);

      List<LocationSearchResult> results = [];

      // Get details for each location (limit to 5 results)
      for (var i = 0; i < locations.length && i < 5; i++) {
        try {
          final location = locations[i];
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final name = _getLocationName(place, query);
            final address = _formatAddress(place);

            // Only add if not duplicate
            if (!results.any((r) => r.latitude == location.latitude && r.longitude == location.longitude)) {
              results.add(LocationSearchResult(
                name: name,
                address: address,
                latitude: location.latitude,
                longitude: location.longitude,
              ));
            }
          }
        } catch (e) {
          AppLogger().error('Error processing location $i: $e');
        }
      }

      setState(() {
        _searchResults = results;
      });

      if (results.isEmpty) {
        _showError('Lokasi tidak ditemukan. Gunakan alamat lengkap seperti "Stadion Manahan, Solo" atau "Jl. Slamet Riyadi".');
      }
    } catch (e) {
      AppLogger().error('Error searching location: $e');
      _showError('Lokasi tidak ditemukan. Gunakan alamat lengkap dan spesifik (contoh: "Jl. Slamet Riyadi No.1, Solo").');
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getLocationName(Placemark place, String query) {
    // Try to create a descriptive name
    if (place.name != null && place.name!.isNotEmpty && place.name != query) {
      return place.name!;
    }

    List<String> nameParts = [];
    if (place.street != null && place.street!.isNotEmpty) {
      nameParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      nameParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      nameParts.add(place.locality!);
    }

    return nameParts.isNotEmpty ? nameParts.first : query;
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

  void _selectLocation(LocationSearchResult result) {
    setState(() {
      _searchController.text = result.name;
      _selectedLocation = LocationData(
        name: result.name,
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      );
      _searchResults = [];
      _isSearching = false;
    });

    _searchFocusNode.unfocus();
    widget.onLocationSelected(_selectedLocation!);
    AppLogger().info('Location selected: ${_selectedLocation!.name} at ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
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
      height: MediaQuery.of(context).size.height * 0.85,
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
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Cari alamat lengkap (contoh: Jl. Slamet Riyadi, Solo)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _isSearching = false;
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
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _searchController.text) {
                    _searchLocation(value);
                  }
                });
              },
              onSubmitted: _searchLocation,
            ),
          ),

          // Use Current Location Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF84994F)),
                  foregroundColor: const Color(0xFF84994F),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Results or Selected Location
          Expanded(
            child: _isLoading && _searchResults.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _searchResults.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return _buildLocationResultTile(result);
                        },
                      )
                    : _selectedLocation != null
                        ? _buildSelectedLocation()
                        : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationResultTile(LocationSearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _selectLocation(result),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF84994F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.location_on,
            color: Color(0xFF84994F),
            size: 24,
          ),
        ),
        title: Text(
          result.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          result.address,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSelectedLocation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lokasi Dipilih',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedLocation!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedLocation!.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '📍 ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84994F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Konfirmasi Lokasi',
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Cari Lokasi Event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketik alamat lengkap di kolom pencarian\n(contoh: Stadion Manahan, Solo)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
