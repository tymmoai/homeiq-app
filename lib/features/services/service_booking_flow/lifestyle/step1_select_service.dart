import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../utils/responsive_utils.dart';
import './lifestyle_booking_flow.dart';

class LifestyleStep1SelectService extends StatefulWidget {
  final LifestyleBookingFormData formData;
  final String categoryName;
  final int totalSteps;
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LifestyleStep1SelectService({
    super.key,
    required this.formData,
    required this.categoryName,
    required this.totalSteps,
    required this.currentStep,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<LifestyleStep1SelectService> createState() =>
      _LifestyleStep1SelectServiceState();
}

class _LifestyleStep1SelectServiceState
    extends State<LifestyleStep1SelectService> {
  static const String _assetImgPath = 'lib/asset_img';

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Cab Booking',
      'icon': Icons.local_taxi,
      'iconOutlined': Icons.local_taxi_outlined,
      'image': '$_assetImgPath/cab_service.jpg',
    },
    {
      'name': 'Restaurant Reservations',
      'icon': Icons.restaurant,
      'iconOutlined': Icons.restaurant_outlined,
      'image': '$_assetImgPath/restaurant _service.jpg',
    },
    {
      'name': 'Hotel Booking',
      'icon': Icons.hotel,
      'iconOutlined': Icons.hotel_outlined,
      'image': '$_assetImgPath/hotel_service.jpg',
    },
    {
      'name': 'Healthcare Appointments',
      'icon': Icons.medical_services,
      'iconOutlined': Icons.medical_services_outlined,
      'image': '$_assetImgPath/healthcare_service.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What lifestyle service do you need?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the type of lifestyle service',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 29),
                  Text(
                    'Service Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final isSelected =
                          widget.formData.selectedService == service['name'];
                      return _buildServiceCard(service, isSelected);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isSelected) {
    final responsive = ResponsiveUtils(context);
    final imagePath = service['image'] as String?;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.formData.selectedService = service['name'];
          widget.formData.serviceIcon = service['icon'].toString();
          widget.formData.clearServiceSpecificData();
        });
      },
      child: Container(
        height: responsive.hp(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary05 : AppColors.white,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          boxShadow: isSelected ? null : AppShadows.standard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          child: Column(
            children: [
              Expanded(
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // ignore: unnecessary_underscores - Image.errorBuilder has 3 params, all unused
                        errorBuilder: (_, __, ___) =>
                            _buildIconFallback(service, isSelected),
                      )
                    : _buildIconFallback(service, isSelected),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(4),
                  responsive.spacing(4),
                  responsive.spacing(4),
                  responsive.spacing(6),
                ),
                child: Text(
                  service['name'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: responsive.fontSize(11),
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconFallback(Map<String, dynamic> service, bool isSelected) {
    final responsive = ResponsiveUtils(context);
    return Center(
      child: Icon(
        service['iconOutlined'] as IconData,
        size: responsive.iconSize(28),
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMinimalStepper(widget.currentStep),
            ),
          ),
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper(int currentStep) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(widget.totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isCurrent = stepNumber == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              if (index < widget.totalSteps - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton() {
    final bool canContinue = widget.formData.selectedService != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canContinue ? widget.onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}