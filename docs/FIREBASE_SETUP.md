# Firebase Setup Guide — Civic Citizen

This guide walks you from creating a Firebase account to having Firebase Auth working in the Civic Citizen Flutter app.

---

## 1. Create a Firebase account and project

1. Go to **[Firebase Console](https://console.firebase.google.com)** and sign in with your Google account.
2. Click **“Create a project”** (or “Add project”).
3. Enter a **project name** (e.g. `Civic Citizen`).
4. (Optional) Disable Google Analytics if you don’t need it for now.
5. Click **“Create project”** and wait until it’s ready, then click **“Continue”**.

You now have a Firebase project. All services (Auth, Firestore, etc.) are configured inside this project.

---

## 2. Register your Android app

1. In the Firebase Console, open your project.
2. On the **Project Overview** page, click the **Android icon** to add an Android app.
3. **Android package name** must match your Flutter app. For this project it is:
   ```text
   com.example.civic_citizen
   ```
   You can confirm in `android/app/build.gradle.kts` under `applicationId`.
4. (Optional) Fill in **App nickname** (e.g. `Civic Citizen Android`) and **Debug signing certificate SHA-1** if you need Google Sign-In later. You can skip for Email/Password only.
5. Click **“Register app”**.
6. On the next step, **download `google-services.json`** and click **“Next”**.
7. Firebase will show you instructions to add the Google Services plugin. We’ll do that in the next section — click **“Next”** and then **“Continue to console”**.

---

## 3. Add `google-services.json` to your Flutter project

1. Open your project folder: `D:\flutter_projects\civic_citizen`.
2. Move the downloaded **`google-services.json`** into:
   ```text
   android/app/google-services.json
   ```
   So the file path is: `civic_citizen/android/app/google-services.json`.
3. Do **not** put it in `android/` or `lib/` — it must be inside `android/app/`.

---

## 4. Enable the Google Services plugin (Android)

The Android app must use the Google Services plugin so it can read `google-services.json`.

1. Open **`android/settings.gradle.kts`**.
2. In the `plugins` block, add the Firebase/Google Services plugin. It should look like this (add the line with `com.google.gms.google-services`):

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false   // add this
}
include(":app")
```

3. Open **`android/app/build.gradle.kts`**.
4. At the **top**, with the other plugin lines, add:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // add this
}
```

5. Save both files.

---

## 5. Enable Email/Password sign-in in Firebase

1. In the Firebase Console, go to **Build → Authentication**.
2. Click **“Get started”** if you see it.
3. Open the **“Sign-in method”** tab.
4. Click **“Email/Password”**.
5. Turn **Enable** ON.
6. Leave **“Email link”** OFF unless you want passwordless sign-in later.
7. Click **“Save”**.

Your app will use this for login and signup.

---

## 6. Turn Firebase back on in the app

The project is currently set up to run **without** Firebase so you can view the UI. To use real auth:

1. Open **`lib/main.dart`**.
2. Uncomment the Firebase import at the top:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   ```
3. Uncomment the initialization line in `main()`:
   ```dart
   await Firebase.initializeApp();
   ```

So your `main()` looks like this:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CivicCitizenApp());
}
```

4. Save and run the app:
   ```bash
   flutter run
   ```

You should be able to **Sign up** and **Sign in** with email and password; accounts will appear under **Authentication → Users** in the Firebase Console.

---

## 7. (Optional) iOS setup

If you will run on iPhone or iPad:

1. In Firebase Console, **Project Overview** → click the **iOS icon** and add an iOS app.
2. **iOS bundle ID**: use the one from Xcode/Flutter (e.g. `com.example.civicCitizen` — check `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`).
3. Download **`GoogleService-Info.plist`**.
4. Open the **`ios/Runner`** folder in Xcode (or Finder) and **copy `GoogleService-Info.plist`** into **`ios/Runner/`**.
5. In Xcode, right‑click **Runner** in the project navigator → **Add Files to "Runner"** → select **GoogleService-Info.plist** and ensure **“Copy items if needed”** and the **Runner** target are checked.

After this, `Firebase.initializeApp()` will work on iOS as well.

---

## 8. (Optional) FlutterFire CLI — one command for all platforms

Instead of manually adding Android and iOS apps and downloading config files, you can use the **FlutterFire CLI** to generate a single Dart file and link your project:

1. Install the CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. From your project root:
   ```bash
   cd D:\flutter_projects\civic_citizen
   flutterfire configure
   ```
3. Sign in when prompted and select your Firebase project (or create one).
4. The CLI will:
   - Create/register Android and iOS apps if needed
   - Download and place `google-services.json` and `GoogleService-Info.plist`
   - Generate **`lib/firebase_options.dart`** with default options

Then in **`lib/main.dart`** you can use:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CivicCitizenApp());
}
```

This is especially useful when you add more platforms (e.g. web) later.

---

## Quick checklist

- [ ] Firebase project created at [console.firebase.google.com](https://console.firebase.google.com)
- [ ] Android app registered with package name `com.example.civic_citizen`
- [ ] `google-services.json` placed in `android/app/`
- [ ] `com.google.gms.google-services` plugin added in `settings.gradle.kts` and `app/build.gradle.kts`
- [ ] **Authentication → Sign-in method → Email/Password** enabled
- [ ] In `lib/main.dart`: Firebase import and `await Firebase.initializeApp();` uncommented
- [ ] (Optional) iOS app added and `GoogleService-Info.plist` in `ios/Runner/`
- [ ] (Optional) `flutterfire configure` run and `firebase_options.dart` used in `main.dart`

---

## Troubleshooting

| Issue | What to do |
|--------|------------|
| “Failed to load FirebaseOptions from resource” | Ensure `google-services.json` is in `android/app/` and the Google Services plugin is applied in both `settings.gradle.kts` and `app/build.gradle.kts`. Then run `flutter clean` and `flutter run`. |
| “minSdkVersion” / “NDK” errors | Already fixed in this project: `minSdk = 23` and `ndkVersion = "27.0.12077973"` in `android/app/build.gradle.kts`. |
| Sign-in does nothing or “Firebase not configured” | You’re still running without init. Uncomment the Firebase import and `Firebase.initializeApp()` in `main.dart`. |
| New users not showing | In Firebase Console go to **Authentication → Users**; new accounts appear there after sign-up. |

If you hit an error not listed here, copy the full message and the step you were on — that will make it easy to narrow down.
