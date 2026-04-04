import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _cardNumberController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _backgroundColor = AppColors.background;

  bool _isCardExpired = false;
  bool _cardNumberValidationFired = false;
  bool _cardholderValidationFired = false;
  bool _expiryValidationFired = false;
  bool _cvvValidationFired = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_validateCardNumberLive);
    _cardholderNameController.addListener(_validateCardholderNameLive);
    _expiryDateController.addListener(_validateExpiryLive);
    _cvvController.addListener(_validateCvvLive);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cardNumberController.dispose();
    _cardholderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Real-time card number validation
  void _validateCardNumberLive() {
    if (!_cardNumberValidationFired && _cardNumberController.text.isNotEmpty) {
      setState(() => _cardNumberValidationFired = true);
    }
    if (_cardNumberValidationFired) {
      setState(() {});
    }
  }

  // Real-time cardholder validation
  void _validateCardholderNameLive() {
    if (!_cardholderValidationFired && _cardholderNameController.text.isNotEmpty) {
      setState(() => _cardholderValidationFired = true);
    }
    if (_cardholderValidationFired) {
      setState(() {});
    }
  }

  // Real-time expiry validation
  void _validateExpiryLive() {
    if (!_expiryValidationFired && _expiryDateController.text.isNotEmpty) {
      setState(() => _expiryValidationFired = true);
    }
    if (_expiryValidationFired) {
      _validateExpiry(_expiryDateController.text);
    }
  }

  // Real-time CVV validation
  void _validateCvvLive() {
    if (!_cvvValidationFired && _cvvController.text.isNotEmpty) {
      setState(() => _cvvValidationFired = true);
    }
    if (_cvvValidationFired) {
      setState(() {});
    }
  }

  void _validateExpiry(String value) {
    setState(() {
      if (value.isEmpty) {
        _isCardExpired = false;
        return;
      }

      final parts = value.split('/');
      if (parts.length != 2) {
        _isCardExpired = true;
        return;
      }

      final month = int.tryParse(parts[0]);
      final year = int.tryParse(parts[1]);

      if (month == null || year == null || month < 1 || month > 12) {
        _isCardExpired = true;
        return;
      }

      // Current year is 2026, allow year 25 and above
      if (year < 25) {
        _isCardExpired = true;
        return;
      }

      final fullYear = 2000 + year;
      final expiryDate = DateTime(fullYear, month);
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      _isCardExpired = expiryDate.isBefore(currentMonth);
    });
  }

  String? _getCardNumberErrorMessage() {
    if (!_cardNumberValidationFired) return null;

    final value = _cardNumberController.text;
    if (value.isEmpty) {
      return 'Please enter card number';
    }
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length != 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _getCardholderNameErrorMessage() {
    if (!_cardholderValidationFired) return null;

    final value = _cardholderNameController.text;
    if (value.isEmpty) {
      return 'Please enter cardholder name';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    // Check if contains only alphabets and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Letters only';
    }
    return null;
  }

  String? _getExpiryDateErrorMessage() {
    if (!_expiryValidationFired) return null;

    final value = _expiryDateController.text;
    if (value.isEmpty) {
      return 'Please enter expiry date';
    }
    if (value.length != 5) {
      return 'Invalid format (MM/YY)';
    }
    if (_isCardExpired) {
      return 'Card is expired or year is invalid';
    }
    return null;
  }

  String? _getCvvErrorMessage() {
    if (!_cvvValidationFired) return null;

    final value = _cvvController.text;
    if (value.isEmpty) {
      return 'Please enter CVV';
    }
    if (value.length != 3) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  bool _isFormValid() {
    final cardNumberValid = _cardNumberController.text.replaceAll(' ', '').length == 16;
    final cardholderValid = _cardholderNameController.text.isNotEmpty &&
        _cardholderNameController.text.length >= 3 &&
        RegExp(r'^[a-zA-Z\s]+$').hasMatch(_cardholderNameController.text);
    final expiryValid =
        _expiryDateController.text.length == 5 && !_isCardExpired;
    final cvvValid = _cvvController.text.length == 3;

    return cardNumberValid && cardholderValid && expiryValid && cvvValid;
  }



  void _saveCard() {
    // Trigger validation on all fields
    setState(() {
      _cardNumberValidationFired = true;
      _cardholderValidationFired = true;
      _expiryValidationFired = true;
      _cvvValidationFired = true;
    });

    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Get last 4 digits of card
    final cleaned = _cardNumberController.text.replaceAll(' ', '');
    final lastFour = cleaned.substring(cleaned.length - 4);

    final newCard = {
      'id': 'card_${DateTime.now().millisecondsSinceEpoch}',
      'cardNumber': cleaned,
      'lastFour': lastFour,
      'cardholderName': _cardholderNameController.text,
      'expiryDate': _expiryDateController.text,
      'cardType': _getCardType(cleaned),
    };

    // Return to checkout with new card
    context.pop(newCard);
  }

  String _getCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith('5')) return 'Mastercard';
    if (cardNumber.startsWith('3')) return 'American Express';
    return 'Card';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add New Card',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: responsive.padding(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Number
                    Text(
                      'Card Number',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13.0),
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(8.0),
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        hintText: '1234 5678 9012 3456',
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          color: AppColors.gray400,
                        ),
                        prefixIcon: Icon(
                          Icons.credit_card_outlined,
                          color: _headerColor,
                          size: responsive.iconSize(20.0),
                        ),
                        errorText: _getCardNumberErrorMessage(),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: BorderSide(color: _headerColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: responsive.padding(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        color: _textPrimary,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(19),
                        _CardNumberFormatter(),
                      ],
                    ),
                    responsive.heightBox(20.0),

                    // Cardholder Name
                    Text(
                      'Cardholder Name',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13.0),
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(8.0),
                    TextFormField(
                      controller: _cardholderNameController,
                      decoration: InputDecoration(
                        hintText: 'John Doe',
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          color: AppColors.gray400,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: _headerColor,
                          size: responsive.iconSize(20.0),
                        ),
                        errorText: _getCardholderNameErrorMessage(),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: BorderSide(color: _headerColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: responsive.padding(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        color: _textPrimary,
                      ),
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],
                    ),
                    responsive.heightBox(20.0),

                    // Expiry Date and CVV Row
                    Row(
                      children: [
                        // Expiry Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                              responsive.heightBox(8.0),
                              TextFormField(
                                controller: _expiryDateController,
                                decoration: InputDecoration(
                                  hintText: 'MM/YY',
                                  hintStyle: TextStyle(
                                    fontSize: responsive.fontSize(14.0),
                                    color: AppColors.gray400,
                                  ),
                                  errorText: _getExpiryDateErrorMessage(),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.gray300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.gray300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: _headerColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: responsive.padding(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14.0),
                                  color: _textPrimary,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryDateFormatter(),
                                ],
                                onChanged: _validateExpiry,
                              ),
                            ],
                          ),
                        ),
                        responsive.widthBox(16.0),
                        // CVV
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CVV',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                              responsive.heightBox(8.0),
                              TextFormField(
                                controller: _cvvController,
                                decoration: InputDecoration(
                                  hintText: '123',
                                  hintStyle: TextStyle(
                                    fontSize: responsive.fontSize(14.0),
                                    color: AppColors.gray400,
                                  ),
                                  errorText: _getCvvErrorMessage(),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.gray300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.gray300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: BorderSide(
                                      color: _headerColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(12.0),
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: responsive.padding(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14.0),
                                  color: _textPrimary,
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    responsive.heightBox(24.0),

                    // Security note
                    Container(
                      padding: responsive.padding(all: 12),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(
                          responsive.borderRadius(8.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: responsive.iconSize(20.0),
                            color: AppColors.infoDark,
                          ),
                          responsive.widthBox(10.0),
                          Expanded(
                            child: Text(
                              'Your card information is encrypted and secure',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12.0),
                                color: AppColors.infoDark,
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

            // Save Button
            Container(
              padding: responsive.padding(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(color: AppColors.white),
              child: SizedBox(
                width: double.infinity,
                height: responsive.buttonHeight(52.0),
                child: ElevatedButton(
                  onPressed: _isFormValid() ? _saveCard : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid() ? _headerColor : AppColors.gray300,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Card',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.w600,
                      color: _isFormValid() ? AppColors.white : AppColors.gray600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card number formatter for spacing
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 16 digits
    if (text.length > 16) {
      return oldValue;
    }

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Expiry date formatter for MM/YY format
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits
    var text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 4 digits
    if (text.length > 4) {
      return oldValue;
    }

    // Auto-add 0 prefix if first digit is 2-9
    if (text.length == 1 && int.tryParse(text)! >= 2 && int.tryParse(text)! <= 9) {
      text = '0$text';
    }

    String formatted = text;
    if (text.length >= 3 && !text.contains('/')) {
      formatted = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

