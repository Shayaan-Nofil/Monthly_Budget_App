import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/months_provider.dart';
import 'providers/theme_preferences_provider.dart';
import 'repositories/firestore_hive_budget_repository.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final repository = FirestoreHiveBudgetRepository();
  final monthsProvider = MonthsProvider(repository);
  final authProvider = AuthProvider();
  final themePrefs = ThemePreferencesProvider();
  await themePrefs.init();
  themePrefs.bindUser(authProvider.user?.uid);
  authProvider.addListener(() {
    themePrefs.bindUser(authProvider.user?.uid);
  });

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: repository),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: monthsProvider),
        ChangeNotifierProvider.value(value: themePrefs),
      ],
      child: const BudgetApp(),
    ),
  );
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = context.watch<ThemePreferencesProvider>().primary;

    return MaterialApp(
      title: 'Monthly Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(primary: primary),
      darkTheme: AppTheme.dark(primary: primary),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
