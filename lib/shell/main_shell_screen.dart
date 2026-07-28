import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shifts/shifts_providers.dart';
import 'shell_user_header_provider.dart';

/// Hosts [StatefulNavigationShell]: AppBar, tab body, bottom [NavigationBar].
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = ['Dashboard', 'Find Shifts', 'Settings'];
  static const _shellBg = Color(0xFFF8F9FA);
  static const _titleNavy = Color(0xFF1A2B3C);

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  bool _rejectionDialogShown = false;

  void _showRejectionDialog(ShellUserHeader header) {
    if (_rejectionDialogShown ||
        header.approvalStatus.trim().toUpperCase() != 'REJECTED') {
      return;
    }

    _rejectionDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final reason = header.approvalReason?.trim();
      final acknowledged = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Profile rejected'),
          content: Text(
            reason != null && reason.isNotEmpty
                ? reason
                : 'Your profile has been rejected. Please review your profile details.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted && acknowledged == true) context.push('/profile');
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    final headerAsync = ref.watch(shellUserHeaderProvider);
    headerAsync.whenData(_showRejectionDialog);

    return Scaffold(
      backgroundColor: index == 0 || index == 1
          ? MainShellScreen._shellBg
          : null,
      appBar: AppBar(
        toolbarHeight: 64,
        title: headerAsync.when(
          data: (header) => _AppBarUserHeader(header: header),
          loading: () => Text(
            MainShellScreen._titles[index],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MainShellScreen._titleNavy,
            ),
          ),
          error: (_, _) => Text(
            MainShellScreen._titles[index],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MainShellScreen._titleNavy,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: index == 0 || index == 1
            ? MainShellScreen._shellBg
            : null,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          if (index == 1)
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter shifts',
              onPressed: () {
                ref.read(shiftsFilterOpenTriggerProvider.notifier).open();
              },
            ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: widget.navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search),
            label: 'Find Shifts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AppBarUserHeader extends StatelessWidget {
  const _AppBarUserHeader({required this.header});

  final ShellUserHeader header;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          header.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MainShellScreen._titleNavy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          header.yourRole,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
