import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/months_provider.dart';
import '../widgets/month_card.dart';
import 'month_detail_screen.dart';
import 'new_month_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonthsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          if (provider.mostRecentMonth != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MonthDetailScreen(
                      monthId: provider.mostRecentMonth!.id,
                    ),
                  ),
                );
              },
              child: const Text('Current'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewMonthScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New month'),
      ),
      body: _Body(provider: provider),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider});

  final MonthsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load budgets.\n${provider.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (provider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No months yet.\nTap New month to get started.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.months.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final month = provider.months[index];
        return MonthCard(
          month: month,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MonthDetailScreen(monthId: month.id),
              ),
            );
          },
          onLongPress: () => _showMonthActions(context, month.id, month.name),
        );
      },
    );
  }

  Future<void> _showMonthActions(
    BuildContext context,
    String id,
    String name,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    final provider = context.read<MonthsProvider>();

    if (action == 'rename') {
      final controller = TextEditingController(text: name);
      final newName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename month'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (newName != null && newName.isNotEmpty) {
        await provider.renameMonth(id, newName);
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete month?'),
          content: Text('Delete "$name"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await provider.deleteMonth(id);
      }
    }
  }
}
