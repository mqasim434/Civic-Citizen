# Civic Citizen — Project Status

Short overview of what is **built** vs what the **proposal still requires**.

---

## Done

| Area | What's working |
|------|----------------|
| **Auth** | Email signup/login, password reset, sign out |
| **KYC (3FV)** | CNIC front/back upload, camera-only selfie + ML Kit face check, admin approve/reject, pending/rejected screens |
| **Civic posts** | Lost, Found, Charity, Resources, Lend, Borrow — create (with images + location), edit, delete, detail view |
| **Location** | Manual address, map pin picker, reverse geocoding |
| **Home** | Real-time feed with module filter chips |
| **Map** | Post markers, module + category filters, info windows, user location |
| **Profile** | View account, list/manage own posts, settings link |
| **Settings** | Dark mode + system theme (saved locally) |
| **Admin** | KYC review, flag/delete posts, ban/unban/delete users, posts timeline, map |
| **Lend/borrow contracts** | Auto-generated terms, dual signatures, QR handshake, GPS log; fulfilled listings hidden from feed/map; profile **Completed exchanges** |
| **Backend** | Firebase Auth & Firestore, ImageKit uploads, EmailJS verification emails |

---

## Left to build

| Module | What's missing |
|--------|----------------|
| **Search & filter** | Keyword search; radius filter; search on home |
| **Nearby items** | Posts within 1–5 km of user; store lat/lng on posts |
| **Lost/found (advanced)** | Claim flow with QR confirmation on recovery |
| **Broadcasting** | Mass broadcasts, polls, audience feedback |
| **Mutual confidence** | Secure mediated contact, trust cards, safe meetup suggestions |
| **Admin (legal)** | Export evidence package (CNIC, selfie, contracts, GPS logs) |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **Polish** | Edit profile, enforce bans, hide flagged posts from public feed |

---

## Proposal coverage (rough)

- **Core platform** (auth, KYC, posting, map, basic admin): ~**done**
- **Advanced trust/legal features** (nearby, search, broadcast, FCM, admin legal export): ~**partial** (lend/borrow contracts done)

---

## Stack notes

Proposal mentions **Firebase Storage**; app uses **ImageKit** for images and signature PNGs. Lend/borrow uses `signature`, `qr_flutter`, and `mobile_scanner`.

---

See also: [IMPLEMENTED.md](./IMPLEMENTED.md) · [MAPS_SETUP.md](./MAPS_SETUP.md)
