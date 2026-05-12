import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This will permanently remove your account and data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted || ok != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion (demo only).')),
    );
    context.go(AppRoute.login);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Profile details'),
          subtitle: const Text('View or edit your profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoute.profile),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () => context.go(AppRoute.login),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
          title: Text(
            'Delete account',
            style: TextStyle(color: Colors.red.shade700),
          ),
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }
}
