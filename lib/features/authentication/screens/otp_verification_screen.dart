// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_api_service.dart';
import '../../../utils/responsive_utils.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String emailOrPhone;
  final bool isFromSignUp;

  const OtpVerificationScreen({
    super.key,
    required this.emailOrPhone,
    this.isFromSignUp = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _hiddenFocusNode = FocusNode();
  bool _isVerifying = false;
  String? _otpError;

  // ── OTP Expiry Timer (10 minutes — matches server OTP_EXPIRY_MINUTES) ──
  static const int _otpExpirySeconds = 600; // 10 minutes
  int _expirySecondsLeft = _otpExpirySeconds;
  Timer? _expiryTimer;
  bool get _isExpired => _expirySecondsLeft <= 0;

  // ── Resend Cooldown Timer (30 seconds) ──
  static const int _resendCooldownSeconds = 30;
  int _resendSecondsLeft = _resendCooldownSeconds;
  Timer? _resendTimer;
  bool get _canResend => _resendSecondsLeft <= 0 && !_isExpired;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hiddenFocusNode.requestFocus();
    });
    _otpController.addListener(_onOtpChanged);
    _startExpiryTimer();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _hiddenFocusNode.dispose();
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expirySecondsLeft = _otpExpirySeconds;
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _expirySecondsLeft--;
        if (_expirySecondsLeft <= 0) {
          timer.cancel();
        }
      });
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSecondsLeft = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSecondsLeft--;
        if (_resendSecondsLeft <= 0) {
          timer.cancel();
        }
      });
    });
  }

  void _onOtpChanged() {
    // Clear error if validation was attempted AND user has now entered 6 digits
    if (_otpError != null && _otpController.text.length == 6) {
      setState(() => _otpError = null);
    } else {
      setState(() {});
    }

    // Auto-submit when all 6 digits are entered
    if (_otpController.text.length == 6 && !_isVerifying) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _otpController.text.length == 6 && !_isVerifying) {
          _handleVerify();
        }
      });
    }
  }

  void _openKeyboard() {
    _hiddenFocusNode.requestFocus();
    // Force the keyboard to show even if focus was already held
    // but keyboard was manually dismissed by the user.
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  Future<void> _handleVerify() async {
    if (_isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code has expired. Please request a new one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final otp = _otpController.text;
    if (otp.length != 6) {
      setState(() => _otpError = 'Please enter the full 6-digit code');
      return;
    }

    setState(() {
      _otpError = null;
      _isVerifying = true;
    });
    _hiddenFocusNode.unfocus();

    try {
      final email = widget.emailOrPhone.trim().toLowerCase();
      Map<String, dynamic> result;

      if (widget.isFromSignUp) {
        result = await AuthApiService.instance.verifyEmail(
          email: email,
          otp: otp,
        );
      } else {
        result = await AuthApiService.instance.verifyLoginOtp(
          email: email,
          otp: otp,
        );
      }

      final accessToken = result['accessToken'] as String;
      final refreshToken = result['refreshToken'] as String;

      if (!mounted) return;

      // Login with real tokens
      final container = ProviderScope.containerOf(context);
      await container
          .read(authProvider.notifier)
          .loginWithTokens(accessToken, refreshToken);
    } on Object catch (e) {
      if (!mounted) return;
      // Clear OTP and show error
      _otpController.clear();
      setState(() => _otpError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isVerifying = false);
      _hiddenFocusNode.requestFocus();
    }
  }

  Future<void> _handleResendCode() async {
    if (!_canResend && !_isExpired) return; // Still in cooldown

    try {
      final email = widget.emailOrPhone.trim().toLowerCase();
      final type = widget.isFromSignUp ? 'EMAIL_VERIFY' : 'LOGIN_OTP';
      await AuthApiService.instance.resendOtp(email: email, type: type);

      if (!mounted) return;

      // Reset both timers
      _otpController.clear();
      _startExpiryTimer();
      _startResendCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification code resent!'),
          backgroundColor: AppColors.primary,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final otpBoxWidth =
        (screenWidth - responsive.spacing(48) - responsive.spacing(50)) / 6;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.spacing(16)),
                    // Back button
                    GestureDetector(
                      onTap: () {
                        if (widget.isFromSignUp) {
                          context.go('/signup');
                        } else {
                          context.go('/signin');
                        }
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                        size: responsive.iconSize(24),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    // Title
                    Center(
                      child: Text(
                        'Verification Code',
                        style: TextStyle(
                          fontSize: responsive.fontSize(32),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    Center(
                      child: Text(
                        "We've sent a verification code to",
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(6)),
                    Center(
                      child: Text(
                        widget.emailOrPhone,
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // Hidden TextField for keyboard input — positioned behind OTP boxes.
                    // Uses a real size so iOS reliably activates the keyboard.
                    // NOTE: autofocus is intentionally false here because initState’s
                    // addPostFrameCallback already requests focus once the frame is
                    // drawn.  Setting autofocus:true at the same time causes two
                    // simultaneous IME-show requests on Android which race each other
                    // and both get cancelled at PHASE_CLIENT_APPLY_ANIMATION —
                    // resulting in the keyboard never appearing.
                    SizedBox(
                      height: 1,
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _hiddenFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: false,
                          showCursor: false,
                          enableSuggestions: false,
                          autocorrect: false,
                          enableInteractiveSelection: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    // OTP Display Boxes
                    GestureDetector(
                      onTap: _openKeyboard,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final otp = _otpController.text;
                          final digit = index < otp.length ? otp[index] : '';
                          final isCurrentIndex =
                              index == otp.length && otp.length < 6;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: otpBoxWidth.clamp(42.0, 55.0),
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isCurrentIndex && _hiddenFocusNode.hasFocus
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  digit,
                                  key: ValueKey(digit),
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(24),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24)),
                    if (_otpError != null) ...[
                      Center(
                        child: Text(
                          _otpError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(16)),
                    ],
                    // Resend code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            color: Colors.grey.shade500,
                          ),
                        ),
                        GestureDetector(
                          onTap: (_canResend || _isExpired)
                              ? _handleResendCode
                              : null,
                          child: Text(
                            (_canResend || _isExpired)
                                ? 'Resend Code'
                                : 'Resend in ${_resendSecondsLeft}s',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              color: (_canResend || _isExpired)
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    // Or Sign in with divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(16),
                          ),
                          child: Text(
                            widget.isFromSignUp
                                ? 'Or Sign up with'
                                : 'Or Sign in with',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(24)),
                    // Google Sign In button
                    OutlinedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z" fill="#4285F4"/></svg>',
                        width: 20,
                        height: 20,
                      ),
                      label: Text(
                        widget.isFromSignUp
                            ? 'Sign up with Google'
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
                    SizedBox(height: responsive.spacing(40)),
                  ],
                ),
              ),
            ),
            // Verify Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVerifying
                        ? Colors.grey.shade300
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    elevation: _isVerifying ? 0 : 4,
                    shadowColor: _isVerifying
                        ? null
                        : AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: responsive.spacing(12)),
                            Text(
                              'Verifying...',
                              style: TextStyle(
                                fontSize: responsive.fontSize(16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.isFromSignUp
                              ? 'Verify & Get Started'
                              : 'Verify & Log In',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
