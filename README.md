# GetSetO KYC SDK (Flutter)

The GetSetO KYC SDK provides a full-screen, self-contained eKYC onboarding journey that you embed into your existing Flutter app with a single method call. The SDK manages its own screens and navigation internally — you only need to supply your API credentials, a logo, and handle the result when the journey finishes.

---

## 🚀 Quick Start

### 1. Add dependency

```yaml
getseto_sdk:
  git:
    url: https://github.com/getseto-com/getseto-sdk.git
    ref: v1.1.0
```

---

### 2. Launch KYC

```dart
await GetsetoKyc.launch(
  context,
  config: GetsetoKycConfig(
    environment: KycEnvironment.uat,
    apiKey: 'YOUR_API_KEY',
    tenantName: 'Your Brand Name',
    logo: const AssetImage('assets/logo.png'),
  ),
  callbacks: GetsetoKycCallbacks(
    onComplete: (result) {
      print(result.applicationId);
    },
    onError: (error) {
      print(error);
    },
  ),
);
```

---

## 📚 Documentation

* 👉 Full Integration Guide: `docs/flutter-integration.md`
* 🎨 Theming Guide: `docs/theming.md`
* 🛠 Troubleshooting: `docs/troubleshooting.md`
* 🔌 GetSetO API: `docs/getseto-api.md`

---

## 🧪 Example App

Check the `example/` folder for a developer demo app.

---

## 🧠 How it works

* SDK runs as a full-screen flow
* Navigation is handled internally
* Host app only:

  * launches SDK
  * receives callbacks

---

## 🔑 Two ways to start the KYC journey

**Option 1 — SDK handles login (default)**

The SDK shows its own mobile number entry and OTP verification screens. No extra work required.

**Option 2 — Your app handles login (advanced)**

Your app verifies the user via your own OTP flow, your backend fetches an access token from GetSetO server-to-server, and you pass it to the SDK. The SDK skips its own login screens and goes straight to the KYC steps.

See the [Advanced Integration section](docs/flutter-integration.md#advanced-access-token-login) for step-by-step instructions.

---

## 📦 Versioning

Current version: **1.1.0**

> 0.x versions are development releases and may include breaking changes.

---

## 🔐 Security Note

Do not expose your API key in public repositories.

---

## 📞 Support

For integration support, contact GetSetO team.
