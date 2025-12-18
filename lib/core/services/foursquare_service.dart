import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class FoursquarePlace {
  final String fsqId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? category;
  final int? distance;

  FoursquarePlace({
    required this.fsqId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category,
    this.distance,
  });

  factory FoursquarePlace.fromJson(Map<String, dynamic> json) {
    final geocodes = json['geocodes']?['main'];
    final location = json['location'];

    // Parse address
    String address = '';
    if (location != null) {
      List<String> addressParts = [];
      if (location['address'] != null && location['address'].toString().isNotEmpty) {
        addressParts.add(location['address']);
      }
      if (location['locality'] != null && location['locality'].toString().isNotEmpty) {
        addressParts.add(location['locality']);
      }
      if (location['region'] != null && location['region'].toString().isNotEmpty) {
        addressParts.add(location['region']);
      }
      if (location['country'] != null && location['country'].toString().isNotEmpty) {
        addressParts.add(location['country']);
      }
      address = addressParts.join(', ');
    }

    // Parse category
    String? category;
    if (json['categories'] != null && (json['categories'] as List).isNotEmpty) {
      category = json['categories'][0]['name'];
    }

    // Parse coordinates - Try multiple possible locations
    double? latitude;
    double? longitude;

    // 1. Try geocodes.main (standard format)
    if (geocodes != null) {
      latitude = geocodes['latitude']?.toDouble();
      longitude = geocodes['longitude']?.toDouble();
    }

    // 2. Try direct geocodes (without main)
    if ((latitude == null || longitude == null) && json['geocodes'] != null) {
      final directGeo = json['geocodes'];
      latitude = directGeo['latitude']?.toDouble();
      longitude = directGeo['longitude']?.toDouble();
    }

    // 3. Try location object
    if ((latitude == null || longitude == null) && location != null) {
      latitude = location['latitude']?.toDouble();
      longitude = location['longitude']?.toDouble();
    }

    // 4. Try geo field (some APIs use this)
    if ((latitude == null || longitude == null) && json['geo'] != null) {
      final geo = json['geo'];
      latitude = geo['latitude']?.toDouble() ?? geo['lat']?.toDouble();
      longitude = geo['longitude']?.toDouble() ?? geo['lng']?.toDouble();
    }

    // 5. Try top-level lat/lng
    if (latitude == null || longitude == null) {
      latitude = json['latitude']?.toDouble() ?? json['lat']?.toDouble();
      longitude = json['longitude']?.toDouble() ?? json['lng']?.toDouble();
    }

    // If still no coordinates, throw error to skip this place
    if (latitude == null || longitude == null || (latitude == 0.0 && longitude == 0.0)) {
      final placeName = json['name'] ?? 'Unknown';
      AppLogger().warning(
        'Skipping place "$placeName" - no valid coordinates found'
      );
      throw Exception('Invalid coordinates for place: $placeName');
    }

    return FoursquarePlace(
      fsqId: json['fsq_id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      address: address.isNotEmpty ? address : 'Address not available',
      latitude: latitude,
      longitude: longitude,
      category: category,
      distance: json['distance'],
    );
  }
}

class FoursquareService {
  // IMPORTANT: Replace with your actual Foursquare API key
  // Get it from: https://foursquare.com/developers/apps
  static const String _apiKey = 'HBPGD0IN2KVQSDGXRWDTQ42PPLUY0AF3TLXVDWMFCGF040KN';
  static const String _baseUrl = 'https://places-api.foursquare.com';

  /// Search for places near a location
  ///
  /// [query] - Search query (e.g., "restaurant", "coffee")
  /// [latitude] - Latitude of the search center
  /// [longitude] - Longitude of the search center
  /// [radius] - Search radius in meters (default: 5000)
  /// [limit] - Maximum number of results (default: 20)
  Future<List<FoursquarePlace>> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    int radius = 5000,
    int limit = 20,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/places/search').replace(
        queryParameters: {
          'query': query,
          'll': '$latitude,$longitude',
          'radius': radius.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Foursquare search request: ${url.toString()}');
      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic>? results;
        if (data['results'] != null) {
          results = data['results'] as List<dynamic>?;
        } else if (data is List) {
          results = data;
        }

        if (results == null || results.isEmpty) {
          AppLogger().warning('No results found in search');
          return [];
        }

        AppLogger().info('Foursquare search found ${results.length} places');

        // Parse places with error handling
        final places = <FoursquarePlace>[];
        for (var placeJson in results) {
          try {
            places.add(FoursquarePlace.fromJson(placeJson));
          } catch (e) {
            AppLogger().error('Failed to parse search place: $e');
            // Continue processing other places
          }
        }

        return places;
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger().error('Error searching places: $e');
      AppLogger().error('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get nearby places (without specific query)
  ///
  /// [latitude] - Latitude of the search center
  /// [longitude] - Longitude of the search center
  /// [radius] - Search radius in meters (default: 1000)
  /// [limit] - Maximum number of results (default: 50)
  Future<List<FoursquarePlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 1000,
    int limit = 50,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/geotagging/candidates').replace(
        queryParameters: {
          'll': '$latitude,$longitude',
          'radius': radius.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Foursquare nearby request: ${url.toString()}');
      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the response structure for debugging
        AppLogger().info('Response data keys: ${data.keys.toList()}');

        // Handle different response formats
        List<dynamic>? results;
        if (data['results'] != null) {
          results = data['results'] as List<dynamic>?;
        } else if (data['candidates'] != null) {
          results = data['candidates'] as List<dynamic>?;
        } else if (data is List) {
          results = data;
        }

        if (results == null || results.isEmpty) {
          AppLogger().warning('No results found in response. Response body: ${response.body}');
          return [];
        }

        AppLogger().info('Foursquare nearby found ${results.length} places');

        // Parse places with error handling
        final places = <FoursquarePlace>[];
        for (var placeJson in results) {
          try {
            places.add(FoursquarePlace.fromJson(placeJson));
          } catch (e) {
            AppLogger().error('Failed to parse nearby place: $e');
            // Continue processing other places
          }
        }

        return places;
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger().error('Error getting nearby places: $e');
      AppLogger().error('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get autocomplete suggestions for a query
  ///
  /// Uses the /places/search endpoint instead of /autocomplete because
  /// the autocomplete endpoint doesn't return full geocodes.
  ///
  /// [query] - Search query
  /// [latitude] - Latitude of the search center
  /// [longitude] - Longitude of the search center
  /// [limit] - Maximum number of results (default: 10)
  Future<List<FoursquarePlace>> getAutocompleteSuggestions({
    required String query,
    required double latitude,
    required double longitude,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      // Use search endpoint instead of autocomplete for better geocode coverage
      final url = Uri.parse('$_baseUrl/places/search').replace(
        queryParameters: {
          'query': query,
          'll': '$latitude,$longitude',
          'limit': limit.toString(),
          'radius': '50000', // 50km radius for search
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Foursquare search request: ${url.toString()}');
      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic>? results;
        if (data['results'] != null) {
          results = data['results'] as List<dynamic>?;
        } else if (data is List) {
          results = data;
        }

        if (results == null || results.isEmpty) {
          AppLogger().warning('No results found in search');
          return [];
        }

        AppLogger().info('Foursquare search found ${results.length} places');

        // Parse places with error handling
        final places = <FoursquarePlace>[];
        for (var placeJson in results) {
          try {
            places.add(FoursquarePlace.fromJson(placeJson));
          } catch (e) {
            AppLogger().error('Failed to parse search place: $e');
            // Continue processing other places
          }
        }

        AppLogger().info('Filtered to ${places.length} valid places');

        return places;
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger().error('Error getting autocomplete suggestions: $e');
      AppLogger().error('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get place details by Foursquare ID
  ///
  /// [fsqId] - Foursquare place ID
  Future<FoursquarePlace?> getPlaceDetails(String fsqId) async {
    try {
      final url = Uri.parse('$_baseUrl/places/$fsqId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
          'X-Places-Api-Version': '2025-06-17',
        },
      );

      AppLogger().info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger().info('Foursquare place details retrieved');
        return FoursquarePlace.fromJson(data);
      } else {
        AppLogger().error(
          'Foursquare API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      AppLogger().error('Error getting place details: $e');
      return null;
    }
  }
}
