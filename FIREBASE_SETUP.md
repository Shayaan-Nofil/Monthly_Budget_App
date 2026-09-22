# Firebase setup (local only — generated files are gitignored)
#
# 1. Create a Firebase project and enable:
#      - Authentication → Email/Password
#      - Cloud Firestore
#      - Storage
# 2. From the project root:
#      flutterfire configure
#    That regenerates (gitignored):
#      - lib/firebase_options.dart
#      - android/app/google-services.json
#      - ios/Runner/GoogleService-Info.plist
#      - macos/Runner/GoogleService-Info.plist
#      - firebase.json
# 3. Deploy rules:
#      firebase deploy --only firestore:rules,storage
#
# Shared household data: create one Email/Password account and sign in with it
# on every device (same email + password). Data lives under users/{uid}/months.
#
# Receipts need Storage rules deployed (unauthorized uploads usually mean
# storage.rules were not deployed yet):
#      firebase deploy --only storage
#
# See firebase.json.example for the expected FlutterFire shape.
