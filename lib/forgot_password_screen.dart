import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_providers.dart';
import 'auth/auth_repository.dart';
import 'brand_colors.dart';
import 'router/app_router.dart';

/// Request password reset with email only; opened from [LoginScreen].
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _submitting = false;

  static const _radius = 20.0;
  static const _labelGrey = Color(0xFF9E9E9E);
  static const _textDark = Color(0xFF424242);

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _labelGrey,
      ),
      hintStyle: TextStyle(
        fontSize: 15,
        color: Colors.grey.shade600,
      ),
      filled: true,
      fillColor: BrandColors.locumsMint.withValues(alpha: 0.18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: BrandColors.locumsGreen, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.2),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailRegex.hasMatch(v)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final message = await ref.read(authRepositoryProvider).forgotPassword(
            email: _emailController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.pop();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textDark),
          onPressed: _submitting
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoute.login);
                  }
                },
        ),
        title: const Text(
          'Forgot password',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            children: [
              Text(
                'Enter the email associated with your account. We\'ll send reset instructions if we find a match.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(fontSize: 16, color: _textDark),
                decoration: _fieldDecoration(
                  label: 'Email',
                  hint: 'Enter your email',
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) {
                  if (!_submitting) _onSubmit();
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.locumsGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: _submitting ? null : _onSubmit,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SEND RESET LINK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
