# Security, Data Integrity & UX Requirements

**Status:** 📋 **REQUIREMENTS DOCUMENTED**
**Total Effort:** ~50-70 hours
**Priority:** Sprint 1-3 based on criticality

---

## 📋 Table of Contents

1. [Security Fixes (Sprint 1)](#security-fixes)
2. [Data Integrity & Transactional Safety (Sprint 1-2)](#data-integrity)
3. [UX & Product Completion (Sprint 2)](#ux-product)
4. [Non-Critical but Important (Sprint 3)](#non-critical)

---

<a name="security-fixes"></a>
## 🔒 SECURITY FIXES (Sprint 1)

**Priority:** 🔥 **CRITICAL** - Must be implemented after core blockers
**Effort:** 16-22 hours
**Focus:** Prevent common OWASP Top 10 vulnerabilities

---

### 1. Rate Limiting (Redis-based) - 4-6 hours

**Problem:** No rate limiting = vulnerable to brute force, DDoS, spam

**Solution:** Implement Redis-based rate limiting per IP + route

#### Backend Implementation

**Install Dependencies:**
```bash
# Node.js
npm install express-rate-limit rate-limit-redis redis

# Go
go get github.com/go-redis/redis/v8
go get github.com/ulule/limiter/v3
```

**Configuration:**
```javascript
// Node.js + Express
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const redis = require('redis');

const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
});

// Global rate limit: 100 requests per 15 minutes per IP
const globalLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:global:',
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// Strict rate limit for authentication routes
const authLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:auth:',
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 login attempts per windowMs
  message: 'Too many login attempts, please try again later.',
  skipSuccessfulRequests: true, // Don't count successful requests
});

// Payment rate limit: 5 purchases per minute per user
const paymentLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:payment:',
  }),
  windowMs: 60 * 1000, // 1 minute
  max: 5,
  message: 'Too many purchase attempts, please slow down.',
  keyGenerator: (req) => req.user?.id || req.ip, // Rate limit by user ID
});

// Apply middleware
app.use('/api/', globalLimiter);
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
app.use('/api/tickets/purchase', paymentLimiter);
```

**Go Implementation:**
```go
import (
    "github.com/gin-gonic/gin"
    "github.com/go-redis/redis/v8"
    "github.com/ulule/limiter/v3"
    "github.com/ulule/limiter/v3/drivers/store/redis"
)

func setupRateLimiting(router *gin.Engine) {
    // Create Redis client
    client := redis.NewClient(&redis.Options{
        Addr: "localhost:6379",
    })

    // Create Redis store
    store, _ := redisstore.NewStoreWithOptions(client, limiter.StoreOptions{
        Prefix: "rl:",
    })

    // Global rate limit: 100 req/15min
    globalRate := limiter.Rate{
        Period: 15 * time.Minute,
        Limit:  100,
    }

    // Auth rate limit: 5 req/15min
    authRate := limiter.Rate{
        Period: 15 * time.Minute,
        Limit:  5,
    }

    // Payment rate limit: 5 req/1min
    paymentRate := limiter.Rate{
        Period: 1 * time.Minute,
        Limit:  5,
    }

    // Apply middleware
    router.Use(rateLimitMiddleware(store, globalRate))
    router.POST("/api/auth/login", rateLimitMiddleware(store, authRate), loginHandler)
    router.POST("/api/tickets/purchase", rateLimitMiddleware(store, paymentRate), purchaseHandler)
}

func rateLimitMiddleware(store limiter.Store, rate limiter.Rate) gin.HandlerFunc {
    instance := limiter.New(store, rate)

    return func(c *gin.Context) {
        limiterContext, err := instance.Get(c, c.ClientIP())

        if err != nil {
            c.JSON(500, gin.H{"error": "Rate limiter error"})
            c.Abort()
            return
        }

        if limiterContext.Reached {
            c.JSON(429, gin.H{"error": "Too many requests"})
            c.Abort()
            return
        }

        c.Next()
    }
}
```

**Rate Limit Strategy:**
| Route Pattern | Limit | Window | Reason |
|--------------|-------|--------|--------|
| `/api/*` | 100 | 15min | Global protection |
| `/api/auth/login` | 5 | 15min | Brute force prevention |
| `/api/auth/register` | 3 | 1hour | Spam account prevention |
| `/api/auth/verify-email` | 5 | 1hour | Email verification abuse |
| `/api/auth/reset-password` | 3 | 1hour | Password reset abuse |
| `/api/tickets/purchase` | 5 | 1min | Payment spam prevention |
| `/api/posts` (POST) | 10 | 5min | Spam post prevention |
| `/api/comments` (POST) | 20 | 5min | Comment spam prevention |

---

### 2. CSRF Protection - 3-4 hours

**Problem:** State-changing endpoints vulnerable to Cross-Site Request Forgery

**Solution:** Implement CSRF tokens for all POST/PUT/DELETE requests

#### Backend Implementation

**Install Dependencies:**
```bash
# Node.js
npm install csurf cookie-parser

# Go
go get github.com/gorilla/csrf
```

**Node.js + Express:**
```javascript
const csrf = require('csurf');
const cookieParser = require('cookie-parser');

// Setup CSRF protection
const csrfProtection = csrf({
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production', // HTTPS only in production
    sameSite: 'strict',
  },
});

app.use(cookieParser());
app.use(csrfProtection);

// Endpoint to get CSRF token
app.get('/api/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// All state-changing routes automatically protected
app.post('/api/posts', (req, res) => {
  // CSRF token validated automatically
  // If invalid, returns 403 Forbidden
});
```

**Go + Gin:**
```go
import (
    "github.com/gin-gonic/gin"
    "github.com/gorilla/csrf"
)

func setupCSRF(router *gin.Engine) {
    CSRF := csrf.Protect(
        []byte("32-byte-long-secret-key-here"),
        csrf.Secure(true), // HTTPS only
        csrf.HttpOnly(true),
        csrf.SameSite(csrf.SameSiteStrictMode),
    )

    // Apply to all routes
    router.Use(func(c *gin.Context) {
        CSRF(c.Writer, c.Request)
        c.Next()
    })

    // Get CSRF token endpoint
    router.GET("/api/csrf-token", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "csrf_token": csrf.Token(c.Request),
        })
    })
}
```

#### Frontend Implementation (Flutter)

```dart
// In DioClient
class DioClient {
  final Dio _dio;
  String? _csrfToken;

  Future<void> fetchCSRFToken() async {
    final response = await _dio.get('/api/csrf-token');
    _csrfToken = response.data['csrfToken'] ?? response.data['csrf_token'];
  }

  Future<Response> post(String path, {dynamic data}) async {
    // Ensure we have CSRF token
    if (_csrfToken == null) {
      await fetchCSRFToken();
    }

    return await _dio.post(
      path,
      data: data,
      options: Options(
        headers: {
          'X-CSRF-Token': _csrfToken,
        },
      ),
    );
  }

  // Similar for put, delete
}

// Initialize CSRF token on app start
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Fetch CSRF token
  await di.sl<DioClient>().fetchCSRFToken();

  runApp(MyApp());
}
```

---

### 3. XSS Prevention (HTML Sanitization) - 2-3 hours

**Problem:** User-generated content can inject malicious scripts

**Solution:** Sanitize all HTML input on backend, escape output on frontend

#### Backend Implementation

**Install Dependencies:**
```bash
# Node.js
npm install dompurify jsdom

# Go
go get github.com/microcosm-cc/bluemonday
```

**Node.js:**
```javascript
const createDOMPurify = require('dompurify');
const { JSDOM } = require('jsdom');

const window = new JSDOM('').window;
const DOMPurify = createDOMPurify(window);

// Sanitize middleware
function sanitizeBody(req, res, next) {
  if (req.body) {
    Object.keys(req.body).forEach(key => {
      if (typeof req.body[key] === 'string') {
        req.body[key] = DOMPurify.sanitize(req.body[key], {
          ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
          ALLOWED_ATTR: ['href'],
        });
      }
    });
  }
  next();
}

// Apply to routes with user content
app.post('/api/posts', sanitizeBody, createPostHandler);
app.post('/api/comments', sanitizeBody, createCommentHandler);
app.put('/api/users/profile', sanitizeBody, updateProfileHandler);
```

**Go:**
```go
import (
    "github.com/microcosm-cc/bluemonday"
)

var policy = bluemonday.UGCPolicy()

func sanitizeString(input string) string {
    return policy.Sanitize(input)
}

// Middleware
func SanitizeMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        var body map[string]interface{}
        if err := c.BindJSON(&body); err == nil {
            for key, value := range body {
                if str, ok := value.(string); ok {
                    body[key] = sanitizeString(str)
                }
            }
            c.Set("sanitized_body", body)
        }
        c.Next()
    }
}
```

**Sanitize Fields:**
- Post content/caption
- Comment text
- User bio
- Event description
- Community description
- Any user-provided text

---

### 4. Secure VerifyEmail Endpoint - 2-3 hours

**Current Issues:**
- Token validation might be weak
- No expiration
- No one-time use enforcement

**Solution:** Implement secure token validation

```javascript
const crypto = require('crypto');

// Generate verification token (when user registers)
async function generateVerificationToken(userId) {
  const token = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  // Store hashed token with expiration
  await db.emailVerifications.create({
    user_id: userId,
    token: hashedToken,
    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
    used: false,
  });

  return token; // Send unhashed token to user's email
}

// Verify email endpoint
app.get('/api/auth/verify-email/:token', async (req, res) => {
  const { token } = req.params;

  // Hash the token from URL
  const hashedToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  // Find verification record
  const verification = await db.emailVerifications.findOne({
    where: {
      token: hashedToken,
      used: false,
      expires_at: { [Op.gt]: new Date() }, // Not expired
    },
  });

  if (!verification) {
    return res.status(400).json({
      error: 'Invalid or expired verification link',
    });
  }

  // Mark token as used (one-time use)
  await verification.update({ used: true });

  // Update user's email verification status
  await db.users.update(
    { email_verified: true },
    { where: { id: verification.user_id } }
  );

  res.json({ message: 'Email verified successfully' });
});
```

**Security Measures:**
- ✅ Store hashed tokens (not plaintext)
- ✅ 24-hour expiration
- ✅ One-time use (mark as used)
- ✅ Rate limit verification attempts
- ✅ Log all verification attempts

---

### 5. Secure ResetPassword Endpoint - 2-3 hours

**Similar approach to email verification:**

```javascript
// Request password reset
app.post('/api/auth/forgot-password', authLimiter, async (req, res) => {
  const { email } = req.body;

  const user = await db.users.findOne({ where: { email } });

  // Always return success (don't leak user existence)
  if (!user) {
    return res.json({
      message: 'If that email exists, a reset link has been sent',
    });
  }

  // Generate reset token
  const token = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  await db.passwordResets.create({
    user_id: user.id,
    token: hashedToken,
    expires_at: new Date(Date.now() + 1 * 60 * 60 * 1000), // 1 hour
    used: false,
  });

  // Send email with reset link
  await sendEmail({
    to: email,
    subject: 'Password Reset',
    text: `Click here to reset: ${process.env.APP_URL}/reset-password?token=${token}`,
  });

  res.json({
    message: 'If that email exists, a reset link has been sent',
  });
});

// Reset password
app.post('/api/auth/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;

  const hashedToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  const reset = await db.passwordResets.findOne({
    where: {
      token: hashedToken,
      used: false,
      expires_at: { [Op.gt]: new Date() },
    },
  });

  if (!reset) {
    return res.status(400).json({
      error: 'Invalid or expired reset link',
    });
  }

  // Validate password strength
  if (newPassword.length < 8) {
    return res.status(400).json({
      error: 'Password must be at least 8 characters',
    });
  }

  // Hash new password
  const hashedPassword = await bcrypt.hash(newPassword, 10);

  // Update user password
  await db.users.update(
    { password: hashedPassword },
    { where: { id: reset.user_id } }
  );

  // Mark token as used
  await reset.update({ used: true });

  // Invalidate all active sessions for this user
  await db.sessions.destroy({ where: { user_id: reset.user_id } });

  res.json({ message: 'Password reset successfully' });
});
```

**Security Measures:**
- ✅ 1-hour expiration (shorter than email verification)
- ✅ One-time use
- ✅ Don't leak user existence
- ✅ Invalidate sessions after reset
- ✅ Enforce password strength
- ✅ Rate limit requests

---

### 6. Fix fmt.Sprintf SQL Injection Risks - 1-2 hours

**Problem:** Dynamic queries with fmt.Sprintf can cause SQL injection

**BAD Example:**
```go
// VULNERABLE - Never do this!
query := fmt.Sprintf("SELECT * FROM users WHERE username = '%s'", username)
db.Exec(query)
```

**GOOD Example:**
```go
// Safe - Use parameterized queries
query := "SELECT * FROM users WHERE username = ?"
db.Query(query, username)

// For Gorm
db.Where("username = ?", username).Find(&user)
```

**Search and Fix:**
```bash
# Find all fmt.Sprintf uses
grep -r "fmt.Sprintf.*SELECT\|INSERT\|UPDATE\|DELETE" .

# Replace with parameterized queries
```

**Safe Patterns:**
```go
// ✅ Good
db.Where("name = ? AND age > ?", name, age).Find(&users)

// ✅ Good
db.Exec("UPDATE users SET name = ? WHERE id = ?", newName, userId)

// ❌ Bad
query := fmt.Sprintf("DELETE FROM users WHERE id = %d", userId)

// ✅ Fixed
db.Exec("DELETE FROM users WHERE id = ?", userId)
```

---

### 7. Secrets Rotation & Vault Storage - 2-3 hours

**Current Problem:** Secrets likely stored in environment variables or config files

**Solution:** Use secret management service

#### Setup HashiCorp Vault (Recommended)

```bash
# Install Vault
brew install vault  # macOS
# or download from https://www.vaultproject.io/downloads

# Start Vault server (dev mode for testing)
vault server -dev

# Set environment variable
export VAULT_ADDR='http://127.0.0.1:8200'

# Store secrets
vault kv put secret/anigmaa/production \
  db_password=your_db_password \
  jwt_secret=your_jwt_secret \
  midtrans_server_key=your_midtrans_key \
  redis_password=your_redis_password
```

#### Backend Integration

```javascript
// Node.js
const vault = require('node-vault')({
  endpoint: process.env.VAULT_ADDR,
  token: process.env.VAULT_TOKEN,
});

async function loadSecrets() {
  const result = await vault.read('secret/data/anigmaa/production');

  process.env.DB_PASSWORD = result.data.data.db_password;
  process.env.JWT_SECRET = result.data.data.jwt_secret;
  process.env.MIDTRANS_SERVER_KEY = result.data.data.midtrans_server_key;
}

// Call on startup
loadSecrets().then(() => {
  startServer();
});
```

**Rotation Strategy:**
| Secret | Rotation Frequency | Method |
|--------|-------------------|--------|
| JWT Secret | Every 90 days | Gradual (support 2 keys during transition) |
| Database Password | Every 90 days | Coordinated with DB admin |
| Midtrans Keys | Yearly or on compromise | Update in Vault + app |
| Session Secret | Every 30 days | Gradual transition |
| API Keys (3rd party) | Per vendor policy | Update in Vault |

---

## 🎯 Security Implementation Checklist

- [ ] Implement Redis-based rate limiting on all routes
- [ ] Add CSRF protection for state-changing endpoints
- [ ] Sanitize all user-generated HTML content
- [ ] Secure VerifyEmail endpoint (hashed tokens, expiration, one-time use)
- [ ] Secure ResetPassword endpoint (1-hour expiration, session invalidation)
- [ ] Replace all fmt.Sprintf SQL queries with parameterized queries
- [ ] Setup secret vault (Vault/AWS Secrets Manager)
- [ ] Implement secret rotation schedule
- [ ] Add security headers (HSTS, X-Frame-Options, CSP)
- [ ] Enable HTTPS in production
- [ ] Audit all endpoints for authentication/authorization
- [ ] Add logging for all security-sensitive operations

**Total Time:** 16-22 hours

---

<a name="data-integrity"></a>
## 🔐 DATA INTEGRITY & TRANSACTIONAL SAFETY (Sprint 1-2)

**Priority:** 🔥 **HIGH** - Prevent data corruption and race conditions
**Effort:** 14-20 hours
**Focus:** ACID compliance and consistency

---

### 1. Transactional Event Join - 3-4 hours

**Problem:** Event join might fail partially (user added but count not updated)

**Solution:** Wrap in database transaction

#### Implementation

**Node.js (Sequelize):**
```javascript
async function joinEvent(userId, eventId) {
  // Start transaction
  const t = await db.sequelize.transaction();

  try {
    // 1. Check if already joined
    const existing = await db.eventAttendees.findOne({
      where: { user_id: userId, event_id: eventId },
      transaction: t,
    });

    if (existing) {
      await t.rollback();
      throw new Error('Already joined this event');
    }

    // 2. Check event capacity
    const event = await db.events.findByPk(eventId, {
      transaction: t,
      lock: true, // Row-level lock
    });

    if (event.attendee_count >= event.max_attendees) {
      await t.rollback();
      throw new Error('Event is full');
    }

    // 3. Add attendee
    await db.eventAttendees.create({
      user_id: userId,
      event_id: eventId,
      joined_at: new Date(),
    }, { transaction: t });

    // 4. Increment count
    await event.increment('attendee_count', { transaction: t });

    // Commit transaction
    await t.commit();

    return { success: true };
  } catch (error) {
    // Rollback on any error
    await t.rollback();
    throw error;
  }
}
```

**Go (Gorm):**
```go
func JoinEvent(userID, eventID string) error {
    return db.Transaction(func(tx *gorm.DB) error {
        // 1. Check if already joined
        var existing EventAttendee
        if err := tx.Where("user_id = ? AND event_id = ?", userID, eventID).
            First(&existing).Error; err == nil {
            return errors.New("already joined")
        }

        // 2. Lock event row and check capacity
        var event Event
        if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
            First(&event, "id = ?", eventID).Error; err != nil {
            return err
        }

        if event.AttendeeCount >= event.MaxAttendees {
            return errors.New("event is full")
        }

        // 3. Add attendee
        attendee := EventAttendee{
            UserID:   userID,
            EventID:  eventID,
            JoinedAt: time.Now(),
        }
        if err := tx.Create(&attendee).Error; err != nil {
            return err
        }

        // 4. Increment count
        if err := tx.Model(&event).Update("attendee_count", gorm.Expr("attendee_count + 1")).Error; err != nil {
            return err
        }

        return nil // Commit
    })
}
```

**Test Cases:**
- ✅ Successful join (count incremented, record created)
- ✅ Duplicate join attempt (no duplicate, no count change)
- ✅ Full event (rejection, no changes)
- ✅ Concurrent joins (only N attendees for capacity N)

---

### 2. Cascade Delete for Posts → Comments → Interactions - 2-3 hours

**Problem:** Deleting post might leave orphaned comments/likes

**Solution:** Database cascade rules + application logic

#### Database Schema

```sql
CREATE TABLE posts (
  id VARCHAR(36) PRIMARY KEY,
  -- other fields
);

CREATE TABLE comments (
  id VARCHAR(36) PRIMARY KEY,
  post_id VARCHAR(36) NOT NULL,
  -- other fields
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  INDEX idx_post_id (post_id)
);

CREATE TABLE post_likes (
  id VARCHAR(36) PRIMARY KEY,
  post_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  INDEX idx_post_id (post_id)
);

CREATE TABLE comment_likes (
  id VARCHAR(36) PRIMARY KEY,
  comment_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
  INDEX idx_comment_id (comment_id)
);

CREATE TABLE bookmarks (
  id VARCHAR(36) PRIMARY KEY,
  post_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  INDEX idx_post_id (post_id)
);

CREATE TABLE reposts (
  id VARCHAR(36) PRIMARY KEY,
  post_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  INDEX idx_post_id (post_id)
);
```

#### Application-Level Cascade (if DB doesn't support)

```javascript
async function deletePost(postId) {
  const t = await db.sequelize.transaction();

  try {
    // 1. Delete all interactions
    await db.postLikes.destroy({
      where: { post_id: postId },
      transaction: t,
    });

    await db.bookmarks.destroy({
      where: { post_id: postId },
      transaction: t,
    });

    await db.reposts.destroy({
      where: { post_id: postId },
      transaction: t,
    });

    // 2. Delete all comments (and their likes)
    const comments = await db.comments.findAll({
      where: { post_id: postId },
      transaction: t,
    });

    for (const comment of comments) {
      await db.commentLikes.destroy({
        where: { comment_id: comment.id },
        transaction: t,
      });
    }

    await db.comments.destroy({
      where: { post_id: postId },
      transaction: t,
    });

    // 3. Delete post itself
    await db.posts.destroy({
      where: { id: postId },
      transaction: t,
    });

    await t.commit();
  } catch (error) {
    await t.rollback();
    throw error;
  }
}
```

---

### 3. Race Condition Prevention: Attendee Counter Locking - 3-4 hours

**Problem:** Concurrent joins can exceed max capacity

**Solution:** Row-level locking + atomic increment

```javascript
// Use row-level locks (FOR UPDATE)
async function joinEventSafe(userId, eventId) {
  const t = await db.sequelize.transaction({
    isolationLevel: Transaction.ISOLATION_LEVELS.SERIALIZABLE,
  });

  try {
    // Lock event row
    const event = await db.events.findByPk(eventId, {
      transaction: t,
      lock: t.LOCK.UPDATE, // SELECT ... FOR UPDATE
    });

    if (!event) {
      throw new Error('Event not found');
    }

    // Check capacity with locked value
    if (event.attendee_count >= event.max_attendees) {
      await t.rollback();
      throw new Error('Event is full');
    }

    // Add attendee
    await db.eventAttendees.create({
      user_id: userId,
      event_id: eventId,
    }, { transaction: t });

    // Atomic increment
    await db.events.increment('attendee_count', {
      where: { id: eventId },
      transaction: t,
    });

    await t.commit();
    return { success: true };
  } catch (error) {
    await t.rollback();
    throw error;
  }
}
```

**Test Scenario:**
```javascript
// Simulate 100 concurrent joins to event with max 50 capacity
const promises = Array.from({ length: 100 }, (_, i) =>
  joinEventSafe(`user_${i}`, 'event_123')
);

const results = await Promise.allSettled(promises);

// Expected: 50 successful, 50 failed with "Event is full"
const successful = results.filter(r => r.status === 'fulfilled');
const failed = results.filter(r => r.status === 'rejected');

console.log(`Successful: ${successful.length}`); // Should be 50
console.log(`Failed: ${failed.length}`); // Should be 50

// Verify database count matches
const event = await db.events.findByPk('event_123');
console.log(`Attendee count: ${event.attendee_count}`); // Should be exactly 50
```

---

### 4. Payment-Ticket Atomicity (Webhook Handling) - 4-6 hours

**Problem:** Webhook might be called multiple times, or fail partially

**Solution:** Idempotent webhook handling with transactions

```javascript
async function handlePaymentWebhook(notification) {
  const orderId = notification.order_id;
  const transactionStatus = notification.transaction_status;

  // Use orderId as idempotency key
  const t = await db.sequelize.transaction();

  try {
    // 1. Find transaction record with lock
    const transaction = await db.ticketTransactions.findOne({
      where: { payment_gateway_id: orderId },
      transaction: t,
      lock: t.LOCK.UPDATE,
    });

    if (!transaction) {
      await t.rollback();
      return { error: 'Transaction not found' };
    }

    // 2. Check if already processed (idempotency)
    if (transaction.status === 'completed') {
      await t.rollback();
      return { message: 'Already processed', alreadyProcessed: true };
    }

    // 3. Update based on status
    if (transactionStatus === 'settlement' || transactionStatus === 'capture') {
      // Payment successful
      await transaction.update({
        status: 'completed',
        completed_at: new Date(),
        payment_gateway_response: JSON.stringify(notification),
      }, { transaction: t });

      // Activate ticket
      await db.tickets.update({
        status: 'active',
      }, {
        where: { id: transaction.ticket_id },
        transaction: t,
      });

      // Update event attendee count
      await db.events.increment('attendee_count', {
        where: { id: transaction.event_id },
        transaction: t,
      });

    } else if (['cancel', 'deny', 'expire'].includes(transactionStatus)) {
      // Payment failed
      await transaction.update({
        status: 'failed',
        payment_gateway_response: JSON.stringify(notification),
      }, { transaction: t });

      // Cancel ticket
      await db.tickets.update({
        status: 'cancelled',
      }, {
        where: { id: transaction.ticket_id },
        transaction: t,
      });
    }

    await t.commit();
    return { success: true };

  } catch (error) {
    await t.rollback();
    throw error;
  }
}
```

**Idempotency Check:**
```javascript
// Log webhook calls to detect duplicates
CREATE TABLE webhook_logs (
  id VARCHAR(36) PRIMARY KEY,
  order_id VARCHAR(100) NOT NULL,
  status VARCHAR(50),
  received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  processed BOOLEAN DEFAULT FALSE,
  INDEX idx_order_id (order_id)
);

async function logWebhook(orderId, status) {
  await db.webhookLogs.create({
    id: uuid.v4(),
    order_id: orderId,
    status: status,
    processed: true,
  });
}
```

---

### 5. Validation Layer for Ticket/Event Consistency - 2-3 hours

**Validations:**

```javascript
// Before creating ticket
function validateTicketPurchase(eventId, userId, amount) {
  // 1. Event exists and is active
  const event = await db.events.findByPk(eventId);
  if (!event) throw new Error('Event not found');
  if (event.status !== 'active') throw new Error('Event is not active');

  // 2. Event hasn't started yet
  if (new Date() > event.start_date) {
    throw new Error('Event has already started');
  }

  // 3. Event has capacity
  if (event.attendee_count >= event.max_attendees) {
    throw new Error('Event is full');
  }

  // 4. User not already registered
  const existing = await db.tickets.findOne({
    where: {
      user_id: userId,
      event_id: eventId,
      status: { [Op.in]: ['active', 'pending'] },
    },
  });
  if (existing) throw new Error('Already registered for this event');

  // 5. Amount matches event price
  if (amount !== event.ticket_price) {
    throw new Error('Invalid ticket price');
  }

  // 6. User has valid payment method (if paid event)
  if (amount > 0) {
    // Check user payment info
  }

  return true;
}

// Before check-in
function validateCheckIn(ticketId) {
  const ticket = await db.tickets.findByPk(ticketId);
  if (!ticket) throw new Error('Ticket not found');
  if (ticket.status !== 'active') throw new Error('Ticket not active');
  if (ticket.is_checked_in) throw new Error('Already checked in');

  // Check event is happening now
  const event = await db.events.findByPk(ticket.event_id);
  const now = new Date();
  if (now < event.start_date || now > event.end_date) {
    throw new Error('Check-in not available outside event time');
  }

  return true;
}
```

---

## 🎯 Data Integrity Checklist

- [ ] Wrap event join in database transaction
- [ ] Add cascade delete rules to all foreign keys
- [ ] Implement row-level locking for attendee counter
- [ ] Add idempotent webhook handling with transaction logs
- [ ] Implement validation layer for all ticket operations
- [ ] Add database constraints (unique, not null, foreign keys)
- [ ] Test race conditions with concurrent requests
- [ ] Add database indexes for performance
- [ ] Implement audit logging for all data changes
- [ ] Setup database backups and point-in-time recovery

**Total Time:** 14-20 hours

---

<a name="ux-product"></a>
## 🎨 UX & PRODUCT COMPLETION (Sprint 2)

**Priority:** 🟡 **MEDIUM** - Polish and user experience
**Effort:** 16-22 hours
**Focus:** Real-time updates, UI polish, data accuracy

---

### 1. Real-time Status Sync for Likes/Comments - 6-8 hours

**Current Problem:** Like count only updates on refresh

**Solution:** Implement optimistic updates + WebSocket/polling for real-time sync

#### Optimistic Updates (Quick Win - 3 hours)

```dart
// In PostBloc
Future<void> _onLikePost(LikePost event, Emitter<PostState> emit) async {
  if (state is! PostLoaded) return;

  final currentState = state as PostLoaded;
  final posts = List<Post>.from(currentState.posts);

  // Find post
  final postIndex = posts.indexWhere((p) => p.id == event.postId);
  if (postIndex == -1) return;

  final post = posts[postIndex];

  // Optimistic update (update UI immediately)
  final updatedPost = post.copyWith(
    isLiked: !post.isLiked,
    likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
  );
  posts[postIndex] = updatedPost;

  // Emit new state immediately
  emit(PostLoaded(posts));

  // Call API in background
  final result = post.isLiked
      ? await unlikePost(UnlikePostParams(postId: event.postId))
      : await likePost(LikePostParams(postId: event.postId));

  // If API fails, revert
  result.fold(
    (failure) {
      posts[postIndex] = post; // Revert to original
      emit(PostLoaded(posts));
      // Show error toast
    },
    (success) {
      // Success - keep the optimistic update
    },
  );
}
```

#### Real-time Updates with Polling (Medium - 3 hours)

```dart
class PostBloc extends Bloc<PostEvent, PostState> {
  Timer? _pollTimer;

  void startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      add(RefreshPosts());
    });
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
```

#### Real-time Updates with WebSocket (Advanced - 6-8 hours)

Backend (Node.js + Socket.io):
```javascript
const io = require('socket.io')(server, {
  cors: { origin: '*' },
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Join post room
  socket.on('join_post', (postId) => {
    socket.join(`post_${postId}`);
  });

  // Leave post room
  socket.on('leave_post', (postId) => {
    socket.leave(`post_${postId}`);
  });
});

// When someone likes a post
async function likePost(userId, postId) {
  // ... database logic

  // Broadcast to all users viewing this post
  io.to(`post_${postId}`).emit('post_updated', {
    post_id: postId,
    like_count: newLikeCount,
    comment_count: commentCount,
  });
}
```

Frontend (Flutter + socket_io_client):
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io('http://your-backend.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on('post_updated', (data) {
      // Update PostBloc
      final postId = data['post_id'];
      final likeCount = data['like_count'];
      final commentCount = data['comment_count'];

      // Dispatch event to update UI
      postBloc.add(UpdatePostStats(
        postId: postId,
        likeCount: likeCount,
        commentCount: commentCount,
      ));
    });
  }

  void joinPost(String postId) {
    socket.emit('join_post', postId);
  }

  void leavePost(String postId) {
    socket.emit('leave_post', postId);
  }
}
```

**Recommendation:** Start with optimistic updates (immediate UX improvement), add polling for v1, consider WebSocket for v2.

---

### 2. Cleaned Profile UI Showing Real User Stats - 4-6 hours

**Current Issue:** Profile shows placeholder or incorrect stats

**Solution:** Fetch real aggregated stats from backend

#### Backend Endpoint

```javascript
app.get('/api/users/:userId/stats', async (req, res) => {
  const { userId } = req.params;

  const [postCount, followerCount, followingCount, eventCount, ticketCount] = await Promise.all([
    db.posts.count({ where: { user_id: userId } }),
    db.follows.count({ where: { followed_id: userId } }),
    db.follows.count({ where: { follower_id: userId } }),
    db.events.count({ where: { host_id: userId } }),
    db.tickets.count({ where: { user_id: userId, status: 'active' } }),
  ]);

  res.json({
    post_count: postCount,
    follower_count: followerCount,
    following_count: followingCount,
    event_count: eventCount,
    ticket_count: ticketCount,
  });
});
```

#### Frontend

```dart
// Add stats to User entity
class User extends Equatable {
  final String id;
  final String name;
  final String? bio;
  final UserStats? stats;
  // ...
}

class UserStats extends Equatable {
  final int postCount;
  final int followerCount;
  final int followingCount;
  final int eventCount;
  final int ticketCount;

  const UserStats({
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.eventCount,
    required this.ticketCount,
  });
}

// Update ProfileScreen
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final user = state.user;
          final stats = user.stats;

          return Column(
            children: [
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Posts', stats?.postCount ?? 0),
                  _buildStatItem('Followers', stats?.followerCount ?? 0),
                  _buildStatItem('Following', stats?.followingCount ?? 0),
                  _buildStatItem('Events', stats?.eventCount ?? 0),
                ],
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
```

---

### 3. Ticket Display Shows Real Event Data - 3-4 hours

**Already documented in BLOCKER 1 - My Tickets Screen Update**

See: `BLOCKER_1_MONETIZATION_ANALYSIS.md` Section "Update My Tickets Screen to Show Real Event Data"

---

### 4. Host Dashboard Fetch Real Analytics Data - 3-4 hours

**Current Issue:** Host dashboard shows mock analytics

#### Backend Endpoint

```javascript
app.get('/api/events/:eventId/analytics', async (req, res) => {
  const { eventId } = req.params;

  // Verify user is host
  const event = await db.events.findByPk(eventId);
  if (event.host_id !== req.user.id) {
    return res.status(403).json({ error: 'Not authorized' });
  }

  const [
    ticketCount,
    checkedInCount,
    revenue,
    attendeesByDate,
  ] = await Promise.all([
    db.tickets.count({
      where: { event_id: eventId, status: 'active' },
    }),

    db.tickets.count({
      where: { event_id: eventId, is_checked_in: true },
    }),

    db.ticketTransactions.sum('amount', {
      where: { event_id: eventId, status: 'completed' },
    }),

    db.sequelize.query(`
      SELECT DATE(purchased_at) as date, COUNT(*) as count
      FROM tickets
      WHERE event_id = :eventId AND status = 'active'
      GROUP BY DATE(purchased_at)
      ORDER BY date
    `, {
      replacements: { eventId },
      type: QueryTypes.SELECT,
    }),
  ]);

  res.json({
    ticket_count: ticketCount,
    checked_in_count: checkedInCount,
    revenue: revenue || 0,
    attendees_by_date: attendeesByDate,
    check_in_rate: ticketCount > 0 ? (checkedInCount / ticketCount * 100).toFixed(1) : 0,
  });
});
```

#### Frontend

```dart
// Update HostDashboardScreen
class EventAnalytics extends Equatable {
  final int ticketCount;
  final int checkedInCount;
  final double revenue;
  final double checkInRate;
  final List<AttendeesByDate> attendeesByDate;

  const EventAnalytics({
    required this.ticketCount,
    required this.checkedInCount,
    required this.revenue,
    required this.checkInRate,
    required this.attendeesByDate,
  });
}

// Display in UI
Text('Total Tickets: ${analytics.ticketCount}'),
Text('Checked In: ${analytics.checkedInCount}'),
Text('Revenue: Rp ${analytics.revenue.toStringAsFixed(0)}'),
Text('Check-in Rate: ${analytics.checkInRate}%'),
```

---

### 5. Error Handling Messaging Consistent - 2-3 hours

**Goal:** Consistent, user-friendly error messages across app

```dart
// Create error message mapper
class ErrorMessageMapper {
  static String mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Koneksi internet bermasalah. Coba lagi ya!';
    } else if (failure is ServerFailure) {
      if (failure.message.contains('not found')) {
        return 'Data tidak ditemukan';
      } else if (failure.message.contains('full')) {
        return 'Event udah penuh, coba event lain ya!';
      } else if (failure.message.contains('already')) {
        return 'Kamu udah join event ini kok!';
      }
      return 'Ada masalah di server. Coba lagi nanti ya!';
    } else if (failure is AuthenticationFailure) {
      return 'Sesi kamu udah habis. Login lagi yuk!';
    } else if (failure is AuthorizationFailure) {
      return 'Kamu ga punya akses buat ini';
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'Ada yang salah. Coba lagi ya!';
  }
}

// Consistent error toast
void showErrorToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ),
  );
}
```

---

## 🎯 UX Checklist

- [ ] Implement optimistic updates for likes/comments
- [ ] Add real-time sync (polling or WebSocket)
- [ ] Update Profile UI with real user stats
- [ ] Update My Tickets screen with event data
- [ ] Update Host Dashboard with real analytics
- [ ] Implement consistent error messaging
- [ ] Add loading states to all data fetching
- [ ] Add pull-to-refresh on all list screens
- [ ] Add empty states for all lists
- [ ] Add retry buttons on error states

**Total Time:** 16-22 hours

---

<a name="non-critical"></a>
## ⚡ NON-CRITICAL BUT IMPORTANT (Sprint 3)

**Priority:** 🟢 **LOW** - Performance and monitoring
**Effort:** 14-18 hours
**Focus:** Optimization, observability, testing

---

### 1. Redis Caching for Feed & Events Nearby - 6-8 hours

**Implementation:**

```javascript
const redis = require('redis');
const client = redis.createClient();

// Cache feed
app.get('/api/feed', async (req, res) => {
  const userId = req.user.id;
  const cacheKey = `feed:${userId}`;

  // Try cache first
  const cached = await client.get(cacheKey);
  if (cached) {
    return res.json(JSON.parse(cached));
  }

  // Fetch from database
  const posts = await db.posts.findAll({
    // ... complex query
  });

  // Cache for 5 minutes
  await client.setEx(cacheKey, 300, JSON.stringify(posts));

  res.json(posts);
});

// Cache nearby events (by location)
app.get('/api/events/nearby', async (req, res) => {
  const { lat, lng } = req.query;
  const cacheKey = `events:nearby:${lat}:${lng}`;

  const cached = await client.get(cacheKey);
  if (cached) {
    return res.json(JSON.parse(cached));
  }

  const events = await db.events.findAll({
    // ... geospatial query
  });

  // Cache for 10 minutes
  await client.setEx(cacheKey, 600, JSON.stringify(events));

  res.json(events);
});

// Invalidate cache on post creation
async function createPost(data) {
  const post = await db.posts.create(data);

  // Invalidate feed cache for followers
  const followers = await db.follows.findAll({
    where: { followed_id: data.user_id },
  });

  for (const follower of followers) {
    await client.del(`feed:${follower.follower_id}`);
  }

  return post;
}
```

**Cache Strategy:**
| Data Type | TTL | Invalidation |
|-----------|-----|--------------|
| Feed | 5 min | On new post by followed users |
| Nearby events | 10 min | On event create/update in area |
| User profile | 15 min | On profile update |
| Event details | 30 min | On event update |
| Post details | Until update | On like/comment/edit |

---

### 2. Log Monitoring (ELK / Grafana) - 4-6 hours

**Setup ELK Stack:**

```bash
# docker-compose.yml
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0
    environment:
      - discovery.type=single-node
    ports:
      - 9200:9200

  logstash:
    image: docker.elastic.co/logstash/logstash:8.5.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf

  kibana:
    image: docker.elastic.co/kibana/kibana:8.5.0
    ports:
      - 5601:5601
```

**Application Logging:**
```javascript
const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.Console(),
    new ElasticsearchTransport({
      clientOpts: { node: 'http://localhost:9200' },
      index: 'anigmaa-logs',
    }),
  ],
});

// Log important events
logger.info('Ticket purchased', {
  user_id: userId,
  event_id: eventId,
  amount: amount,
  transaction_id: transactionId,
});

logger.error('Payment webhook failed', {
  order_id: orderId,
  error: error.message,
});
```

---

### 3. API Performance Profiling - 2-3 hours

```javascript
// Add response time logging
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('API request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration: duration,
    });

    // Alert on slow requests
    if (duration > 1000) {
      logger.warn('Slow request detected', {
        method: req.method,
        path: req.path,
        duration: duration,
      });
    }
  });

  next();
});
```

---

### 4. Unit Tests for Core Modules (60% coverage) - 6-8 hours

**Backend Testing:**
```javascript
// tests/ticket.test.js
const { purchaseTicket } = require('../services/ticketService');

describe('Ticket Purchase', () => {
  it('should create ticket for free event', async () => {
    const result = await purchaseTicket({
      userId: 'user123',
      eventId: 'event456',
      amount: 0,
    });

    expect(result.success).toBe(true);
    expect(result.ticket).toBeDefined();
  });

  it('should reject purchase for full event', async () => {
    await expect(
      purchaseTicket({
        userId: 'user123',
        eventId: 'full_event',
        amount: 50000,
      })
    ).rejects.toThrow('Event is full');
  });

  it('should handle concurrent purchases correctly', async () => {
    // Test race condition
    const promises = Array.from({ length: 10 }, (_, i) =>
      purchaseTicket({
        userId: `user${i}`,
        eventId: 'event_capacity_5',
        amount: 0,
      })
    );

    const results = await Promise.allSettled(promises);
    const successful = results.filter(r => r.status === 'fulfilled');

    expect(successful.length).toBe(5); // Only 5 should succeed
  });
});
```

**Frontend Testing:**
```dart
// test/blocs/post_bloc_test.dart
void main() {
  group('PostBloc', () {
    late PostBloc postBloc;
    late MockGetPosts mockGetPosts;
    late MockLikePost mockLikePost;

    setUp(() {
      mockGetPosts = MockGetPosts();
      mockLikePost = MockLikePost();
      postBloc = PostBloc(
        getPosts: mockGetPosts,
        likePost: mockLikePost,
      );
    });

    test('should emit [PostLoading, PostLoaded] when data is fetched', () {
      // arrange
      when(mockGetPosts(any))
          .thenAnswer((_) async => Right([tPost]));

      // assert later
      final expected = [
        PostLoading(),
        PostLoaded([tPost]),
      ];
      expectLater(postBloc.stream, emitsInOrder(expected));

      // act
      postBloc.add(LoadPosts());
    });

    test('should update like count optimistically', () async {
      // Test optimistic update logic
    });
  });
}
```

**Coverage Goals:**
- Core services: 80%
- Repositories: 70%
- Controllers/Routes: 60%
- Overall: 60%

---

## 🎯 Non-Critical Checklist

- [ ] Implement Redis caching for feed and nearby events
- [ ] Setup ELK stack for log aggregation
- [ ] Add Grafana dashboards for metrics
- [ ] Implement API performance profiling
- [ ] Add slow query logging
- [ ] Write unit tests for ticket service
- [ ] Write unit tests for payment service
- [ ] Write unit tests for event service
- [ ] Write widget tests for key screens
- [ ] Setup CI/CD with test coverage reporting

**Total Time:** 14-18 hours

---

## 📊 TOTAL EFFORT SUMMARY

| Category | Priority | Effort | Sprint |
|----------|----------|--------|--------|
| Security Fixes | 🔥 Critical | 16-22h | Sprint 1 |
| Data Integrity | 🔥 High | 14-20h | Sprint 1-2 |
| UX & Product | 🟡 Medium | 16-22h | Sprint 2 |
| Non-Critical | 🟢 Low | 14-18h | Sprint 3 |
| **TOTAL** | | **60-82h** | **3 Sprints** |

---

**Last Updated:** 2025-01-18
**Status:** 📋 Requirements documented and ready for implementation
