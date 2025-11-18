# Backend Bugs & Issues

**Last Updated:** 2025-11-18

This document tracks backend bugs and issues that need to be fixed for the frontend to work properly.

---

## 🚨 CRITICAL BUGS

### 1. Communities API - Missing `creator_name` Field Mapping

**Endpoint:** `GET /communities/my-communities`

**Status:** 🔴 **CRITICAL** - Endpoint returning 500 error

**Error Message:**
```
Failed to get user communities
error: {
  code: INTERNAL_ERROR,
  details: missing destination name creator_name in *[]community.CommunityWithDetails
}
```

**Root Cause:**
The database query for `/communities/my-communities` is returning a `creator_name` field (likely from a JOIN with the users table), but the Go struct `CommunityWithDetails` doesn't have a corresponding field to receive this data.

**Impact:**
- Users cannot view their communities in the Communities tab
- Frontend is handling gracefully by showing empty list, but functionality is broken

**Fix Required:**
Add the `creator_name` field to the `CommunityWithDetails` struct in the backend:

```go
type CommunityWithDetails struct {
    ID           string    `json:"id" db:"id"`
    Name         string    `json:"name" db:"name"`
    Description  string    `json:"description" db:"description"`
    Category     string    `json:"category" db:"category"`
    CoverURL     string    `json:"cover_url" db:"cover_url"`
    AvatarURL    string    `json:"avatar_url" db:"avatar_url"`
    Location     string    `json:"location" db:"location"`
    MembersCount int       `json:"members_count" db:"members_count"`
    CreatedAt    time.Time `json:"created_at" db:"created_at"`
    Privacy      string    `json:"privacy" db:"privacy"`
    IsVerified   bool      `json:"is_verified" db:"is_verified"`

    // Add this field:
    CreatorName  string    `json:"creator_name" db:"creator_name"`

    // Or if the field should not be returned, remove it from the SQL query
}
```

**Alternative Fix:**
If `creator_name` is not needed in the response, remove it from the SQL query that fetches community data.

**Workaround (Frontend):**
The frontend datasource is already catching the 500 error and returning an empty list to prevent crashes. However, this is not a permanent solution.

**Priority:** HIGH - Users cannot see their communities

**Date Reported:** 2025-11-18

---

### 2. Posts API - 404 Error for User Posts

**Endpoint:** `GET /posts/user/{userId}`

**Status:** ⚠️ **MEDIUM** - Endpoint returning 404 for some users

**Error Message:**
```
404 page not found
```

**Example Request:**
```
GET /posts/user/1?page=1&limit=20
```

**Root Cause:**
The endpoint `/posts/user/{userId}` is returning 404 for user ID "1". This could mean:
- User ID "1" doesn't exist in the database
- The endpoint expects UUID format instead of numeric IDs
- The endpoint is not properly implemented

**Impact:**
- Users see empty posts list in their profile
- Frontend handles gracefully by showing "No posts" message

**Fix Required:**
1. Verify the endpoint exists and is properly configured
2. Check if user ID "1" exists in the database
3. Ensure the endpoint handles both numeric IDs and UUIDs if needed
4. Add proper error handling to return meaningful error messages

**Priority:** MEDIUM - Profile posts not showing for some users

**Date Reported:** 2025-11-18

---

## 📋 Notes for Backend Team

- The frontend Community model expects these fields: `id`, `name`, `description`, `category`, `cover_url`, `avatar_url`, `location`, `members_count`, `created_at`, `privacy`, `is_verified`
- See API specification in `request-api.txt` lines 437-462 for the expected response format
- Frontend is 100% ready and will work immediately once this backend issue is fixed
- The error occurs when a user navigates to the Communities tab in the app

---

## 🔧 Testing Instructions

After fixing:
1. Test the endpoint: `GET /communities/my-communities?limit=20&offset=0`
2. Verify it returns 200 status code
3. Verify the response matches the API specification format
4. Verify no database mapping errors in logs

---

## ✅ Fixed Bugs

(None yet)
