import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/currency_preferences_provider.dart';
import 'providers/months_provider.dart';
import 'providers/scraper_access_provider.dart';
import 'providers/theme_preferences_provider.dart';
import 'repositories/firestore_hive_budget_repository.dart';
import 'screens/auth_gate.dart';
import 'services/currency_service.dart';
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
  final currencyPrefs = CurrencyPreferencesProvider();
  final currencyService = CurrencyService();
  final scraperAccess = ScraperAccessProvider();
  await themePrefs.init();
  await currencyPrefs.init();
  await currencyService.init();
  await scraperAccess.initialize();
  themePrefs.bindUser(authProvider.user?.uid);
  currencyPrefs.bindUser(authProvider.user?.uid);
  scraperAccess.bindEmail(authProvider.email);
  authProvider.addListener(() {
    final uid = authProvider.user?.uid;
    themePrefs.bindUser(uid);
    currencyPrefs.bindUser(uid);
    scraperAccess.bindEmail(authProvider.email);
  });

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: repository),
        Provider.value(value: currencyService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: monthsProvider),
        ChangeNotifierProvider.value(value: themePrefs),
        ChangeNotifierProvider.value(value: currencyPrefs),
        ChangeNotifierProvider.value(value: scraperAccess),
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
      builder: (context, child) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
      home: const AuthGate(),
    );
  }
}
