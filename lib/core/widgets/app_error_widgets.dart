import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/app_button.dart';

/// Widget that shows error with retry option
class AppErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorRetry({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: AppDimensions.fontXl * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              message,
              style: TextStyle(
                fontSize: AppDimensions.fontM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              AppButton(
                text: 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for network error
class AppNetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const AppNetworkError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorRetry(
      message: 'No internet connection.\nPlease check your network settings.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }
}

/// Widget for not found error
class AppNotFoundError extends StatelessWidget {
  final String? message;
  final VoidCallback? onBack;

  const AppNotFoundError({super.key, this.message, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              '404',
              style: TextStyle(
                fontSize: AppDimensions.fontXl * 2.4,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              message ?? 'The page you\'re looking for doesn\'t exist.',
              style: TextStyle(
                fontSize: AppDimensions.fontM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onBack != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              AppButton(
                text: 'Go Back',
                onPressed: onBack,
                icon: Icons.arrow_back,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for permission denied error
class AppPermissionError extends StatelessWidget {
  final String message;
  final VoidCallback? onSettings;

  const AppPermissionError({super.key, required this.message, this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.warning),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              'Permission Required',
              style: TextStyle(
                fontSize: AppDimensions.fontXl * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              message,
              style: TextStyle(
                fontSize: AppDimensions.fontM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onSettings != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              AppButton(
                text: 'Open Settings',
                onPressed: onSettings,
                icon: Icons.settings,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for empty states
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              title,
              style: TextStyle(
                fontSize: AppDimensions.fontXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: AppDimensions.fontM,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for maintenance/coming soon
class AppMaintenanceState extends StatelessWidget {
  final String? message;

  const AppMaintenanceState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: AppColors.warning),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              'Under Maintenance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              message ??
                  'We\'re working on improvements.\nPlease check back soon!',
              style: TextStyle(
                fontSize: AppDimensions.fontM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
