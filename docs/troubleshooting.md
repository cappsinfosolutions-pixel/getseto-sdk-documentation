# Troubleshooting

## SDK not opening

* Ensure `context` is valid
* Check API key

---

## Camera not working

* Verify permissions
* Check device settings

---

## Build issues

Run:

```bash
flutter clean
flutter pub get
```

---

## Unexpected errors

Use `onError` callback to log issues.
