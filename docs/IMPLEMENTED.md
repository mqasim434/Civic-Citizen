# Civic Citizen — What's Implemented

This document summarizes features that are **already built** in the Flutter app as of the current codebase. Use it when onboarding a new developer or handing the project to someone else.

---

## Overview

**Civic Citizen** is a community app where verified users can create civic posts (lost/found items, charity, resources, lend/borrow), browse them on a feed and map, and interact after identity verification. Admins review KYC submissions, moderate posts, and manage users.

**Stack:** Flutter · Firebase Auth & Firestore · ImageKit (image uploads) · EmailJS (verification emails) · Google Maps · Provider (state management)

---

## App flow & navigation

| Stage | Screen | Behavior |
|-------|--------|----------|
| Launch | Splash | Animated splash (~2s), then routes by auth + profile state |
| Guest | Login / Sign up | Email/password auth |
| New user | KYC | CNIC front/back + selfie upload before app access |
| Waiting | Verification pending | Live-updates when admin approves/rejects |
| Rejected | Verification rejected | Shows optional rejection reason; can sign out |
| Verified user | Main shell | Home feed, Map, Profile tabs |
| Admin | Admin dashboard | Separate shell with verifications, posts, map, users |

Post-login routing is centralized in `lib/core/navigation/post_auth_navigation.dart`:

1. If UID exists in Firestore `admins` collection → **Admin dashboard**
2. Else if KYC not submitted → **KYC flow**
3. Else if `verificationStatus == verified` → **Home**
4. Else if `verificationStatus == rejected` → **Rejected screen**
5. Else → **Verification pending**

---

## Authentication

**Location:** `lib/features/auth/`

- Email/password **sign up** with optional display name
- Email/password **sign in**
- **Sign out**
- **Forgot password** (Firebase password reset email via dialog on login screen)
- Auth state via `AuthController` + `AuthService` (Firebase Auth)
- Minimum password length: 6 characters

---

## Identity verification (KYC)

**Location:** `lib/features/kyc/`, `lib/features/verification/`

- Two-step wizard:
  1. **CNIC front & back** — camera or gallery
  2. **Selfie** — camera or gallery with **ML Kit face detection** (must detect a face)
- Documents uploaded to **ImageKit** (`kyc/cnic/{uid}/…`, `kyc/selfie/{uid}`)
- User profile saved to Firestore `users` collection with:
  - `verificationStatus`: `pending` | `verified` | `rejected`
  - `kycSubmittedAt`, image URLs, display name, email
- **Verification pending** screen listens to Firestore and auto-navigates when status changes
- **Verification rejected** screen shows admin rejection reason when present

---

## Posts (citizen features)

**Location:** `lib/features/posts/`

### Post modules

Six module types (`PostModule`):

| Module | Label | Example categories |
|--------|-------|-------------------|
| `lost` | Lost | Keys, Wallet, Phone, Documents, Bag, Other |
| `found` | Found | (same as Lost) |
| `charity` | Charity | Clothes, Books, Food, Furniture, Electronics, Other |
| `resources` | Resources | Conveyance, Study materials, Tools, Other |
| `lend` | Lend | Electronics, Books, Accessories, Tools, Other |
| `borrow` | Borrow | (same as Lend) |

“Other” category supports a custom label (`categoryCustom`).

### Create post

- Module, category, title, description, contact number, location (required)
- **At least one image** required; multiple images supported
- Images uploaded to ImageKit (`posts/{postId}/…`) after Firestore doc is created
- **Location:** type manually or open **map picker** (`LocationPickerView`)

### Edit / delete

- Authors can **edit** post fields (module, category, title, description, contact, location) from Profile
- Authors can **delete** their own posts (with confirmation)

### Browse

- **Home feed** — real-time Firestore stream, filter chips by module (All + each module)
- **Post detail** — full view with images, module badge, category, location, contact, author
- **Post cards** — thumbnail, module badge, title, description preview

### Map view

**Location:** `lib/features/home/views/map_placeholder_view.dart` (`MapPostsView`)

- Google Map with markers for posts that have a resolvable location
- Geocoding: address → coordinates via `geocoding` package; also supports `lat,lng` strings
- Module filter chips + category filter dropdown
- Color-coded markers by module
- Custom info windows on marker tap → navigate to post detail
- “My location” button and auto-center on user when permission granted
- Default map center: Lahore (31.5204, 74.3587)

### Location picker (create/edit post)

**Location:** `lib/features/posts/views/location_picker_view.dart`

- Full-screen Google Map; tap to place marker
- Reverse geocoding on confirm → returns address string (or `lat,lng` fallback)
- Uses device location when available

See [MAPS_SETUP.md](./MAPS_SETUP.md) for Google Maps API key setup.

---

## Profile & settings

**Location:** `lib/features/profile/`, `lib/features/settings/`

### Profile tab

- Avatar initial, display name, email
- **My posts** list (real-time) with View / Edit / Delete actions
- Link to Settings
- Sign out

### Settings

- **Dark mode** toggle
- **Use system theme** toggle
- Theme preference persisted via `SharedPreferences`

---

## Admin panel

**Location:** `lib/features/admin/`

Admin access: create a document at Firestore `admins/{uid}` (Firebase Console only). Admins skip KYC and land on the admin dashboard after login.

### Admin dashboard tabs

1. **Verifications** — list of users with `verificationStatus == pending`
   - Tap user → review CNIC/selfie images
   - **Approve** → sets `verified`, sends EmailJS notification
   - **Decline** → sets `rejected` with optional reason, sends EmailJS notification

2. **Posts timeline** — all posts with module filter
   - Mark post **inappropriate** / **appropriate** (optional reason)
   - **Delete** post
   - Visual indicator for flagged posts

3. **Map** — same `MapPostsView` as citizens (moderation context)

4. **User management** — all users from Firestore
   - **Ban / unban** (optional reason stored on profile)
   - **Delete profile** — removes user doc and all their posts (batch delete)

---

## Backend & integrations

### Firebase

| Service | Usage |
|---------|--------|
| **Firebase Auth** | Sign up, sign in, password reset |
| **Cloud Firestore** | `users`, `posts`, `admins` collections |
| **google-services.json** | Committed for Android (`android/app/google-services.json`) |

**Firestore collections** (see `lib/core/constants/app_constants.dart`):

- `users` — profiles, KYC data, verification status, ban flags
- `posts` — civic posts with module, category, location, images, moderation flags
- `admins` — admin UID allowlist

> **Note:** `ios/Runner/GoogleService-Info.plist` is not in the repo. iOS Firebase requires adding it locally from the Firebase Console.

### ImageKit

**Location:** `lib/core/config/imagekit_config.dart`, `lib/core/services/imagekit_service.dart`

- Direct server-side upload using public + private keys (configured in code)
- Used for KYC images and post images
- Replaces Firebase Storage

### EmailJS

**Location:** `lib/core/config/emailjs_config.dart`, `lib/core/services/emailjs_service.dart`

- Sends best-effort email when admin approves or rejects KYC
- No Firebase Cloud Functions required
- Failures are logged but do not block Firestore updates

---

## UI & architecture

### State management

- **Provider** — `AuthController`, `KycController`, `PostController`, `ThemeController`
- **Services** — `AuthService`, `KycService`, `PostService`, `AdminService`, `ImageKitService`, `EmailJsService`

### Theming

- Light and dark themes (`lib/core/theme/app_theme.dart`)
- Google Fonts typography
- `flutter_animate` on splash, login, and KYC screens

### Shared widgets

- `AppButton`, `AppTextField`, `AppScaffold` (`lib/shared/widgets/`)

### Routing

- Named routes via `AppRouter` (`lib/core/routes/app_router.dart`)
- Global `navigatorKey` for navigation outside widget tree

---

## Permissions (Android)

Already declared in `AndroidManifest.xml`:

- Camera (KYC, post images)
- Fine & coarse location (map, location picker)
- Read external storage / read media images (image picker)

iOS location usage string is in `Info.plist` (see MAPS_SETUP.md).

---

## Local setup files (not in Git)

These are required on a fresh clone but are gitignored or contain placeholders:

| File | Platform | Purpose |
|------|----------|---------|
| `android/local.properties` | Android | `sdk.dir`, `MAPS_API_KEY` |
| `ios/Runner/AppDelegate.swift` | iOS | Replace `YOUR_GOOGLE_MAPS_API_KEY` with real key |
| `ios/Runner/GoogleService-Info.plist` | iOS | Firebase config (add from Console) |
| `android/key.properties` + keystore | Android | Release signing only (optional for debug) |

Committed config (no local file needed for basic run):

- ImageKit keys in `lib/core/config/imagekit_config.dart`
- EmailJS keys in `lib/core/config/emailjs_config.dart`
- Android Firebase: `android/app/google-services.json`

---

## Project structure (features)

```
lib/
├── core/           # Routes, theme, constants, config, shared services
├── features/
│   ├── admin/      # Admin dashboard, verification review, moderation
│   ├── auth/       # Login, signup, auth service
│   ├── home/       # Main shell, dashboard feed, map view
│   ├── kyc/        # Identity verification wizard
│   ├── posts/      # CRUD, cards, detail, location picker
│   ├── profile/    # User profile & my posts
│   ├── settings/   # Theme settings
│   ├── splash/     # Splash screen
│   └── verification/ # Pending & rejected states
└── shared/widgets/ # Reusable UI components
```

---

## Known limitations / not implemented

- Inappropriate posts are **flagged in admin UI** but still appear in the public home feed (no client-side hide filter yet)
- No in-app chat or messaging between users
- No push notifications (FCM)
- No social login (Google, Apple, etc.)
- Edit post does not support changing images after creation
- iOS Google Maps key is a hardcoded placeholder until edited in `AppDelegate.swift`
- `assets/env.defaults.json` is bundled but not wired to runtime config (ImageKit/EmailJS use Dart config files instead)

---

## Related docs

- [MAPS_SETUP.md](./MAPS_SETUP.md) — Google Maps API key for Android & iOS
