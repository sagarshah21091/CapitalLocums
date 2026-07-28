import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_version.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_session.dart';
import '../router/app_router.dart';
import '../shell/shell_user_header_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeletingAccount = false;

  Future<void> _confirmDelete() async {
    if (_isDeletingAccount) return;

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

    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } catch (_) {
      // The requested fallback for any API failure is to log the user out.
    } finally {
      await ref.read(authSessionProvider.notifier).logout();
      refreshShellUserHeader(ref);
      if (mounted) context.go(AppRoute.login);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(authSessionProvider.notifier).logout();
    refreshShellUserHeader(ref);
    if (!context.mounted) return;
    context.go(AppRoute.login);
  }

  @override
  Widget build(BuildContext context) {
    final versionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
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
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('My bookings'),
                      subtitle: const Text('View all your shift bookings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoute.myBookings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () => _logout(context, ref),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: Colors.red.shade700,
                      ),
                      title: Text(
                        'Delete account',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      trailing: _isDeletingAccount
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      enabled: !_isDeletingAccount,
                      onTap: _confirmDelete,
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    24,
                    16,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: Text(appVersionLabel, style: versionStyle),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
