import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/months_provider.dart';
import 'repositories/firestore_hive_budget_repository.dart';
import 'screens/main_shell.dart';
import 'services/seed_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final repository = FirestoreHiveBudgetRepository();
  final monthsProvider = MonthsProvider(repository);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: repository),
        ChangeNotifierProvider.value(value: monthsProvider),
      ],
      child: const BudgetApp(),
    ),
  );

  await monthsProvider.init(seedIfEmpty: SeedService.seedSeptemberIfEmpty);
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monthly Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
