import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/responsive_utils.dart';

/// Splash screen shown while [AuthNotifier] determines login status.
///
/// No manual navigation here — [GoRouter]'s redirect handles routing
/// once auth state resolves from [AuthState.loading].
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content - Centered
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: r.spacing(24)),
                child: Image.asset(
                  'lib/asset_img/brandsmart_spashscreen_logo.png',
                  width: r.wp(80).clamp(200, 420),
                  height: r.hp(12).clamp(60, 120),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Version number in bottom right
            Positioned(
              bottom: r.spacing(20),
              right: r.spacing(20),
              child: Text(
                'Version 1.1.1',
                style: TextStyle(
                  fontSize: r.fontSize(12),
                  color: AppColors.gray400,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
