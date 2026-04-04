import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/asset_form_model.dart';
import '../widgets/asset_type_button_widget.dart';
import '../widgets/category_button_widget.dart';

class Step1TypeSelectionScreen extends StatefulWidget {
  final AssetFormModel formData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step1TypeSelectionScreen({
    super.key,
    required this.formData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step1TypeSelectionScreen> createState() =>
      _Step1TypeSelectionScreenState();
}

class _Step1TypeSelectionScreenState extends State<Step1TypeSelectionScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _otherTypeController = TextEditingController();
  bool _isOtherSelected = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Appliances', 'icon': Icons.kitchen_outlined},
    {'name': 'Home Systems', 'icon': Icons.home_work_outlined},
    {'name': 'Electronics', 'icon': Icons.devices_outlined},
  ];

  final Map<String, List<Map<String, dynamic>>> _assetTypes = {
    'Appliances': [
      {'name': 'Refrigerator', 'icon': Icons.kitchen_outlined},
      {'name': 'Washer', 'icon': Icons.local_laundry_service_outlined},
      {'name': 'Dryer', 'icon': Icons.dry_cleaning_outlined},
      {'name': 'Dishwasher', 'icon': Icons.water_outlined},
      {'name': 'Range / Stove', 'icon': Icons.fireplace_outlined},
      {'name': 'Microwave', 'icon': Icons.microwave_outlined},
      {'name': 'Other', 'icon': Icons.more_horiz_outlined},
    ],
    'Home Systems': [
      {'name': 'Heating & Cooling', 'icon': Icons.heat_pump_outlined},
      {'name': 'Water Heater', 'icon': Icons.whatshot_outlined},
      {'name': 'Garbage Disposal', 'icon': Icons.recycling_outlined},
      {'name': 'Sump Pump', 'icon': Icons.plumbing_outlined},
      {'name': 'EV Charger', 'icon': Icons.ev_station_outlined},
      {'name': 'Security System', 'icon': Icons.security_outlined},
      {'name': 'Other', 'icon': Icons.more_horiz_outlined},
    ],
    'Electronics': [
      {'name': 'Television', 'icon': Icons.connected_tv_outlined},
      {'name': 'Computer', 'icon': Icons.desktop_mac_outlined},
      {'name': 'Gaming Console', 'icon': Icons.sports_esports_outlined},
      {'name': 'Smart Speaker', 'icon': Icons.speaker_group_outlined},
      {'name': 'Security Camera', 'icon': Icons.videocam_outlined},
      {'name': 'Other', 'icon': Icons.more_horiz_outlined},
    ],
  };

  @override
  void initState() {
    super.initState();
    // Check if previously selected type was custom ("Other")
    final currentType = widget.formData.selectedAssetType;
    if (currentType != null) {
      final category = widget.formData.selectedCategory;
      final knownTypes = (_assetTypes[category] ?? [])
          .map((t) => t['name'] as String)
          .where((n) => n != 'Other')
          .toSet();
      if (!knownTypes.contains(currentType)) {
        _isOtherSelected = true;
        _otherTypeController.text = currentType;
      }
    }
  }

  @override
  void dispose() {
    _otherTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(),
        // Content
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(20),
                vertical: responsive.spacing(0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'What would you like to add?',
                    style: TextStyle(
                      fontSize: responsive.fontSize(22),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(6)),
                  Text(
                    'Choose the category and type of asset',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(29)),
                  // Primary Category
                  Text(
                    'Primary Category',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Row(
                    children: _categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < _categories.length - 1 ? 12 : 0,
                          ),
                          child: CategoryButton(
                            label: category['name'] as String,
                            icon: category['icon'] as IconData,
                            isSelected:
                                widget.formData.selectedCategory ==
                                category['name'],
                            onTap: () {
                              setState(() {
                                widget.formData.selectedCategory =
                                    category['name'] as String;
                                widget.formData.selectedAssetType = null;
                                _isOtherSelected = false;
                                _otherTypeController.clear();
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: responsive.spacing(24)),
                  // Select Asset Type
                  if (widget.formData.selectedCategory != null) ...[
                    Text(
                      'Select Asset Type',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),
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
                      itemCount:
                          (_assetTypes[widget.formData.selectedCategory] ?? [])
                              .length,
                      itemBuilder: (context, index) {
                        final assetType =
                            _assetTypes[widget
                                .formData
                                .selectedCategory]![index];
                        final typeName = assetType['name'] as String;
                        final isOther = typeName == 'Other';
                        return AssetTypeButton(
                          label: typeName,
                          icon: assetType['icon'] as IconData,
                          isSelected: isOther
                              ? _isOtherSelected
                              : (!_isOtherSelected &&
                                    widget.formData.selectedAssetType ==
                                        typeName),
                          onTap: () {
                            setState(() {
                              if (isOther) {
                                _isOtherSelected = true;
                                widget.formData.selectedAssetType =
                                    _otherTypeController.text.trim().isNotEmpty
                                    ? _otherTypeController.text.trim()
                                    : null;
                              } else {
                                _isOtherSelected = false;
                                _otherTypeController.clear();
                                widget.formData.selectedAssetType = typeName;
                              }
                            });
                          },
                        );
                      },
                    ),
                    // Custom type text field when "Other" is selected
                    if (_isOtherSelected) ...[
                      SizedBox(height: responsive.spacing(16)),
                      TextField(
                        controller: _otherTypeController,
                        decoration: InputDecoration(
                          hintText: 'Enter asset type name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(16),
                            vertical: responsive.spacing(14),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) {
                          setState(() {
                            widget.formData.selectedAssetType =
                                value.trim().isNotEmpty ? value.trim() : null;
                          });
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        // Continue Button
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: responsive.spacing(16)),
              child: _buildMinimalStepper(1),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(6)),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: responsive.iconSize(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper(int currentStep) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(4, (index) {
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
              if (index < 3) SizedBox(width: responsive.spacing(4)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton() {
    final isValid = widget.formData.isStep1Valid();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(20),
        responsive.spacing(16),
        responsive.spacing(20),
        responsive.spacing(16) + bottomInset,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: responsive.spacing(52),
        child: ElevatedButton(
          onPressed: isValid ? widget.onNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? AppColors.primary : AppColors.gray300.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            disabledBackgroundColor: AppColors.gray300.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Continue',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: isValid ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
