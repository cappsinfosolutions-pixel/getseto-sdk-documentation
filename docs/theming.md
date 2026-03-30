# Theming Guide

You can customize the SDK UI using `GetsetoKycTheme`.

---

## Example

```dart
theme: GetsetoKycTheme(
  primaryColor: Color(0xFF066AFF),
  fontFamily: 'Poppins',
)
```

---

## Guidelines

* Use standard fonts only
* Avoid extreme colors
* Test on multiple devices

---

## Important

Custom fonts must be declared in your app's `pubspec.yaml`.

---

## Theming Configuration

Pass a `GetsetoKycTheme` to `GetsetoKycConfig.theme` to match the SDK's appearance to your brand. All fields are optional — omit any you want to keep at the SDK default.

```dart
const myTheme = GetsetoKycTheme(
  brightness: Brightness.light,        // Brightness.light or Brightness.dark

  primaryColor: Color(0xFF066AFF),     // brand accent color
  backgroundColor: Color(0xFFFFFFFF),
  headerColor: Color(0xFFFFFFFF),
  inputFillColor: Color(0xFFF5F7FA),

  textPrimary: Color(0xFF1D1D1D),
  textSecondary: Color(0xFF6B7280),
  linkColor: Color(0xFF3B82F6),

  errorColor: Color(0xFFFB2A23),
  successColor: Color(0xFF209E49),

  fontFamily: 'Poppins',               // must be declared in your app's pubspec.yaml

  button: KycButtonTheme(
    borderRadius: 10,
    // Optional: solid color or gradient for the primary button background
    // backgroundColor: Color(0xFF066AFF),
    // gradient: LinearGradient(colors: [Color(0xFF066AFF), Color(0xFF0040CC)]),
    textColor: Color(0xFFFFFFFF),
  ),
);
```

> **Note:** `KycButtonTheme.backgroundColor` and `KycButtonTheme.gradient` are mutually exclusive — provide only one.

### `GetsetoKycTheme` fields

| Field | Type | Description |
|---|---|---|
| `brightness` | `Brightness` | Overall light/dark mode for the SDK UI. Default: `Brightness.dark`. |
| `primaryColor` | `Color?` | Brand accent color used for buttons, highlights, and active states. |
| `backgroundColor` | `Color?` | Background color for SDK screens. |
| `headerColor` | `Color?` | Background color for the SDK header/app bar. |
| `inputFillColor` | `Color?` | Background fill color for text input fields. |
| `textPrimary` | `Color?` | Main body text color. |
| `textSecondary` | `Color?` | Secondary / label text color. |
| `linkColor` | `Color?` | Color for hyperlinks and tappable text. |
| `errorColor` | `Color?` | Color for error messages and validation indicators. |
| `successColor` | `Color?` | Color for success messages and completion indicators. |
| `fontFamily` | `String?` | Font family name. The font must be included in your app's `pubspec.yaml`. |
| `button` | `KycButtonTheme?` | Primary button styling. See below. |

### `KycButtonTheme` fields

| Field | Type | Description |
|---|---|---|
| `backgroundColor` | `Color?` | Solid fill color for buttons. Mutually exclusive with `gradient`. |
| `gradient` | `Gradient?` | Gradient fill for buttons. Mutually exclusive with `backgroundColor`. |
| `textColor` | `Color?` | Button label text color. |
| `borderColor` | `Color?` | Button border color. |
| `borderRadius` | `double?` | Corner radius of buttons in logical pixels. |

---