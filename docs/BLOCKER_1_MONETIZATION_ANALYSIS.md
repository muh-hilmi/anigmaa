# BLOCKER 1: Monetization System (Payment + Tickets) - Analysis

**Status:** ⚠️ **PARTIALLY IMPLEMENTED** (Frontend infrastructure complete, backend + integrations missing)
**Priority:** 🔥 **CRITICAL** - Core revenue feature
**Effort:** ~60-80 hours total (40-50 backend, 20-30 frontend integration)

---

## 📋 Executive Summary

The ticketing and payment system has **complete frontend infrastructure** but is currently **non-functional** because:

1. ❌ Backend API endpoints not implemented (9 ticket endpoints missing)
2. ❌ Midtrans payment gateway not integrated (mocked in frontend)
3. ❌ Webhook handler for payment callbacks doesn't exist
4. ❌ Frontend repository using local cache instead of API calls
5. ❌ No QR code generation (uses 4-character codes)
6. ❌ My Tickets screen shows placeholder data

**Bottom Line:** Frontend architecture is solid, but needs backend API + Midtrans integration to become functional.

---

## 🔍 Current State Assessment

### ✅ What's Already Implemented (Frontend)

#### 1. **Complete Domain Layer**
```
lib/domain/
├── entities/
│   ├── ticket.dart ✅ (Full entity with status, check-in, pricing)
│   ├── ticket_transaction.dart ✅ (Transaction tracking)
│   └── transaction.dart ✅ (Payment records)
├── repositories/
│   └── ticket_repository.dart ✅ (9 methods defined)
└── usecases/
    ├── purchase_ticket.dart ✅
    ├── get_user_tickets.dart ✅
    └── check_in_ticket.dart ✅
```

**9 Repository Methods:**
1. `purchaseTicket()` - Create ticket with payment
2. `getUserTickets()` - Get user's tickets
3. `getEventTickets()` - Get tickets for an event
4. `getTicketById()` - Get single ticket
5. `getTicketByCode()` - Get ticket by attendance code
6. `checkInTicket()` - Check in a ticket
7. `cancelTicket()` - Cancel a ticket
8. `getUserTransactions()` - Get transaction history
9. `getTransactionById()` - Get single transaction

#### 2. **Complete Data Layer**
```
lib/data/
├── repositories/
│   └── ticket_repository_impl.dart ✅ (All 9 methods implemented)
├── datasources/
│   ├── ticket_local_datasource.dart ✅ (SharedPreferences - fully functional)
│   └── ticket_remote_datasource.dart ✅ (API client ready, endpoints defined)
└── models/
    ├── ticket_model.dart ✅
    ├── ticket_transaction_model.dart ✅
    └── transaction_model.dart ✅
```

**Issue:** `TicketRepositoryImpl` only calls `localDataSource`, never `remoteDataSource`

#### 3. **Complete Presentation Layer**
```
lib/presentation/
├── bloc/tickets/
│   ├── tickets_bloc.dart ✅
│   ├── tickets_event.dart ✅
│   └── tickets_state.dart ✅
└── pages/tickets/
    ├── my_tickets_screen.dart ⚠️ (Shows "Nama Event" placeholder)
    ├── ticket_detail_screen.dart ✅
    └── host_checkin_screen.dart ✅
```

#### 4. **Payment Service Infrastructure**
```
lib/core/services/payment_service.dart ⚠️ (MOCKED)
```

**Current Behavior:**
- `processPayment()` always returns success after 500ms delay
- `processFreeTicket()` works correctly
- Has placeholder for Midtrans but not implemented

---

### ❌ What's Missing

#### BACKEND (40-50 hours)

**1. Ticket API Endpoints (12-16 hours)**

Need to implement 9 API endpoints (reference: `lib/data/datasources/ticket_remote_datasource.dart`):

| Endpoint | Method | Purpose | Priority |
|----------|--------|---------|----------|
| `/events/:eventId/tickets` | GET | Get tickets for event | High |
| `/tickets/:id` | GET | Get single ticket | High |
| `/tickets/purchase` | POST | Purchase ticket | **CRITICAL** |
| `/tickets/my-tickets` | GET | Get user's tickets | **CRITICAL** |
| `/tickets/transactions/:id` | GET | Get transaction | High |
| `/tickets/check-in` | POST | Check in ticket | **CRITICAL** |
| `/tickets` | POST | Create ticket | Medium |
| `/tickets/:id` | PUT | Update ticket | Medium |
| `/tickets/:id/cancel` | POST | Cancel ticket | High |

**Expected Request/Response Formats:**

```typescript
// POST /tickets/purchase
Request: {
  event_id: string
  user_id: string
  customer_name: string
  customer_email: string
  customer_phone?: string
  amount: number
}

Response: {
  data: {
    id: string
    user_id: string
    event_id: string
    attendance_code: string // 4-char code (e.g., "A3F7")
    price_paid: number
    purchased_at: timestamp
    is_checked_in: boolean
    checked_in_at?: timestamp
    status: "active" | "cancelled" | "refunded" | "expired"
  }
}

// GET /tickets/my-tickets
Response: {
  data: [
    {
      id: string
      user_id: string
      event_id: string
      attendance_code: string
      price_paid: number
      purchased_at: timestamp
      is_checked_in: boolean
      checked_in_at?: timestamp
      status: string
    }
  ]
}

// POST /tickets/check-in
Request: {
  attendance_code: string
}

Response: {
  data: {
    // Updated ticket object with is_checked_in = true
  }
}
```

**Database Schema Needed:**

```sql
-- Tickets table
CREATE TABLE tickets (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  event_id VARCHAR(36) NOT NULL,
  attendance_code VARCHAR(4) UNIQUE NOT NULL, -- e.g., "A3F7"
  price_paid DECIMAL(10,2) NOT NULL,
  purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_checked_in BOOLEAN DEFAULT FALSE,
  checked_in_at TIMESTAMP NULL,
  status ENUM('active', 'cancelled', 'refunded', 'expired') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (event_id) REFERENCES events(id),
  INDEX idx_user_id (user_id),
  INDEX idx_event_id (event_id),
  INDEX idx_attendance_code (attendance_code)
);

-- Ticket transactions table
CREATE TABLE ticket_transactions (
  id VARCHAR(36) PRIMARY KEY,
  ticket_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  event_id VARCHAR(36) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status ENUM('pending', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
  payment_method VARCHAR(50),
  payment_gateway_id VARCHAR(100), -- Midtrans order_id
  payment_gateway_response TEXT, -- JSON response from Midtrans
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (event_id) REFERENCES events(id),
  INDEX idx_user_id (user_id),
  INDEX idx_payment_gateway_id (payment_gateway_id)
);
```

**2. Midtrans Integration - Backend (20-24 hours)**

**Required Steps:**

a) **Setup Midtrans Account** (1-2 hours)
   - Sign up at https://midtrans.com
   - Get Server Key and Client Key (sandbox + production)
   - Configure notification URL for webhooks

b) **Install Midtrans SDK** (1 hour)
   ```bash
   # For Node.js backend
   npm install midtrans-client

   # For Go backend
   go get github.com/veritrans/go-midtrans
   ```

c) **Implement Snap Token Generation** (4-6 hours)
   ```javascript
   // Example: Node.js
   const midtransClient = require('midtrans-client');

   const snap = new midtransClient.Snap({
     isProduction: false,
     serverKey: process.env.MIDTRANS_SERVER_KEY,
     clientKey: process.env.MIDTRANS_CLIENT_KEY
   });

   // POST /api/payment/create-snap-token
   async function createSnapToken(req, res) {
     const { orderId, amount, customerName, customerEmail, customerPhone } = req.body;

     const parameter = {
       transaction_details: {
         order_id: orderId,
         gross_amount: amount
       },
       customer_details: {
         first_name: customerName,
         email: customerEmail,
         phone: customerPhone
       },
       credit_card: {
         secure: true
       }
     };

     try {
       const transaction = await snap.createTransaction(parameter);
       res.json({
         token: transaction.token,
         redirect_url: transaction.redirect_url
       });
     } catch (error) {
       res.status(500).json({ error: error.message });
     }
   }
   ```

d) **Implement Webhook Handler** (8-10 hours) **[CRITICAL]**

   **Endpoint:** `POST /api/payment/notification`

   ```javascript
   const crypto = require('crypto');

   async function handleMidtransNotification(req, res) {
     const notification = req.body;

     // 1. Verify signature
     const serverKey = process.env.MIDTRANS_SERVER_KEY;
     const orderId = notification.order_id;
     const statusCode = notification.status_code;
     const grossAmount = notification.gross_amount;
     const signatureKey = notification.signature_key;

     const hash = crypto
       .createHash('sha512')
       .update(orderId + statusCode + grossAmount + serverKey)
       .digest('hex');

     if (hash !== signatureKey) {
       return res.status(403).json({ message: 'Invalid signature' });
     }

     // 2. Get transaction status
     const transactionStatus = notification.transaction_status;
     const fraudStatus = notification.fraud_status;

     // 3. Find ticket by order_id (stored as payment_gateway_id)
     const transaction = await TicketTransaction.findOne({
       payment_gateway_id: orderId
     });

     if (!transaction) {
       return res.status(404).json({ message: 'Transaction not found' });
     }

     // 4. Update transaction and ticket based on status
     if (transactionStatus === 'capture') {
       if (fraudStatus === 'accept') {
         // Payment successful
         await transaction.update({
           status: 'completed',
           completed_at: new Date()
         });

         await Ticket.update({
           status: 'active'
         }, {
           where: { id: transaction.ticket_id }
         });
       }
     } else if (transactionStatus === 'settlement') {
       // Payment successful
       await transaction.update({
         status: 'completed',
         completed_at: new Date()
       });

       await Ticket.update({
         status: 'active'
       }, {
         where: { id: transaction.ticket_id }
       });
     } else if (transactionStatus === 'cancel' ||
                transactionStatus === 'deny' ||
                transactionStatus === 'expire') {
       // Payment failed
       await transaction.update({
         status: 'failed'
       });

       await Ticket.update({
         status: 'cancelled'
       }, {
         where: { id: transaction.ticket_id }
       });
     } else if (transactionStatus === 'pending') {
       // Payment pending
       await transaction.update({
         status: 'pending'
       });
     }

     // 5. Send response
     res.status(200).json({ message: 'OK' });
   }
   ```

e) **Add Payment Verification Endpoint** (3-4 hours)
   ```javascript
   // GET /api/payment/status/:orderId
   async function getPaymentStatus(req, res) {
     const { orderId } = req.params;

     try {
       const statusResponse = await snap.transaction.status(orderId);
       res.json(statusResponse);
     } catch (error) {
       res.status(500).json({ error: error.message });
     }
   }
   ```

f) **Environment Configuration** (1 hour)
   ```env
   # .env
   MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxxxxxx
   MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxxxxxxxxxx
   MIDTRANS_IS_PRODUCTION=false
   MIDTRANS_NOTIFICATION_URL=https://yourdomain.com/api/payment/notification
   ```

**Security Requirements:**
- ✅ Verify webhook signature on every notification
- ✅ Use HTTPS for webhook URL
- ✅ Store server key in environment variables, never in code
- ✅ Implement idempotency for webhook handling (same notification can arrive multiple times)
- ✅ Log all payment transactions for audit

**Testing:**
- Use Midtrans Sandbox for development
- Test card numbers: https://docs.midtrans.com/en/technical-reference/sandbox-test
- Test webhook with ngrok: `ngrok http 3000`

**3. QR Code Generation (2-3 hours)** [OPTIONAL]

Currently using 4-character attendance codes (e.g., "A3F7"). If QR codes are needed:

Backend:
```javascript
const QRCode = require('qrcode');

async function generateTicketQR(ticketId, attendanceCode) {
  const qrData = JSON.stringify({
    ticket_id: ticketId,
    attendance_code: attendanceCode,
    timestamp: Date.now()
  });

  const qrCodeURL = await QRCode.toDataURL(qrData);
  return qrCodeURL; // Return base64 image
}
```

Frontend already has the code field in UI, just needs to display QR instead of text.

---

#### FRONTEND (20-30 hours)

**1. Update TicketRepositoryImpl to use Remote API (4-6 hours)**

File: `lib/data/repositories/ticket_repository_impl.dart`

**Current Issue:** Only calls `localDataSource`, needs to call `remoteDataSource`

```dart
@override
Future<Either<Failure, Ticket>> purchaseTicket({
  required String userId,
  required String eventId,
  required double amount,
  required String customerName,
  required String customerEmail,
  String? customerPhone,
}) async {
  try {
    // 1. Get Snap token from backend
    final snapToken = await paymentService.getSnapToken(
      eventId: eventId,
      userId: userId,
      amount: amount,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
    );

    // 2. Show Midtrans Snap UI
    final paymentResult = await paymentService.showSnapPayment(snapToken);

    if (!paymentResult.success) {
      return Left(ServerFailure(paymentResult.message));
    }

    // 3. Call backend to create ticket (backend creates after webhook confirmation)
    final ticketModel = await remoteDataSource.purchaseTicket(
      eventId,
      {
        'user_id': userId,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'amount': amount,
        'payment_gateway_id': paymentResult.transactionId,
      },
    );

    // 4. Cache locally
    await localDataSource.saveTicket(ticketModel);

    return Right(ticketModel.toEntity());
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

// Other methods: Call remoteDataSource first, then cache with localDataSource
@override
Future<Either<Failure, List<Ticket>>> getUserTickets(String userId) async {
  try {
    // Try remote first
    final tickets = await remoteDataSource.getUserTickets();

    // Cache locally
    for (var ticket in tickets) {
      await localDataSource.saveTicket(ticket);
    }

    return Right(tickets.map((t) => t.toEntity()).toList());
  } on NetworkFailure {
    // Fallback to cache
    try {
      final cachedTickets = await localDataSource.getUserTickets(userId);
      return Right(cachedTickets.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('No internet and no cached data'));
    }
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

**2. Integrate Midtrans Flutter SDK (8-12 hours)**

File: `lib/core/services/payment_service.dart`

**Steps:**

a) Add dependency in `pubspec.yaml`:
```yaml
dependencies:
  midtrans_sdk: ^0.2.0  # Check latest version
```

b) Update PaymentService:
```dart
import 'package:midtrans_sdk/midtrans_sdk.dart';

class PaymentService {
  late MidtransSDK _midtrans;
  bool _isInitialized = false;

  Future<void> initialize({
    required String clientKey,
    required String merchantBaseUrl,
    MidtransEnvironment environment = MidtransEnvironment.sandbox,
  }) async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: clientKey,
        merchantBaseUrl: merchantBaseUrl,
        colorTheme: ColorTheme(
          colorPrimary: const Color(0xFF84994F),
          colorPrimaryDark: const Color(0xFF6B7A3F),
          colorSecondary: const Color(0xFFFAF8F5),
        ),
      ),
    );

    _midtrans.setUIKitCustomSetting(
      skipCustomerDetailsPages: true,
    );

    _isInitialized = true;
  }

  /// Get Snap token from backend
  Future<String> getSnapToken({
    required String eventId,
    required String userId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  }) async {
    final orderId = _generateOrderId();

    // Call your backend API to generate Snap token
    final response = await dio.post('/api/payment/create-snap-token', data: {
      'order_id': orderId,
      'amount': amount,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'event_id': eventId,
      'user_id': userId,
    });

    return response.data['token'];
  }

  /// Show Midtrans Snap payment UI
  Future<PaymentResult> showSnapPayment(String snapToken) async {
    if (!_isInitialized) {
      throw Exception('PaymentService not initialized');
    }

    try {
      await _midtrans.startPaymentUiFlow(
        token: snapToken,
      );

      // Listen for result
      final result = await _midtrans.transactionResult;

      if (result.transactionStatus == TransactionResultStatus.settlement ||
          result.transactionStatus == TransactionResultStatus.capture) {
        return PaymentResult(
          success: true,
          transactionId: result.orderId,
          message: 'Payment successful',
          status: TransactionStatus.completed,
          paymentType: result.paymentType,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Payment ${result.transactionStatus}',
          status: TransactionStatus.failed,
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment error: ${e.toString()}',
        status: TransactionStatus.failed,
        error: e.toString(),
      );
    }
  }
}
```

c) Initialize in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.init();

  // Initialize payment service
  await di.sl<PaymentService>().initialize(
    clientKey: const String.fromEnvironment('MIDTRANS_CLIENT_KEY'),
    merchantBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    environment: MidtransEnvironment.sandbox,
  );

  runApp(MyApp());
}
```

**3. Update My Tickets Screen to Show Real Event Data (4-6 hours)**

File: `lib/presentation/pages/tickets/my_tickets_screen.dart:275`

**Current Issue:** Shows "Nama Event" placeholder

**Solution:** Load event data for each ticket

```dart
// In TicketsBloc, when loading tickets
class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  final GetUserTickets getUserTickets;
  final GetEventById getEventById; // Add this usecase

  // When LoadUserTickets event
  Future<void> _onLoadUserTickets(
    LoadUserTickets event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    final result = await getUserTickets(event.userId);

    await result.fold(
      (failure) async {
        emit(TicketsError(_mapFailureToMessage(failure)));
      },
      (tickets) async {
        // Load event data for each ticket
        final ticketsWithEvents = <TicketWithEvent>[];

        for (var ticket in tickets) {
          final eventResult = await getEventById(ticket.eventId);

          eventResult.fold(
            (failure) {
              // If event fetch fails, still show ticket with placeholder
              ticketsWithEvents.add(TicketWithEvent(
                ticket: ticket,
                event: null,
              ));
            },
            (event) {
              ticketsWithEvents.add(TicketWithEvent(
                ticket: ticket,
                event: event,
              ));
            },
          );
        }

        emit(TicketsLoaded(ticketsWithEvents));
      },
    );
  }
}

// Update state
class TicketsLoaded extends TicketsState {
  final List<TicketWithEvent> ticketsWithEvents;

  const TicketsLoaded(this.ticketsWithEvents);
}

class TicketWithEvent {
  final Ticket ticket;
  final Event? event;

  const TicketWithEvent({
    required this.ticket,
    required this.event,
  });
}

// Update UI
Widget _buildTicketCard(BuildContext context, TicketWithEvent ticketWithEvent) {
  final ticket = ticketWithEvent.ticket;
  final event = ticketWithEvent.event;

  // ...

  Text(
    event?.title ?? 'Event tidak ditemukan',
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: Color(0xFF1A1A1A),
    ),
  ),
}
```

**4. Add QR Code Display (3-4 hours)** [OPTIONAL]

If backend generates QR codes:

a) Add dependency:
```yaml
dependencies:
  qr_flutter: ^4.1.0
```

b) Update Ticket entity to include QR code URL:
```dart
class Ticket extends Equatable {
  // ... existing fields
  final String? qrCodeUrl; // Base64 or URL to QR image
}
```

c) Display QR in TicketDetailScreen:
```dart
import 'package:qr_flutter/qr_flutter.dart';

// In ticket detail
if (ticket.qrCodeUrl != null)
  QrImageView(
    data: ticket.qrCodeUrl!,
    version: QrVersions.auto,
    size: 200.0,
  )
else
  // Fallback: Generate QR from attendance code
  QrImageView(
    data: ticket.attendanceCode,
    version: QrVersions.auto,
    size: 200.0,
  )
```

**5. Error Handling & Loading States (2-3 hours)**

Update UI to handle:
- Payment in progress
- Payment failed with retry
- Network errors with offline mode
- Transaction pending status

---

## 📊 Effort Estimation

| Task | Complexity | Time | Priority |
|------|-----------|------|----------|
| **BACKEND** |  |  |  |
| Setup ticket API endpoints | Medium | 12-16h | **CRITICAL** |
| Midtrans account setup | Low | 1-2h | **CRITICAL** |
| Midtrans SDK integration | Medium | 4-6h | **CRITICAL** |
| Webhook handler | High | 8-10h | **CRITICAL** |
| Payment verification | Medium | 3-4h | High |
| QR code generation | Low | 2-3h | Optional |
| Testing & debugging | Medium | 8-10h | High |
| **FRONTEND** |  |  |  |
| Update repository to use API | Medium | 4-6h | **CRITICAL** |
| Midtrans Flutter SDK | Medium | 8-12h | **CRITICAL** |
| Event data in My Tickets | Low | 4-6h | High |
| QR code display | Low | 3-4h | Optional |
| Error handling & polish | Low | 2-3h | Medium |
| **Total** |  | **60-80h** |  |
| - Backend | | **40-50h** |  |
| - Frontend | | **20-30h** |  |

---

## 🎯 Implementation Plan

### Phase 1: Backend Foundation (Sprint 1 - Week 1)
**Goal:** Get basic ticket CRUD working

1. ✅ Setup database schema (tickets + ticket_transactions)
2. ✅ Implement ticket API endpoints (9 endpoints)
3. ✅ Test with Postman/API client
4. ✅ Deploy to staging

**Deliverable:** Backend API functional for ticket operations (without payment)

### Phase 2: Midtrans Integration (Sprint 1 - Week 2)
**Goal:** Enable real payments

1. ✅ Setup Midtrans sandbox account
2. ✅ Implement Snap token generation endpoint
3. ✅ Implement webhook handler
4. ✅ Test payment flow end-to-end
5. ✅ Add payment status verification

**Deliverable:** Full payment flow working in sandbox

### Phase 3: Frontend Integration (Sprint 2 - Week 3)
**Goal:** Connect frontend to backend

1. ✅ Update TicketRepositoryImpl to use remote API
2. ✅ Integrate Midtrans Flutter SDK
3. ✅ Update My Tickets screen with event data
4. ✅ Add proper error handling
5. ✅ Test complete flow: Browse event → Purchase → Pay → View ticket

**Deliverable:** End-to-end working ticket purchase flow

### Phase 4: Polish & Production (Sprint 2 - Week 4)
**Goal:** Production-ready

1. ✅ Add QR codes (if needed)
2. ✅ Implement rate limiting on payment endpoints
3. ✅ Add transaction logging
4. ✅ Switch to production Midtrans keys
5. ✅ Final testing with real payment methods
6. ✅ Deploy to production

**Deliverable:** Production-ready monetization system

---

## 🔐 Security Considerations

### Payment Security
- ✅ Never store credit card details (handled by Midtrans)
- ✅ Verify webhook signatures
- ✅ Use HTTPS for all payment communication
- ✅ Implement idempotent webhook handling
- ✅ Log all payment transactions for audit

### API Security
- ✅ Authenticate all ticket endpoints (require user auth)
- ✅ Validate ticket ownership before operations
- ✅ Rate limit purchase endpoint (max 5 purchases/minute/user)
- ✅ Sanitize all input data

### Data Integrity
- ✅ Use database transactions for ticket creation + payment
- ✅ Handle race conditions (multiple webhook calls)
- ✅ Implement ticket uniqueness (attendance_code UNIQUE constraint)

---

## 📈 Success Criteria

- [ ] User can purchase ticket for paid event via Midtrans
- [ ] User can reserve ticket for free event
- [ ] Payment webhook correctly updates ticket status
- [ ] User sees tickets in My Tickets screen with event details
- [ ] Host can check in attendees via attendance code
- [ ] Cancelled payments don't create active tickets
- [ ] System handles payment pending → success flow
- [ ] System handles payment pending → failed flow
- [ ] Offline mode shows cached tickets
- [ ] All payment transactions logged for audit

---

## 🚨 Blockers & Dependencies

### External Dependencies
1. **Midtrans Account** - Need to sign up and get API keys
2. **SSL Certificate** - Webhook URL must be HTTPS
3. **Backend Infrastructure** - API endpoints must be deployed
4. **Database** - Need tickets and ticket_transactions tables

### Internal Dependencies
1. **Auth System** - Need working user authentication
2. **Events System** - Need event data to link tickets
3. **User Profile** - Need user email for payment notifications

---

## 📚 References

- Midtrans Docs: https://docs.midtrans.com/
- Midtrans Snap: https://docs.midtrans.com/en/snap/overview
- Midtrans Webhook: https://docs.midtrans.com/en/after-payment/http-notification
- Midtrans Flutter SDK: https://pub.dev/packages/midtrans_sdk
- QR Flutter: https://pub.dev/packages/qr_flutter

---

**Last Updated:** 2025-01-18
**Status:** ⚠️ Awaiting backend implementation
