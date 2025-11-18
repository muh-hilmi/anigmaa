# Master Implementation Roadmap - Anigmaa

**Last Updated:** 2025-01-18
**Total Effort:** 140-180 hours (~18-23 days of work)
**Timeline:** 6-8 weeks with 1-2 developers

---

## 📊 Executive Summary

### Current Status

| Category | Complete | In Progress | Blocked | Total |
|----------|---------|-------------|---------|-------|
| **Frontend Blockers** | 4 | 0 | 3 | 7 |
| **Backend Blockers** | 0 | 0 | 7 | 7 |
| **Security** | 0 | 0 | 7 | 7 |
| **Data Integrity** | 0 | 0 | 5 | 5 |
| **UX Polish** | 0 | 0 | 5 | 5 |
| **Performance** | 0 | 0 | 4 | 4 |

### Frontend Work (Anigmaa Flutter App)
✅ **Complete:** 4 of 7 blockers (57%)
- BLOCKER 3: API Contract Fixes (100%)
- BLOCKER 5: Mock Data Removal (100%)
- BLOCKER 6: Pagination Infrastructure (100%)
- ~BLOCKER 1: Partial (frontend structure done, needs backend)~

⏳ **Waiting for Backend:** 3 blockers
- BLOCKER 1: Monetization (needs backend API + Midtrans)
- BLOCKER 2: Social Features (needs 14 backend endpoints)
- BLOCKER 4: Auth Flow (needs 4 backend endpoints)
- BLOCKER 7: Missing Features (needs 4 backend endpoints)

### Backend Work (Needs Implementation)
❌ **Not Started:** All backend work
- This repo is **frontend-only** (Flutter/Dart)
- Backend API needs to be implemented separately
- Estimated: 100-130 hours of backend work

---

## 🎯 Priority Matrix

```
HIGH PRIORITY (Sprint 1-2)              MEDIUM PRIORITY (Sprint 3-4)
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│ 1. BLOCKER 1 - Monetization     │    │ 5. BLOCKER 7 - Missing Features │
│    Backend: 40-50h               │    │    Backend: 8-12h               │
│    Frontend: 20-30h              │    │    Frontend: 6-10h              │
│    Impact: Revenue generation    │    │    Impact: User features        │
│                                  │    │                                 │
│ 2. Security Fixes                │    │ 6. UX & Product Polish          │
│    Backend: 16-22h               │    │    Backend: 4-6h                │
│    Impact: Production safety     │    │    Frontend: 12-16h             │
│                                  │    │    Impact: User experience      │
│ 3. BLOCKER 2 - Social Features   │    └─────────────────────────────────┘
│    Backend: 12-16h               │
│    Frontend: 8-12h               │    LOW PRIORITY (Sprint 5-6)
│    Impact: Engagement            │    ┌─────────────────────────────────┐
│                                  │    │ 7. Performance & Monitoring     │
│ 4. BLOCKER 4 - Auth Flow         │    │    Backend: 8-12h               │
│    Backend: 8-10h                │    │    Impact: Observability        │
│    Frontend: 4-6h                │    │                                 │
│    Impact: User onboarding       │    │ 8. Unit Tests                   │
└─────────────────────────────────┘    │    Backend: 6-8h                │
                                        │    Frontend: 4-6h               │
                                        │    Impact: Code quality         │
                                        └─────────────────────────────────┘
```

---

## 📅 Sprint Breakdown (6-8 weeks)

### SPRINT 1 (Week 1-2): Foundation & Monetization
**Goal:** Get ticket system working end-to-end

#### Backend Tasks (40-50 hours)
- [ ] **Setup ticket database schema** (2h)
  - Create `tickets` table
  - Create `ticket_transactions` table
  - Add foreign keys and indexes

- [ ] **Implement ticket API endpoints** (12-16h)
  - `GET /events/:id/tickets` - Get event tickets
  - `GET /tickets/:id` - Get ticket details
  - `POST /tickets/purchase` - Purchase ticket
  - `GET /tickets/my-tickets` - Get user's tickets
  - `GET /tickets/transactions/:id` - Get transaction
  - `POST /tickets/check-in` - Check in ticket
  - `POST /tickets` - Create ticket (admin)
  - `PUT /tickets/:id` - Update ticket
  - `POST /tickets/:id/cancel` - Cancel ticket

- [ ] **Setup Midtrans account** (1-2h)
  - Sign up for Midtrans
  - Get sandbox credentials
  - Configure notification URL

- [ ] **Integrate Midtrans Snap API** (4-6h)
  - Install Midtrans SDK
  - Implement token generation endpoint
  - Test payment flow

- [ ] **Implement webhook handler** (8-10h) 🔥 **CRITICAL**
  - Create `POST /api/payment/notification`
  - Verify signature
  - Handle payment status updates
  - Implement idempotency
  - Add transaction logging

- [ ] **Implement security basics** (8-10h)
  - Setup Redis for rate limiting
  - Add rate limits to auth endpoints
  - Add CSRF protection
  - Secure email verification endpoint
  - Secure password reset endpoint

#### Frontend Tasks (20-30 hours)
- [ ] **Update TicketRepositoryImpl** (4-6h)
  - Call remoteDataSource instead of localDataSource
  - Implement fallback to cache on network error
  - Handle all ticket operations via API

- [ ] **Integrate Midtrans Flutter SDK** (8-12h)
  - Add `midtrans_sdk` dependency
  - Update PaymentService to use real Midtrans
  - Implement Snap payment UI flow
  - Handle payment success/failure
  - Test with sandbox

- [ ] **Update My Tickets screen** (4-6h)
  - Load event data for each ticket
  - Update TicketsBloc to fetch event details
  - Replace "Nama Event" placeholder with real data
  - Add error handling for missing events

- [ ] **Add QR code display** (3-4h) [Optional]
  - Add `qr_flutter` dependency
  - Generate QR from attendance code
  - Display in TicketDetailScreen

- [ ] **Error handling & polish** (2-3h)
  - Add loading states
  - Handle payment errors
  - Add retry buttons
  - Consistent error messages

**Sprint 1 Deliverable:** ✅ Working ticket purchase and payment system

---

### SPRINT 2 (Week 3-4): Social Features & Auth
**Goal:** Complete user engagement features

#### Backend Tasks (20-26 hours)
- [ ] **Implement social interaction endpoints** (12-16h)
  - `POST /posts/:id/like` - Like a post
  - `DELETE /posts/:id/like` - Unlike a post
  - `POST /posts/:id/bookmark` - Bookmark post
  - `DELETE /posts/:id/bookmark` - Remove bookmark
  - `POST /posts/:id/repost` - Repost
  - `DELETE /posts/:id/repost` - Delete repost
  - `GET /posts/:id/comments` - Get comments (with pagination)
  - `POST /posts/:id/comments` - Add comment
  - `PUT /comments/:id` - Update comment
  - `DELETE /comments/:id` - Delete comment
  - `POST /comments/:id/like` - Like comment
  - `DELETE /comments/:id/like` - Unlike comment
  - `POST /users/:id/follow` - Follow user
  - `DELETE /users/:id/follow` - Unfollow user

- [ ] **Implement auth flow endpoints** (8-10h)
  - `POST /auth/send-verification` - Resend email verification
  - `POST /auth/forgot-password` - Request password reset
  - `POST /auth/reset-password` - Reset password with token
  - `POST /users/change-password` - Change password (authenticated)

- [ ] **Data integrity improvements** (6-8h)
  - Add cascade delete rules
  - Implement transactional event join
  - Add row-level locking for counters
  - Add validation layer for tickets

#### Frontend Tasks (12-18 hours)
- [ ] **Implement social features** (8-12h)
  - Connect like buttons to API
  - Connect bookmark buttons to API
  - Connect repost buttons to API
  - Connect comment forms to API
  - Implement optimistic updates
  - Add real-time sync (polling or WebSocket)

- [ ] **Implement auth flows** (4-6h)
  - Email verification screen
  - Forgot password flow
  - Reset password screen
  - Change password in settings

**Sprint 2 Deliverable:** ✅ Social interactions + complete auth flows working

---

### SPRINT 3 (Week 5): Security & Data Integrity
**Goal:** Production-ready security and data safety

#### Backend Tasks (18-24 hours)
- [ ] **Complete security fixes** (8-12h)
  - XSS prevention (HTML sanitization)
  - Fix SQL injection risks (fmt.Sprintf)
  - Setup secret vault (HashiCorp Vault)
  - Implement secret rotation guidelines
  - Add security headers (HSTS, CSP, X-Frame-Options)

- [ ] **Data integrity hardening** (8-10h)
  - Idempotent webhook handling
  - Payment-ticket atomicity
  - Race condition testing
  - Database constraints
  - Audit logging

- [ ] **Testing & validation** (4-6h)
  - Load test ticket purchase
  - Test concurrent event joins
  - Test webhook replay attacks
  - Validate all input data

#### Frontend Tasks (4-6 hours)
- [ ] **Security improvements** (2-3h)
  - Implement CSRF token handling
  - Secure token storage (flutter_secure_storage)
  - Add biometric authentication option

- [ ] **Error handling polish** (2-3h)
  - Consistent error messages
  - Network error handling
  - Offline mode improvements

**Sprint 3 Deliverable:** ✅ Production-ready security and data integrity

---

### SPRINT 4 (Week 6): Missing Features & UX
**Goal:** Complete feature set and polish UX

#### Backend Tasks (12-18 hours)
- [ ] **Missing feature endpoints** (8-12h)
  - `GET /events/hosted` - Get hosted events
  - `GET /events/joined` - Get joined events
  - `POST /users/change-password` - Change password
  - `GET /posts/bookmarked` - Get bookmarked posts

- [ ] **Analytics endpoints** (4-6h)
  - `GET /events/:id/analytics` - Event analytics for host
  - `GET /users/:id/stats` - User statistics
  - Aggregate data queries

#### Frontend Tasks (18-24 hours)
- [ ] **Missing features** (6-10h)
  - Hosted events screen
  - Joined events screen
  - Bookmarked posts screen
  - Change password screen

- [ ] **UX improvements** (12-14h)
  - Real-time status sync for likes/comments
  - Profile UI with real stats
  - Host dashboard with real analytics
  - Loading states everywhere
  - Pull-to-refresh on lists
  - Empty states
  - Error states with retry

**Sprint 4 Deliverable:** ✅ Complete feature set with polished UX

---

### SPRINT 5 (Week 7): Performance & Monitoring [Optional]
**Goal:** Optimize performance and add observability

#### Backend Tasks (14-18 hours)
- [ ] **Redis caching** (6-8h)
  - Cache feed queries
  - Cache nearby events
  - Implement cache invalidation
  - Monitor cache hit rate

- [ ] **Monitoring setup** (4-6h)
  - Setup ELK stack (Elasticsearch, Logstash, Kibana)
  - Configure log aggregation
  - Create Grafana dashboards
  - Add alerts for errors

- [ ] **Performance profiling** (2-3h)
  - Add response time logging
  - Identify slow queries
  - Optimize N+1 queries
  - Add database indexes

- [ ] **Unit tests** (6-8h)
  - Test ticket service (80% coverage)
  - Test payment service (80% coverage)
  - Test social features (60% coverage)
  - Test auth service (70% coverage)

#### Frontend Tasks (4-6 hours)
- [ ] **Performance optimization** (2-3h)
  - Image caching
  - List view optimization
  - Reduce rebuilds

- [ ] **Unit tests** (4-6h)
  - Test BLoCs (70% coverage)
  - Test repositories (60% coverage)
  - Widget tests for key screens

**Sprint 5 Deliverable:** ✅ Optimized performance and monitoring

---

### SPRINT 6 (Week 8): Production Deployment
**Goal:** Deploy to production

#### Tasks (10-15 hours)
- [ ] **Backend deployment** (4-6h)
  - Deploy to production server
  - Setup production database
  - Configure environment variables
  - Setup SSL certificates
  - Configure DNS

- [ ] **Midtrans production** (2-3h)
  - Switch to production keys
  - Update webhook URL
  - Test with real payment methods

- [ ] **Frontend release** (2-3h)
  - Build production APK/IPA
  - Submit to Play Store
  - Submit to App Store
  - Configure analytics

- [ ] **Final testing** (2-3h)
  - End-to-end testing
  - Payment flow testing
  - User acceptance testing

**Sprint 6 Deliverable:** ✅ Production release

---

## 📈 Effort Summary by Role

### Backend Developer
| Sprint | Hours | Focus |
|--------|-------|-------|
| Sprint 1 | 40-50h | Tickets + Payment + Security basics |
| Sprint 2 | 20-26h | Social + Auth + Data integrity |
| Sprint 3 | 18-24h | Security hardening + Testing |
| Sprint 4 | 12-18h | Missing features + Analytics |
| Sprint 5 | 14-18h | Performance + Monitoring |
| Sprint 6 | 4-6h | Deployment |
| **Total** | **108-142h** | ~14-18 days |

### Frontend Developer
| Sprint | Hours | Focus |
|--------|-------|-------|
| Sprint 1 | 20-30h | Ticket UI + Midtrans integration |
| Sprint 2 | 12-18h | Social features + Auth flows |
| Sprint 3 | 4-6h | Security + Error handling |
| Sprint 4 | 18-24h | Missing features + UX polish |
| Sprint 5 | 4-6h | Performance + Tests |
| Sprint 6 | 2-3h | Release |
| **Total** | **60-87h** | ~8-11 days |

---

## 🎯 Success Metrics

### Week 2 (After Sprint 1)
- [ ] Users can purchase tickets via Midtrans
- [ ] Payments processed correctly
- [ ] Tickets visible in My Tickets screen
- [ ] Rate limiting active on all endpoints

### Week 4 (After Sprint 2)
- [ ] Users can like/comment/repost
- [ ] Users can follow other users
- [ ] Email verification works
- [ ] Password reset works

### Week 6 (After Sprint 3)
- [ ] All security fixes implemented
- [ ] No SQL injection vulnerabilities
- [ ] Webhook handling is idempotent
- [ ] All secrets in vault

### Week 8 (After Sprint 4)
- [ ] All 7 blockers resolved
- [ ] User stats accurate
- [ ] Host analytics functional
- [ ] UX polished

### Production (After Sprint 6)
- [ ] App live on stores
- [ ] Payments working in production
- [ ] Monitoring active
- [ ] No critical bugs

---

## 🚨 Critical Dependencies

### External Services
1. **Midtrans Account** - Sign up ASAP (Week 1)
2. **SSL Certificate** - For webhook URL (Week 1)
3. **Redis Server** - For rate limiting and caching (Week 1)
4. **Email Service** - For verification emails (Week 1)
5. **Database Server** - Production database (Week 1)

### Internal Dependencies
1. **Backend API** - Must be built (this repo is frontend-only)
2. **User Authentication** - Required for all features
3. **Event System** - Required for tickets
4. **Post System** - Required for social features

---

## 📚 Key Documents

### Implementation Guides
- [BLOCKER_1_MONETIZATION_ANALYSIS.md](./BLOCKER_1_MONETIZATION_ANALYSIS.md) - Ticket + Payment system
- [SECURITY_INTEGRITY_UX_REQUIREMENTS.md](./SECURITY_INTEGRITY_UX_REQUIREMENTS.md) - Security, Data Integrity, UX
- [BACKEND_REQUIREMENTS_SUMMARY.md](./BACKEND_REQUIREMENTS_SUMMARY.md) - All backend API requirements
- [CTO_FRONTEND_REVIEW_FIXES.md](./CTO_FRONTEND_REVIEW_FIXES.md) - Overall progress tracking

### Technical References
- [BLOCKER_6_PAGINATION_IMPLEMENTATION.md](./BLOCKER_6_PAGINATION_IMPLEMENTATION.md) - Pagination pattern
- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - API specifications

---

## 🎬 Getting Started

### For Backend Team
1. **Read:** [BLOCKER_1_MONETIZATION_ANALYSIS.md](./BLOCKER_1_MONETIZATION_ANALYSIS.md)
2. **Read:** [BACKEND_REQUIREMENTS_SUMMARY.md](./BACKEND_REQUIREMENTS_SUMMARY.md)
3. **Setup:** Database, Redis, Midtrans account
4. **Start:** Sprint 1 - Ticket API endpoints
5. **Test:** With Postman before frontend integration

### For Frontend Team
1. **Read:** [BLOCKER_1_MONETIZATION_ANALYSIS.md](./BLOCKER_1_MONETIZATION_ANALYSIS.md) (Frontend sections)
2. **Wait:** For backend API endpoints to be ready
3. **Test:** Backend endpoints with Postman
4. **Start:** Sprint 1 - Update repositories to use remote API
5. **Integrate:** Midtrans Flutter SDK

### For DevOps Team
1. **Setup:** Production servers (API, Database, Redis)
2. **Configure:** SSL certificates
3. **Setup:** ELK stack for logging (Sprint 5)
4. **Configure:** CI/CD pipelines
5. **Monitor:** Once deployed

---

## ⚠️ Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Midtrans integration complex | High | Start early (Sprint 1), use sandbox extensively |
| Webhook failures | High | Implement idempotency, logging, retry logic |
| Race conditions | Medium | Use transactions, row-level locks, extensive testing |
| API not ready | High | Backend team starts Sprint 1 immediately |
| Security vulnerabilities | Critical | Sprint 3 dedicated to security, external audit |
| Performance issues | Medium | Sprint 5 for optimization, load testing |

---

## 📞 Support & Questions

### For Implementation Questions
- **Monetization:** See [BLOCKER_1_MONETIZATION_ANALYSIS.md](./BLOCKER_1_MONETIZATION_ANALYSIS.md)
- **Security:** See [SECURITY_INTEGRITY_UX_REQUIREMENTS.md](./SECURITY_INTEGRITY_UX_REQUIREMENTS.md)
- **Backend APIs:** See [BACKEND_REQUIREMENTS_SUMMARY.md](./BACKEND_REQUIREMENTS_SUMMARY.md)

### For Midtrans Help
- Docs: https://docs.midtrans.com/
- Support: support@midtrans.com

### For Technical Decisions
- Consult CTO
- Review architecture docs
- Check Flutter best practices

---

**Status:** 📋 Ready to start implementation
**Next Step:** Backend team starts Sprint 1 (Ticket API + Midtrans)
**ETA to Production:** 6-8 weeks with full team
