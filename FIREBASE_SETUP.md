# Firebase setup (local only — generated files are gitignored)
#
# 1. Create a Firebase project and enable Anonymous Auth, Firestore, Storage.
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
# See firebase.json.example for the expected FlutterFire shape.
