import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_version.dart';
import 'auth/auth_providers.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_session.dart';
import 'brand_colors.dart';
import 'router/app_router.dart';
import 'shell/shell_user_header_provider.dart';

/// Login layout inspired by the reference: logo + name, soft-filled fields, primary CTA.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _loggingIn = false;

  static const _radius = 20.0;
  static const _labelGrey = Color(0xFF9E9E9E);
  static const _textDark = Color(0xFF424242);
  static const _linkCaptionGrey = Color(0xFF616161);

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    Widget? suffixIcon,
  }) {
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
      suffixIcon: suffixIcon,
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

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) {
      return 'Please enter your password';
    }
    if (v.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (v.length > 128) {
      return 'Password is too long';
    }
    final hasLower = RegExp('[a-z]').hasMatch(v);
    final hasUpper = RegExp('[A-Z]').hasMatch(v);
    final hasDigit = RegExp('[0-9]').hasMatch(v);
    final hasSpecial = RegExp('[^A-Za-z0-9]').hasMatch(v);
    if (!hasLower || !hasUpper || !hasDigit || !hasSpecial) {
      return 'Use upper & lower case, a number, and a symbol';
    }
    return null;
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (_loggingIn) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loggingIn = true);
    try {
      await ref.read(authRepositoryProvider).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      ref.read(authSessionProvider.notifier).markAuthenticated();
      refreshShellUserHeader(ref);
      context.go(AppRoute.dashboard);
    } on AuthFailure catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _loggingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 72,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                          const SizedBox(height: 12),
                          _BrandHeader(
                            onSubtitleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _labelGrey,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: _validateEmail,
                            style: const TextStyle(
                              fontSize: 16,
                              color: _textDark,
                            ),
                            decoration: _fieldDecoration(
                              label: 'Email',
                              hint: 'Enter your email',
                            ),
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: _validatePassword,
                            style: const TextStyle(
                              fontSize: 16,
                              color: _textDark,
                            ),
                            decoration: _fieldDecoration(
                              label: 'Password',
                              hint: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade600,
                                  size: 22,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) {
                              if (!_loggingIn) {
                                _onLogin();
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: BrandColors.locumsGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(_radius),
                                      ),
                                      elevation: 0,
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    onPressed: _loggingIn ? null : _onLogin,
                                    child: _loggingIn
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('LOGIN'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: _loggingIn
                                          ? null
                                          : () =>
                                              context.push(AppRoute.forgotPassword),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: _textDark,
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'New to Capital Locums?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _linkCaptionGrey,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    TextButton(
                                      onPressed: _loggingIn
                                          ? null
                                          : () =>
                                              context.push(AppRoute.register),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: BrandColors.locumsGreen,
                                      ),
                                      child: const Text(
                                        'Sign up here',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      appVersionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _labelGrey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onSubtitleStyle});

  final TextStyle onSubtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/branding/app_icon.png',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BrandColors.locumsMint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business,
                color: BrandColors.locumsGreen,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAPITAL LOCUMS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BrandColors.locumsGreen,
                      letterSpacing: 0.6,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'HEALTHCARE RECRUITMENT',
                style: onSubtitleStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
