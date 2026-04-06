import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../utils/responsive_utils.dart';

class ServiceSubcategoryScreen extends ConsumerStatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> services;

  const ServiceSubcategoryScreen({
    super.key,
    required this.categoryName,
    required this.services,
  });

  @override
  ConsumerState<ServiceSubcategoryScreen> createState() =>
      _ServiceSubcategoryScreenState();
}

class _ServiceSubcategoryScreenState
    extends ConsumerState<ServiceSubcategoryScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  Map<String, dynamic>? _selectedService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      body: SafeArea(
        child: Column(
          children: [
            // Header with stepper style like Assembly step1
            _buildHeader(context),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'What service do you need?',
                      style: TextStyle(
                        fontSize: responsive.fontSize(24),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    Text(
                      'Choose the type of ${widget.categoryName} service',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(29)),
                    // Section Title - same as Assembly step1
                    Text(
                      'Service Type',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    // Services Grid - 3 columns like Assembly step1
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
                      itemCount: widget.services.length,
                      itemBuilder: (context, index) {
                        final service = widget.services[index];
                        final isSelected =
                            _selectedService?['name'] == service['name'];
                        return _buildServiceCard(service, isSelected);
                      },
                    ),
                    SizedBox(height: responsive.spacing(20)),
                  ],
                ),
              ),
            ),
            // Continue Button
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Header style exactly same as Assembly step1 - stepper + close button only
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildMinimalStepper(),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Icon(
              Icons.close_outlined,
              color: AppColors.textPrimary,
              size: responsive.iconSize(24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper() {
    // Single step indicator (step 1 of multi-step flow) - same as Assembly
    const int totalSteps = 5;
    int currentStep = 1;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isActive = stepNumber == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              if (index < totalSteps - 1)
                SizedBox(width: responsive.spacing(4)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedService = service;
        });
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              service['icon'] as IconData,
              size: responsive.iconSize(28),
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
            SizedBox(height: responsive.spacing(8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(4)),
              child: Text(
                service['name'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: responsive.fontSize(11),
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool isEnabled = _selectedService != null;
    final bool isViewer = ref.watch(selectedHomeIsViewerProvider);

    return Container(
      padding: EdgeInsets.all(responsive.spacing(20)),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isEnabled
                ? () {
                    if (isViewer) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Viewers cannot book services. Contact the home owner to update your permissions.',
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    // Navigate to booking screen with selected service
                    context.push(
                      '/service-booking',
                      extra: {
                        'categoryName': widget.categoryName,
                        'service': _selectedService,
                      },
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? AppColors.primary
                  : AppColors.gray300,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.gray300,
              disabledForegroundColor: AppColors.gray500,
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
