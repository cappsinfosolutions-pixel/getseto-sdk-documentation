# GetSetO KYC SDK (Flutter)

The GetSetO KYC SDK provides a full-screen, self-contained eKYC onboarding journey that you embed into your existing Flutter app with a single method call. The SDK manages its own screens and navigation internally — you only need to supply your API credentials, a logo, and handle the result when the journey finishes.

---

## 🚀 Quick Start

### 1. Add dependency

```yaml
getseto_sdk:
  git:
    url: https://github.com/cappsinfosolutions-pixel/getseto-sdk.git
    path: packages/getseto_sdk
    ref: v0.1.0
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

## 📦 Versioning

Current version: **0.1.0**

> 0.x versions are development releases and may include breaking changes.

---

## 🔐 Security Note

Do not expose your API key in public repositories.

---

## 📞 Support

For integration support, contact GetSetO team.
