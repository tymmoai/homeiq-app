import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Enum representing the different steps in the AI fix problem flow
enum AiStep {
  issueSelection,
  analysis,
  solution,
  diyGuide,
  partsComparison,
  partsActionSelection,
  // Buy Parts flow
  partsOrderConfirmation,
  partsPaymentInfo,
  partsOrderSummary,
  // Book Technician flow
  technicianAddressConfirmation,
  technicianSelection,
  technicianTimeSlot,
  technicianConfirmation, // NEW: Review technician + address before payment
  technicianPaymentConfirmation,
  technicianBookingConfirmation,
  // Combined flow (new: Tech Selection → Time Slot → Confirmation → Payment → Success)
  combinedTechnicianSelection, // Step 1: Select technician
  combinedTimeSlot, // Step 2: Select date/time
  combinedConfirmation, // Step 3: Review parts + technician + address
  combinedPayment, // Step 4: Payment method
  combinedOrderBookingConfirmation, // Step 5: Success
}

/// Model class representing a DIY step with instructions
class DiyStep {
  final String title;
  final String description;
  final List<String> instructions;
  final String? safetyNote;
  final String? duration;
  final String? riskLevel;
  final List<String>? toolsNeeded;

  DiyStep({
    required this.title,
    required this.description,
    required this.instructions,
    this.safetyNote,
    this.duration,
    this.riskLevel,
    this.toolsNeeded,
  });
}

/// Model class representing a part option with pricing from different providers
class PartOption {
  final String name;
  final int quantity;
  final String description;
  final double priceEncompass;
  final double priceMarcone;
  final double priceLocal;

  PartOption({
    required this.name,
    required this.quantity,
    required this.description,
    required this.priceEncompass,
    required this.priceMarcone,
    required this.priceLocal,
  });
}

/// Model class representing a technician option with details
class TechnicianOption {
  final String name;
  final double rating;
  final int experienceYears;
  final double fee;

  TechnicianOption({
    required this.name,
    required this.rating,
    required this.experienceYears,
    required this.fee,
  });
}

/// Premium animated loader widget for AI operations
class PremiumLoaderWidget extends StatefulWidget {
  const PremiumLoaderWidget({super.key});

  @override
  State<PremiumLoaderWidget> createState() => _PremiumLoaderWidgetState();
}

class _PremiumLoaderWidgetState extends State<PremiumLoaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner animated progress
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    value: 0.7,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          // Pulsing center icon
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_fix_high,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
