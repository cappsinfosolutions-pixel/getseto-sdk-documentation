# Google Sign-In Setup Guide

This guide walks you through everything you need to do — in Firebase Console and Google Cloud Console — so that the **"Sign in with Google"** button works inside the GetSetO KYC SDK on Android.

> **You only need to do this once per app.**

---

## What you will end up with

| Item | Where it goes |
|------|--------------|
| `google-services.json` | `android/app/google-services.json` in your Flutter project |
| **Web Client ID** | Passed to the SDK as `googleSignInClientId` |

---

## Step 1 — Create a Firebase project (skip if you already have one)

1. Open [https://console.firebase.google.com](https://console.firebase.google.com) and sign in with your Google account.
2. Click **Add project**.
3. Enter a project name (e.g. `my-company-kyc`) and click **Continue**.
4. You can turn off Google Analytics if you do not need it.
5. Click **Create project** and wait for it to finish.

---

## Step 2 — Register your Android app in Firebase

1. On the Firebase project home page, click the **Android** icon (looks like the Android robot).
2. Fill in the form:
   - **Android package name** — this must exactly match the `applicationId` in your `android/app/build.gradle` file.  
     Example: `com.mycompany.myapp`
   - **App nickname** — any friendly name, e.g. `My KYC App`.
   - **Debug signing certificate SHA-1** — see Step 3 below for how to get this.
3. Click **Register app**.

---

## Step 3 — Get your SHA-1 fingerprint

The SHA-1 fingerprint tells Google which app is allowed to use your credentials. You need to add it so that "Sign in with Google" works.

### For debug builds

Run this command in your project folder:

```bash
keytool -list -v \
  -keystore android/app/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

> **Windows users:** replace `\` with a backtick `` ` `` or run it as a single line.

Copy the **SHA1** value from the output. It looks like:
```
A1:B2:C3:D4:E5:F6:07:08:09:AA:BB:CC:DD:EE:FF:00:11:22:33:44
```

### For release builds

Run `keytool` using your release keystore file and keystore password instead of the debug defaults.

### Add the SHA-1 to Firebase

1. In Firebase Console, go to **Project Settings** (gear icon, top-left).
2. Under **Your apps**, find your Android app and click on it.
3. Scroll down to **SHA certificate fingerprints** and click **Add fingerprint**.
4. Paste the SHA-1 value and click **Save**.
5. Repeat for any other keystores (debug, release, CI, etc.).

---

## Step 4 — Download google-services.json

1. In **Project Settings → Your apps**, click **Download google-services.json**.
2. Place the downloaded file at:
   ```
   android/app/google-services.json
   ```
   (Overwrite the existing placeholder file if one is present.)

---

## Step 5 — Enable Google Sign-In in Firebase Authentication

1. In the Firebase Console left sidebar, click **Authentication**.
2. Go to the **Sign-in method** tab.
3. Click **Google** in the provider list.
4. Toggle **Enable** to on.
5. Set a **Project support email** (required).
6. Click **Save**.

---

## Step 6 — Get your Web Client ID

The SDK needs the **Web application** OAuth client ID — NOT the Android client ID.

1. Go to [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials).
2. Make sure the correct project is selected in the top dropdown.
3. Under **OAuth 2.0 Client IDs**, look for a client with type **Web application**. Firebase creates this automatically when you enable Google Sign-In. It is usually named `Web client (auto created by Google Service)`.
4. Click on it and copy the **Client ID**.

It will look like:
```
1234567890-abcdefghijklmnopqrstuvwxyz012345.apps.googleusercontent.com
```

> **Important:** Do NOT use the client ID labelled "Android". That is a different credential and will cause a `sign_in_failed` error if used here.

---

## Step 7 — Pass the Client ID to the SDK

In your Flutter app, pass the Web Client ID when configuring the SDK:

```dart
final config = GetsetoKycConfig(
  apiKey: 'your-api-key',
  tenantName: 'Your Company',
  logo: AssetImage('assets/logo.png'),
  googleSignInClientId: '1234567890-abcdefghijklmnopqrstuvwxyz012345.apps.googleusercontent.com',
);
```

---

## Quick checklist

- [ ] Firebase project created
- [ ] Android app registered with correct package name
- [ ] SHA-1 fingerprint added for every keystore (debug + release)
- [ ] `google-services.json` downloaded and placed at `android/app/google-services.json`
- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] Web Client ID copied from Google Cloud Console credentials page
- [ ] Web Client ID passed as `googleSignInClientId` in `GetsetoKycConfig`

---

## Common errors

| Error | Likely cause | Fix |
|-------|-------------|-----|
| `DEVELOPER_ERROR (code 10)` | Wrong client ID type (Android instead of Web) | Use the **Web application** client ID from Google Cloud Console |
| `DEVELOPER_ERROR (code 10)` | SHA-1 not registered | Add your debug/release SHA-1 to Firebase → Project Settings |
| `sign_in_cancelled` | User dismissed the picker | No action needed |
| `network_error` | No internet on device | Check device connectivity |
| Build fails: `Missing project_info` | `google-services.json` is missing or invalid | Download the real file from Firebase Console and replace the placeholder |
