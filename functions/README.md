# Cloud Functions (optional — Blaze plan only)

This folder is **not required** for Civic Citizen on the free Firebase **Spark** plan.

Notifications work on Spark via:

- Firestore in-app notifications (bell + list)
- Local tray alerts while the app is running
- EmailJS for KYC approve/reject only (see `docs/NOTIFICATIONS_SETUP.md`)

Deploy `index.js` only if you upgrade to **Blaze** and want FCM push when the app is fully closed:

```bash
cd functions && npm install && cd ..
firebase use civic-citizen-3d0af
firebase deploy --only functions
```
