# Anigmaa Backend API - Frontend Developer Guide

**Last Updated:** 2025-11-12
**API Version:** 1.0
**Base URL:** `http://localhost:8081/api/v1`
**Production URL:** `https://anigmaa.muhhilmi.site/api/v1`

---

## 📚 Table of Contents

1. [Authentication](#1-authentication)
2. [User Management](#2-user-management)
3. [Events](#3-events)
4. [Posts & Feed](#4-posts--feed)
5. [Comments](#5-comments)
6. [Tickets](#6-tickets)
7. [Analytics (Host Only)](#7-analytics-host-only)
8. [Profile](#8-profile)
9. [Event Q&A](#9-event-qa)
10. [File Upload](#10-file-upload)
11. [Communities](#11-communities)
12. [Error Handling](#12-error-handling)
13. [Flutter Integration Examples](#13-flutter-integration-examples)

---

## 🔐 Authentication

All authenticated endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

### Response Format

All API responses follow this standard format:

```json
{
  "success": true,
  "message": "Success message",
  "data": { /* response data */ }
}
```

Or for errors:

```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error information"
}
```

---

## 1. Authentication

### 1.1. Register

**POST** `/auth/register`

**Public** (No authentication required)

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "username": "johndoe"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "John Doe",
      "username": "johndoe",
      "avatar_url": null,
      "bio": null,
      "created_at": "2025-11-12T10:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> register({
  required String email,
  required String password,
  required String name,
  required String username,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
      'name': name,
      'username': username,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    // Save token to secure storage
    await secureStorage.write(key: 'auth_token', value: data['data']['token']);
    return data['data'];
  } else {
    throw Exception('Registration failed');
  }
}
```

---

### 1.2. Login

**POST** `/auth/login`

**Public** (No authentication required)

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "John Doe",
      "username": "johndoe",
      "avatar_url": "https://example.com/avatar.jpg",
      "bio": "Software developer"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }'
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    await secureStorage.write(key: 'auth_token', value: data['data']['token']);
    await secureStorage.write(key: 'refresh_token', value: data['data']['refresh_token']);
    return data['data'];
  } else {
    throw Exception('Login failed');
  }
}
```

---

### 1.3. Login with Google

**POST** `/auth/google`

**Public** (No authentication required)

**Request Body:**
```json
{
  "token": "google_id_token_from_firebase_or_google_sign_in"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Google login successful",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@gmail.com",
      "name": "John Doe",
      "username": "johndoe",
      "avatar_url": "https://lh3.googleusercontent.com/..."
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Flutter Example:**
```dart
import 'package:google_sign_in/google_sign_in.dart';

Future<Map<String, dynamic>> loginWithGoogle() async {
  // Sign in with Google
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) return null;

  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  // Send token to backend
  final response = await http.post(
    Uri.parse('$baseUrl/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'token': googleAuth.idToken,
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    await secureStorage.write(key: 'auth_token', value: data['data']['token']);
    return data['data'];
  } else {
    throw Exception('Google login failed');
  }
}
```

---

### 1.4. Refresh Token

**POST** `/auth/refresh`

**Protected** (Requires authentication)

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "refresh_token": "your_refresh_token_here"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "token": "new_access_token",
    "refresh_token": "new_refresh_token"
  }
}
```

---

### 1.5. Logout

**POST** `/auth/logout`

**Protected** (Requires authentication)

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Logout successful",
  "data": null
}
```

---

### 1.6. Forgot Password

**POST** `/auth/forgot-password`

**Public** (No authentication required)

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password reset email sent",
  "data": null
}
```

---

### 1.7. Reset Password

**POST** `/auth/reset-password`

**Public** (No authentication required)

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "new_password": "NewSecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password reset successfully",
  "data": null
}
```

---

### 1.8. Verify Email

**POST** `/auth/verify-email`

**Public** (No authentication required)

**Request Body:**
```json
{
  "token": "verification_token_from_email"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Email verified successfully",
  "data": null
}
```

---

## 2. User Management

### 2.1. Get Current User

**GET** `/users/me`

**Protected** (Requires authentication)

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe",
    "username": "johndoe",
    "avatar_url": "https://example.com/avatar.jpg",
    "cover_url": "https://example.com/cover.jpg",
    "bio": "Software developer and coffee enthusiast",
    "location": "Jakarta, Indonesia",
    "website": "https://johndoe.com",
    "is_verified": true,
    "followers_count": 250,
    "following_count": 180,
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getCurrentUser() async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/users/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to get user');
  }
}
```

---

### 2.2. Update Current User

**PUT** `/users/me`

**Protected** (Requires authentication)

**Request Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "name": "John Doe Updated",
  "username": "johndoe2",
  "bio": "Updated bio",
  "location": "Bandung, Indonesia",
  "website": "https://newwebsite.com",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "cover_url": "https://example.com/new-cover.jpg"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe Updated",
    "username": "johndoe2",
    "bio": "Updated bio",
    "location": "Bandung, Indonesia",
    "website": "https://newwebsite.com",
    "avatar_url": "https://example.com/new-avatar.jpg",
    "cover_url": "https://example.com/new-cover.jpg"
  }
}
```

---

### 2.3. Update User Settings

**PUT** `/users/me/settings`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "notification_enabled": true,
  "email_notifications": false,
  "push_notifications": true,
  "private_account": false
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Settings updated successfully",
  "data": {
    "notification_enabled": true,
    "email_notifications": false,
    "push_notifications": true,
    "private_account": false
  }
}
```

---

### 2.4. Search Users

**GET** `/users/search?q=john&limit=20&offset=0`

**Protected** (Requires authentication)

**Query Parameters:**
- `q` (required): Search query (minimum 2 characters)
- `limit` (optional): Number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Users found successfully",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Doe",
      "username": "johndoe",
      "avatar_url": "https://example.com/avatar.jpg",
      "bio": "Software developer",
      "is_verified": true,
      "followers_count": 250,
      "is_followed_by_current_user": false
    }
  ]
}
```

**Flutter Example:**
```dart
Future<List<dynamic>> searchUsers(String query, {int limit = 20, int offset = 0}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/users/search?q=${Uri.encodeComponent(query)}&limit=$limit&offset=$offset'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Search failed');
  }
}
```

---

### 2.5. Get User by ID

**GET** `/users/:id`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "username": "johndoe",
    "avatar_url": "https://example.com/avatar.jpg",
    "bio": "Software developer",
    "followers_count": 250,
    "following_count": 180,
    "is_followed_by_current_user": false
  }
}
```

---

### 2.6. Follow User

**POST** `/users/:id/follow`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "User followed successfully",
  "data": null
}
```

**Flutter Example:**
```dart
Future<void> followUser(String userId) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/users/$userId/follow'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to follow user');
  }
}
```

---

### 2.7. Unfollow User

**DELETE** `/users/:id/follow`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "User unfollowed successfully",
  "data": null
}
```

---

### 2.8. Get User Followers

**GET** `/users/:id/followers?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Followers retrieved successfully",
  "data": [
    {
      "id": "user-id-1",
      "name": "Follower Name",
      "username": "follower",
      "avatar_url": "https://example.com/avatar.jpg",
      "is_followed_by_current_user": true
    }
  ]
}
```

---

### 2.9. Get User Following

**GET** `/users/:id/following?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Following retrieved successfully",
  "data": [
    {
      "id": "user-id-1",
      "name": "Following Name",
      "username": "following",
      "avatar_url": "https://example.com/avatar.jpg",
      "is_followed_by_current_user": true
    }
  ]
}
```

---

### 2.10. Get User Stats

**GET** `/users/:id/stats`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "User stats retrieved successfully",
  "data": {
    "posts_count": 42,
    "followers_count": 250,
    "following_count": 180,
    "events_hosted": 5,
    "events_attended": 15
  }
}
```

---

## 3. Events

### 3.1. Get Events

**GET** `/events?category=Coffee&limit=20&offset=0`

**Public** (No authentication required)

**Query Parameters:**
- `category` (optional): Filter by category (e.g., "Coffee", "Food", "Gaming")
- `search` (optional): Search query
- `start_date` (optional): Filter events after this date
- `end_date` (optional): Filter events before this date
- `limit` (optional): Number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Events retrieved successfully",
  "data": [
    {
      "id": "e0000001-0000-0000-0000-000000000001",
      "title": "Coffee Cupping Session",
      "description": "Learn how to taste and evaluate coffee like a professional",
      "category": "Coffee",
      "location": "Kopi Kenangan, Jakarta",
      "latitude": -6.2088,
      "longitude": 106.8456,
      "start_time": "2025-11-15T10:00:00Z",
      "end_time": "2025-11-15T12:00:00Z",
      "image_url": "https://example.com/event-image.jpg",
      "ticket_price": 150000,
      "max_attendees": 30,
      "current_attendees": 15,
      "is_free": false,
      "host": {
        "id": "host-id",
        "name": "Rudi Hartono",
        "username": "rudihartono",
        "avatar_url": "https://example.com/host-avatar.jpg"
      },
      "is_joined_by_current_user": false,
      "created_at": "2025-11-01T00:00:00Z"
    }
  ]
}
```

**Flutter Example:**
```dart
Future<List<dynamic>> getEvents({
  String? category,
  String? search,
  int limit = 20,
  int offset = 0,
}) async {
  var queryParams = {
    'limit': limit.toString(),
    'offset': offset.toString(),
  };

  if (category != null) queryParams['category'] = category;
  if (search != null) queryParams['search'] = search;

  final uri = Uri.parse('$baseUrl/events').replace(queryParameters: queryParams);

  final response = await http.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to get events');
  }
}
```

---

### 3.2. Get Event by ID

**GET** `/events/:id`

**Public** (No authentication required)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Event retrieved successfully",
  "data": {
    "id": "e0000001-0000-0000-0000-000000000001",
    "title": "Coffee Cupping Session",
    "description": "Learn how to taste and evaluate coffee like a professional",
    "category": "Coffee",
    "location": "Kopi Kenangan, Jakarta",
    "latitude": -6.2088,
    "longitude": 106.8456,
    "start_time": "2025-11-15T10:00:00Z",
    "end_time": "2025-11-15T12:00:00Z",
    "image_url": "https://example.com/event-image.jpg",
    "ticket_price": 150000,
    "max_attendees": 30,
    "current_attendees": 15,
    "is_free": false,
    "host": {
      "id": "host-id",
      "name": "Rudi Hartono",
      "username": "rudihartono",
      "avatar_url": "https://example.com/host-avatar.jpg"
    },
    "is_joined_by_current_user": false,
    "tags": ["coffee", "workshop", "jakarta"],
    "created_at": "2025-11-01T00:00:00Z",
    "updated_at": "2025-11-01T00:00:00Z"
  }
}
```

---

### 3.3. Get Nearby Events

**GET** `/events/nearby?latitude=-6.2088&longitude=106.8456&radius=10&limit=20`

**Public** (No authentication required)

**Query Parameters:**
- `latitude` (required): Current latitude
- `longitude` (required): Current longitude
- `radius` (optional): Search radius in kilometers (default: 10)
- `limit` (optional): Number of results (default: 20)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Nearby events retrieved successfully",
  "data": [
    {
      "id": "event-id",
      "title": "Coffee Cupping Session",
      "location": "Kopi Kenangan, Jakarta",
      "distance_km": 2.5,
      "start_time": "2025-11-15T10:00:00Z",
      "image_url": "https://example.com/event-image.jpg",
      "ticket_price": 150000
    }
  ]
}
```

---

### 3.4. Create Event

**POST** `/events`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "title": "Coffee Cupping Session",
  "description": "Learn how to taste and evaluate coffee",
  "category": "Coffee",
  "location": "Kopi Kenangan, Jakarta",
  "latitude": -6.2088,
  "longitude": 106.8456,
  "start_time": "2025-11-15T10:00:00Z",
  "end_time": "2025-11-15T12:00:00Z",
  "image_url": "https://example.com/event-image.jpg",
  "ticket_price": 150000,
  "max_attendees": 30,
  "is_free": false,
  "tags": ["coffee", "workshop", "jakarta"]
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Event created successfully",
  "data": {
    "id": "e0000001-0000-0000-0000-000000000001",
    "title": "Coffee Cupping Session",
    "description": "Learn how to taste and evaluate coffee",
    "host_id": "your-user-id",
    "created_at": "2025-11-12T10:00:00Z"
  }
}
```

**Important Note for Frontend:**
- ❌ **DO NOT** generate the event `id` on the frontend
- ✅ Let the backend generate the UUID
- ❌ Remove any UUID generation code like `Uuid().v4()` from CreateEventScreen

**Flutter Example (Correct):**
```dart
Future<Map<String, dynamic>> createEvent({
  required String title,
  required String description,
  required String category,
  required String location,
  required double latitude,
  required double longitude,
  required DateTime startTime,
  required DateTime endTime,
  String? imageUrl,
  int? ticketPrice,
  int? maxAttendees,
  bool isFree = false,
  List<String>? tags,
}) async {
  final token = await secureStorage.read(key: 'auth_token');

  // ❌ WRONG: Do NOT generate ID here
  // final id = Uuid().v4(); // Remove this!

  final response = await http.post(
    Uri.parse('$baseUrl/events'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      // ❌ WRONG: Do NOT send id
      // 'id': id, // Remove this!
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'image_url': imageUrl,
      'ticket_price': ticketPrice,
      'max_attendees': maxAttendees,
      'is_free': isFree,
      'tags': tags,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    // ✅ Use the ID returned by backend
    return data['data'];
  } else {
    throw Exception('Failed to create event');
  }
}
```

---

### 3.5. Update Event

**PUT** `/events/:id`

**Protected** (Requires authentication - Host only)

**Request Body:**
```json
{
  "title": "Updated Coffee Cupping Session",
  "description": "Updated description",
  "ticket_price": 175000
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Event updated successfully",
  "data": {
    "id": "event-id",
    "title": "Updated Coffee Cupping Session",
    "updated_at": "2025-11-12T10:00:00Z"
  }
}
```

---

### 3.6. Delete Event

**DELETE** `/events/:id`

**Protected** (Requires authentication - Host only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Event deleted successfully",
  "data": null
}
```

---

### 3.7. Join Event

**POST** `/events/:id/join`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Joined event successfully",
  "data": null
}
```

**Flutter Example:**
```dart
Future<void> joinEvent(String eventId) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/events/$eventId/join'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to join event');
  }
}
```

---

### 3.8. Leave Event

**DELETE** `/events/:id/join`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Left event successfully",
  "data": null
}
```

---

### 3.9. Get Event Attendees

**GET** `/events/:id/attendees?limit=20&offset=0`

**Public** (No authentication required)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Attendees retrieved successfully",
  "data": [
    {
      "id": "user-id",
      "name": "John Doe",
      "username": "johndoe",
      "avatar_url": "https://example.com/avatar.jpg",
      "joined_at": "2025-11-10T12:00:00Z"
    }
  ]
}
```

---

### 3.10. Get My Events (Hosted)

**GET** `/events/my-events?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Events retrieved successfully",
  "data": [
    {
      "id": "event-id",
      "title": "Coffee Cupping Session",
      "start_time": "2025-11-15T10:00:00Z",
      "current_attendees": 15,
      "max_attendees": 30
    }
  ]
}
```

---

### 3.11. Get Joined Events

**GET** `/events/joined?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Joined events retrieved successfully",
  "data": [
    {
      "id": "event-id",
      "title": "Coffee Cupping Session",
      "start_time": "2025-11-15T10:00:00Z",
      "location": "Kopi Kenangan, Jakarta",
      "image_url": "https://example.com/event.jpg"
    }
  ]
}
```

---

## 4. Posts & Feed

### 4.1. Get Feed

**GET** `/posts/feed?limit=20&offset=0`

**Protected** (Requires authentication)

**Query Parameters:**
- `limit` (optional): Number of posts (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Feed retrieved successfully",
  "data": [
    {
      "id": "post-id",
      "author": {
        "id": "user-id",
        "name": "John Doe",
        "username": "johndoe",
        "avatar_url": "https://example.com/avatar.jpg",
        "is_verified": true
      },
      "content": "Just had an amazing coffee cupping session! ☕",
      "media_urls": ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
      "event": {
        "id": "event-id",
        "title": "Coffee Cupping Session",
        "image_url": "https://example.com/event.jpg"
      },
      "likes_count": 42,
      "comments_count": 10,
      "reposts_count": 5,
      "is_liked_by_current_user": false,
      "is_reposted_by_current_user": false,
      "is_bookmarked_by_current_user": false,
      "created_at": "2025-11-12T10:00:00Z"
    }
  ]
}
```

**Flutter Example:**
```dart
Future<List<dynamic>> getFeed({int limit = 20, int offset = 0}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/posts/feed?limit=$limit&offset=$offset'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to get feed');
  }
}
```

---

### 4.2. Get Post by ID

**GET** `/posts/:id`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Post retrieved successfully",
  "data": {
    "id": "post-id",
    "author": {
      "id": "user-id",
      "name": "John Doe",
      "username": "johndoe",
      "avatar_url": "https://example.com/avatar.jpg"
    },
    "content": "Amazing event! #coffee #jakarta",
    "media_urls": ["https://example.com/image1.jpg"],
    "event": {
      "id": "event-id",
      "title": "Coffee Cupping Session"
    },
    "likes_count": 42,
    "comments_count": 10,
    "is_liked_by_current_user": false,
    "created_at": "2025-11-12T10:00:00Z"
  }
}
```

---

### 4.3. Create Post

**POST** `/posts`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "content": "Just had an amazing coffee cupping session! ☕",
  "media_urls": ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
  "event_id": "e0000001-0000-0000-0000-000000000001"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Post created successfully",
  "data": {
    "id": "post-id",
    "author_id": "your-user-id",
    "content": "Just had an amazing coffee cupping session! ☕",
    "created_at": "2025-11-12T10:00:00Z"
  }
}
```

**Important Note for Frontend:**
- ❌ **DO NOT** generate the post `id` on the frontend
- ✅ Let the backend generate the UUID
- ❌ Remove any UUID generation code from CreatePostScreen

**Flutter Example (Correct):**
```dart
Future<Map<String, dynamic>> createPost({
  required String content,
  List<String>? mediaUrls,
  String? eventId,
}) async {
  final token = await secureStorage.read(key: 'auth_token');

  // ❌ WRONG: Do NOT generate ID
  // final id = Uuid().v4(); // Remove this!

  final response = await http.post(
    Uri.parse('$baseUrl/posts'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      // ❌ WRONG: Do NOT send id
      // 'id': id, // Remove this!
      'content': content,
      'media_urls': mediaUrls,
      'event_id': eventId,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to create post');
  }
}
```

---

### 4.4. Update Post

**PUT** `/posts/:id`

**Protected** (Requires authentication - Author only)

**Request Body:**
```json
{
  "content": "Updated post content",
  "media_urls": ["https://example.com/new-image.jpg"]
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Post updated successfully",
  "data": {
    "id": "post-id",
    "content": "Updated post content",
    "updated_at": "2025-11-12T10:30:00Z"
  }
}
```

---

### 4.5. Delete Post

**DELETE** `/posts/:id`

**Protected** (Requires authentication - Author only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Post deleted successfully",
  "data": null
}
```

---

### 4.6. Like Post

**POST** `/posts/:id/like`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Post liked successfully",
  "data": null
}
```

**Flutter Example:**
```dart
Future<void> likePost(String postId) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/posts/$postId/like'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to like post');
  }
}
```

---

### 4.7. Unlike Post

**POST** `/posts/:id/unlike`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Post unliked successfully",
  "data": null
}
```

---

### 4.8. Repost Post

**POST** `/posts/repost`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "original_post_id": "post-id-to-repost",
  "content": "Optional comment on the repost"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Post reposted successfully",
  "data": {
    "id": "new-repost-id",
    "original_post_id": "original-post-id",
    "created_at": "2025-11-12T10:00:00Z"
  }
}
```

---

### 4.9. Undo Repost

**POST** `/posts/:id/undo-repost`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Repost removed successfully",
  "data": null
}
```

---

### 4.10. Bookmark Post

**POST** `/posts/:id/bookmark`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Post bookmarked successfully",
  "data": null
}
```

**Flutter Example:**
```dart
Future<void> bookmarkPost(String postId) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/posts/$postId/bookmark'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to bookmark post');
  }
}
```

---

### 4.11. Remove Bookmark

**DELETE** `/posts/:id/bookmark`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Bookmark removed successfully",
  "data": null
}
```

---

### 4.12. Get Bookmarks

**GET** `/posts/bookmarks?limit=20&offset=0`

**Protected** (Requires authentication)

**Query Parameters:**
- `limit` (optional): Number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Bookmarks retrieved successfully",
  "data": [
    {
      "id": "post-id",
      "author": {
        "id": "user-id",
        "name": "John Doe",
        "username": "johndoe",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "content": "Amazing coffee cupping session! ☕",
      "media_urls": ["https://example.com/image1.jpg"],
      "likes_count": 42,
      "comments_count": 10,
      "is_liked_by_current_user": true,
      "is_bookmarked_by_current_user": true,
      "created_at": "2025-11-12T10:00:00Z"
    }
  ]
}
```

**Flutter Example:**
```dart
Future<List<dynamic>> getBookmarks({int limit = 20, int offset = 0}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/posts/bookmarks?limit=$limit&offset=$offset'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to get bookmarks');
  }
}
```

---

## 5. Comments

### 5.1. Get Comments for Post

**GET** `/posts/:id/comments?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Comments retrieved successfully",
  "data": [
    {
      "id": "comment-id",
      "post_id": "post-id",
      "author": {
        "id": "user-id",
        "name": "Jane Doe",
        "username": "janedoe",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "content": "Great post! Looking forward to the event 🎉",
      "parent_comment_id": null,
      "likes_count": 5,
      "replies_count": 2,
      "is_liked_by_current_user": false,
      "created_at": "2025-11-12T11:00:00Z"
    },
    {
      "id": "reply-comment-id",
      "post_id": "post-id",
      "author": {
        "id": "author-id",
        "name": "John Doe",
        "username": "johndoe",
        "avatar_url": "https://example.com/avatar2.jpg"
      },
      "content": "Thank you! See you there! 😊",
      "parent_comment_id": "comment-id",
      "likes_count": 2,
      "replies_count": 0,
      "is_liked_by_current_user": false,
      "created_at": "2025-11-12T11:05:00Z"
    }
  ]
}
```

**Flutter Example:**
```dart
Future<List<dynamic>> getComments(String postId, {int limit = 20, int offset = 0}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/posts/$postId/comments?limit=$limit&offset=$offset'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to get comments');
  }
}
```

---

### 5.2. Add Comment

**POST** `/posts/comments`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "post_id": "post-id",
  "content": "Great post! Looking forward to the event 🎉",
  "parent_comment_id": null
}
```

**For Replies (nested comments):**
```json
{
  "post_id": "post-id",
  "content": "Thank you! See you there! 😊",
  "parent_comment_id": "parent-comment-id"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Comment added successfully",
  "data": {
    "id": "new-comment-id",
    "post_id": "post-id",
    "content": "Great post!",
    "created_at": "2025-11-12T11:00:00Z"
  }
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> addComment({
  required String postId,
  required String content,
  String? parentCommentId,
}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/posts/comments'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'post_id': postId,
      'content': content,
      'parent_comment_id': parentCommentId,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to add comment');
  }
}
```

---

### 5.3. Update Comment

**PUT** `/posts/comments/:commentId`

**Protected** (Requires authentication - Author only)

**Request Body:**
```json
{
  "content": "Updated comment content"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Comment updated successfully",
  "data": {
    "id": "comment-id",
    "content": "Updated comment content",
    "updated_at": "2025-11-12T11:30:00Z"
  }
}
```

---

### 5.4. Delete Comment

**DELETE** `/posts/comments/:commentId`

**Protected** (Requires authentication - Author only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Comment deleted successfully",
  "data": null
}
```

---

### 5.5. Like Comment

**POST** `/posts/:postId/comments/:commentId/like`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Comment liked successfully",
  "data": null
}
```

---

### 5.6. Unlike Comment

**POST** `/posts/:postId/comments/:commentId/unlike`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Comment unliked successfully",
  "data": null
}
```

---

## 6. Tickets

### 6.1. Purchase Ticket

**POST** `/tickets/purchase`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "event_id": "e0000001-0000-0000-0000-000000000001",
  "quantity": 2,
  "payment_method": "credit_card"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Ticket purchased successfully",
  "data": {
    "id": "ticket-id",
    "event_id": "event-id",
    "user_id": "your-user-id",
    "quantity": 2,
    "total_price": 300000,
    "status": "pending",
    "payment_url": "https://midtrans.com/payment/...",
    "created_at": "2025-11-12T10:00:00Z"
  }
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> purchaseTicket({
  required String eventId,
  required int quantity,
  String paymentMethod = 'credit_card',
}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/tickets/purchase'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'event_id': eventId,
      'quantity': quantity,
      'payment_method': paymentMethod,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to purchase ticket');
  }
}
```

---

### 6.2. Get My Tickets

**GET** `/tickets/my-tickets?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Tickets retrieved successfully",
  "data": [
    {
      "id": "ticket-id",
      "event": {
        "id": "event-id",
        "title": "Coffee Cupping Session",
        "start_time": "2025-11-15T10:00:00Z",
        "location": "Kopi Kenangan, Jakarta",
        "image_url": "https://example.com/event.jpg"
      },
      "quantity": 2,
      "total_price": 300000,
      "status": "confirmed",
      "qr_code": "base64_encoded_qr_code",
      "purchased_at": "2025-11-12T10:00:00Z"
    }
  ]
}
```

---

### 6.3. Get Ticket by ID

**GET** `/tickets/:id`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Ticket retrieved successfully",
  "data": {
    "id": "ticket-id",
    "event": {
      "id": "event-id",
      "title": "Coffee Cupping Session",
      "start_time": "2025-11-15T10:00:00Z",
      "location": "Kopi Kenangan, Jakarta"
    },
    "quantity": 2,
    "total_price": 300000,
    "status": "confirmed",
    "qr_code": "base64_encoded_qr_code",
    "is_checked_in": false
  }
}
```

---

### 6.4. Check-in Ticket

**POST** `/tickets/check-in`

**Protected** (Requires authentication - Host only)

**Request Body:**
```json
{
  "ticket_id": "ticket-id"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Check-in successful",
  "data": {
    "ticket_id": "ticket-id",
    "checked_in_at": "2025-11-15T09:45:00Z"
  }
}
```

---

### 6.5. Cancel Ticket

**POST** `/tickets/:id/cancel`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Ticket cancelled successfully",
  "data": null
}
```

---

## 7. Analytics (Host Only)

### 7.1. Get Event Analytics

**GET** `/analytics/events/:id`

**Protected** (Requires authentication - Host only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Analytics retrieved successfully",
  "data": {
    "event_id": "event-id",
    "total_attendees": 25,
    "total_revenue": 3750000,
    "tickets_sold": 25,
    "tickets_available": 5,
    "check_ins": 20,
    "conversion_rate": 0.83
  }
}
```

---

### 7.2. Get Event Transactions

**GET** `/analytics/events/:id/transactions?limit=20&offset=0`

**Protected** (Requires authentication - Host only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Transactions retrieved successfully",
  "data": [
    {
      "id": "transaction-id",
      "user": {
        "id": "user-id",
        "name": "John Doe",
        "email": "john@example.com"
      },
      "quantity": 2,
      "total_price": 300000,
      "status": "confirmed",
      "purchased_at": "2025-11-12T10:00:00Z"
    }
  ]
}
```

---

### 7.3. Get Host Revenue Summary

**GET** `/analytics/host/revenue?start_date=2025-01-01&end_date=2025-12-31`

**Protected** (Requires authentication - Host only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Revenue summary retrieved successfully",
  "data": {
    "total_revenue": 15000000,
    "total_events": 10,
    "total_tickets_sold": 200,
    "average_ticket_price": 75000,
    "revenue_by_month": [
      {
        "month": "2025-01",
        "revenue": 2500000
      },
      {
        "month": "2025-02",
        "revenue": 3000000
      }
    ]
  }
}
```

---

### 7.4. Get Host Events List

**GET** `/analytics/host/events?limit=20&offset=0`

**Protected** (Requires authentication - Host only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Host events retrieved successfully",
  "data": [
    {
      "id": "event-id",
      "title": "Coffee Cupping Session",
      "start_time": "2025-11-15T10:00:00Z",
      "total_attendees": 25,
      "revenue": 3750000,
      "status": "active"
    }
  ]
}
```

---

## 8. Profile

### 8.1. Get Profile by Username

**GET** `/profile/:username`

**Public** (No authentication required)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "user-id",
    "name": "John Doe",
    "username": "johndoe",
    "avatar_url": "https://example.com/avatar.jpg",
    "cover_url": "https://example.com/cover.jpg",
    "bio": "Software developer and coffee enthusiast",
    "location": "Jakarta, Indonesia",
    "website": "https://johndoe.com",
    "followers_count": 250,
    "following_count": 180,
    "posts_count": 42,
    "events_hosted": 5,
    "is_followed_by_current_user": false,
    "joined_at": "2025-01-01T00:00:00Z"
  }
}
```

---

### 8.2. Get Profile Posts

**GET** `/profile/:username/posts?limit=20&offset=0`

**Public** (No authentication required)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Profile posts retrieved successfully",
  "data": [
    {
      "id": "post-id",
      "content": "Amazing event! #coffee",
      "media_urls": ["https://example.com/image.jpg"],
      "likes_count": 42,
      "comments_count": 10,
      "created_at": "2025-11-12T10:00:00Z"
    }
  ]
}
```

---

### 8.3. Get Profile Events

**GET** `/profile/:username/events?limit=20&offset=0`

**Public** (No authentication required)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Profile events retrieved successfully",
  "data": [
    {
      "id": "event-id",
      "title": "Coffee Cupping Session",
      "start_time": "2025-11-15T10:00:00Z",
      "location": "Kopi Kenangan, Jakarta",
      "image_url": "https://example.com/event.jpg",
      "attendees_count": 25
    }
  ]
}
```

---

## 9. Event Q&A

### 9.1. Get Event Q&A

**GET** `/events/:id/qna?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Q&A retrieved successfully",
  "data": [
    {
      "id": "qna-id",
      "event_id": "event-id",
      "author": {
        "id": "user-id",
        "name": "Jane Doe",
        "username": "janedoe",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "question": "Apakah ada demo brewing juga?",
      "answer": "Yes! We will have brewing demonstrations using V60, Aeropress, and French Press.",
      "answered_by": {
        "id": "host-id",
        "name": "Rudi Hartono",
        "username": "rudihartono",
        "avatar_url": "https://example.com/host-avatar.jpg"
      },
      "answered_at": "2025-11-12T10:30:00Z",
      "is_answered": true,
      "upvotes_count": 5,
      "is_upvoted_by_current_user": false,
      "created_at": "2025-11-12T10:00:00Z"
    }
  ]
}
```

**Flutter Example:**
```dart
Future<List<dynamic>> getEventQnA(String eventId, {int limit = 20, int offset = 0}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/events/$eventId/qna?limit=$limit&offset=$offset'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to get Q&A');
  }
}
```

---

### 9.2. Ask Question

**POST** `/events/:id/qna`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "question": "What should I bring to the event?"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Question posted successfully",
  "data": {
    "id": "qna-id",
    "event_id": "event-id",
    "question": "What should I bring to the event?",
    "is_answered": false,
    "created_at": "2025-11-12T10:00:00Z"
  }
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> askQuestion(String eventId, String question) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/events/$eventId/qna'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'question': question,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to post question');
  }
}
```

---

### 9.3. Answer Question

**POST** `/qna/:id/answer`

**Protected** (Requires authentication - Host only)

**Request Body:**
```json
{
  "answer": "Just bring yourself and enthusiasm! All equipment will be provided."
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Question answered successfully",
  "data": {
    "id": "qna-id",
    "question": "What should I bring to the event?",
    "answer": "Just bring yourself and enthusiasm!",
    "answered_at": "2025-11-12T10:30:00Z"
  }
}
```

---

### 9.4. Upvote Question

**POST** `/qna/:id/upvote`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Question upvoted successfully",
  "data": null
}
```

---

### 9.5. Remove Upvote

**DELETE** `/qna/:id/upvote`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Upvote removed successfully",
  "data": null
}
```

---

### 9.6. Delete Question

**DELETE** `/qna/:id`

**Protected** (Requires authentication - Author or Host only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Question deleted successfully",
  "data": null
}
```

---

## 10. File Upload

### 10.1. Upload Image

**POST** `/upload/image`

**Protected** (Requires authentication)

**Request:**
- **Content-Type:** `multipart/form-data`
- **Form Field:** `file`

**Supported Image Types:**
- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- GIF (`.gif`)
- WebP (`.webp`)

**Maximum File Size:** 10 MB

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "url": "https://s3.amazonaws.com/anigmaa/uploads/550e8400-e29b-41d4-a716-446655440000_1699999999.jpg",
    "filename": "550e8400-e29b-41d4-a716-446655440000_1699999999.jpg",
    "size": 245678,
    "mime_type": "image/jpeg"
  }
}
```

**Error Response:** `413 Payload Too Large`
```json
{
  "success": false,
  "message": "File too large",
  "error": {
    "code": "FILE_TOO_LARGE",
    "message": "file size exceeds maximum allowed size of 10 MB"
  }
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/api/v1/upload/image \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/image.jpg"
```

**Flutter Example:**
```dart
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<String> uploadImage(File imageFile) async {
  final token = await secureStorage.read(key: 'auth_token');

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/upload/image'),
  );

  // Add auth header
  request.headers['Authorization'] = 'Bearer $token';

  // Add file
  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ),
  );

  // Send request
  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data']['url']; // Return the uploaded image URL
  } else if (response.statusCode == 413) {
    throw Exception('File too large (max 10 MB)');
  } else {
    throw Exception('Failed to upload image');
  }
}

// Complete example with image picker
Future<String?> pickAndUploadImage() async {
  final ImagePicker picker = ImagePicker();

  // Pick image from gallery
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );

  if (image == null) return null;

  // Check file size before upload
  final file = File(image.path);
  final fileSize = await file.length();

  if (fileSize > 10 * 1024 * 1024) { // 10 MB
    throw Exception('Image too large. Please select an image under 10 MB.');
  }

  // Upload
  return await uploadImage(file);
}
```

**Complete Upload Flow Example:**
```dart
// 1. Pick and upload image
Future<void> createPostWithImage() async {
  try {
    // Pick and upload image
    String? imageUrl = await pickAndUploadImage();

    if (imageUrl == null) {
      print('No image selected');
      return;
    }

    // 2. Create post with uploaded image URL
    await createPost(
      content: 'Check out this amazing coffee! ☕',
      mediaUrls: [imageUrl],
    );

    print('Post created successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

// Similar flow for events
Future<void> createEventWithImage() async {
  try {
    // Upload event image
    String? imageUrl = await pickAndUploadImage();

    if (imageUrl == null) return;

    // Create event
    await createEvent(
      title: 'Coffee Cupping Session',
      description: 'Learn professional coffee tasting',
      category: 'Coffee',
      location: 'Kopi Kenangan, Jakarta',
      latitude: -6.2088,
      longitude: 106.8456,
      startTime: DateTime.now().add(Duration(days: 3)),
      endTime: DateTime.now().add(Duration(days: 3, hours: 2)),
      imageUrl: imageUrl, // Use uploaded image
      ticketPrice: 150000,
      maxAttendees: 30,
    );
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 11. Communities

### 11.1. Get Communities

**GET** `/communities?search=coffee&privacy=public&limit=20&offset=0`

**Protected** (Requires authentication)

**Query Parameters:**
- `search` (optional): Search query
- `privacy` (optional): Filter by privacy (`public`, `private`, `secret`)
- `limit` (optional): Number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Communities retrieved successfully",
  "data": [
    {
      "id": "community-id",
      "name": "Coffee Lovers Jakarta",
      "slug": "coffee-lovers-jakarta",
      "description": "A community for coffee enthusiasts in Jakarta",
      "avatar_url": "https://example.com/community-avatar.jpg",
      "cover_url": "https://example.com/community-cover.jpg",
      "privacy": "public",
      "members_count": 250,
      "creator_name": "John Doe",
      "creator_avatar_url": "https://example.com/avatar.jpg",
      "is_joined_by_current_user": false,
      "created_at": "2025-11-01T00:00:00Z"
    }
  ]
}
```

**Flutter Example:**
```dart
Future<List<dynamic>> getCommunities({
  String? search,
  String? privacy,
  int limit = 20,
  int offset = 0,
}) async {
  final token = await secureStorage.read(key: 'auth_token');

  var queryParams = {
    'limit': limit.toString(),
    'offset': offset.toString(),
  };

  if (search != null) queryParams['search'] = search;
  if (privacy != null) queryParams['privacy'] = privacy;

  final uri = Uri.parse('$baseUrl/communities').replace(queryParameters: queryParams);

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to get communities');
  }
}
```

---

### 11.2. Get Community by ID

**GET** `/communities/:id`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Community retrieved successfully",
  "data": {
    "id": "community-id",
    "name": "Coffee Lovers Jakarta",
    "slug": "coffee-lovers-jakarta",
    "description": "A community for coffee enthusiasts",
    "avatar_url": "https://example.com/community-avatar.jpg",
    "cover_url": "https://example.com/community-cover.jpg",
    "privacy": "public",
    "members_count": 250,
    "creator_name": "John Doe",
    "is_joined_by_current_user": false,
    "user_role": null,
    "created_at": "2025-11-01T00:00:00Z"
  }
}
```

---

### 11.3. Create Community

**POST** `/communities`

**Protected** (Requires authentication)

**Request Body:**
```json
{
  "name": "Coffee Lovers Jakarta",
  "description": "A community for coffee enthusiasts in Jakarta",
  "avatar_url": "https://example.com/community-avatar.jpg",
  "cover_url": "https://example.com/community-cover.jpg",
  "privacy": "public"
}
```

**Privacy Options:**
- `public`: Anyone can join
- `private`: Requires approval to join
- `secret`: Not visible in search, invite-only

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Community created successfully",
  "data": {
    "id": "new-community-id",
    "name": "Coffee Lovers Jakarta",
    "slug": "coffee-lovers-jakarta",
    "description": "A community for coffee enthusiasts",
    "privacy": "public",
    "creator_id": "your-user-id",
    "created_at": "2025-11-12T10:00:00Z"
  }
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> createCommunity({
  required String name,
  String? description,
  String? avatarUrl,
  String? coverUrl,
  String privacy = 'public',
}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/communities'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'privacy': privacy,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to create community');
  }
}
```

---

### 11.4. Update Community

**PUT** `/communities/:id`

**Protected** (Requires authentication - Owner only)

**Request Body:**
```json
{
  "name": "Coffee Lovers Jakarta Updated",
  "description": "Updated description",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "privacy": "private"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Community updated successfully",
  "data": {
    "id": "community-id",
    "name": "Coffee Lovers Jakarta Updated",
    "description": "Updated description",
    "updated_at": "2025-11-12T10:30:00Z"
  }
}
```

---

### 11.5. Delete Community

**DELETE** `/communities/:id`

**Protected** (Requires authentication - Owner only)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Community deleted successfully",
  "data": null
}
```

---

### 11.6. Join Community

**POST** `/communities/:id/join`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Joined community successfully",
  "data": null
}
```

**Flutter Example:**
```dart
Future<void> joinCommunity(String communityId) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/communities/$communityId/join'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to join community');
  }
}
```

---

### 11.7. Leave Community

**DELETE** `/communities/:id/leave`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Left community successfully",
  "data": null
}
```

**Note:** Community owners cannot leave their own community. They must delete it or transfer ownership first.

---

### 11.8. Get Community Members

**GET** `/communities/:id/members?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Community members retrieved successfully",
  "data": [
    {
      "id": "member-id",
      "community_id": "community-id",
      "user_id": "user-id",
      "name": "John Doe",
      "username": "johndoe",
      "avatar_url": "https://example.com/avatar.jpg",
      "role": "owner",
      "joined_at": "2025-11-01T00:00:00Z"
    }
  ]
}
```

**Member Roles:**
- `owner`: Community creator (full permissions)
- `admin`: Can moderate and manage members
- `moderator`: Can moderate content
- `member`: Regular member

---

### 11.9. Get My Communities

**GET** `/communities/my-communities?limit=20&offset=0`

**Protected** (Requires authentication)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "User communities retrieved successfully",
  "data": [
    {
      "id": "community-id",
      "name": "Coffee Lovers Jakarta",
      "slug": "coffee-lovers-jakarta",
      "description": "A community for coffee enthusiasts",
      "avatar_url": "https://example.com/community-avatar.jpg",
      "privacy": "public",
      "members_count": 250,
      "is_joined_by_current_user": true,
      "user_role": "owner",
      "joined_at": "2025-11-01T00:00:00Z"
    }
  ]
}
```

---

## 12. Error Handling

All API errors follow this standard format:

```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error information"
}
```

### Common HTTP Status Codes

| Status Code | Meaning | Example |
|------------|---------|---------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request body or parameters |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | User doesn't have permission |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists (e.g., already following) |
| 413 | Payload Too Large | File size exceeds limit |
| 422 | Unprocessable Entity | Validation failed |
| 500 | Internal Server Error | Server error |

### Error Handling in Flutter

```dart
Future<Map<String, dynamic>> makeApiCall() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/some/endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return data['data'];

      case 400:
        throw BadRequestException(data['message']);

      case 401:
        // Token expired - refresh or redirect to login
        await refreshToken();
        return makeApiCall(); // Retry

      case 403:
        throw ForbiddenException(data['message']);

      case 404:
        throw NotFoundException(data['message']);

      case 409:
        throw ConflictException(data['message']);

      case 413:
        throw FileTooLargeException('File size exceeds 10 MB');

      case 422:
        throw ValidationException(data['error']);

      case 500:
      default:
        throw ServerException('Server error. Please try again later.');
    }
  } on SocketException {
    throw NetworkException('No internet connection');
  } on TimeoutException {
    throw NetworkException('Request timeout');
  } catch (e) {
    rethrow;
  }
}

// Custom exception classes
class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}

class ConflictException implements Exception {
  final String message;
  ConflictException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class FileTooLargeException implements Exception {
  final String message;
  FileTooLargeException(this.message);
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
```

---

## 13. Flutter Integration Examples

### Complete API Service Class

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AnigmaaApiService {
  final String baseUrl = 'http://localhost:8081/api/v1';
  final secureStorage = const FlutterSecureStorage();

  // Helper method to get auth headers
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await secureStorage.read(key: 'auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await secureStorage.write(key: 'auth_token', value: data['data']['token']);
      await secureStorage.write(key: 'refresh_token', value: data['data']['refresh_token']);
      return data['data'];
    } else {
      throw Exception('Login failed');
    }
  }

  // Get feed
  Future<List<dynamic>> getFeed({int limit = 20, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/feed?limit=$limit&offset=$offset'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to get feed');
    }
  }

  // Create post
  Future<Map<String, dynamic>> createPost({
    required String content,
    List<String>? mediaUrls,
    String? eventId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: await _getHeaders(),
      body: json.encode({
        'content': content,
        'media_urls': mediaUrls,
        'event_id': eventId,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to create post');
    }
  }

  // Upload image
  Future<String> uploadImage(File imageFile) async {
    final token = await secureStorage.read(key: 'auth_token');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }

  // Like post
  Future<void> likePost(String postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like post');
    }
  }

  // Get events
  Future<List<dynamic>> getEvents({
    String? category,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    var queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/events').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(includeAuth: false),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to get events');
    }
  }
}
```

### Usage in Flutter App

```dart
// Initialize the service
final apiService = AnigmaaApiService();

// Login
try {
  final userData = await apiService.login('user@example.com', 'password');
  print('Logged in: ${userData['user']['name']}');
} catch (e) {
  print('Login error: $e');
}

// Get feed
try {
  final feedPosts = await apiService.getFeed(limit: 20);
  print('Fetched ${feedPosts.length} posts');
} catch (e) {
  print('Feed error: $e');
}

// Create post with image
try {
  // 1. Upload image
  final imageUrl = await apiService.uploadImage(imageFile);

  // 2. Create post
  final post = await apiService.createPost(
    content: 'Check out this amazing coffee! ☕',
    mediaUrls: [imageUrl],
  );

  print('Post created: ${post['id']}');
} catch (e) {
  print('Post creation error: $e');
}
```

---

## 📝 Important Notes for Frontend Developers

### 1. **DO NOT Generate IDs on Frontend**

❌ **WRONG:**
```dart
final postId = Uuid().v4(); // Don't do this!
await createPost(id: postId, content: 'Hello');
```

✅ **CORRECT:**
```dart
final post = await createPost(content: 'Hello');
final postId = post['id']; // Use backend-generated ID
```

### 2. **Always Include Authorization Header**

All protected endpoints require the JWT token:

```dart
headers: {
  'Authorization': 'Bearer $token',
}
```

### 3. **Handle Empty Data Arrays**

The API always returns empty arrays `[]` instead of `null` for list endpoints. Check length before accessing:

```dart
if (data.isEmpty) {
  // Show empty state
} else {
  // Show data
}
```

### 4. **Image Upload Flow**

Always upload images BEFORE creating posts/events:

```dart
// 1. Upload image first
String imageUrl = await uploadImage(file);

// 2. Then create post/event with the URL
await createPost(content: '...', mediaUrls: [imageUrl]);
```

### 5. **Pagination**

Most list endpoints support pagination with `limit` and `offset`:

```dart
// First page
final posts = await getFeed(limit: 20, offset: 0);

// Second page
final morePosts = await getFeed(limit: 20, offset: 20);

// Third page
final evenMorePosts = await getFeed(limit: 20, offset: 40);
```

### 6. **Date Formats**

All timestamps are in ISO 8601 format:

```dart
// Parse
final createdAt = DateTime.parse('2025-11-12T10:00:00Z');

// Format for API
final startTime = DateTime.now().toIso8601String();
```

### 7. **Error Responses**

Always check the `success` field:

```dart
final data = json.decode(response.body);

if (data['success']) {
  // Success
  return data['data'];
} else {
  // Error
  throw Exception(data['message']);
}
```

---

## 🔗 Additional Resources

- **Swagger Documentation:** `http://localhost:8081/swagger/index.html`
- **Health Check:** `http://localhost:8081/health`
- **Backend Repository:** `backend_anigmaa`

---

## 📞 Support

If you encounter any issues:
1. Check the error response message
2. Verify your authentication token is valid
3. Check the API documentation at `/swagger/index.html`
4. Contact the backend team

---

**Last Updated:** 2025-11-12
**API Version:** 1.0
**Maintained by:** Anigmaa Development Team
