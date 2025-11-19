# Backend API Documentation - Anigmaa

## 🔐 Authentication (Google Sign-In Only)

### POST `/auth/google`
**Authenticate user dengan Google ID Token**

**Request:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6..." // Google ID Token
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "uuid-string",
    "email": "user@gmail.com",
    "name": "John Doe",              // REQUIRED - dari Google
    "bio": null,
    "avatar_url": "https://...",      // optional
    "phone": null,
    "date_of_birth": null,            // ISO 8601 string atau null
    "gender": null,                   // "Laki-laki" | "Perempuan" | "Lainnya" | "Prefer not to say" | null
    "location": null,
    "interests": [],
    "is_verified": false,
    "is_email_verified": false,       // IMPORTANT: track email verification status
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "access_token": "jwt-token",
  "refresh_token": "refresh-token"
}
```

**Logic Backend:**
1. Verify Google ID token dengan Google API
2. Extract email & name dari Google token
3. Cek apakah user sudah ada (by email):
   - **Existing user:** return user data + tokens
   - **New user:**
     - Create user baru dengan name dari Google
     - Set `is_email_verified = false`
     - Send verification email
     - Return user data + tokens

**Notes:**
- ❌ NO username field (removed)
- ❌ NO password (Google Sign-In only)
- ✅ `name` field WAJIB dari Google (tidak bisa diubah user)
- ✅ Email verification REQUIRED untuk full access

---

## 👤 User Profile Management

### GET `/users/me`
**Get current authenticated user**

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "user@gmail.com",
  "name": "John Doe",
  "bio": "Event enthusiast 🎉",
  "avatar_url": "https://...",
  "phone": "08123456789",
  "date_of_birth": "1995-05-15",
  "gender": "Laki-laki",
  "location": "Jakarta, Indonesia",
  "interests": ["Music", "Sports", "Technology"],
  "is_verified": false,
  "is_email_verified": true,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "settings": {
    "push_notifications": true,
    "email_notifications": true,
    "dark_mode": false,
    "language": "id",
    "location_enabled": true,
    "show_online_status": true
  },
  "stats": {
    "events_attended": 10,
    "events_created": 5,
    "followers_count": 150,
    "following_count": 200,
    "reviews_given": 8,
    "average_rating": 4.5
  },
  "privacy": {
    "profile_visible": true,
    "events_visible": true,
    "allow_followers": true,
    "show_email": false,
    "show_location": true
  }
}
```

---

### PUT `/users/me`
**Update current user profile**

**Headers:**
```
Authorization: Bearer {access_token}
```

**Request Body:**
```json
{
  // Personal Info (optional)
  "bio": "Event enthusiast 🎉",
  "avatar_url": "https://storage.../avatar.jpg",  // after upload to cloud storage

  // Essential Fields (recommended after first login)
  "phone": "08123456789",
  "date_of_birth": "1995-05-15",                   // YYYY-MM-DD format
  "gender": "Laki-laki",                           // "Laki-laki" | "Perempuan" | "Lainnya" | "Prefer not to say"
  "location": "Jakarta, Indonesia",

  // Interests (for event recommendations)
  "interests": ["Music", "Sports", "Technology"]
}
```

**Response (200 OK):**
```json
{
  // Same as GET /users/me with updated data
}
```

**Validation Rules:**
- `bio`: max 150 characters
- `phone`: digits only, 10-15 characters
- `date_of_birth`: valid date, user must be 13+ years old
- `gender`: enum values only
- `interests`: array of strings, max 20 items
- ❌ `name` CANNOT be updated (from Google only)
- ❌ `email` CANNOT be updated (from Google only)

---

## ✉️ Email Verification

### POST `/auth/verify-email`
**Verify user email dengan token dari email**

**Request:**
```json
{
  "token": "verification-token-from-email"
}
```

**Response (200 OK):**
```json
{
  "message": "Email verified successfully"
}
```

---

### POST `/auth/resend-verification`
**Resend verification email**

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response (200 OK):**
```json
{
  "message": "Verification email sent"
}
```

**Rate Limit:** Max 3 requests per hour per user

---

## 📋 User Model Schema

### Database Table: `users`

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,                    -- From Google, cannot be changed
  bio TEXT,
  avatar_url TEXT,

  -- Essential fields
  phone VARCHAR(20),
  date_of_birth DATE,
  gender VARCHAR(50),                            -- enum: Laki-laki, Perempuan, Lainnya, Prefer not to say
  location VARCHAR(255),

  -- Additional fields
  interests TEXT[],                              -- Array of interest categories
  is_verified BOOLEAN DEFAULT FALSE,
  is_email_verified BOOLEAN DEFAULT FALSE,       -- IMPORTANT: track verification status

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_email_verified ON users(is_email_verified);
CREATE INDEX idx_users_location ON users(location);
```

---

## 🔄 Migration from Old Schema

### Removed Fields:
- ❌ `username` - removed completely
- ❌ `password` - Google Sign-In only, no password needed

### Added Fields:
- ✅ `phone` - for emergency contact & WhatsApp notifications
- ✅ `date_of_birth` - for age verification & recommendations
- ✅ `gender` - for personalized event filtering
- ✅ `location` - for nearby events discovery

### Changed Fields:
- ✅ `name` - Now immutable (from Google only)
- ✅ `is_email_verified` - Important for access control

---

## 🚦 Access Control Rules

### Email Verification Required For:
- Creating events
- Joining paid events
- Posting reviews
- Sending direct messages

### Optional Features (No Verification Required):
- Browsing events
- Viewing user profiles
- Following users
- Saving events to favorites

**Implementation:**
```javascript
// Middleware example (Node.js/Express)
function requireEmailVerification(req, res, next) {
  if (!req.user.is_email_verified) {
    return res.status(403).json({
      error: 'Email verification required',
      message: 'Please verify your email to access this feature'
    });
  }
  next();
}

// Usage
app.post('/events', requireEmailVerification, createEvent);
```

---

## 📤 File Upload (Avatar)

### Recommended Flow:
1. Frontend gets signed upload URL from backend
2. Frontend uploads image directly to cloud storage (S3/GCS/Cloudinary)
3. Frontend sends final URL to backend via `PUT /users/me`

**Example (Node.js with AWS S3):**
```javascript
// POST /upload/avatar
router.post('/upload/avatar', async (req, res) => {
  const { filename, contentType } = req.body;

  const s3Params = {
    Bucket: process.env.S3_BUCKET,
    Key: `avatars/${req.user.id}/${Date.now()}-${filename}`,
    ContentType: contentType,
    Expires: 60, // URL valid for 60 seconds
  };

  const uploadURL = await s3.getSignedUrl('putObject', s3Params);

  res.json({ uploadURL });
});
```

---

## 🔍 Profile Completion Status

### Check if User Needs to Complete Profile:

**Frontend Logic:**
```typescript
function needsProfileCompletion(user: User): boolean {
  return !user.date_of_birth || !user.location;
}
```

**Backend Helper:**
```javascript
function hasCompletedEssentialProfile(user) {
  return user.date_of_birth && user.location;
}
```

**Required Fields:**
- ✅ `date_of_birth` (mandatory)
- ✅ `location` (mandatory)

**Recommended Fields:**
- 📱 `phone` (optional but recommended)
- 👤 `gender` (optional)
- ❤️ `interests` (min 3 for better recommendations)

---

## 📊 Event Recommendations Algorithm

### User Profile Data Usage:

**Essential for Recommendations:**
```javascript
{
  "date_of_birth": "1995-05-15",    // Age-based filtering (18+, family events, etc.)
  "location": "Jakarta, Indonesia", // Distance-based ranking
  "interests": ["Music", "Sports"], // Category matching
  "gender": "Laki-laki"             // Gender-specific events (optional)
}
```

**Recommendation Query Example:**
```sql
SELECT e.* FROM events e
WHERE e.category = ANY($1)                    -- Match interests
  AND ST_Distance(e.location, $2) < 50000     -- Within 50km
  AND (e.min_age <= $3 OR e.min_age IS NULL)  -- Age appropriate
  AND e.start_date > NOW()
ORDER BY
  -- Prioritize by match score
  (SELECT COUNT(*) FROM unnest(e.tags) tag
   WHERE tag = ANY($1)) DESC,                 -- Interest match count
  ST_Distance(e.location, $2) ASC,            -- Distance
  e.attendees_count DESC                      -- Popularity
LIMIT 50;
```

---

## 🔑 Key Differences from Traditional Auth:

| Feature | Traditional | Anigmaa (Google Only) |
|---------|-------------|----------------------|
| Username | ✅ Required | ❌ Removed |
| Password | ✅ Required | ❌ N/A (Google OAuth) |
| Email | User input | ✅ From Google |
| Name | User input | ✅ From Google (immutable) |
| Registration | Manual form | ✅ Auto on first Google login |
| Email Verification | Optional | ✅ Required for features |
| Password Reset | ✅ Needed | ❌ N/A |

---

## 🛡️ Security Notes:

1. **Google ID Token Verification:**
   ```javascript
   const { OAuth2Client } = require('google-auth-library');
   const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

   async function verifyGoogleToken(idToken) {
     const ticket = await client.verifyIdToken({
       idToken,
       audience: process.env.GOOGLE_CLIENT_ID,
     });
     const payload = ticket.getPayload();
     return {
       email: payload.email,
       name: payload.name,
       picture: payload.picture,
       emailVerified: payload.email_verified,
     };
   }
   ```

2. **JWT Token:** Include `is_email_verified` in JWT payload
3. **Rate Limiting:** Apply to email verification endpoints
4. **Data Validation:** Sanitize all user inputs

---

## 📝 Error Codes:

| Code | Scenario | Message |
|------|----------|---------|
| 401 | Invalid Google token | "Invalid or expired Google ID token" |
| 403 | Email not verified | "Email verification required" |
| 400 | Invalid profile data | "Invalid date of birth format" |
| 429 | Too many requests | "Too many verification emails sent" |
| 422 | Validation failed | "Phone number must be 10-15 digits" |

---

## ✅ Testing Checklist:

- [ ] Google Sign-In creates new user with email & name
- [ ] Existing user login returns correct data
- [ ] Email verification sends email correctly
- [ ] Profile update validates all fields
- [ ] `name` field cannot be updated (returns 400)
- [ ] Avatar upload flow works end-to-end
- [ ] Essential profile check works correctly
- [ ] Event recommendations use profile data
- [ ] Rate limiting on verification emails works

---

**Last Updated:** 2024-11-19
**API Version:** 1.0
**Flutter App Version:** Commit `6f04e99`
