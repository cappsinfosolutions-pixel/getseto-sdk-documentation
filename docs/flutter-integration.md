# GetSetO KYC SDK — Flutter Integration Guide

> **Version:** 0.1.0
> **Flutter SDK requirement:** ≥ 3.10.1

---

## Overview

Embed a complete eKYC journey into your Flutter app with a single method call.

---

## Prerequisites

- Flutter **3.10.1** or later
- Dart **3.10.1** or later
- Your **API key** (provided by GetSetO)
- Your **tenant name** (the display name for your brand)
- Your **tenant logo** as a Flutter `ImageProvider`

---

## Step 1 — Add the dependency

The SDK is distributed as a private Flutter package. Add it to your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  getseto_sdk:
    git:
      url: https://github.com/cappsinfosolutions-pixel/getseto-sdk.git
      path: packages/getseto_sdk
      ref: v0.1.0   # pin to a specific release tag
```

Then fetch the package:

```bash
flutter pub get
```

---

## Step 2 — Android setup

### 2.1 Permissions

Add the following permissions to `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag (before `<application>`):

```xml
<!-- Network access for API calls -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Camera — required for document capture and live photo -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Microphone and audio — required for In-Person Verification (IPV) -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

<!-- Location — required for In-Person Verification (IPV) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 2.2 JitPack repository

The SDK depends on libraries hosted on JitPack. Add the JitPack Maven repository to your project-level `android/build.gradle` (or `android/build.gradle.kts`):

```kotlin
// build.gradle.kts
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

### 2.3 Java / Kotlin compatibility

Ensure your app-level `android/app/build.gradle.kts` targets Java 17:

```kotlin
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}
```

### 2.4 Google Sign-In (optional)

If you are using the Google Sign-In feature for email verification, place your `google-services.json` file in `android/app/` and apply the Google Services plugin in your app-level `build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

Add the plugin classpath to the project-level `build.gradle.kts`:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

---

## Step 3 — iOS setup

### 3.1 Minimum deployment target

Set your iOS deployment target to **13.0** or later in `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

### 3.2 Permissions

Add the following keys to `ios/Runner/Info.plist`:

```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>Camera access is required to capture your documents and photo.</string>

<!-- Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for In-Person Verification.</string>

<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required for In-Person Verification.</string>
```

### 3.3 Install CocoaPods dependencies

```bash
cd ios && pod install && cd ..
```

---

## Step 4 — Launch the KYC journey

Import the SDK in the file where you want to trigger the KYC flow:

```dart
import 'package:getseto_sdk/getseto_sdk.dart';
```

Call `GetsetoKyc.launch()` from any place where you have a `BuildContext` (e.g., a button's `onPressed` handler):

```dart
await GetsetoKyc.launch(
  context,
  config: GetsetoKycConfig(
    environment: KycEnvironment.uat,    // use KycEnvironment.production for live builds
    apiKey: 'YOUR_API_KEY',
    tenantName: 'Your Brand Name',
    logo: const AssetImage('assets/images/logo.png'),
  ),
  callbacks: GetsetoKycCallbacks(
    onComplete: (result) {
      // KYC journey completed successfully
      print('Application ID: ${result.applicationId}, Status: ${result.status}');
    },
    onError: (error) {
      // A non-recoverable error occurred
      print('KYC error: $error');
    },
  ),
);
```

The SDK presents a full-screen modal over your app. When the user completes or exits the journey, the modal is dismissed and the `Future` returned by `launch()` completes.

---

## Configuration reference

`GetsetoKycConfig` is the single object you pass to `GetsetoKyc.launch()`. Required fields are marked with *.

| Parameter | Type | Description |
|---|---|---|
| `environment` * | `KycEnvironment` | Deployment environment. Use `uat` for testing, `production` for live builds. |
| `apiKey` * | `String` | Your tenant API key provided by GetSetO. Must not be empty. |
| `tenantName` * | `String` | Your brand display name. Must not be empty. |
| `logo` * | `ImageProvider` | Your brand logo shown in the SDK header. Accepts `AssetImage`, `NetworkImage`, or `MemoryImage`. |
| `theme` | `GetsetoKycTheme?` | Optional branding configuration. Defaults to the SDK's built-in theme when omitted. |
| `locale` | `String` | BCP 47 language tag (e.g., `'en'`, `'hi'`, `'gu'`). Defaults to `'en'`. |
| `googleSignInClientId` | `String?` | Your Google OAuth 2.0 web client ID. Required only if Google Sign-In is enabled for your tenant. |

### `KycEnvironment` values

| Value | Description |
|---|---|
| `KycEnvironment.uat` | Test / staging environment. Use for development and QA. |
| `KycEnvironment.production` | Live production environment. Use only in released builds. |

---

## Handling results and errors

`GetsetoKycCallbacks` defines two handlers you must provide:

### `onComplete`

Called when the user completes the KYC journey successfully.

```dart
onComplete: (KycResult result) {
  final int appId  = result.applicationId; // backend-assigned application ID
  final String status = result.status;     // e.g. "COMPLETED", "PENDING"
  final String? msg   = result.message;    // optional human-readable message

  // Navigate the user forward in your app or show a confirmation screen.
},
```

### `onError`

Called when a non-recoverable error occurs inside the SDK.

```dart
onError: (Object error) {
  // Log the error and show an appropriate fallback screen to the user.
  print('KYC failed: $error');
},
```

> The SDK dismisses its own modal before invoking either callback, so `context` is safe to use for navigation inside the handler (check `context.mounted` first as a best practice).

---

## Complete example

A fully working reference app is included alongside this guide:

```
example/
├── lib/main.dart            ← complete integration code
├── android/                 ← Android platform config with all required permissions
├── ios/                     ← iOS platform config with all required permissions
└── pubspec.yaml             ← dependency setup
```

Open `example/lib/main.dart` to see the complete integration in one file. The app uses a dummy API key and will not connect to the backend, but it compiles and serves as a copy-paste starting point.
