# Google Maps Setup — Civic Citizen

The location picker (optional when creating a post) uses Google Maps. You need a Google Maps API key.

---

## 1. Get an API key

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create a project or select an existing one.
3. Enable **Maps SDK for Android** and **Maps SDK for iOS**.
4. Enable **Geocoding API** (for reverse geocoding: coordinates → address).
5. Go to **Credentials** → **Create credentials** → **API key**.
6. Copy the API key.

---

## 2. Configure the app

### Android

Edit **`android/app/src/main/AndroidManifest.xml`** and replace `YOUR_GOOGLE_MAPS_API_KEY`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY"/>
```

### iOS

Edit **`ios/Runner/AppDelegate.swift`** and replace `YOUR_GOOGLE_MAPS_API_KEY`:

```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
```

---

## 3. Permissions

Location permissions are already added:

- **Android**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- **iOS**: `NSLocationWhenInUseUsageDescription`

---

## Usage

When creating a post:

- **Manual**: Type the location in the text field.
- **Map picker**: Tap the map icon in the location field to open the map, select a point, and confirm. The address is filled in automatically.
