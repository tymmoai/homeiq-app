import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_step_header.dart';

/// Shared step widget for selecting items with quantity controls (+/-).
///
/// Displays a list of items with per-item quantity selectors,
/// a special requirements text field, and a bottom bar showing
/// item count + total price.
class ItemQuantitySelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final List<ServiceItem> items;
  final String title;
  final String subtitle;
  final String sectionTitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  /// Whether to show the special requirements text field.
  final bool showSpecialRequirements;

  const ItemQuantitySelector({
    super.key,
    required this.formData,
    required this.items,
    this.title = 'What do you need?',
    this.subtitle = 'Select the items you need',
    this.sectionTitle = 'Select Items',
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
    this.showSpecialRequirements = true,
  });

  @override
  State<ItemQuantitySelector> createState() => _ItemQuantitySelectorState();
}

class _ItemQuantitySelectorState extends State<ItemQuantitySelector> {
  final TextEditingController _specialRequirementsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _specialRequirementsController.text =
        widget.formData.specialRequirements ?? '';
  }

  @override
  void dispose() {
    _specialRequirementsController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = 0;
    widget.formData.selectedItems.forEach((itemName, quantity) {
      for (var item in widget.items) {
        if (item.name == itemName) {
          total += item.price * quantity;
          break;
        }
      }
    });
    return total;
  }

  int get _totalItems => widget.formData.totalItemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: context.responsive.padding(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(24.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  context.responsive.heightBox(8.0),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(14.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  context.responsive.heightBox(29.0),
                  Text(
                    widget.sectionTitle,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(16.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  context.responsive.heightBox(12.0),
                  // Items List
                  ...List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    return _buildItemCard(item);
                  }),
                  context.responsive.heightBox(24.0),
                  // Special Requirements Section
                  if (widget.showSpecialRequirements)
                    _buildSpecialRequirementsSection(),
                  context.responsive.heightBox(24.0),
                ],
              ),
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildItemCard(ServiceItem item) {
    final quantity = widget.formData.selectedItems[item.name] ?? 0;
    final isSelected = quantity > 0;

    return Container(
      margin: EdgeInsets.only(bottom: context.responsive.spacing(12.0)),
      padding: context.responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary05 : Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(12.0),
        ),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: isSelected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Item Icon
          Container(
            width: context.responsive.spacing(48.0),
            height: context.responsive.spacing(48.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray100,
              borderRadius: BorderRadius.circular(
                context.responsive.borderRadius(10.0),
              ),
            ),
            child: Icon(
              item.icon,
              color: isSelected ? AppColors.primary : AppColors.gray600,
              size: context.responsive.iconSize(24.0),
            ),
          ),
          context.responsive.widthBox(16.0),
          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(15.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                context.responsive.heightBox(4.0),
                Text(
                  '\$${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          _buildQuantityControls(item.name, quantity),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(String itemName, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus Button
        GestureDetector(
          onTap: quantity > 0
              ? () {
                  setState(() {
                    if (quantity == 1) {
                      widget.formData.selectedItems.remove(itemName);
                    } else {
                      widget.formData.selectedItems[itemName] = quantity - 1;
                    }
                  });
                }
              : null,
          child: Container(
            width: context.responsive.spacing(32.0),
            height: context.responsive.spacing(32.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: quantity > 0 ? Colors.white : AppColors.gray100,
              border: Border.all(
                color: quantity > 0 ? AppColors.primary : AppColors.gray300,
                width: 1.5,
              ),
              boxShadow: quantity > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.remove,
              color: quantity > 0 ? AppColors.primary : AppColors.gray400,
              size: context.responsive.iconSize(18.0),
            ),
          ),
        ),
        // Quantity
        Container(
          width: context.responsive.spacing(44.0),
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: TextStyle(
              fontSize: context.responsive.fontSize(17.0),
              fontWeight: FontWeight.w700,
              color: quantity > 0 ? AppColors.primary : AppColors.gray500,
            ),
          ),
        ),
        // Plus Button
        GestureDetector(
          onTap: () {
            setState(() {
              widget.formData.selectedItems[itemName] = quantity + 1;
            });
          },
          child: Container(
            width: context.responsive.spacing(32.0),
            height: context.responsive.spacing(32.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: context.responsive.iconSize(18.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialRequirementsSection() {
    return Container(
      padding: context.responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(12.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                color: AppColors.primary,
                size: context.responsive.iconSize(22.0),
              ),
              context.responsive.widthBox(8.0),
              Text(
                'Special Requirements',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              context.responsive.widthBox(4.0),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(14.0),
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          context.responsive.heightBox(12.0),
          TextField(
            controller: _specialRequirementsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Let us know if you have any special requirements or instructions',
              hintStyle: TextStyle(
                fontSize: context.responsive.fontSize(14.0),
                color: AppColors.gray400,
              ),
              filled: true,
              fillColor: AppColors.backgroundGray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.responsive.borderRadius(10.0),
                ),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.responsive.borderRadius(10.0),
                ),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.responsive.borderRadius(10.0),
                ),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: context.responsive.padding(all: 14),
            ),
            style: TextStyle(
              fontSize: context.responsive.fontSize(14.0),
              color: AppColors.textPrimary,
            ),
            onChanged: (value) {
              widget.formData.specialRequirements = value.isEmpty
                  ? null
                  : value;
            },
          ),
          context.responsive.heightBox(8.0),
          Text(
            'Let us know if you have any special requirements or instructions',
            style: TextStyle(
              fontSize: context.responsive.fontSize(12.0),
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isValid = _totalItems > 0;
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price Summary
          if (_totalItems > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_totalItems item${_totalItems != 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(14.0),
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Total: \$${_totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(16.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            context.responsive.heightBox(16.0),
          ],
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: context.responsive.buttonHeight(50.0),
            child: ElevatedButton(
              onPressed: isValid
                  ? () {
                      widget.formData.totalPrice = _totalPrice;
                      widget.onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid
                    ? AppColors.primary
                    : AppColors.divider,
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: isValid ? Colors.white : AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
