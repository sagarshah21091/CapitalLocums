import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brand_colors.dart';

const _contactUrl = 'https://www.capitallocums.co.uk/contact';
const _titleNavy = Color(0xFF1A2B3C);
const _cancelRed = Color(0xFFE53935);

/// Shows the cancellation contact dialog. Does not call the cancel API.
Future<void> showCancelBookingDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.close_rounded,
              size: 56,
              color: _cancelRed,
              weight: 700,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancel Booking',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _titleNavy,
              ),
            ),
            const SizedBox(height: 14),
            Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Colors.grey.shade800,
                ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => _openContactPage(ctx),
                      child: const Text(
                        'Click here',
                        style: TextStyle(
                          fontSize: 15,
                          color: BrandColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' to contact Capital Locums'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: _titleNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openContactPage(BuildContext context) async {
  final uri = Uri.parse(_contactUrl);
  if (!await canLaunchUrl(uri)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
