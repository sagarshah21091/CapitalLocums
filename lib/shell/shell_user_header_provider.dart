import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile_providers.dart';
import '../profile/profile_repository.dart';

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
  if (r.isEmpty) return '—';
  return r[0].toUpperCase() + r.substring(1);
}

final shellUserHeaderProvider = FutureProvider<ShellUserHeader>((ref) async {
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
