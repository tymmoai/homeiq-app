import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class ServiceImageCard extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceImageCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final hasFlow = service['hasFlow'] as bool? ?? false;
    final name = service['name'] as String? ?? '';
    final route = service['route'] as String?;

    return GestureDetector(
      onTap: () {
        if (hasFlow && route != null) {
          // Pass lifestyle serviceType as extra data if present
          final serviceType = service['serviceType'] as String?;
          if (serviceType != null) {
            context.push(route, extra: {'preSelectedService': serviceType});
          } else {
            context.push(route);
          }
        } else if (!hasFlow) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name service coming soon!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Service Image
              Image.asset(
                service['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.gray300,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: AppColors.gray400,
                    ),
                  );
                },
              ),
              // Dark overlay so white text is always visible (no fading)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.2),
                      AppColors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Service name - white, bold, bottom-left
              Positioned(
                bottom: responsive.spacing(12.0),
                left: responsive.spacing(12.0),
                right: responsive.spacing(12.0),
                child: Text(
                  service['name'] as String,
                  style: TextStyle(
                    fontSize: responsive.fontSize(17.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    shadows: [
                      Shadow(
                        color: AppColors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
