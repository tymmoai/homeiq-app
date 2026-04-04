import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/asset_form_model.dart';
import '../widgets/location_button_widget.dart';

class Step3DetailsScreen extends StatefulWidget {
  final AssetFormModel formData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step3DetailsScreen({
    super.key,
    required this.formData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step3DetailsScreen> createState() => _Step3DetailsScreenState();
}

class _Step3DetailsScreenState extends State<Step3DetailsScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final List<Map<String, dynamic>> _locations = [
    {'label': 'Kitchen', 'icon': Icons.kitchen},
    {'label': 'Living Room', 'icon': Icons.chair},
    {'label': 'Bedroom', 'icon': Icons.bed},
    {'label': 'Bathroom', 'icon': Icons.bathtub_outlined},
    {'label': 'Office', 'icon': Icons.desktop_windows_outlined},
    {'label': 'Garage', 'icon': Icons.garage_outlined},
    {'label': 'Other', 'icon': Icons.location_on},
  ];

  String? _selectedYear;
  String? _selectedMonth;
  bool _isOtherSelected = false;
  final TextEditingController _otherLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Seed local state from formData so any date pre-filled by Step 2
    // (e.g. manufacture year from label scan) is immediately visible.
    _selectedYear = widget.formData.purchaseYear;
    _selectedMonth = widget.formData.purchaseMonth;

    // If location was set to something not in the standard list, it's a custom "Other" value
    final loc = widget.formData.location;
    if (loc != null && loc.isNotEmpty) {
      final isStandard = _locations.any((l) => l['label'] == loc);
      if (!isStandard) {
        _isOtherSelected = true;
        _otherLocationController.text = loc;
      }
    }
  }

  @override
  void dispose() {
    _otherLocationController.dispose();
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
                    'Confirm asset details',
                    style: TextStyle(
                      fontSize: responsive.fontSize(22),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(6)),
                  Text(
                    'Review and add final details',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(24)),
                  // Asset Details Card
                  _buildAssetDetailsCard(),
                  SizedBox(height: responsive.spacing(24)),
                  // Location Section
                  Row(
                    children: [
                      Text(
                        'Where is it located?',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Text(
                        '*',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Wrap(
                    spacing: responsive.spacing(8),
                    runSpacing: responsive.spacing(8),
                    children: _locations.map((location) {
                      final label = location['label'] as String;
                      final isOther = label == 'Other';
                      final isSelected = isOther
                          ? _isOtherSelected
                          : (!_isOtherSelected && widget.formData.location == label);
                      return SizedBox(
                        width: (MediaQuery.of(context).size.width - responsive.spacing(40) - responsive.spacing(24)) / 4,
                        child: LocationButton(
                          label: label,
                          icon: location['icon'] as IconData,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isOther) {
                                _isOtherSelected = true;
                                widget.formData.location = _otherLocationController.text.trim().isEmpty
                                    ? null
                                    : _otherLocationController.text.trim();
                              } else {
                                _isOtherSelected = false;
                                _otherLocationController.clear();
                                widget.formData.location = label;
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  if (_isOtherSelected) ...[
                    SizedBox(height: responsive.spacing(12)),
                    TextFormField(
                      controller: _otherLocationController,
                      decoration: InputDecoration(
                        hintText: 'Enter location name',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: responsive.fontSize(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(16),
                          vertical: responsive.spacing(12),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        widget.formData.location = value.trim().isEmpty ? null : value.trim();
                      },
                    ),
                  ],
                  SizedBox(height: responsive.spacing(24)),
                  // Purchase Date Section
                  Row(
                    children: [
                      Text(
                        'Purchase Date',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Text(
                        '(Optional but recommended)',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  GestureDetector(
                    onTap: () {
                      _showMonthYearPicker();
                    },
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(16),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getPurchaseDateDisplayText(),
                            style: TextStyle(
                              color: _hasPurchaseDate()
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.textSecondary,
                            size: responsive.iconSize(20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Hint when purchase date was auto-filled from label
                  if (widget.formData.manufacturedYear != null &&
                      widget.formData.manufacturedYear!.isNotEmpty &&
                      _hasPurchaseDate())
                    Padding(
                      padding: EdgeInsets.only(top: responsive.spacing(8)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: responsive.iconSize(14),
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: responsive.spacing(4)),
                          Expanded(
                            child: Text(
                              'Auto-filled from label manufacture year (${widget.formData.manufacturedYear}). Tap to adjust.',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(6)),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: responsive.iconSize(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
              child: _buildMinimalStepper(3),
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

  Widget _buildAssetDetailsCard() {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image preview
          if (widget.formData.productImageUrl != null &&
              widget.formData.productImageUrl!.isNotEmpty) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.formData.productImageUrl!,
                  height: responsive.spacing(120),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(12)),
          ],
          // WiFi discovery badge
          if (widget.formData.isWifiDiscovered) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_rounded,
                    size: 14,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Discovered on your WiFi network',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(12)),
          ],
          _buildDetailRow('Asset Name', widget.formData.getAssetName()),
          SizedBox(height: responsive.spacing(12)),
          _buildDetailRow('Brand', widget.formData.brand ?? '-'),
          SizedBox(height: responsive.spacing(12)),
          _buildDetailRow('Model', widget.formData.model ?? '-'),
          SizedBox(height: responsive.spacing(12)),
          _buildDetailRow('Serial Number', widget.formData.serial ?? '-'),
          if (widget.formData.wifiDeviceIp != null) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildDetailRow('IP Address', widget.formData.wifiDeviceIp!),
          ],
          if (widget.formData.wifiDeviceMac != null) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildDetailRow('MAC Address', widget.formData.wifiDeviceMac!),
          ],
          if (widget.formData.wifiHostname != null) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildDetailRow('Hostname', widget.formData.wifiHostname!),
          ],
          if (widget.formData.wifiFirmware != null) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildDetailRow('Firmware', widget.formData.wifiFirmware!),
          ],
          if (widget.formData.wifiOsHint != null) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildDetailRow('OS', widget.formData.wifiOsHint!),
          ],
          if (widget.formData.wifiOpenPorts != null &&
              widget.formData.wifiOpenPorts!.isNotEmpty) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildDetailRow(
              'Open Ports',
              widget.formData.wifiOpenPorts!.join(', '),
            ),
          ],
          if (widget.formData.wifiConfidence != null) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildDetailRow('Confidence', '${widget.formData.wifiConfidence}%'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  bool _hasPurchaseDate() {
    return (_selectedYear ?? widget.formData.purchaseYear) != null;
  }

  String _getPurchaseDateDisplayText() {
    final year = _selectedYear ?? widget.formData.purchaseYear;
    final month = _selectedMonth ?? widget.formData.purchaseMonth;
    if (year == null) return "Select date or 'I don't remember'";
    if (month != null) {
      final idx = int.tryParse(month);
      if (idx != null && idx >= 1 && idx <= 12) {
        const shortMonths = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${shortMonths[idx - 1]} $year';
      }
    }
    return year;
  }

  void _showMonthYearPicker() {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    // Initialize picker state from existing selection
    int pickerYear =
        int.tryParse(_selectedYear ?? widget.formData.purchaseYear ?? '') ??
        currentYear;
    int? pickerMonth;
    final existingMonth = _selectedMonth ?? widget.formData.purchaseMonth;
    if (existingMonth != null) {
      pickerMonth = int.tryParse(existingMonth);
    }

    const monthShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.55,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header with year navigation
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Purchase Date',
                          style: TextStyle(
                            fontSize: responsive.fontSize(18),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: responsive.iconSize(22),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // Year selector row
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: pickerYear > (currentYear - 29)
                              ? () {
                                  setSheetState(() {
                                    pickerYear--;
                                    // Reset month if going past current month in current year
                                    if (pickerYear == currentYear &&
                                        pickerMonth != null &&
                                        pickerMonth! > currentMonth) {
                                      pickerMonth = null;
                                    }
                                  });
                                }
                              : null,
                        ),
                        SizedBox(width: responsive.spacing(16)),
                        Text(
                          '$pickerYear',
                          style: TextStyle(
                            fontSize: responsive.fontSize(20),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: responsive.spacing(16)),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: pickerYear < currentYear
                              ? () {
                                  setSheetState(() {
                                    pickerYear++;
                                    if (pickerYear == currentYear &&
                                        pickerMonth != null &&
                                        pickerMonth! > currentMonth) {
                                      pickerMonth = null;
                                    }
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(8)),
                  // Month grid (4 columns × 3 rows)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(20),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.8,
                            ),
                        itemCount: 12,
                        itemBuilder: (ctx, index) {
                          final monthNum = index + 1;
                          final isSelected = pickerMonth == monthNum;
                          // Disable future months in current year
                          final isDisabled =
                              pickerYear == currentYear &&
                              monthNum > currentMonth;

                          return GestureDetector(
                            onTap: isDisabled
                                ? null
                                : () {
                                    setSheetState(() {
                                      pickerMonth = monthNum;
                                    });
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : isDisabled
                                    ? AppColors.gray100
                                    : AppColors.backgroundGray50,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusBadge,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.gray200,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  monthShort[index],
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : isDisabled
                                        ? AppColors.gray400
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Bottom buttons: "I don't remember" + Done
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        // "I don't remember" button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedMonth = null;
                                _selectedYear = null;
                                widget.formData.purchaseMonth = null;
                                widget.formData.purchaseYear = null;
                              });
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              "I don't remember",
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        // Done button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedYear = pickerYear.toString();
                                widget.formData.purchaseYear = pickerYear
                                    .toString();
                                if (pickerMonth != null) {
                                  _selectedMonth = pickerMonth.toString();
                                  widget.formData.purchaseMonth = pickerMonth
                                      .toString();
                                } else {
                                  _selectedMonth = null;
                                  widget.formData.purchaseMonth = null;
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: Text(
                              pickerMonth != null
                                  ? 'Select ${monthShort[pickerMonth! - 1]} $pickerYear'
                                  : 'Select $pickerYear',
                              style: TextStyle(
                                fontSize: responsive.fontSize(15),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContinueButton() {
    final isValid = widget.formData.isStep3Valid();
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
