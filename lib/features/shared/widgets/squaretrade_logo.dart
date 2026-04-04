import 'package:flutter/material.dart';

/// Keep old name as a typedef so existing imports don't break
typedef SquareTradeLogo = AppLogo;

/// Brand logo widget — displays the BrandsMart USA logo.
/// Change the asset path here to swap the logo app-wide.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/asset_img/brandsmart_spashscreen_logo.png',
      width: size * 3.5, // Logo is wider than tall
      height: size,
      fit: BoxFit.contain,
    );
  }
}
