# Monthly Budget Tracker

A Flutter budget app for tracking monthly household spending. Share one Email/Password account across phones so everyone sees the same data.

Originally based on a Google Sheets budget tracker; this is the mobile replacement with live totals, analytics, recurring expenses, receipt scanning, and multi-currency entry.

## Features

- **Months** — create, rename, delete months; optionally copy categories (and recurring items) from the previous month
- **Categories** — default set (Petrol, Food, Subscriptions, Cigarette, Miscellaneous); add / edit / delete / set budgets
- **Expenses** — name, price, date; blank prices stay listed but are excluded from totals and charts
- **Multi-currency** — set a **home currency** per account in Settings; enter expenses in any supported currency and convert into home on save (analytics stay in one currency). FX rates are cached locally for offline reuse. Changing home currency does **not** rewrite existing amounts
- **Recurring items** — monthly or yearly with a day (and month for yearly); copied into new months with price left empty until filled
- **Live totals** — used / budget / remaining / % always computed from items (never stored as hardcoded totals)
- **Overspend flags** — category and month level (color + icon, not color alone)
- **Analytics** — month-over-month spend chart, category pie chart, quick stats
- **Receipts** — scan with the document scanner, compress, upload to Firebase Storage, fullscreen preview
- **Auth** — Email/Password (same account on multiple devices = shared budget)
- **Offline-ish** — Firestore persistence + Hive cache for budget CRUD when previously synced; receipt uploads and first-time FX conversion need network
- **Theming** — system light / dark; primary color defaults to the app-icon green and is customizable per account (local). Scaffold surfaces tint from the seed color
- **UI** — floating liquid-glass bottom nav; elevated month / item cards; haptics throughout

## Stack

| Area | Choice |
|------|--------|
| UI | Flutter (iOS-first, Android supported) |
| State | Provider (`ChangeNotifier`) |
| Backend | Firebase Auth, Cloud Firestore, Storage |
| Local cache | Hive (budget cache, theme prefs, FX rates, currency prefs) |
| Charts | fl_chart |
| Receipts | cunning_document_scanner + flutter_image_compress + cached_network_image |
| FX | currency_converter + connectivity_plus |

## Project layout

```
lib/
  models/          Month, Category, ExpenseItem (computed totals as getters)
  providers/       Auth, Months, theme prefs, currency prefs
  repositories/    Firestore + Hive budget repository
  screens/         Auth, Months, Analytics, Settings, detail / forms
  services/        Receipt scan / upload, currency conversion
  widgets/         Cards, progress, glass nav, color picker
  theme/           Seed-tinted light / dark theme
  utils/           Formatters, supported currencies, haptics
firestore.rules
storage.rules
FIREBASE_SETUP.md
```

## Setup

### 1. Flutter

```bash
flutter pub get
```

After changing the icon asset, regenerate launcher icons and splash:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### 2. Firebase

Firebase config files are **gitignored** (so the repo stays safe to make public). See [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

Short version:

1. Create a Firebase project
2. Enable **Email/Password** auth, **Firestore**, and **Storage**
3. Run `flutterfire configure`
4. Deploy rules:

```bash
firebase deploy --only firestore:rules,storage
```

Home currency for each account is stored at `users/{uid}/settings/prefs` (and cached in Hive). Existing rules already allow that path under `users/{userId}/{document=**}`.

### 3. Run

```bash
flutter run
```

On iOS, from `ios/`:

```bash
pod install
cd ..
flutter run
```

For longer-lived device installs, use a paid Apple Developer team (e.g. organization) and Profile mode; free personal teams expire development installs after about 7 days.

## Receipt AI (optional)

Scan → on-device OCR (ML Kit) → Gemini `gemini-flash-lite-latest` (12s timeout) fills name, total, category, date, and currency on the Add item screen. If Gemini is slow or fails, Add item still opens with the receipt so you can fill fields manually.

1. Copy `lib/config/api_keys.dart.example` → `lib/config/api_keys.dart`
2. Paste your key into `_pasted`, **or** run:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Get a key at [Google AI Studio](https://aistudio.google.com/apikey). `api_keys.dart` is gitignored.

## Shared household use

1. Create one account in the app (Email/Password)
2. Sign in with that same email and password on every device

Data lives under `users/{uid}/months/...`. Theme color is local per device/account; home currency syncs via Firestore for that uid.

## Currency

- **Home currency** (default `PKR`) is chosen in Settings and applies to new expenses, budgets display, and analytics formatting
- On add/edit item, pick an entry currency; if it differs from home, the amount is converted **before save** into `price`
- Original amount / currency / FX rate are kept on the item for display
- Supported codes include PKR, USD, EUR, GBP, AED, SAR, INR, AUD, CAD, CHF, JPY, CNY, TRY, SGD
- Offline: reuse last cached rate; if none exists, conversion is blocked until the device has been online once for that pair

## Out of scope (for now)

- CSV / PDF export
- Push / budget alerts
- Rewriting historical amounts when home currency changes
- Separate per-person accounts with invites (use one shared login instead)

## License

Private / personal project unless you add a license later.
