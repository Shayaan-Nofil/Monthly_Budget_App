# Monthly Budget Tracker

A Flutter budget app for tracking monthly spending in **Pakistani Rupees (Rs.)**. Built for personal / household use: share one Email/Password account across phones so everyone sees the same data.

Originally based on a Google Sheets budget tracker; this is the mobile replacement with live totals, analytics, recurring expenses, and receipt scanning.

## Features

- **Months** — create, rename, delete months; optionally copy categories (and recurring items) from the previous month
- **Categories** — default set (Petrol, Food, Subscriptions, Cigarette, Miscellaneous); add / edit / delete / set budgets
- **Expenses** — name, price, date; blank prices stay listed but are excluded from totals and charts
- **Recurring items** — monthly or yearly with a day (and month for yearly); copied into new months with price left empty until filled
- **Live totals** — used / budget / remaining / % always computed from items (never stored as hardcoded totals)
- **Overspend flags** — category and month level (color + icon, not color alone)
- **Analytics** — month-over-month spend chart, category pie chart, quick stats
- **Receipts** — scan with the document scanner, compress, upload to Firebase Storage, preview on the item
- **Auth** — Email/Password (same account on multiple devices = shared budget)
- **Offline-ish** — Firestore persistence + Hive cache for budget CRUD when previously synced; receipt uploads need network
- **Theming** — light / dark from system; lavender accent

## Stack

| Area | Choice |
|------|--------|
| UI | Flutter (iOS-first, Android supported) |
| State | Provider (`ChangeNotifier`) |
| Backend | Firebase Auth, Cloud Firestore, Storage |
| Local cache | Hive |
| Charts | fl_chart |
| Receipts | cunning_document_scanner + flutter_image_compress + cached_network_image |

## Project layout

```
lib/
  models/          Month, Category, ExpenseItem (computed totals as getters)
  providers/       Auth + Months
  repositories/    Firestore + Hive budget repository
  screens/         Auth, Months, Analytics, detail / forms
  services/        Receipt scan / upload
  widgets/         Cards, progress, summaries
  theme/           Light / dark theme
firestore.rules
storage.rules
FIREBASE_SETUP.md
```

## Setup

### 1. Flutter

```bash
flutter pub get
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

## Shared household use

1. Create one account in the app (Email/Password)
2. Sign in with that same email and password on every device  
Data is stored under `users/{uid}/months/...`.

## Currency

All amounts use **Rs.** with thousands separators and **no decimals** (e.g. `Rs. 16,363`).

## Out of scope (for now)

- CSV / PDF export
- Push / budget alerts
- Multi-currency
- Separate per-person accounts with invites (use one shared login instead)

## License

Private / personal project unless you add a license later.
