import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../profile/profile_providers.dart';
import '../profile/profile_repository.dart';

/// Clears cached shell header (call after login, logout, or profile save).
void refreshShellUserHeader(WidgetRef ref) {
  ref.invalidate(shellUserHeaderProvider);
}

/// Name and locum role shown in the main shell app bar.
class ShellUserHeader {
  const ShellUserHeader({
    required this.name,
    required this.yourRole,
  });

  final String name;
  final String yourRole;
}

String _formatLocumRole(String? apiRole) {
  final r = apiRole?.trim().toLowerCase() ?? '';
  if (r == 'technician') return 'Technician';
  if (r == 'pharmacist') return 'Pharmacist';
  if (r == 'dispenser') return 'Dispenser';
  if (r.isEmpty) return '—';
  return r[0].toUpperCase() + r.substring(1);
}

/// Refetches when [authSessionProvider] changes (login / logout).
final shellUserHeaderProvider =
    FutureProvider.autoDispose<ShellUserHeader>((ref) async {
  final authStatus = ref.watch(authSessionProvider);
  if (authStatus != AuthSessionStatus.authenticated) {
    return const ShellUserHeader(name: '', yourRole: '');
  }

  try {
    final payload = await ref.read(profileRepositoryProvider).fetchProfile();
    return ShellUserHeader(
      name: payload.user?.name.trim().isNotEmpty == true
          ? payload.user!.name.trim()
          : 'Locum',
      yourRole: _formatLocumRole(payload.profile?.locumRole),
    );
  } on ProfileFailure {
    return const ShellUserHeader(name: 'Locum', yourRole: '—');
  }
});
