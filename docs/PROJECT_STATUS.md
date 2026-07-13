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
| **Home** | Real-time feed with module chips, keyword search, category + radius filters |
| **Nearby** | Dedicated tab — posts within 1–10 km, sorted nearest first, distance on cards |
| **Map** | Post markers, module + category + radius filters, nearby circle, info windows, user location |
| **Profile** | View account, edit display name, list/manage own posts, community broadcasts, settings link |
| **Broadcasting** | Admin popups + optional image; user broadcasts list, detail, helpful feedback |
| **Settings** | Dark mode + system theme (saved locally) |
| **Admin** | KYC review, flag/delete posts, ban/unban/delete users, posts timeline, map, broadcast tab |
| **Lost/found recovery** | QR claim flow — counterparty starts, author confirms, QR + GPS handoff; fulfilled listings hidden; profile **Completed recoveries** |
| **Lend/borrow contracts** | Auto-generated terms, dual signatures, QR handshake, GPS log; fulfilled listings hidden from feed/map; profile **Completed exchanges** |
| **Notifications** | In-app center + tray alerts (Spark) — lend/borrow, KYC, admin actions; EmailJS only for KYC approve/reject |
| **Backend** | Firebase Auth & Firestore, ImageKit uploads, EmailJS verification emails |

---

## Left to build

| Module | What's missing |
|--------|----------------|
| **Broadcasting (advanced)** | Interactive polls, admin feedback analytics |
| **Mutual confidence** | Secure mediated contact, trust cards, safe meetup suggestions |
| **Admin (legal)** | Export evidence package (CNIC, selfie, contracts, GPS logs) |

---

## Proposal coverage (rough)

- **Core platform** (auth, KYC, posting, map, basic admin): ~**done**
- **Advanced trust/legal features** (nearby, search, broadcast, admin legal export): ~**partial** (lend/borrow contracts + in-app notifications done)

---

## Stack notes

Proposal mentions **Firebase Storage**; app uses **ImageKit** for images and signature PNGs. Lend/borrow uses `signature`, `qr_flutter`, and `mobile_scanner`.

---

See also: [IMPLEMENTED.md](./IMPLEMENTED.md) · [MAPS_SETUP.md](./MAPS_SETUP.md)
