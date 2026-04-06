// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/auth_api_service.dart';
import '../../../services/user_service.dart';
import '../../../utils/responsive_utils.dart';

class SignUpScreen extends StatefulWidget {
  final String? prefilledEmail;
  final bool isFromInvite;

  const SignUpScreen({
    super.key,
    this.prefilledEmail,
    this.isFromInvite = false,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEmailValid = false;
  bool _isNameValid = false;
  bool _isSubmitting = false;

  /// Inline validation error messages — null means no error displayed.
  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _fullNameController.addListener(_validateName);
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailController.text = widget.prefilledEmail!;
      // Trigger validation for the pre-filled value.
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateEmail());
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    // Only validate (and show error) once the user has started typing.
    final error = email.isEmpty ? null : AppValidators.email(email);
    final valid = email.isNotEmpty && error == null;
    if (valid != _isEmailValid || error != _emailError) {
      setState(() {
        _isEmailValid = valid;
        _emailError = error;
      });
    }
  }

  void _validateName() {
    final name = _fullNameController.text.trim();
    // Only validate (and show error) once the user has started typing.
    final error = name.isEmpty ? null : AppValidators.name(name);
    final valid = name.isNotEmpty && error == null;
    if (valid != _isNameValid || error != _nameError) {
      setState(() {
        _isNameValid = valid;
        _nameError = error;
      });
    }
  }

  bool get canContinue => _isNameValid && _isEmailValid && !_isSubmitting;

  Future<void> _handleContinue() async {
    if (!canContinue) return;
    setState(() => _isSubmitting = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final name = _fullNameController.text.trim();

      await AuthApiService.instance.register(email: email, name: name);

      // Save user data locally
      await UserService.instance.setSignUpUserData(
        fullName: name,
        email: email,
        phone: '',
      );

      if (!mounted) return;

      // Update user profile provider
      final container = ProviderScope.containerOf(context);
      container
          .read(userProfileProvider.notifier)
          .updateProfile(name: name, email: email);

      // Navigate to OTP verification
      context.push('/otp?emailOrPhone=$email&isFromSignUp=true');
    } on SocketException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to connect to server. Please check your internet connection.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } on TimeoutException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection timed out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignUp() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final result = await AuthApiService.instance.googleSignIn();

      final accessToken = result['accessToken'] as String;
      final refreshToken = result['refreshToken'] as String;

      if (!mounted) return;

      final container = ProviderScope.containerOf(context);
      await container
          .read(authProvider.notifier)
          .loginWithTokens(accessToken, refreshToken);
      // GoRouter redirect handles navigation to /home
    } on SocketException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to connect to server. Please check your internet connection.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } on TimeoutException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection timed out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg != 'Google Sign-In was cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(24),
            vertical: responsive.spacing(40),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Invite context banner ─────────────────────────────
                if (widget.isFromInvite) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You\'ve been invited to HomeIQ.\nCreate an account to accept the invitation.',
                            style: TextStyle(
                              fontSize: responsive.fontSize(13),
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(20)),
                ],

                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: responsive.fontSize(28),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.spacing(8)),
                Text(
                  'Fill in your details to get started',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.spacing(32)),

                // Full Name field
                Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                TextField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'John Doe',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _nameError != null
                            ? Colors.red
                            : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _nameError != null
                            ? Colors.red
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                if (_nameError != null) ...[
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    _nameError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: responsive.fontSize(12),
                    ),
                  ),
                ],
                SizedBox(height: responsive.spacing(16)),

                // Email field
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'you@email.com',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailError != null
                            ? Colors.red
                            : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailError != null
                            ? Colors.red
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                if (_emailError != null) ...[
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    _emailError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: responsive.fontSize(12),
                    ),
                  ),
                ],
                SizedBox(height: responsive.spacing(24)),

                // Divider with "Or sign up with"
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(16),
                      ),
                      child: Text(
                        'Or sign up with',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                SizedBox(height: responsive.spacing(16)),

                // Google Sign Up button
                OutlinedButton.icon(
                  onPressed: _handleGoogleSignUp,
                  icon: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z" fill="#4285F4"/></svg>',
                    width: 20,
                    height: 20,
                  ),
                  label: const Text('Sign up with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // Continue button
                ElevatedButton(
                  onPressed: canContinue ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/signin'),
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
