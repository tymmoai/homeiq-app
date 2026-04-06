import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';

/// Shared continue/action button for all service booking flow steps.
///
/// Displays a full-width button at the bottom of the screen with
/// white background container. Disabled state shows gray.
class BookingContinueButton extends StatelessWidget {
  final bool isValid;
  final String label;
  final VoidCallback? onPressed;

  /// Optional widget to show above the button (e.g. price summary row).
  final Widget? topContent;

  const BookingContinueButton({
    super.key,
    required this.isValid,
    this.label = 'Continue',
    this.onPressed,
    this.topContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: const BoxDecoration(color: AppColors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (topContent != null) ...[
            topContent!,
            context.responsive.heightBox(16.0),
          ],
          SizedBox(
            width: double.infinity,
            height: context.responsive.buttonHeight(50.0),
            child: ElevatedButton(
              onPressed: isValid ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid
                    ? AppColors.primary
                    : AppColors.divider,
                elevation: isValid ? 2 : 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: isValid ? AppColors.white : AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
