# Frontend PR - Critical Production Fixes

## 🚨 CRITICAL ISSUES - Production Blockers

### Issue #1: Comments Not Loading on Return Visit ❌ CRITICAL
**Priority:** P0 - URGENT
**Impact:** Users cannot see comments when navigating back to a post they've already visited
**Location:** `lib/presentation/pages/post_detail/post_detail_screen.dart:49-53`

**Root Cause:**
The `LoadComments` event is dispatched in `initState()` using `addPostFrameCallback`, which only runs once when the widget is first created. When users navigate away and return, the widget may be reused from the navigation stack, so `initState()` doesn't run again.

**Current Code:**
```dart
@override
void initState() {
  super.initState();
  // ...
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      context.read<PostsBloc>().add(LoadComments(widget.post.id));
    }
  });
}
```

**Fix Required:**
1. **Option A (Recommended):** Move comment loading to `didChangeDependencies()` or use `didUpdateWidget()` to detect when the post changes
2. **Option B:** Clear the navigation stack when leaving post detail
3. **Option C:** Always reload comments when widget builds (check if not already loading)

**Fix Example:**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Check if comments are already loaded for this post
  final state = context.read<PostsBloc>().state;
  if (state is PostsLoaded) {
    final hasComments = state.commentsByPostId.containsKey(widget.post.id);
    if (!hasComments) {
      context.read<PostsBloc>().add(LoadComments(widget.post.id));
    }
  }
}
```

---

### Issue #2: Discover Page Showing Completed Events ❌ CRITICAL
**Priority:** P0 - URGENT
**Impact:** Users see stale/irrelevant past events in discover modes
**Location:** `lib/presentation/pages/discover/discover_screen.dart:303-306`

**Root Cause:**
Frontend has weak filtering that only excludes events ended >30 days ago. Backend has NO status filter in the SQL query, so it returns ALL events regardless of status.

**Current Code:**
```dart
// Filter out events that ended more than 30 days ago
final displayEvents = _allEvents.where((event) {
  final daysSinceEnd = now.difference(event.endTime).inDays;
  return daysSinceEnd < 30;  // ❌ Still shows events that ended <30 days ago
}).toList();
```

**Fix Required:**
1. **Remove frontend filtering** - Backend should handle this
2. **Wait for backend fix** to add status filter (see Backend PR)
3. **Temporary workaround** (if backend not ready):
```dart
final displayEvents = _allEvents.where((event) {
  return event.status == EventStatus.upcoming ||
         event.status == EventStatus.ongoing;
}).toList();
```

**Backend Dependency:** Backend must add `WHERE e.status IN ('upcoming', 'ongoing')` to event queries (see Backend PR #2)

---

### Issue #3: Explore Page No Event Filtering ⚠️ HIGH
**Priority:** P1 - HIGH
**Impact:** Event search page shows completed events
**Location:** `lib/presentation/pages/explore/explore_screen.dart:38-83`

**Root Cause:**
Similar to Issue #2, the explore page has no status filtering. All events from backend are displayed.

**Fix Required:**
Same as Issue #2 - either wait for backend fix or add temporary filter:
```dart
void _applyFilters() {
  setState(() {
    _filteredEvents = _allEvents.where((event) {
      // Add status filter
      if (event.status != EventStatus.upcoming &&
          event.status != EventStatus.ongoing) {
        return false;
      }

      // ... existing filters ...
      return true;
    }).toList();
  });
}
```

**Backend Dependency:** Backend must add status filter (see Backend PR #2)

---

## ⚠️ MEDIUM PRIORITY ISSUES

### Issue #4: API Fetch Errors (False Alarm) ✅ RESOLVED
**Priority:** P2 - MEDIUM
**Impact:** Minimal - graceful fallback already implemented
**Location:** Multiple data sources

**Status:** ✅ **NOT AN ISSUE** - APIs are correctly aligned

**Investigation Results:**
- ✅ Community endpoints match: `/communities`, `/communities/my-communities`, `/communities/:id/join`
- ✅ Profile endpoints match: `/profile/:username`, `/users/:id/followers`, `/users/:id/stats`
- ✅ Event endpoints match: `DELETE /events/:id/join` for leaving events

**Code Quality:**
The frontend has excellent error handling with fallbacks:
```dart
// Example from community_remote_datasource.dart:249-252
if (e.response?.statusCode == 500) {
  print('[CommunityRemoteDataSource] Backend error (500) - returning empty list');
  return [];
}
```

**Recommendation:** Keep existing error handling, no changes needed

---

## 📋 PR CHECKLIST

### Required Changes:
- [ ] **CRITICAL:** Fix comment loading in post detail screen (Issue #1)
- [ ] **CRITICAL:** Add status filter to discover page OR wait for backend fix (Issue #2)
- [ ] **HIGH:** Add status filter to explore page OR wait for backend fix (Issue #3)

### Testing Requirements:
- [ ] Test comment loading: Open post → navigate away → return → verify comments appear
- [ ] Test discover page: Verify no completed events shown
- [ ] Test explore page: Verify no completed events shown
- [ ] Test navigation: Ensure all filters work after navigation

### Code Quality:
- [ ] No console.log or print statements in production code
- [ ] Error handling maintains user experience
- [ ] Loading states properly managed

---

## 🎯 ACCEPTANCE CRITERIA

**Issue #1 - Comments:**
- [ ] Comments load on first visit to post detail
- [ ] Comments load on subsequent visits to same post
- [ ] No duplicate API calls when comments already loaded
- [ ] Loading state shows while fetching comments

**Issue #2 & #3 - Event Filtering:**
- [ ] Only upcoming and ongoing events shown in discover page
- [ ] Only upcoming and ongoing events shown in explore page
- [ ] Completed events properly hidden
- [ ] No flickering or UI jumps when filtering

---

## 📝 NOTES FOR FRONTEND TEAM

1. **Issue #1 is INDEPENDENT** - Can be fixed immediately without backend changes
2. **Issues #2 & #3 require coordination** - Backend fix is more robust, but temporary frontend fix is acceptable
3. **Backend team is fixing event filtering** - See Backend PR for details
4. **No API mismatches found** - Good job on API alignment!

---

**Generated:** 2025-01-19
**Reviewer:** CTO Review
**Status:** READY FOR IMPLEMENTATION
**Estimated Effort:** 4-6 hours
