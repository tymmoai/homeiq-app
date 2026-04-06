import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../services/payment_service.dart';
import 'payment_card_input.dart';
import 'payment_expiry_formatter.dart';

/// Card payment section: saved payment methods list + add-new-card form.
class PaymentCardSection extends StatelessWidget {
  final List<PaymentMethod> savedMethods;
  final String? selectedMethodId;
  final bool showNewCardForm;
  final bool isCardValid;
  final bool isProcessing;
  final bool isAddingCard;
  final String? selectedCardExpiryError;
  final String? selectedCardCvvError;
  final TextEditingController selectedExpiryController;
  final TextEditingController selectedCvvController;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final VoidCallback onToggleNewCardForm;
  final ValueChanged<String> onExpiryChanged;
  final ValueChanged<String> onCvvChanged;
  final void Function(
    String cardNumber,
    int expiryMonth,
    int expiryYear,
    String cvc,
    String? cardHolderName,
  )
  onCardComplete;
  final ValueChanged<bool> onValidationChanged;
  final VoidCallback onSaveNewCard;

  const PaymentCardSection({
    super.key,
    required this.savedMethods,
    required this.selectedMethodId,
    required this.showNewCardForm,
    required this.isCardValid,
    required this.isProcessing,
    required this.isAddingCard,
    this.selectedCardExpiryError,
    this.selectedCardCvvError,
    required this.selectedExpiryController,
    required this.selectedCvvController,
    required this.onMethodSelected,
    required this.onToggleNewCardForm,
    required this.onExpiryChanged,
    required this.onCvvChanged,
    required this.onCardComplete,
    required this.onValidationChanged,
    required this.onSaveNewCard,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      width: double.infinity,
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: responsive.spacing(10.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (savedMethods.isNotEmpty) ...[
            Text(
              'SAVED PAYMENT METHODS',
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            responsive.heightBox(16.0),
            ...savedMethods.map(
              (method) => Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                child: _buildPaymentMethodItem(context, responsive, method),
              ),
            ),
            responsive.heightBox(16.0),
          ],
          GestureDetector(
            onTap: onToggleNewCardForm,
            child: Text(
              '+ Add new payment card',
              style: TextStyle(
                fontSize: responsive.fontSize(15.0),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          if (showNewCardForm) ...[
            responsive.heightBox(16.0),
            _buildNewCardForm(context, responsive),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context,
    ResponsiveUtils responsive,
    PaymentMethod method,
  ) {
    final isSelected = selectedMethodId == method.id;

    return GestureDetector(
      onTap: () => onMethodSelected(method),
      child: Container(
        padding: responsive.padding(all: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: responsive.spacing(40.0),
                  height: responsive.spacing(28.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(6.0),
                    ),
                  ),
                  child: Center(
                    child: _buildCardBrandIcon(responsive, method.brand),
                  ),
                ),
                responsive.widthBox(12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.cardholderName ?? 'Card Holder',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      responsive.heightBox(4.0),
                      Text(
                        '${method.brand} •••• ${method.last4}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13.0),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: responsive.spacing(24.0),
                  height: responsive.spacing(24.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: responsive.iconSize(14.0),
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isSelected
                  ? Padding(
                      padding: responsive.padding(top: 12),
                      child: Container(
                        padding: responsive.padding(all: 12),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(10.0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Expiry (MM/YY)',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(12.0),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      responsive.heightBox(6.0),
                                      TextFormField(
                                        key: ValueKey('expiry-${method.id}'),
                                        controller: selectedExpiryController,
                                        onChanged: onExpiryChanged,
                                        decoration: InputDecoration(
                                          hintText: 'MM/YY',
                                          errorText: selectedCardExpiryError,
                                          filled: true,
                                          fillColor: AppColors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              responsive.borderRadius(8.0),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              responsive.borderRadius(8.0),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              responsive.borderRadius(8.0),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: responsive.padding(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                        keyboardType: TextInputType.datetime,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          PaymentExpiryDateFormatter(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                responsive.widthBox(12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CVV',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(12.0),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      responsive.heightBox(6.0),
                                      TextFormField(
                                        key: ValueKey('cvv-${method.id}'),
                                        controller: selectedCvvController,
                                        onChanged: onCvvChanged,
                                        decoration: InputDecoration(
                                          hintText: '***',
                                          errorText: selectedCardCvvError,
                                          filled: true,
                                          fillColor: AppColors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              responsive.borderRadius(8.0),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              responsive.borderRadius(8.0),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              responsive.borderRadius(8.0),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: responsive.padding(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          counterText: '',
                                        ),
                                        keyboardType: TextInputType.number,
                                        maxLength: 3,
                                        obscureText: true,
                                        obscuringCharacter: '*',
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBrandIcon(ResponsiveUtils responsive, String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icon(
          Icons.credit_card,
          size: responsive.iconSize(20.0),
          color: AppColors.info,
        );
      case 'mastercard':
        return Icon(
          Icons.credit_card,
          size: responsive.iconSize(20.0),
          color: AppColors.error,
        );
      default:
        return Icon(
          Icons.credit_card,
          size: responsive.iconSize(20.0),
          color: AppColors.textSecondary,
        );
    }
  }

  Widget _buildNewCardForm(BuildContext context, ResponsiveUtils responsive) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Container(
      padding: responsive.padding(all: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: responsive.spacing(8.0),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PaymentCardInput(
            showSecurityNotice: false,
            onCardComplete: onCardComplete,
            onValidationChanged: onValidationChanged,
          ),
          SizedBox(height: isSmallScreen ? 10 : 14),
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 40 : 44,
            child: ElevatedButton(
              onPressed: (isCardValid && !isProcessing && !isAddingCard)
                  ? onSaveNewCard
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (isCardValid && !isProcessing && !isAddingCard)
                    ? AppColors.primary
                    : AppColors.gray300,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: isProcessing || isAddingCard
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Text(
                      'Save Card',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
