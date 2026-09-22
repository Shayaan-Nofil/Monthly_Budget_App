import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/months_provider.dart';
import 'auth_screen.dart';
import 'main_shell.dart';

/// Routes between sign-in and the main app based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _boundUid;
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (!auth.isSignedIn) {
      if (_boundUid != null || _starting) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _boundUid = null;
            _starting = false;
          });
        });
      }
      return const AuthScreen();
    }

    final months = context.watch<MonthsProvider>();
    final uid = auth.user!.uid;

    if (_boundUid != uid && !_starting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bindUser(uid);
      });
    }

    if (!months.isInitialized || _starting || months.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (months.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load budgets.\n${months.error}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return const MainShell();
  }

  Future<void> _bindUser(String uid) async {
    if (!mounted || _starting) return;
    setState(() => _starting = true);
    final months = context.read<MonthsProvider>();
    if (_boundUid != null && _boundUid != uid) {
      await months.reset();
    }
    await months.init();
    if (!mounted) return;
    setState(() {
      _boundUid = uid;
      _starting = false;
    });
  }
}
