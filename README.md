# Anigmaa - Tinder for Hangouts 🔥

**Sosial Network untuk Temuin Orang & Nongki Bareng — Instant, Low-Friction, Real-Time**

Anigmaa adalah platform sosial yang menghubungkan orang untuk hangout spontan. Swipe, match, hangout — semudah itu.

---

## 🎯 **CORE CONCEPT**

### **Bukan Event App Biasa**
Ini **social network dengan events**, bukan sebaliknya. Think:
- **TikTok** (feed algorithm)
- **Tinder** (swipe & match)
- **Discord** (real-time chat/voice)

### **Target Audience**
- **Gen Z Indonesia** (18-30 tahun)
- **Urban, Spontan, FOMO-driven**
- **"Gabut tapi gatau mau ngapain"**

---

## 🔥 **DUA POV UTAMA**

### **POV 1: Si Gabut (Discovery Mode)**
> "Lagi gabut nih, mau ngapain ya?"

**Journey:**
1. Buka app → Langsung **Feed** (bukan browse)
2. Liat **Story Bar** (who's hanging NOW)
3. Scroll **vertical feed** (swipeable cards)
4. Tap **"Gabut Nih?"** → Auto-match to 3 rooms
5. Swipe right → **Instant join** (1-tap)
6. Masuk chat room → Done!

**Target:** Join dalam **< 30 detik**

---

### **POV 2: Si Host (Creator Mode)**
> "Mau ngajak orang nongki ah"

**Journey:**
1. Tap **+ button**
2. Fill **4 fields** (judul, waktu, lokasi, max people)
3. Tap **"GO LIVE 🔴"**
4. Room langsung aktif
5. Auto-invite nearby users
6. Wait di lobby sambil chat

**Target:** Go live dalam **< 1 menit**

---

## 📱 **BOTTOM NAVIGATION (5 Tabs)**

```
┌─────────────────────────────────┐
│  🏠      👥      ➕      💬     👤  │
│ Feed  Nearby  Create  Chat  Me  │
└─────────────────────────────────┘
```

### **1. 🏠 Feed (Home)**
- **Story Bar** dengan LIVE rooms
- **Gabut Button** (hero CTA)
- **Vertical feed** of hangouts
- **Swipe** left (skip) / right (join)

### **2. 👥 Nearby (Map)**
- Live map dengan pins berwarna:
  - 🔴 Red = Live/NOW
  - 🔵 Blue = <1 hour
  - 🟢 Green = Nanti
- Filter by time/vibe
- Quick join from map

### **3. ➕ Create**
- Quick create form
- Templates: Ngopi, Makan, Main, dll
- GO LIVE button
- Schedule optional

### **4. 💬 Chat**
- Active room chats
- DMs with friends
- Group chats from past hangouts
- Notifications

### **5. 👤 Me (Profile)**
- Profile card dengan avatar, bio, badges
- Past hangouts
- Reviews & ratings
- Settings & logout

---

## 🎨 **UI/UX DESIGN PRINCIPLES**

### **A. INSTANT GRATIFICATION**
- ✅ **1-tap join** (no detail pages)
- ✅ **Auto-match** dari Gabut button
- ✅ **Inline preview** di feed
- ✅ **Live indicators** (12 online)

### **B. SOCIAL PROOF**
- ✅ **Attendee avatars** (stacked)
- ✅ **Host reputation** (badges, rating)
- ✅ **Live count** ("12 online" vs "12 joined")
- ✅ **Reviews** dari past attendees

### **C. LOW FRICTION**
- ✅ **Smart defaults** (current location, NOW, public)
- ✅ **Templates** for quick create
- ✅ **Guest join** (no signup until 2nd join)
- ✅ **Voice-first optional** (text default)

### **D. TRUST & SAFETY**
- ✅ **Verified profiles** (badge)
- ✅ **Report/block** feature
- ✅ **Friend-only mode**
- ✅ **Age verification** (18+)

---

## 🌟 **UNIQUE FEATURES**

### **1. "Gabut Nih?" Button**
```
Tap → Modal:
- Pilih time: [Sekarang] [30m] [Nanti]
- Pilih vibe: ☕ 🍜 🎮 🎨 ⚽ 🎵
- Set radius: 2km
→ AI match ke 3 rooms
→ Swipe right to join
```
**Like speed dating for hangouts**

### **2. Story Bar (Active Rooms)**
```
┌─ STORY BAR ────────────────┐
│ 👤 👤 👤 LIVE 🔴 +12      │
│ Tap → Preview → Join       │
└────────────────────────────┘
```
**Who's hanging NOW**

### **3. Swipeable Feed Cards**
```
┌─ FEED CARD ─────────────┐
│ 📍 500m • NOW           │
│ ☕ Ngopi di Blok M      │
│ 👤👤👤 +12 online        │
│ "Yuk ngopi sambil ngobrol" │
│                          │
│ ← Skip    [JOIN NOW] →  │
└─────────────────────────┘
```
**Swipe atau tap JOIN**

### **4. Quick Create Templates**
```
Templates:
- ☕ Ngopi (auto-fill: Kopi Kenangan, NOW, 5 pax)
- 🍜 Makan (auto-fill: food court, lunch, 4 pax)
- 🎮 Main (auto-fill: game cafe, 2h, 4 pax)
- 💬 Ngobrol (auto-fill: public space, NOW, 3 pax)
```

### **5. "After Party" Chat**
- Auto-create group chat setelah hangout selesai
- "Mau lagi minggu depan?"
- Build community & recurring hangouts

### **6. Badges & Gamification**
- 🏆 **Host 10x** = "Community Builder"
- 🦋 **Join 5x** = "Social Butterfly"
- ⭐ **4.5+ rating** = "Top Host"
- 🔥 **Weekly streak** = "Consistent Hangouter"

---

## 🏗️ **TECHNICAL ARCHITECTURE**

### **State Management**
- **BLoC Pattern** (flutter_bloc)
- **EventsBloc**: Feed, filters, join/leave
- **UserBloc**: Profile, badges, following
- **ChatBloc**: Messages, notifications

### **Backend (Future)**
- **Firebase**: Auth, Firestore, Cloud Functions
- **Real-time DB**: Live updates, presence
- **Push Notifications**: Join alerts, chat messages
- **Geolocation**: Nearby matching

### **Key Dependencies**
```yaml
dependencies:
  flutter_bloc: ^9.1.1
  get_it: ^7.6.0           # DI
  dartz: ^0.10.1           # Functional programming
  equatable: ^2.0.7        # Value equality
  cached_network_image: ^3.3.1
  google_fonts: ^6.2.1
  shared_preferences: ^2.2.2
  image_picker: ^1.2.0
```

---

## 🚀 **MVP FEATURES (Phase 1)**

### ✅ **Completed**
- [x] Feed dengan swipeable cards
- [x] Gabut button dengan quick match
- [x] Time filters (Sekarang, 30m, 1h, 2h)
- [x] Live indicators (red badge + online count)
- [x] Direct join CTA
- [x] Attendee avatars
- [x] Filter badge dengan clear button
- [x] Map dengan color-coded pins
- [x] Quick create form
- [x] Profile dengan badges

### 🔄 **In Progress**
- [ ] Story bar dengan active rooms
- [ ] Swipe gestures (left/right)
- [ ] Auto-match algorithm
- [ ] Chat rooms
- [ ] Voice chat integration

### 🚨 **MAJOR REVISION: Twitter-Style Social Feed**

**Current State**: Instagram/Pinterest hybrid for events
- Card-based layout with large images
- All content must be events (structured data)
- No text-only posts
- Missing core social features: like, comment, share, repost

**New Direction**: Twitter-style social media dengan events
- **Feed Design**: Twitter-style timeline
  - Text posts (primary)
  - Text + images (1-4 grid)
  - Text + event attachment
  - Polls (optional)
- **Core Social Features**:
  - ❤️ **Like/Reactions** - tap heart, realtime count
  - 💬 **Comments** - nested threads, reply support
  - 🔁 **Repost** - quote tweet style + simple repost
  - 📤 **Share** - internal (to followers) + external (WA/IG/etc)
- **Post Types**:
  - Text only (unlimited chars)
  - Text + Image(s) (1-4 images)
  - Text + Event (event as attachment)
  - Poll

**Architecture Changes**:
```
domain/entities/
  - post.dart (NEW) - text, images, author, likes, comments
  - comment.dart (NEW) - nested comments
  - interaction.dart (NEW) - like/repost tracking
  - user.dart (NEW) - full user profile

data/models/
  - post_model.dart (NEW)
  - comment_model.dart (NEW)
  - interaction_model.dart (NEW)

presentation/
  - bloc/posts/ (NEW)
  - pages/feed/ (NEW - Twitter-style feed)
  - pages/post_detail/ (NEW)
  - pages/create_post/ (NEW)
  - widgets/post_card/ (NEW)
```

**Why This Matters**:
- Events alone = discovery app (Meetup.com)
- Text posts + events = social network (Twitter + Meetup)
- Engagement: posting text easier than creating events
- Virality: repost/share spreads content faster
- Community: comments build discussions

### 📅 **Phase 2 (Next)**
- [x] Twitter-style feed implementation
- [x] Post create/read/like/comment/repost
- [ ] Following system
- [ ] DMs (direct messages)
- [ ] Stories/Status (24h)
- [ ] Reviews & ratings
- [ ] Push notifications

### 📅 **Phase 3 (Future)**
- [ ] Voice rooms (Clubhouse-style)
- [ ] Premium features
- [ ] Achievement system
- [ ] Community tools
- [ ] Event calendar sync

---

## 📊 **SUCCESS METRICS**

### **North Star Metric**
**Weekly Active Hangouts** (user joins hangout per week)

### **Key Metrics**
1. **Time to First Join**: < 30 detik
2. **Repeat Hangout Rate**: 30%+ (join lagi dalam 7 hari)
3. **Host Retention**: 40%+ create 2+ hangouts
4. **Chat Engagement**: 5+ messages/user/day
5. **Match Accuracy**: 60%+ join after Gabut match

### **Funnel Metrics**
```
100 users open app
├─ 80 scroll feed (80%)
├─ 50 tap card/Gabut (50%)
├─ 30 join room (30%)
└─ 15 create next week (15% activation)
```

---

## 💡 **DESIGN DECISIONS**

### **Why Vertical Feed?**
- Users trained by TikTok/Instagram
- Faster scrolling
- Bigger cards = more info
- Swipe gestures natural

### **Why "Gabut" Button?**
- **Speaks Gen Z language**
- Embraces boredom as valid state
- Low commitment ("coba aja")
- Removes decision paralysis

### **Why Story Bar?**
- **FOMO driver** (missing out on fun)
- Visual & fast
- Promotes live/NOW events
- Builds habit (check stories daily)

### **Why 1-Tap Join?**
- **Reduce friction** from 5 steps → 1
- Trust social proof (12 online)
- Impulse decision = more joins
- Can leave easily if awkward

---

## 🎨 **COPYWRITING (Indonesian Gen Z)**

### **Tone of Voice**
- ✅ Santai, friendly, emoji
- ✅ "Lu/gue" casual
- ✅ Slang: gabut, nongki, gaskeun
- ❌ Formal, corporate, cringe

### **Examples**
```
❌ "Temukan acara menarik di sekitar Anda"
✅ "Gabut? Yuk nongki bareng! 🔥"

❌ "Bergabung dengan 12 peserta"
✅ "12 online • Join yuk! ✨"

❌ "Tidak ada acara tersedia"
✅ "Waduh belum ada yang gabut nih 😅"
```

---

## 🔮 **MONETIZATION STRATEGY**

### **Freemium Model**

**Free Tier:**
- Join 5 hangouts/week
- Create 2 hangouts/week
- Basic filters
- Text chat only

**Premium Tier (Rp 29k/month):**
- ♾️ **Unlimited joins & creates**
- 🎯 **Advanced filters** (vibe match score)
- 🎤 **Voice chat** access
- 🏆 **Verified badge**
- 🚀 **Early access** to new features
- 📊 **Analytics** (who viewed profile)

**Revenue Streams:**
- Monthly subscriptions
- Venue partnerships (coffee shops get exposure)
- Sponsored hangouts
- Boosted posts (bump to top)

---

## 🛠️ **SETUP & DEVELOPMENT**

### **Install Dependencies**
```bash
flutter pub get
```

### **Run App**
```bash
flutter run -d windows   # Windows
flutter run -d chrome    # Web
flutter run              # Auto-detect
```

### **Build for Production**
```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

---

## 📁 **PROJECT STRUCTURE**

```
lib/
├── core/
│   ├── constants/       # Colors, strings
│   ├── services/        # Auth, storage
│   └── utils/           # Helpers
├── domain/
│   ├── entities/        # Event, User, Chat
│   └── usecases/        # Business logic
├── data/
│   ├── models/          # Data models
│   └── repositories/    # Data sources
├── presentation/
│   ├── bloc/            # State management
│   ├── pages/           # Screens
│   │   ├── feed/        # Home feed
│   │   ├── nearby/      # Map view
│   │   ├── create/      # Create hangout
│   │   ├── chat/        # Chat rooms
│   │   └── profile/     # User profile
│   └── widgets/         # Reusable UI
└── main.dart
```

---

## 🤝 **CONTRIBUTING**

Contributions welcome! Please:
1. Fork the repo
2. Create feature branch
3. Follow Flutter style guide
4. Write tests
5. Submit PR

---

## 📄 **LICENSE**

MIT License - feel free to use for learning/portfolio

---

**Anigmaa** - Swipe, Match, Hangout! 🔥

*"Karena gabut itu real, dan temen nongki itu penting"*
