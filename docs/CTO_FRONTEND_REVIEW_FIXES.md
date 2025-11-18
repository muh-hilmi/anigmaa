# CTO Frontend Review - Fixes & Recommendations

**Date:** 2025-11-18
**Status:** In Progress
**Branch:** `claude/review-cto-frontend-notes-011GMpn5s7TYAPKfN4N4uV5N`

---

## ✅ COMPLETED FIXES

### 1. JSON Field Naming Standardization (BLOCKER 3 - Partial)

**Issue:** Frontend models were using camelCase for JSON field names while backend returns snake_case, causing data to always fall back to default values.

**Files Fixed:**
- `lib/data/models/user_model.dart`
- `lib/data/models/ticket_model.dart`
- `lib/data/models/post_model.dart`
- `lib/data/models/transaction_model.dart`

**Impact:**
- User settings now correctly persist (dark mode, notifications, etc.)
- Profile stats display actual data instead of showing 0
- Transaction data properly parsed
- Ticket data correctly populated

**Commit:** `2906a1e - fix: Standardize JSON field naming to snake_case in all models`

---

### 2. CreatePost Type Detection (BLOCKER 3)

**Issue:** When user selects an event to tag, the post type was not being set to `PostType.textWithEvent`, so `attached_event_id` was sent even for non-event posts.

**Fix:** Updated `lib/presentation/pages/create_post/create_post_screen.dart` to properly detect post type:
```dart
// Now correctly sets type to textWithEvent when event is selected
if (_selectedEvent != null) {
  type = PostType.textWithEvent;
} else if (_selectedImages.isNotEmpty) {
  type = PostType.textWithImages;
}
```

**Impact:**
- Backend now receives correct post type
- `attached_event_id` only sent when type is `textWithEvent`
- Fixes API contract mismatch

---

### 3. Event Status Enum Mismatch (BLOCKER 3)

**Issue:** Backend sends "completed" but frontend enum uses "ended", causing status parsing to fail and fall back to "upcoming".

**Fix:** Added `_parseEventStatus()` helper method in `lib/data/models/event_model.dart`:
```dart
static EventStatus _parseEventStatus(String? status) {
  final statusLower = status.toLowerCase();
  // Handle both "completed" from backend and "ended" from frontend
  if (statusLower == 'completed' || statusLower == 'ended') {
    return EventStatus.ended;
  }
  // ... rest of parsing logic
}
```

**Impact:**
- Events correctly show as "ended" when backend sends "completed"
- Prevents events from incorrectly showing as "upcoming" when they've ended

---

## ⚠️ IDENTIFIED BLOCKERS REQUIRING BACKEND WORK

### BLOCKER 2: Social Interactions (Backend Priority)

**Scope:** 14 repository methods are stubs
**Components Affected:**
- Like/Unlike functionality
- Bookmark feature
- Repost feature
- Comment Create/Edit/Delete

**Frontend Status:** UI components exist, but all interaction methods in repository are placeholder stubs.

**Action Required:**
1. Backend team must implement API endpoints for:
   - `POST /posts/{id}/like`
   - `DELETE /posts/{id}/like`
   - `POST /posts/{id}/bookmark`
   - `POST /posts/{id}/repost`
   - `POST /posts/{id}/comments`
   - `PUT /comments/{id}`
   - `DELETE /comments/{id}`

2. Frontend follow-up (after backend complete):
   - Connect repository methods to actual API endpoints
   - Remove stub implementations
   - Test optimistic UI updates
   - Sync interaction counters with backend events

---

### BLOCKER 4: Auth Flow (Backend + Frontend)

**Missing Backend Endpoints:**
- `POST /auth/verify-email` (verify token)
- `POST /auth/forgot-password` (send reset email)
- `POST /auth/reset-password` (validate token + update password)
- `POST /auth/resend-verification`

**Frontend Work Needed (after backend):**
- Create email verification screen
- Create forgot password screen
- Create reset password screen
- Integrate with auth BLoC
- Add email verification reminder UI

---

### BLOCKER 7: Missing Backend Endpoints

**Required Endpoints:**
- `GET /events/hosted` - Get events hosted by current user
- `POST /auth/change-password` - Change password (authenticated)
- `GET /tickets/transactions/:id` - Get transaction details
- `POST /auth/resend-verification` - Resend verification email

**Frontend Impact:** Several screens are blocked without these endpoints:
- Host Dashboard cannot load user's hosted events
- Profile settings cannot change password
- Transaction detail view cannot load
- Email verification flow incomplete

---

## 🚨 BLOCKER 5: Mock Data Removal (Frontend Priority)

**Status:** Analyzed, work in progress

### Screens Using Mock Data:

#### 1. Notifications Screen (`lib/presentation/pages/notifications/notifications_screen.dart`)
**Current State:** Completely hardcoded with mock notifications
```dart
// Line 15: final List<NotificationItem> _mockNotifications = [];
// Line 23-76: _initializeMockData() creates 5 hardcoded notifications
```

**Work Required:**
- [ ] Create Notification entity & model
- [ ] Create NotificationRepository with API datasource
- [ ] Create NotificationsBloc for state management
- [ ] Create API endpoint: `GET /notifications`
- [ ] Update UI to use BLoC pattern
- [ ] Implement mark-as-read functionality
- [ ] Implement filter logic on backend

**Effort:** Medium (8-12 hours)

---

#### 2. Transaction History Screen (`lib/presentation/pages/transactions/transaction_history_screen.dart`)
**Current State:** Uses mock data
```dart
// Line 18: final List<Transaction> _mockTransactions = [];
// Line 33-150: _initializeMockData() creates hardcoded transactions
```

**Work Required:**
- [ ] Create TransactionRepository with API datasource
- [ ] Create TransactionsBloc
- [ ] Create API endpoint: `GET /transactions` (user's transactions)
- [ ] Create API endpoint: `GET /events/{id}/transactions` (event revenue)
- [ ] Update UI to use BLoC pattern
- [ ] Implement filter/tab logic

**Effort:** Medium (6-10 hours)

---

#### 3. My Tickets Screen (`lib/presentation/pages/tickets/my_tickets_screen.dart`)
**Current State:** ✅ **ALREADY USING BLOC!**
```dart
// Uses TicketsBloc, TicketsState, TicketsEvent
// Properly implements BLoC pattern
```

**Work Required:**
- [ ] Verify TicketsBloc is connected to real API (not stub)
- [ ] Test with real backend data
- [ ] Verify pagination works

**Effort:** Low (1-2 hours) - Just needs verification

---

#### 4. Profile Posts & Events
**Files:**
- `lib/presentation/pages/profile/profile_screen.dart`
- `lib/presentation/pages/social/user_profile_screen.dart`

**Current State:** Needs analysis

**Work Required:**
- [ ] Analyze current data source
- [ ] Create API endpoints: `GET /users/{id}/posts`, `GET /users/{id}/events`
- [ ] Connect to PostsBloc and EventsBloc
- [ ] Implement pagination

**Effort:** Medium (6-8 hours)

---

#### 5. Host Dashboard (Analytics)
**File:** Unknown - needs to be located

**Work Required:**
- [ ] Locate host dashboard screen
- [ ] Analyze current implementation
- [ ] Create API endpoint: `GET /host/analytics`
- [ ] Create AnalyticsBloc
- [ ] Update UI to display real revenue, attendee counts, etc.

**Effort:** High (12-16 hours) - Complex analytics logic

---

## 🔄 BLOCKER 6: Pagination Metadata (Backend + Frontend)

**Issue:** List endpoints don't return pagination metadata

**Backend Required:**
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "total": 150,
    "limit": 20,
    "offset": 0,
    "hasNext": true
  }
}
```

**Frontend Work Required:**
- [ ] Update all repository methods to parse `meta` field
- [ ] Update all BLoCs to handle pagination metadata
- [ ] Update infinite scroll widgets to use `hasNext` instead of guessing
- [ ] Add loading indicators for "load more"

**Affected Files:**
- `lib/data/repositories/post_repository_impl.dart`
- `lib/data/repositories/event_repository_impl.dart`
- `lib/data/repositories/community_repository_impl.dart`
- `lib/presentation/bloc/posts/posts_bloc.dart`
- `lib/presentation/bloc/events/events_bloc.dart`
- All list/feed screens

**Effort:** Medium-High (10-14 hours)

---

## 📋 PRIORITY RECOMMENDATIONS

### High Priority (Blocking Production Launch)
1. ✅ **JSON Field Naming** - DONE
2. ✅ **Event Status Parsing** - DONE
3. ✅ **CreatePost Type Detection** - DONE
4. **BLOCKER 4: Auth Flow** - Needs backend endpoints first
5. **BLOCKER 7: Missing Endpoints** - Backend team priority

### Medium Priority (Affects User Experience)
1. **BLOCKER 5: Remove Mock Data** - Can start on frontend while backend implements endpoints
2. **BLOCKER 6: Pagination Metadata** - Backend team should add to all list endpoints

### Lower Priority (Can be done post-MVP)
1. **BLOCKER 2: Social Interactions** - Already has UI, just needs API connection

---

## 🎯 NEXT STEPS

### For Backend Team:
1. Implement missing auth endpoints (BLOCKER 4)
2. Implement missing endpoints (BLOCKER 7)
3. Add pagination metadata to all list endpoints (BLOCKER 6)
4. Implement social interaction endpoints (BLOCKER 2)
5. Create notifications API endpoint

### For Frontend Team:
1. ✅ Complete snake_case model fixes
2. ✅ Fix CreatePost type detection
3. ✅ Fix Event status parsing
4. Remove mock data from NotificationsScreen (can stub API calls)
5. Remove mock data from TransactionHistoryScreen (can stub API calls)
6. Verify My Tickets Screen API connection
7. Update pagination logic to use metadata (after backend implements)
8. Implement auth flow screens (after backend implements endpoints)

### For DevOps/QA:
1. Test all snake_case field changes against staging backend
2. Verify event status handling with real data
3. Test post creation with event tagging
4. Prepare test data for notifications, transactions, analytics

---

## 📊 ESTIMATED TIMELINE

### Week 1 (Current Week)
- [x] Fix snake_case field naming issues
- [x] Fix event status enum mismatch
- [x] Fix CreatePost type detection
- [ ] Remove mock data from Notifications (stub API)
- [ ] Remove mock data from Transactions (stub API)

### Week 2
- [ ] Backend: Implement auth endpoints
- [ ] Backend: Implement missing endpoints
- [ ] Frontend: Create auth flow screens
- [ ] Frontend: Connect to new endpoints

### Week 3
- [ ] Backend: Add pagination metadata
- [ ] Frontend: Update pagination logic
- [ ] Backend: Implement social interaction endpoints
- [ ] Frontend: Connect interaction methods to API

### Week 4 (Final Polish)
- [ ] QA testing all features
- [ ] Fix bugs found in testing
- [ ] Performance optimization
- [ ] Production deployment

---

## 🔍 CODE QUALITY NOTES

### Good Patterns Observed:
- ✅ Clean Architecture (domain/data/presentation layers)
- ✅ BLoC pattern for state management
- ✅ Dependency injection with get_it
- ✅ Repository pattern for data access
- ✅ Proper error handling with Either<Failure, Success>

### Areas for Improvement:
- ⚠️ Inconsistent use of BLoC (some screens use mock data directly)
- ⚠️ Some repository methods are stubs
- ⚠️ Missing integration tests
- ⚠️ API client could use better error handling
- ⚠️ Missing offline support/caching strategy

---

**Last Updated:** 2025-11-18
**Reviewed By:** Claude (Frontend Developer)
**Next Review:** After backend endpoints are implemented
