import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../services/payment_service.dart';

/// A premium styled payment card input widget
class PaymentCardInput extends StatefulWidget {
  final Function(
    String cardNumber,
    int expiryMonth,
    int expiryYear,
    String cvc,
    String cardHolderName,
  )?
  onCardComplete;
  final Function(bool isValid)? onValidationChanged;
  final bool showSecurityNotice;

  const PaymentCardInput({
    super.key,
    this.onCardComplete,
    this.onValidationChanged,
    this.showSecurityNotice = true,
  });

  @override
  State<PaymentCardInput> createState() => _PaymentCardInputState();
}

class _PaymentCardInputState extends State<PaymentCardInput> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardHolderController = TextEditingController();

  final _paymentService = PaymentService();

  String _cardBrand = '';
  bool _isCardNumberValid = false;
  bool _isExpiryValid = false;
  bool _isCvcValid = false;
  bool _isCardHolderValid = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _validateCard() {
    final isValid =
        _isCardNumberValid &&
        _isExpiryValid &&
        _isCvcValid &&
        _isCardHolderValid;
    widget.onValidationChanged?.call(isValid);

    if (isValid) {
      final expiry = _expiryController.text.split('/');
      final month = int.tryParse(expiry[0]) ?? 0;
      final year = int.tryParse(expiry[1]) ?? 0;

      widget.onCardComplete?.call(
        _cardNumberController.text.replaceAll(' ', ''),
        month,
        2000 + year,
        _cvcController.text,
        _cardHolderController.text.trim(),
      );
    }
  }

  IconData _getCardBrandIcon() {
    switch (_cardBrand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: isSmallScreen ? 28 : 32,
              height: isSmallScreen ? 28 : 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
              child: Icon(
                Icons.payment_outlined,
                color: AppColors.primary,
                size: isSmallScreen ? 14 : 16,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Text(
              'Payment Details',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _buildCardLogo('visa'),
                const SizedBox(width: 4),
                _buildCardLogo('mastercard'),
                const SizedBox(width: 4),
                _buildCardLogo('amex'),
              ],
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Divider(height: 1, color: AppColors.gray200),
        SizedBox(height: isSmallScreen ? 8 : 12),

        // Cardholder Name
        _buildTextField(
          controller: _cardHolderController,
          label: 'Cardholder Name',
          hint: 'Name on card',
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          isCompact: isSmallScreen,
          onChanged: (value) {
            setState(() {
              _isCardHolderValid =
                  value.trim().isNotEmpty && value.trim().length >= 2;
            });
            _validateCard();
          },
          suffixIcon: _isCardHolderValid
              ? const Icon(
                  Icons.check_circle_outlined,
                  color: AppColors.success,
                  size: 20,
                )
              : null,
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),

        // Card Number
        _buildTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          prefixIcon: _getCardBrandIcon(),
          keyboardType: TextInputType.number,
          isCompact: isSmallScreen,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          maxLength: 19, // 16 digits + 3 spaces
          onChanged: (value) {
            // Count only digits; spaces are for display and not counted
            final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
            setState(() {
              _isCardNumberValid =
                  cleanNumber.length == 16 &&
                  _paymentService.validateCardNumber(cleanNumber);
              if (cleanNumber.length >= 4) {
                if (cleanNumber.startsWith('4')) {
                  _cardBrand = 'Visa';
                } else if (cleanNumber.startsWith('5') ||
                    cleanNumber.startsWith('2')) {
                  _cardBrand = 'Mastercard';
                } else if (cleanNumber.startsWith('34') ||
                    cleanNumber.startsWith('37')) {
                  _cardBrand = 'Amex';
                } else if (cleanNumber.startsWith('6')) {
                  _cardBrand = 'Discover';
                } else {
                  _cardBrand = '';
                }
              } else {
                _cardBrand = '';
              }
            });
            _validateCard();
          },
          suffixIcon: _isCardNumberValid
              ? const Icon(
                  Icons.check_circle_outlined,
                  color: AppColors.success,
                  size: 20,
                )
              : null,
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),

        // Expiry and CVC Row
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _expiryController,
                label: 'Expiry Date',
                hint: 'MM/YY',
                prefixIcon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
                isCompact: isSmallScreen,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateFormatter(),
                ],
                maxLength: 5, // MM/YY
                onChanged: (value) {
                  if (value.contains('/')) {
                    final parts = value.split('/');
                    if (parts.length == 2 &&
                        parts[0].length == 2 &&
                        parts[1].length == 2) {
                      final month = int.tryParse(parts[0]) ?? 0;
                      final year = int.tryParse(parts[1]) ?? 0;
                      setState(() {
                        _isExpiryValid = _paymentService.validateExpiryDate(
                          month,
                          year,
                        );
                      });
                      _validateCard();
                      return;
                    }
                  }
                  setState(() {
                    _isExpiryValid = false;
                  });
                  _validateCard();
                },
                suffixIcon: _isExpiryValid
                    ? const Icon(
                        Icons.check_circle_outlined,
                        color: AppColors.success,
                        size: 20,
                      )
                    : null,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Expanded(
              child: _buildTextField(
                controller: _cvcController,
                label: 'CVC',
                hint: _cardBrand == 'Amex' ? '1234' : '123',
                prefixIcon: Icons.lock_outline,
                keyboardType: TextInputType.number,
                isCompact: isSmallScreen,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: _cardBrand == 'Amex' ? 4 : 3,
                obscureText: true,
                onChanged: (value) {
                  final cardNumber = _cardNumberController.text.replaceAll(
                    ' ',
                    '',
                  );
                  setState(() {
                    _isCvcValid = _paymentService.validateCvc(
                      value,
                      cardNumber,
                    );
                  });
                  _validateCard();
                },
                suffixIcon: _isCvcValid
                    ? const Icon(
                        Icons.check_circle_outlined,
                        color: AppColors.success,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),

        // Security notice - only show if enabled
        if (widget.showSecurityNotice)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10,
              vertical: isSmallScreen ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: isSmallScreen ? 14 : 16,
                  color: AppColors.successDark,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Your payment information is encrypted and secure',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: AppColors.successDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCardLogo(String brand) {
    return Container(
      width: 32,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.backgroundGray100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Center(
        child: Text(
          brand.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.gray600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
    bool isCompact = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: TextStyle(fontSize: isCompact ? 13 : 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        labelStyle: TextStyle(fontSize: isCompact ? 12 : 13),
        hintStyle: TextStyle(fontSize: isCompact ? 12 : 13),
        prefixIcon: Icon(prefixIcon, size: isCompact ? 18 : 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.backgroundGray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 14,
          vertical: isCompact ? 10 : 12,
        ),
      ),
    );
  }
}

/// Formatter for card number input: exactly 16 digits, display with spaces every 4 digits.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter for expiry date MM/YY.
/// - Month 01-12 only. If user enters 2-9 as first digit, treat as month and add 0 before (02-09).
/// - Slash inserted after 2nd digit; year 2 digits (e.g. 25 â†’ 2025).
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return TextEditingValue.empty;
    }

    String d = digits.length > 4 ? digits.substring(0, 4) : digits;
    // If user entered single digit 2-9, treat as month and add leading 0
    if (d.length == 1) {
      final digit = d[0];
      if (digit == '2' ||
          digit == '3' ||
          digit == '4' ||
          digit == '5' ||
          digit == '6' ||
          digit == '7' ||
          digit == '8' ||
          digit == '9') {
        d = '0$digit'; // 02, 03, ..., 09
      }
    }

    String formatted;
    if (d.length <= 2) {
      formatted = d;
    } else {
      formatted = '${d.substring(0, 2)}/${d.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Widget to select from saved payment methods
class SavedPaymentMethodSelector extends StatefulWidget {
  final List<PaymentMethod> paymentMethods;
  final String? selectedMethodId;
  final ValueChanged<String>? onMethodSelected;
  final VoidCallback? onAddNewMethod;

  const SavedPaymentMethodSelector({
    super.key,
    required this.paymentMethods,
    this.selectedMethodId,
    this.onMethodSelected,
    this.onAddNewMethod,
  });

  @override
  State<SavedPaymentMethodSelector> createState() =>
      _SavedPaymentMethodSelectorState();
}

class _SavedPaymentMethodSelectorState
    extends State<SavedPaymentMethodSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.wallet_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.gray200),
          const SizedBox(height: 12),

          // Saved payment methods
          ...widget.paymentMethods.map(
            (method) => _buildPaymentMethodTile(method),
          ),

          // Add new payment method button
          const SizedBox(height: 8),
          InkWell(
            onTap: widget.onAddNewMethod,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.gray300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_outlined, size: 20, color: AppColors.gray600),
                  SizedBox(width: 8),
                  Text(
                    'Add New Payment Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = widget.selectedMethodId == method.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onMethodSelected?.call(method.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary05 : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.gray300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray100,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusBadge,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.credit_card_outlined,
                    size: 18,
                    color: AppColors.gray700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          method.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (method.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary10,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expires ${method.expiryDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: method.isExpired
                            ? AppColors.error
                            : AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_outlined
                    : Icons.radio_button_unchecked_outlined,
                color: isSelected ? AppColors.primary : AppColors.gray400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
