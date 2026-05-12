import 'package:flutter/material.dart';

/// Main landing tab after login (placeholder).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
