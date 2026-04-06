// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_api_service.dart';
import '../../../utils/responsive_utils.dart';

class SignInScreen extends StatefulWidget {
  final String? prefilledEmail;
  final bool isFromInvite;

  const SignInScreen({
    super.key,
    this.prefilledEmail,
    this.isFromInvite = false,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailController.text = widget.prefilledEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      await AuthApiService.instance.sendLoginOtp(email);

      if (!mounted) return;
      context.push('/otp?emailOrPhone=${Uri.encodeComponent(email)}');
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

      // Backend returns 403 "not verified" and auto-sends an EMAIL_VERIFY OTP.
      // Navigate to OTP screen in signup mode so it calls verify-email instead.
      if (msg.toLowerCase().contains('not verified')) {
        final email = _emailController.text.trim().toLowerCase();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not verified yet. Please verify with the code we sent.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        context.push(
          '/otp?emailOrPhone=${Uri.encodeComponent(email)}&isFromSignUp=true',
        );
        return;
      }

      // Backend returns 404 "no account" — show helpful message
      if (msg.toLowerCase().contains('no account') ||
          msg.toLowerCase().contains('not found')) {
        final emailForSignUp = _emailController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Expanded(
                  child: Text('No account found with this email.'),
                ),
                TextButton(
                  onPressed: () {
                    final emailParam = emailForSignUp.isNotEmpty
                        ? '&prefilledEmail=${Uri.encodeComponent(emailForSignUp)}'
                        : '';
                    context.go(
                      '/signup?fromInvite=${widget.isFromInvite}$emailParam',
                    );
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(24)),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 16
                          : 0,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.06),

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
                                    'You\'ve been invited to HomeIQ.\nSign in to accept the invitation.',
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
                          'Sign In',
                          style: TextStyle(
                            fontSize: responsive.fontSize(36),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            color: AppColors.gray500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.06),

                        // Email Label
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(12)),

                        // Email Input
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              hintStyle: const TextStyle(
                                color: AppColors.gray400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: AppValidators.email,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.06),

                        // Divider with "Or sign in with"
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.gray300)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.spacing(16),
                              ),
                              child: Text(
                                'Or sign in with',
                                style: TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: responsive.fontSize(14),
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.gray300)),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(24)),

                        // Google Sign In button
                        OutlinedButton.icon(
                          onPressed: _isGoogleLoading
                              ? null
                              : _handleGoogleSignIn,
                          icon: _isGoogleLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.gray500,
                                  ),
                                )
                              : SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z" fill="#4285F4"/></svg>',
                                  width: 20,
                                  height: 20,
                                ),
                          label: Text(
                            _isGoogleLoading
                                ? 'Signing in...'
                                : 'Sign in with Google',
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(45)),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: AppColors.gray600,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsive.fontSize(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(
                        0.5,
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: responsive.fontSize(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height:
                      responsive.spacing(24) +
                      MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
