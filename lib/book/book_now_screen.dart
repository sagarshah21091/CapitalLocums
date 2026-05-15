import 'package:flutter/material.dart';

/// Find Shifts tab (placeholder).
class BookNowScreen extends StatelessWidget {
  const BookNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Find Shifts',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
