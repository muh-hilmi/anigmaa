# Anigmaa Backend API Documentation

**Last Updated:** 2025-11-18
**API Version:** v1
**Base URL (Development):** `http://localhost:8081`
**Base URL (Production):** `https://anigmaa.muhhilmi.site`
**Base Path:** `/api/v1`

---

## 📚 Table of Contents

1. [Authentication](#authentication)
2. [Health Check](#health-check)
3. [Users](#users)
4. [Events](#events)
5. [Posts & Feed](#posts--feed)
6. [Comments](#comments)
7. [Tickets](#tickets)
8. [Communities](#communities)
9. [Analytics (Host Only)](#analytics-host-only)
10. [Event Q&A](#event-qa)
11. [Profile](#profile)
12. [File Upload](#file-upload)
13. [Payments](#payments)
14. [Error Handling](#error-handling)
15. [Pagination & Filtering](#pagination--filtering)
16. [Flutter Integration Examples](#flutter-integration-examples)

---

## Authentication

Use JWT Bearer Token for endpoints that require authentication:

```
Authorization: Bearer <your_jwt_token>
```

### Response Format

All API responses follow this standard format:

**Success Response:**
```json
{
  "success": true,
  "message": "Success message",
  "data": { /* response data */ }
}
```

**Error Response:**
```json
{
  "error": "Error message here",
  "details": "Optional detailed explanation"
}
```

---

## Health Check

### Check Service Status

**GET** `/health`

**Auth:** No

**Response:** `200 OK`
```json
{
  "status": "ok"
}
```

---

### Check Database Connection

**GET** `/health/db`

**Auth:** No

**Response:** `200 OK`
```json
{
  "status": "ok",
  "database": "connected"
}
```

---

### Check Redis Connection

**GET** `/health/redis`

**Auth:** No

**Response:** `200 OK`
```json
{
  "status": "ok",
  "redis": "connected"
}
```

---

## Authentication Endpoints

### 1. Register

**POST** `/api/v1/auth/register`

**Auth:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "John Doe",
  "username": "johndoe"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "johndoe",
    "full_name": "John Doe",
    "is_verified": false,
    "avatar_url": null,
    "bio": null,
    "created_at": "2025-11-18T10:00:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> register({
  required String email,
  required String password,
  required String fullName,
  required String username,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
      'full_name': fullName,
      'username': username,
    }),
  );

  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    await secureStorage.write(key: 'auth_token', value: data['access_token']);
    await secureStorage.write(key: 'refresh_token', value: data['refresh_token']);
    return data;
  } else {
    final error = json.decode(response.body);
    throw Exception(error['error']);
  }
}
```

---

### 2. Login

**POST** `/api/v1/auth/login`

**Auth:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:** `200 OK`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "johndoe",
    "full_name": "John Doe",
    "avatar_url": "https://example.com/avatar.jpg",
    "is_verified": true
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### 3. Google OAuth

**POST** `/api/v1/auth/google`

**Auth:** No

**Request Body:**
```json
{
  "id_token": "google_id_token_from_firebase_or_google_sign_in"
}
```

**Response:** `200 OK`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@gmail.com",
    "username": "johndoe",
    "full_name": "John Doe",
    "avatar_url": "https://lh3.googleusercontent.com/..."
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Flutter Example:**
```dart
import 'package:google_sign_in/google_sign_in.dart';

Future<Map<String, dynamic>> loginWithGoogle() async {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) throw Exception('Google sign in cancelled');

  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final response = await http.post(
    Uri.parse('$baseUrl/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'id_token': googleAuth.idToken,
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    await secureStorage.write(key: 'auth_token', value: data['access_token']);
    await secureStorage.write(key: 'refresh_token', value: data['refresh_token']);
    return data;
  } else {
    throw Exception('Google login failed');
  }
}
```

---

### 4. Logout

**POST** `/api/v1/auth/logout`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Logout successful"
}
```

---

### 5. Refresh Token

**POST** `/api/v1/auth/refresh`

**Auth:** Yes

**Request Body:**
```json
{
  "refresh_token": "your_refresh_token_here"
}
```

**Response:** `200 OK`
```json
{
  "access_token": "new_access_token_here"
}
```

---

### 6. Change Password

**POST** `/api/v1/auth/change-password`

**Auth:** Yes

**Request Body:**
```json
{
  "current_password": "oldpass123",
  "new_password": "newpass123"
}
```

**Response:** `200 OK`
```json
{
  "message": "Password changed successfully"
}
```

---

### 7. Forgot Password

**POST** `/api/v1/auth/forgot-password`

**Auth:** No

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:** `200 OK`
```json
{
  "message": "Password reset email sent"
}
```

---

### 8. Reset Password

**POST** `/api/v1/auth/reset-password`

**Auth:** No

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "new_password": "newpass123"
}
```

**Response:** `200 OK`
```json
{
  "message": "Password reset successfully"
}
```

---

### 9. Verify Email

**POST** `/api/v1/auth/verify-email`

**Auth:** No

**Request Body:**
```json
{
  "token": "verification_token_from_email"
}
```

**Response:** `200 OK`
```json
{
  "message": "Email verified successfully"
}
```

---

### 10. Resend Verification Email

**POST** `/api/v1/auth/resend-verification`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Verification email sent"
}
```

---

## Users

### 1. Get Current User

**GET** `/api/v1/users/me`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "johndoe",
  "full_name": "John Doe",
  "bio": "Software developer and coffee enthusiast",
  "avatar_url": "https://example.com/avatar.jpg",
  "is_verified": true,
  "followers_count": 100,
  "following_count": 50,
  "created_at": "2025-01-01T00:00:00Z"
}
```

---

### 2. Update Current User

**PUT** `/api/v1/users/me`

**Auth:** Yes

**Request Body:**
```json
{
  "full_name": "John Updated",
  "bio": "New bio",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "birth_date": "1990-01-01"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "full_name": "John Updated",
  "bio": "New bio",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "updated_at": "2025-11-18T10:00:00Z"
}
```

---

### 3. Update User Settings

**PUT** `/api/v1/users/me/settings`

**Auth:** Yes

**Request Body:**
```json
{
  "privacy_setting": "public",
  "notification_enabled": true,
  "language": "id"
}
```

**Supported Values:**
- `privacy_setting`: `public`, `private`
- `language`: `id`, `en`

**Response:** `200 OK`
```json
{
  "privacy_setting": "public",
  "notification_enabled": true,
  "language": "id"
}
```

---

### 4. Search Users

**GET** `/api/v1/users/search?q=john&limit=20`

**Auth:** Yes

**Query Parameters:**
- `q` (required): Search query (minimum 2 characters)
- `limit` (optional): Number of results (default: 20)

**Response:** `200 OK`
```json
{
  "users": [
    {
      "id": "uuid",
      "username": "johndoe",
      "full_name": "John Doe",
      "avatar_url": "https://example.com/avatar.jpg",
      "is_following": false
    }
  ]
}
```

---

### 5. Get User by ID

**GET** `/api/v1/users/:id`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "username": "johndoe",
  "full_name": "John Doe",
  "bio": "Software developer",
  "avatar_url": "https://example.com/avatar.jpg",
  "followers_count": 100,
  "following_count": 50,
  "is_following": false
}
```

---

### 6. Follow User

**POST** `/api/v1/users/:id/follow`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "User followed successfully"
}
```

---

### 7. Unfollow User

**DELETE** `/api/v1/users/:id/follow`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "User unfollowed successfully"
}
```

---

### 8. Get User Followers

**GET** `/api/v1/users/:id/followers?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "followers": [
    {
      "id": "uuid",
      "username": "follower",
      "full_name": "Follower Name",
      "avatar_url": "https://example.com/avatar.jpg",
      "is_following": true
    }
  ],
  "total": 100
}
```

---

### 9. Get User Following

**GET** `/api/v1/users/:id/following?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "following": [
    {
      "id": "uuid",
      "username": "following",
      "full_name": "Following Name",
      "avatar_url": "https://example.com/avatar.jpg",
      "is_following": true
    }
  ],
  "total": 50
}
```

---

### 10. Get User Stats

**GET** `/api/v1/users/:id/stats`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "followers_count": 100,
  "following_count": 50,
  "posts_count": 25,
  "events_hosted": 5,
  "events_joined": 15
}
```

---

## Events

### Event Categories

Supported categories:
- `music`
- `sports`
- `tech`
- `arts`
- `food`
- `education`
- `business`
- `other`

### 1. Get Events List

**GET** `/api/v1/events?category=music&is_free=true&limit=20&offset=0`

**Auth:** No

**Query Parameters:**
- `category` (optional): Event category (music, sports, tech, etc.)
- `is_free` (optional): Filter free events (`true`/`false`)
- `status` (optional): Event status (`upcoming`, `ongoing`, `past`)
- `limit` (optional): Results per page (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "Music Festival 2025",
      "description": "Annual music event",
      "start_time": "2025-12-01T18:00:00Z",
      "end_time": "2025-12-01T23:00:00Z",
      "location": "Jakarta Convention Center",
      "latitude": -6.2088,
      "longitude": 106.8456,
      "category": "music",
      "max_attendees": 500,
      "current_attendees": 250,
      "price": 150000,
      "image_url": "https://example.com/event.jpg",
      "status": "upcoming",
      "host": {
        "id": "uuid",
        "username": "organizer",
        "full_name": "Event Organizer",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "is_joined": false,
      "created_at": "2025-11-01T00:00:00Z"
    }
  ],
  "total": 100
}
```

---

### 2. Get Nearby Events

**GET** `/api/v1/events/nearby?lat=-6.2088&lng=106.8456&radius=5000&limit=20`

**Auth:** No

**Query Parameters:**
- `lat` (required): Latitude
- `lng` (required): Longitude
- `radius` (optional): Search radius in **meters** (default: 5000)
- `limit` (optional): Number of results (default: 20)

**Response:** `200 OK`
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "Coffee Cupping Session",
      "description": "Learn professional coffee tasting",
      "location": "Kopi Kenangan, Jakarta",
      "distance_meters": 2500,
      "start_time": "2025-11-20T10:00:00Z",
      "image_url": "https://example.com/event.jpg",
      "price": 150000,
      "is_free": false
    }
  ]
}
```

---

### 3. Get Event Details

**GET** `/api/v1/events/:id`

**Auth:** No

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "title": "Music Festival 2025",
  "description": "Annual music event with amazing lineup",
  "start_time": "2025-12-01T18:00:00Z",
  "end_time": "2025-12-01T23:00:00Z",
  "location": "Jakarta Convention Center",
  "latitude": -6.2088,
  "longitude": 106.8456,
  "category": "music",
  "max_attendees": 500,
  "current_attendees": 250,
  "price": 150000,
  "image_url": "https://example.com/event.jpg",
  "status": "upcoming",
  "host": {
    "id": "uuid",
    "username": "organizer",
    "full_name": "Event Organizer",
    "avatar_url": "https://example.com/avatar.jpg"
  },
  "is_joined": false,
  "created_at": "2025-11-01T00:00:00Z",
  "updated_at": "2025-11-01T00:00:00Z"
}
```

---

### 4. Create Event

**POST** `/api/v1/events`

**Auth:** Yes

**Request Body:**
```json
{
  "title": "Music Festival 2025",
  "description": "Annual music event",
  "start_time": "2025-12-01T18:00:00Z",
  "end_time": "2025-12-01T23:00:00Z",
  "location": "Jakarta Convention Center",
  "latitude": -6.2088,
  "longitude": 106.8456,
  "category": "music",
  "max_attendees": 500,
  "price": 150000,
  "image_url": "https://example.com/event.jpg"
}
```

**Important:**
- ❌ **DO NOT** generate event `id` on frontend
- ✅ Let backend generate the UUID
- Date format: RFC3339 (`2025-12-01T18:00:00Z`)

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "title": "Music Festival 2025",
  "host_id": "your-user-id",
  "created_at": "2025-11-18T10:00:00Z"
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> createEvent({
  required String title,
  required String description,
  required DateTime startTime,
  required DateTime endTime,
  required String location,
  required double latitude,
  required double longitude,
  required String category,
  int? maxAttendees,
  int? price,
  String? imageUrl,
}) async {
  final token = await secureStorage.read(key: 'auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/events'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'max_attendees': maxAttendees,
      'price': price,
      'image_url': imageUrl,
    }),
  );

  if (response.statusCode == 201) {
    return json.decode(response.body);
  } else {
    final error = json.decode(response.body);
    throw Exception(error['error']);
  }
}
```

---

### 5. Update Event

**PUT** `/api/v1/events/:id`

**Auth:** Yes (Host only)

**Request Body:**
```json
{
  "title": "Updated Music Festival",
  "description": "Updated description",
  "price": 175000
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "title": "Updated Music Festival",
  "updated_at": "2025-11-18T10:00:00Z"
}
```

---

### 6. Delete Event

**DELETE** `/api/v1/events/:id`

**Auth:** Yes (Host only)

**Response:** `200 OK`
```json
{
  "message": "Event deleted successfully"
}
```

---

### 7. Join Event

**POST** `/api/v1/events/:id/join`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Joined event successfully"
}
```

---

### 8. Leave Event

**DELETE** `/api/v1/events/:id/join`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Left event successfully"
}
```

---

### 9. Get My Events (Hosted)

**GET** `/api/v1/events/my-events?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "Music Festival 2025",
      "start_time": "2025-12-01T18:00:00Z",
      "current_attendees": 250,
      "max_attendees": 500,
      "status": "upcoming"
    }
  ]
}
```

---

### 10. Get Hosted Events

**GET** `/api/v1/events/hosted?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "Music Festival 2025",
      "start_time": "2025-12-01T18:00:00Z",
      "current_attendees": 250,
      "max_attendees": 500
    }
  ]
}
```

---

### 11. Get Joined Events

**GET** `/api/v1/events/joined?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "Coffee Cupping Session",
      "start_time": "2025-11-20T10:00:00Z",
      "location": "Kopi Kenangan, Jakarta",
      "image_url": "https://example.com/event.jpg"
    }
  ]
}
```

---

### 12. Get Event Attendees

**GET** `/api/v1/events/:id/attendees?limit=20&offset=0`

**Auth:** No

**Response:** `200 OK`
```json
{
  "attendees": [
    {
      "id": "uuid",
      "username": "johndoe",
      "full_name": "John Doe",
      "avatar_url": "https://example.com/avatar.jpg",
      "joined_at": "2025-11-10T12:00:00Z"
    }
  ],
  "total": 250
}
```

---

### 13. Get Event Tickets (Host Only)

**GET** `/api/v1/events/:id/tickets`

**Auth:** Yes (Host only)

**Response:** `200 OK`
```json
{
  "tickets": [
    {
      "id": "uuid",
      "user": {
        "id": "uuid",
        "full_name": "John Doe",
        "email": "john@example.com"
      },
      "ticket_code": "TICK-12345",
      "status": "active",
      "purchased_at": "2025-11-15T10:00:00Z"
    }
  ]
}
```

---

## Posts & Feed

### Post Types

- `text`: Text-only post
- `image`: Image post
- `text_with_event`: Post with attached event

### 1. Get Feed

**GET** `/api/v1/posts/feed?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "posts": [
    {
      "id": "uuid",
      "content": "Check out this event!",
      "type": "text_with_event",
      "image_url": "https://example.com/image.jpg",
      "author": {
        "id": "uuid",
        "username": "johndoe",
        "full_name": "John Doe",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "attached_event": {
        "id": "uuid",
        "title": "Music Festival 2025"
      },
      "likes_count": 50,
      "comments_count": 10,
      "reposts_count": 5,
      "is_liked": false,
      "is_reposted": false,
      "is_bookmarked": false,
      "created_at": "2025-11-18T10:00:00Z"
    }
  ]
}
```

---

### 2. Create Post

**POST** `/api/v1/posts`

**Auth:** Yes

**Request Body:**
```json
{
  "content": "Check out this event!",
  "type": "text_with_event",
  "image_url": "https://example.com/image.jpg",
  "attached_event_id": "event_uuid"
}
```

**Important:**
- ❌ **DO NOT** generate post `id` on frontend
- ✅ Let backend generate the UUID

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "content": "Check out this event!",
  "author_id": "your-user-id",
  "created_at": "2025-11-18T10:00:00Z"
}
```

---

### 3. Get Post by ID

**GET** `/api/v1/posts/:id`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "content": "Amazing event!",
  "type": "text",
  "author": {
    "id": "uuid",
    "username": "johndoe",
    "full_name": "John Doe",
    "avatar_url": "https://example.com/avatar.jpg"
  },
  "likes_count": 42,
  "comments_count": 10,
  "is_liked": false,
  "created_at": "2025-11-18T10:00:00Z"
}
```

---

### 4. Update Post

**PUT** `/api/v1/posts/:id`

**Auth:** Yes (Author only)

**Request Body:**
```json
{
  "content": "Updated content",
  "image_url": "https://example.com/new-image.jpg"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "content": "Updated content",
  "updated_at": "2025-11-18T10:30:00Z"
}
```

---

### 5. Delete Post

**DELETE** `/api/v1/posts/:id`

**Auth:** Yes (Author only)

**Response:** `200 OK`
```json
{
  "message": "Post deleted successfully"
}
```

---

### 6. Like Post

**POST** `/api/v1/posts/:id/like`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Post liked successfully"
}
```

---

### 7. Unlike Post

**POST** `/api/v1/posts/:id/unlike`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Post unliked successfully"
}
```

---

### 8. Repost

**POST** `/api/v1/posts/repost`

**Auth:** Yes

**Request Body:**
```json
{
  "post_id": "uuid",
  "quote_text": "Optional quote text"
}
```

**Response:** `201 Created`
```json
{
  "id": "new-repost-id",
  "original_post_id": "uuid",
  "created_at": "2025-11-18T10:00:00Z"
}
```

---

### 9. Undo Repost

**POST** `/api/v1/posts/:id/undo-repost`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Repost removed successfully"
}
```

---

### 10. Bookmark Post

**POST** `/api/v1/posts/:id/bookmark`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Post bookmarked successfully"
}
```

---

### 11. Remove Bookmark

**DELETE** `/api/v1/posts/:id/bookmark`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Bookmark removed successfully"
}
```

---

### 12. Get Bookmarks

**GET** `/api/v1/posts/bookmarks?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "posts": [
    {
      "id": "uuid",
      "content": "Amazing coffee!",
      "author": {
        "id": "uuid",
        "username": "johndoe",
        "full_name": "John Doe",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "likes_count": 42,
      "is_liked": true,
      "is_bookmarked": true,
      "created_at": "2025-11-18T10:00:00Z"
    }
  ]
}
```

---

## Comments

### 1. Get Post Comments

**GET** `/api/v1/posts/:id/comments?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "comments": [
    {
      "id": "uuid",
      "post_id": "post-uuid",
      "author": {
        "id": "uuid",
        "username": "janedoe",
        "full_name": "Jane Doe",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "content": "Great post!",
      "likes_count": 5,
      "is_liked": false,
      "created_at": "2025-11-18T11:00:00Z"
    }
  ]
}
```

---

### 2. Add Comment

**POST** `/api/v1/posts/comments`

**Auth:** Yes

**Request Body:**
```json
{
  "post_id": "uuid",
  "content": "Nice post!"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "post_id": "post-uuid",
  "content": "Nice post!",
  "created_at": "2025-11-18T11:00:00Z"
}
```

---

### 3. Update Comment

**PUT** `/api/v1/posts/comments/:commentId`

**Auth:** Yes (Author only)

**Request Body:**
```json
{
  "content": "Updated comment"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "content": "Updated comment",
  "updated_at": "2025-11-18T11:30:00Z"
}
```

---

### 4. Delete Comment

**DELETE** `/api/v1/posts/comments/:commentId`

**Auth:** Yes (Author only)

**Response:** `200 OK`
```json
{
  "message": "Comment deleted successfully"
}
```

---

### 5. Like Comment

**POST** `/api/v1/posts/:id/comments/:commentId/like`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Comment liked successfully"
}
```

---

### 6. Unlike Comment

**POST** `/api/v1/posts/:id/comments/:commentId/unlike`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Comment unliked successfully"
}
```

---

## Tickets

### 1. Purchase Ticket

**POST** `/api/v1/tickets/purchase`

**Auth:** Yes

**Request Body:**
```json
{
  "event_id": "uuid",
  "quantity": 2
}
```

**Response:** `201 Created`
```json
{
  "transaction_id": "uuid",
  "order_id": "ORDER-123",
  "payment_url": "https://midtrans.com/payment/...",
  "total_amount": 300000,
  "status": "pending"
}
```

---

### 2. Get My Tickets

**GET** `/api/v1/tickets/my-tickets?status=active&limit=20`

**Auth:** Yes

**Query Parameters:**
- `status` (optional): `active`, `used`, `cancelled`
- `limit` (optional): Results per page (default: 20)

**Response:** `200 OK`
```json
{
  "tickets": [
    {
      "id": "uuid",
      "event": {
        "id": "uuid",
        "title": "Music Festival",
        "start_time": "2025-12-01T18:00:00Z",
        "location": "Jakarta Convention Center",
        "image_url": "https://example.com/event.jpg"
      },
      "ticket_code": "TICK-12345",
      "status": "active",
      "purchased_at": "2025-11-18T10:00:00Z"
    }
  ]
}
```

---

### 3. Get Ticket Details

**GET** `/api/v1/tickets/:id`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "event": {
    "id": "uuid",
    "title": "Music Festival",
    "start_time": "2025-12-01T18:00:00Z",
    "location": "Jakarta Convention Center"
  },
  "ticket_code": "TICK-12345",
  "qr_code": "base64_encoded_qr_code",
  "status": "active",
  "purchased_at": "2025-11-18T10:00:00Z"
}
```

---

### 4. Check In

**POST** `/api/v1/tickets/check-in`

**Auth:** Yes

**Request Body:**
```json
{
  "attendance_code": "EVENT-CODE-123"
}
```

**Response:** `200 OK`
```json
{
  "message": "Check-in successful",
  "ticket_id": "uuid",
  "checked_in_at": "2025-12-01T18:15:00Z"
}
```

---

### 5. Cancel Ticket

**POST** `/api/v1/tickets/:id/cancel`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Ticket cancelled successfully"
}
```

---

### 6. Get Transaction

**GET** `/api/v1/tickets/transactions/:id`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "order_id": "ORDER-123",
  "event_id": "uuid",
  "user_id": "uuid",
  "quantity": 2,
  "total_amount": 300000,
  "status": "settlement",
  "payment_type": "gopay",
  "transaction_time": "2025-11-18T10:00:00Z"
}
```

---

## Communities

### 1. Get Communities

**GET** `/api/v1/communities?search=tech&limit=20&offset=0`

**Auth:** Yes

**Query Parameters:**
- `search` (optional): Search query
- `limit` (optional): Results per page (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "communities": [
    {
      "id": "uuid",
      "name": "Tech Enthusiasts",
      "description": "Community for tech lovers",
      "privacy": "public",
      "image_url": "https://example.com/community.jpg",
      "members_count": 500,
      "is_member": false,
      "owner": {
        "id": "uuid",
        "username": "owner",
        "full_name": "Owner Name"
      }
    }
  ]
}
```

---

### 2. Get My Communities

**GET** `/api/v1/communities/my-communities`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "communities": [
    {
      "id": "uuid",
      "name": "Tech Enthusiasts",
      "description": "Community for tech lovers",
      "privacy": "public",
      "members_count": 500,
      "is_member": true,
      "joined_at": "2025-11-01T00:00:00Z"
    }
  ]
}
```

---

### 3. Create Community

**POST** `/api/v1/communities`

**Auth:** Yes

**Request Body:**
```json
{
  "name": "Tech Enthusiasts",
  "description": "Community for tech lovers",
  "privacy": "public",
  "image_url": "https://example.com/community.jpg"
}
```

**Privacy Options:**
- `public`: Anyone can join
- `private`: Requires approval

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "name": "Tech Enthusiasts",
  "privacy": "public",
  "created_at": "2025-11-18T10:00:00Z"
}
```

---

### 4. Get Community Details

**GET** `/api/v1/communities/:id`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "name": "Tech Enthusiasts",
  "description": "Community for tech lovers",
  "privacy": "public",
  "image_url": "https://example.com/community.jpg",
  "members_count": 500,
  "is_member": false,
  "owner": {
    "id": "uuid",
    "username": "owner",
    "full_name": "Owner Name"
  },
  "created_at": "2025-11-01T00:00:00Z"
}
```

---

### 5. Update Community

**PUT** `/api/v1/communities/:id`

**Auth:** Yes (Owner only)

**Request Body:**
```json
{
  "name": "Tech Enthusiasts Updated",
  "description": "Updated description",
  "privacy": "private"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "name": "Tech Enthusiasts Updated",
  "updated_at": "2025-11-18T10:30:00Z"
}
```

---

### 6. Delete Community

**DELETE** `/api/v1/communities/:id`

**Auth:** Yes (Owner only)

**Response:** `200 OK`
```json
{
  "message": "Community deleted successfully"
}
```

---

### 7. Join Community

**POST** `/api/v1/communities/:id/join`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Joined community successfully"
}
```

---

### 8. Leave Community

**DELETE** `/api/v1/communities/:id/leave`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Left community successfully"
}
```

---

### 9. Get Community Members

**GET** `/api/v1/communities/:id/members?limit=20&offset=0`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "members": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "username": "johndoe",
      "full_name": "John Doe",
      "avatar_url": "https://example.com/avatar.jpg",
      "role": "member",
      "joined_at": "2025-11-01T00:00:00Z"
    }
  ],
  "total": 500
}
```

---

## Analytics (Host Only)

### 1. Get Event Analytics

**GET** `/api/v1/analytics/events/:id`

**Auth:** Yes (Host only)

**Response:** `200 OK`
```json
{
  "event_id": "uuid",
  "total_tickets_sold": 250,
  "total_revenue": 37500000,
  "attendance_rate": 95.5,
  "daily_sales": [
    {
      "date": "2025-11-18",
      "tickets_sold": 50,
      "revenue": 7500000
    }
  ]
}
```

---

### 2. Get Event Transactions

**GET** `/api/v1/analytics/events/:id/transactions?limit=20&offset=0`

**Auth:** Yes (Host only)

**Response:** `200 OK`
```json
{
  "transactions": [
    {
      "id": "uuid",
      "user": {
        "id": "uuid",
        "full_name": "John Doe",
        "email": "john@example.com"
      },
      "quantity": 2,
      "total_amount": 300000,
      "status": "settlement",
      "purchased_at": "2025-11-18T10:00:00Z"
    }
  ]
}
```

---

### 3. Get Host Revenue

**GET** `/api/v1/analytics/host/revenue?start_date=2025-01-01&end_date=2025-12-31`

**Auth:** Yes (Host only)

**Response:** `200 OK`
```json
{
  "total_revenue": 150000000,
  "total_tickets_sold": 1500,
  "total_events": 10,
  "commission_paid": 15000000
}
```

---

### 4. Get Host Events with Revenue

**GET** `/api/v1/analytics/host/events?limit=20&offset=0`

**Auth:** Yes (Host only)

**Response:** `200 OK`
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "Music Festival 2025",
      "total_tickets_sold": 250,
      "total_revenue": 37500000,
      "status": "active"
    }
  ]
}
```

---

## Event Q&A

### 1. Get Event Q&A

**GET** `/api/v1/events/:id/qna?limit=20&offset=0&sort=upvotes`

**Auth:** Yes

**Query Parameters:**
- `sort` (optional): `upvotes`, `recent`
- `filter` (optional): `unanswered`, `answered`
- `limit` (optional): Results per page (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "questions": [
    {
      "id": "uuid",
      "question": "What time does the event start?",
      "answer": "Event starts at 6 PM",
      "upvotes_count": 10,
      "is_upvoted": false,
      "is_answered": true,
      "author": {
        "id": "uuid",
        "username": "user",
        "full_name": "User Name"
      },
      "created_at": "2025-11-18T10:00:00Z"
    }
  ]
}
```

---

### 2. Ask Question

**POST** `/api/v1/events/:id/qna`

**Auth:** Yes

**Request Body:**
```json
{
  "question": "What time does the event start?"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "event_id": "uuid",
  "question": "What time does the event start?",
  "is_answered": false,
  "created_at": "2025-11-18T10:00:00Z"
}
```

---

### 3. Upvote Question

**POST** `/api/v1/qna/:id/upvote`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Question upvoted successfully"
}
```

---

### 4. Remove Upvote

**DELETE** `/api/v1/qna/:id/upvote`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "message": "Upvote removed successfully"
}
```

---

### 5. Answer Question

**POST** `/api/v1/qna/:id/answer`

**Auth:** Yes (Host only)

**Request Body:**
```json
{
  "answer": "Event starts at 6 PM"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "question": "What time does the event start?",
  "answer": "Event starts at 6 PM",
  "answered_at": "2025-11-18T10:30:00Z"
}
```

---

### 6. Delete Question

**DELETE** `/api/v1/qna/:id`

**Auth:** Yes (Author only)

**Response:** `200 OK`
```json
{
  "message": "Question deleted successfully"
}
```

---

## Profile

### 1. Get Profile by Username

**GET** `/api/v1/profile/:username`

**Auth:** No

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "username": "johndoe",
  "full_name": "John Doe",
  "bio": "Tech enthusiast",
  "avatar_url": "https://example.com/avatar.jpg",
  "followers_count": 100,
  "following_count": 50,
  "posts_count": 25,
  "is_following": false
}
```

---

### 2. Get User Posts

**GET** `/api/v1/profile/:username/posts?limit=20&offset=0`

**Auth:** No

**Response:** `200 OK`
```json
{
  "posts": [
    {
      "id": "uuid",
      "content": "Amazing event!",
      "likes_count": 42,
      "comments_count": 10,
      "created_at": "2025-11-18T10:00:00Z"
    }
  ]
}
```

---

### 3. Get User Events

**GET** `/api/v1/profile/:username/events?type=hosted&limit=20`

**Auth:** No

**Query Parameters:**
- `type` (optional): `hosted`, `joined`
- `limit` (optional): Results per page (default: 20)

**Response:** `200 OK`
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "Music Festival 2025",
      "start_time": "2025-12-01T18:00:00Z",
      "location": "Jakarta Convention Center",
      "image_url": "https://example.com/event.jpg"
    }
  ]
}
```

---

## File Upload

### Upload Image

**POST** `/api/v1/upload/image`

**Auth:** Yes

**Content-Type:** `multipart/form-data`

**Form Field:** `image`

**Supported Formats:**
- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- GIF (`.gif`)
- WebP (`.webp`)

**Maximum File Size:** 5 MB

**Response:** `200 OK`
```json
{
  "url": "https://storage.example.com/images/uuid.jpg"
}
```

**Error:** `413 Payload Too Large`
```json
{
  "error": "File too large",
  "details": "Maximum file size is 5 MB"
}
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

  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(
    await http.MultipartFile.fromPath('image', imageFile.path),
  );

  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['url'];
  } else if (response.statusCode == 413) {
    throw Exception('File too large (max 5 MB)');
  } else {
    final error = json.decode(response.body);
    throw Exception(error['error']);
  }
}

// Complete upload flow
Future<void> createEventWithImage() async {
  try {
    // 1. Pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    // 2. Upload image
    final imageUrl = await uploadImage(File(image.path));

    // 3. Create event with uploaded image
    await createEvent(
      title: 'Music Festival 2025',
      description: 'Amazing lineup',
      startTime: DateTime.now().add(Duration(days: 7)),
      endTime: DateTime.now().add(Duration(days: 7, hours: 5)),
      location: 'Jakarta Convention Center',
      latitude: -6.2088,
      longitude: 106.8456,
      category: 'music',
      imageUrl: imageUrl,
      price: 150000,
      maxAttendees: 500,
    );

    print('Event created successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## Payments

### 1. Midtrans Webhook

**POST** `/api/v1/webhooks/midtrans`

**Auth:** No (Signature verified)

**Note:** This endpoint is used by Midtrans for payment notifications. Do not call directly from frontend.

---

### 2. Get Transaction Status

**GET** `/api/v1/payments/transactions/:order_id/status`

**Auth:** Yes

**Response:** `200 OK`
```json
{
  "order_id": "ORDER-123",
  "status": "settlement",
  "payment_type": "gopay",
  "gross_amount": 300000,
  "transaction_time": "2025-11-18T10:00:00Z"
}
```

**Payment Statuses:**
- `pending`: Waiting for payment
- `settlement`: Payment successful
- `deny`: Payment denied
- `cancel`: Payment cancelled
- `expire`: Payment expired

---

## Error Handling

### Error Response Format

All errors follow this format:

```json
{
  "error": "Error message here",
  "details": "Optional detailed explanation"
}
```

### HTTP Status Codes

| Status Code | Meaning | Example |
|------------|---------|---------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request body or parameters |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | User doesn't have permission |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists |
| 413 | Payload Too Large | File size exceeds limit |
| 422 | Unprocessable Entity | Validation failed |
| 500 | Internal Server Error | Server error |

### Flutter Error Handling

```dart
Future<Map<String, dynamic>> makeApiCall() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/some/endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired - refresh or redirect to login
      await refreshToken();
      return makeApiCall(); // Retry
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Unknown error');
    }
  } on SocketException {
    throw Exception('No internet connection');
  } on TimeoutException {
    throw Exception('Request timeout');
  } catch (e) {
    rethrow;
  }
}
```

---

## Pagination & Filtering

Most list endpoints support pagination using query parameters:

**Query Parameters:**
- `limit`: Number of items per page (default: 20)
- `offset`: Skip number of items (default: 0)

**Example:**
```
GET /api/v1/events?limit=20&offset=0  # First page
GET /api/v1/events?limit=20&offset=20 # Second page
GET /api/v1/events?limit=20&offset=40 # Third page
```

**Response Format:**
```json
{
  "data": [...],
  "total": 100,
  "limit": 20,
  "offset": 0
}
```

**Flutter Pagination Example:**
```dart
class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<dynamic> events = [];
  int offset = 0;
  final int limit = 20;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events?limit=$limit&offset=$offset'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newEvents = data['events'] as List;

        setState(() {
          events.addAll(newEvents);
          offset += limit;
          hasMore = newEvents.length == limit;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == events.length) {
          loadEvents();
          return Center(child: CircularProgressIndicator());
        }
        return EventCard(event: events[index]);
      },
    );
  }
}
```

---

## Date Format

All timestamps use **RFC3339 format** (ISO 8601):

```
2025-11-18T10:00:00Z
```

**Flutter Examples:**

```dart
// Parse from API
final createdAt = DateTime.parse('2025-11-18T10:00:00Z');

// Format for API
final startTime = DateTime.now().toIso8601String();

// Custom formatting
import 'package:intl/intl.dart';

final formatted = DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
// Output: "Nov 18, 2025 10:00"
```

---

## Flutter Integration Examples

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
    final headers = {'Content-Type': 'application/json'};

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
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await secureStorage.write(key: 'auth_token', value: data['access_token']);
      await secureStorage.write(key: 'refresh_token', value: data['refresh_token']);
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    }
  }

  // Get events
  Future<List<dynamic>> getEvents({
    String? category,
    bool? isFree,
    int limit = 20,
    int offset = 0,
  }) async {
    var queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (isFree != null) queryParams['is_free'] = isFree.toString();

    final uri = Uri.parse('$baseUrl/events').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders(includeAuth: false));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['events'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    }
  }

  // Get nearby events
  Future<List<dynamic>> getNearbyEvents({
    required double lat,
    required double lng,
    int radius = 5000,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/events/nearby').replace(queryParameters: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radius.toString(),
      'limit': limit.toString(),
    });

    final response = await http.get(uri, headers: await _getHeaders(includeAuth: false));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['events'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    }
  }

  // Create event
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required double latitude,
    required double longitude,
    required String category,
    int? maxAttendees,
    int? price,
    String? imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: await _getHeaders(),
      body: json.encode({
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'max_attendees': maxAttendees,
        'price': price,
        'image_url': imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    }
  }

  // Upload image
  Future<String> uploadImage(File imageFile) async {
    final token = await secureStorage.read(key: 'auth_token');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/image'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error']);
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
      return data['posts'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    }
  }

  // Like post
  Future<void> likePost(String postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    }
  }
}
```

---

## Important Notes for Frontend Developers

### 1. DO NOT Generate IDs on Frontend

❌ **WRONG:**
```dart
final eventId = Uuid().v4(); // Don't do this!
await createEvent(id: eventId, title: 'Event');
```

✅ **CORRECT:**
```dart
final event = await createEvent(title: 'Event');
final eventId = event['id']; // Use backend-generated ID
```

### 2. Always Include Authorization Header

For protected endpoints, always include the JWT token:

```dart
headers: {
  'Authorization': 'Bearer $token',
}
```

### 3. Image Upload Flow

Always upload images BEFORE creating posts/events:

```dart
// 1. Upload image first
String imageUrl = await uploadImage(file);

// 2. Then create event with the URL
await createEvent(title: '...', imageUrl: imageUrl);
```

### 4. Field Names

Pay attention to field names:
- Use `full_name` (not `name`)
- Use `id_token` for Google auth (not `token`)
- Use `lat`, `lng` for nearby events (not `latitude`, `longitude`)

### 5. Event Categories

Use the exact category values:
- `music`, `sports`, `tech`, `arts`, `food`, `education`, `business`, `other`

### 6. Nearby Events Radius

The `radius` parameter is in **meters**, not kilometers:

```dart
// 5km radius
await getNearbyEvents(lat: -6.2088, lng: 106.8456, radius: 5000);
```

---

## Environment Variables

For backend setup:

```bash
DATABASE_URL=postgresql://user:pass@localhost:5432/anigmaa
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_jwt_secret
GOOGLE_CLIENT_ID=your_google_client_id
MIDTRANS_SERVER_KEY=your_midtrans_key
MIDTRANS_IS_PRODUCTION=false
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email
SMTP_PASS=your_password
```

---

## Swagger Documentation

Interactive API documentation available at:

```
http://localhost:8081/swagger/index.html
```

---

## Support

For questions or issues:
1. Check the error response message
2. Verify your authentication token is valid
3. Check Swagger documentation
4. Contact the backend team

---

**Last Updated:** 2025-11-18
**API Version:** v1
**Maintained by:** Anigmaa Development Team
