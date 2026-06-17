import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shifts/shifts_providers.dart';
import 'shell_user_header_provider.dart';

/// Hosts [StatefulNavigationShell]: AppBar, tab body, bottom [NavigationBar].
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = ['Dashboard', 'Find Shifts', 'Settings'];
  static const _shellBg = Color(0xFFF8F9FA);
  static const _titleNavy = Color(0xFF1A2B3C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    final headerAsync = ref.watch(shellUserHeaderProvider);

    return Scaffold(
      backgroundColor: index == 0 || index == 1 ? _shellBg : null,
      appBar: AppBar(
        toolbarHeight: 64,
        title: headerAsync.when(
          data: (header) => _AppBarUserHeader(header: header),
          loading: () => Text(
            _titles[index],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _titleNavy,
            ),
          ),
          error: (_, _) => Text(
            _titles[index],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _titleNavy,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: index == 0 || index == 1 ? _shellBg : null,
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
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: navigationShell.goBranch,
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
