import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../utils/responsive_utils.dart';

/// Primary button widget with consistent pill-shaped styling (SquareTrade)
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? responsive.spacing(AppDimensions.buttonHeight),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.buttonPrimary,
          foregroundColor: textColor ?? AppColors.textOnPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(AppDimensions.buttonPaddingHorizontal),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: responsive.iconSize(20),
                width: responsive.iconSize(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: responsive.iconSize(20)),
                    SizedBox(width: responsive.spacing(8)),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      fontSize: responsive.fontSize(16),
                      color: textColor ?? AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary button with outline
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final double? height;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? responsive.spacing(AppDimensions.buttonHeight),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(AppDimensions.buttonPaddingHorizontal),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: responsive.iconSize(20)),
              SizedBox(width: responsive.spacing(8)),
            ],
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                fontSize: responsive.fontSize(16),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text button
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: responsive.iconSize(20)),
            SizedBox(width: responsive.spacing(4)),
          ],
          Text(
            text,
            style: AppTextStyles.button.copyWith(
              fontSize: responsive.fontSize(14),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}






