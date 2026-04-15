# GetSetO KYC SDK (Flutter)

The GetSetO KYC SDK provides a full-screen, self-contained eKYC onboarding journey that you embed into your existing Flutter app with a single method call. The SDK manages its own screens and navigation internally â€” you only need to supply your API credentials, a logo, and handle the result when the journey finishes.

---

## ðŸš€ Quick Start

### 1. Add dependency

```yaml
getseto_sdk:
  git:
    url: https://github.com/getseto-com/getseto-sdk.git
    ref: v1.0.2
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

## ðŸ“š Documentation

* ðŸ‘‰ Full Integration Guide: `docs/flutter-integration.md`
* ðŸŽ¨ Theming Guide: `docs/theming.md`
* ðŸ›  Troubleshooting: `docs/troubleshooting.md`
* ðŸ”Œ GetSetO API: `docs/getseto-api.md`

---

## ðŸ§ª Example App

Check the `example/` folder for a developer demo app.

---

## ðŸ§  How it works

* SDK runs as a full-screen flow
* Navigation is handled internally
* Host app only:

  * launches SDK
  * receives callbacks

---

## ðŸ“¦ Versioning

Current version: **1.0.2**

> 0.x versions are development releases and may include breaking changes.

---

## ðŸ” Security Note

Do not expose your API key in public repositories.

---

## ðŸ“ž Support

For integration support, contact GetSetO team.
