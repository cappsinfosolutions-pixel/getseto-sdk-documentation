# GetSetO KYC SDK — Flutter Integration Guide

> **Version:** 1.2.0
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
      url: https://github.com/getseto-com/getseto-sdk.git
      ref: v1.2.0   # pin to a specific release tag
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
| `logo` * | `ImageProvider` | Your brand logo shown in the SDK header. Accepts `AssetImage`, `NetworkImage`, or `MemoryImage`. Recommended size W 200px x H 50px|
| `theme` | `GetsetoKycTheme?` | Optional branding configuration. Defaults to the SDK's built-in theme when omitted. |
| `locale` | `String` | BCP 47 language tag (e.g., `'en'`, `'hi'`, `'gu'`). Defaults to `'en'`. |
| `googleSignInClientId` | `String?` | Your Google OAuth 2.0 web client ID. Required only if Google Sign-In is enabled for your tenant. |
| `accessToken` | `ApplicationAccessToken?` | **Advanced.** Pre-obtained access token for bypassing the SDK's own OTP login. When set, the SDK skips the mobile/OTP screens and starts the KYC journey directly. See [Advanced: Access Token Login](#advanced-access-token-login) for details. |

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

---

## Advanced: Access Token Login (Tenant-Handled OTP) {#advanced-access-token-login}

> **This section is for advanced integrations only.** If you just want to embed the KYC journey in your app, [Steps 1–4 above](#step-4--launch-the-kyc-journey) are all you need.

By default, the SDK handles the entire login experience — it shows a screen where the user types their mobile number, sends an OTP to that number, and verifies it. Everything is automatic.

But if **your app already has its own OTP or authentication flow**, you can skip the SDK's login screens entirely. Once your app has verified the user, you get a token from GetSetO through a server-to-server call, and then hand that token to the SDK. The SDK will jump straight to the KYC steps — no mobile or OTP screen shown at all.

### How it works

1. Your Flutter app shows **your own** mobile entry / login screen.
2. The user enters their mobile number and verifies it via OTP — using **your own OTP system**.
3. Once verified, your Flutter app calls **your own backend** to get a GetSetO access token.
4. Your backend makes a server-to-server call to GetSetO (using your Secret Key) and gets back a token.
5. Your backend returns only the token (and a few fields) to your Flutter app.
6. You pass those values to `GetsetoKycConfig.accessToken` when launching the SDK.
7. The SDK validates the token silently, then the KYC journey begins immediately.

```
Your Flutter App              Your Backend               GetSetO API
       │                            │                         │
       │── POST /your-api/otp ─────►│                         │
       │   (mobile + otp)           │  (verify OTP yourself)  │
       │                            │                         │
       │── POST /your-api/kyc-token►│                         │
       │                            │── POST /api/tenant-api/─►│
       │                            │       access-token       │
       │                            │◄── { Token, ... } ──────│
       │◄── { token, mobile, ... }──│                         │
       │                            │                         │
       │  (launch SDK with token)   │                         │
       ▼                            │                         │
   KYC Journey starts               │                         │
```

### Step A — Get the token from your backend

Your backend calls GetSetO's `POST /api/tenant-api/access-token` (a server-to-server, encrypted call) and returns the relevant fields to your Flutter app. See [GetSetO API — Get Access Token](getseto-api.md#get-access-token-server-to-server) for the full server-side documentation and C# example.

> **Important:** Your GetSetO **Secret Key must never appear in your Flutter code.** It belongs on your backend server only.

Your backend should return a JSON object like:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "mobile": "9876543210",
  "mobileRelationshipId": 1,
  "source": 1
}
```

### Step B — Launch the SDK with the token

After receiving the token from your backend, create an `ApplicationAccessToken` object and pass it to `GetsetoKycConfig.accessToken`:

```dart
import 'package:getseto_sdk/getseto_sdk.dart';

await GetsetoKyc.launch(
  context,
  config: GetsetoKycConfig(
    environment: KycEnvironment.uat,
    apiKey: 'YOUR_API_KEY',
    tenantName: 'Your Brand Name',
    logo: const AssetImage('assets/images/logo.png'),

    // The access token — when provided, the SDK skips its own mobile/OTP screens
    accessToken: ApplicationAccessToken(
      token: tokenFromYourBackend,           // the JWT string from GetSetO
      mobile: '9876543210',                  // the user's verified mobile number
      mobileRelationshipId: 1,               // relationship ID (e.g. 1 = Self)
      source: ApplicationCreationSources.kyc, // journey type
    ),
  ),
  callbacks: GetsetoKycCallbacks(
    onComplete: (result) {
      print('KYC done: ${result.applicationId}');
    },
    onError: (error) {
      print('KYC error: $error');
    },
  ),
);
```

When `accessToken` is set, the SDK shows a brief loading screen while it validates the token, then goes straight into the KYC journey. The user never sees the mobile or OTP screens.

### `ApplicationAccessToken` fields

| Field | Type | Required | Description |
|---|---|---|---|
| `token` | `String` | Yes | The JWT string from GetSetO's `tenant-api/access-token` endpoint. |
| `mobile` | `String?` | Yes | The user's verified mobile number (10 digits). |
| `mobileRelationshipId` | `int?` | Yes | Relationship type ID. Provided to you during tenant onboarding. |
| `clientCode` | `String?` | No | Your client or employee code if your tenant workflow uses it. Omit if not needed. |
| `source` | `ApplicationCreationSources?` | No | Journey type. Defaults to `kyc` if omitted. |

### `ApplicationCreationSources` values

| Value | Description |
|---|---|
| `ApplicationCreationSources.kyc` | Standard new KYC onboarding (most common). |
| `ApplicationCreationSources.modification` | Modification of an existing account. |

### Resume vs. new application

When your backend calls `tenant-api/access-token`, GetSetO checks whether a KYC application already exists for that mobile number:

- **`AppExists: true`** — an existing application was found. The SDK will **resume** from where the user left off.
- **`AppExists: false`** — no existing application. The SDK will **start a fresh** journey.

You do not need to do anything differently in the Flutter code — the SDK handles both cases automatically based on the token. If you want to show a message in your UI (e.g. "Resuming your application…"), you can use the `appExists` field that your backend returns to your Flutter app.

### Full example

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:getseto_sdk/getseto_sdk.dart';

/// Calls YOUR backend endpoint to retrieve a GetSetO access token.
/// Your backend is responsible for verifying the OTP and calling GetSetO
/// server-to-server. Your Flutter app never talks to GetSetO directly here.
Future<Map<String, dynamic>> fetchAccessTokenFromMyBackend(String mobile) async {
  final response = await http.post(
    Uri.parse('https://my-backend.example.com/api/kyc/access-token'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mobile': mobile}),
  );

  if (response.statusCode != 200) {
    throw Exception('Could not get access token from backend');
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// Launches the KYC SDK using the access token flow.
Future<void> startKycWithAccessToken(BuildContext context, String mobile) async {
  // Get the token from your own backend
  final data = await fetchAccessTokenFromMyBackend(mobile);

  if (!context.mounted) return;

  await GetsetoKyc.launch(
    context,
    config: GetsetoKycConfig(
      environment: KycEnvironment.uat,
      apiKey: 'YOUR_API_KEY',
      tenantName: 'Your Brand Name',
      logo: const AssetImage('assets/images/logo.png'),
      accessToken: ApplicationAccessToken(
        token: data['token'] as String,
        mobile: data['mobile'] as String?,
        mobileRelationshipId: data['mobileRelationshipId'] as int?,
        source: ApplicationCreationSources.kyc,
      ),
    ),
    callbacks: GetsetoKycCallbacks(
      onComplete: (result) {
        print('KYC complete: ${result.applicationId}');
      },
      onError: (error) {
        print('KYC error: $error');
      },
    ),
  );
}
```

> The standard OTP login flow remains fully supported and is the default. Setting `accessToken` is entirely optional — if you don't set it, the SDK behaves exactly as before and handles everything itself.
