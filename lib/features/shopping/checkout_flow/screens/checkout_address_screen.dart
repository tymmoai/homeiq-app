// Unified Checkout Screen - Address & Payment Combined

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../profile/payment_methods/widgets/payment_method_selector.dart';
import '../widgets/address_form_screen.dart';
import '../widgets/expiry_date_formatter.dart';

class CheckoutAddressScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int tradeInValue;
  final int quantity;
  final Map<String, dynamic>? asset;

  const CheckoutAddressScreen({
    super.key,
    required this.product,
    required this.tradeInValue,
    required this.quantity,
    this.asset,
  });

  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;

  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _backgroundColor = AppColors.background;

  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessingPayment = false;
  int _selectedAddressIndex = 0;

  // Card expansion state
  String? _expandedCardId;
  bool _isAddNewCardExpanded = false;

  // Card details state
  late final TextEditingController _cardholderNameController;
  final _cardExpiryController = TextEditingController(text: '12/25');
  final _cardCvvController = TextEditingController(text: '');

  // New card form controllers
  final _newCardNumberController = TextEditingController();
  final _newCardholderNameController = TextEditingController();
  final _newCardExpiryController = TextEditingController();
  final _newCardCvvController = TextEditingController();

  // Card validation
  bool _isCardExpired = false;
  bool _isCardDetailsValid = true;
  bool _isNewCardExpired = false;

  // Installment state
  Map<String, dynamic>? _selectedInstallmentPlan;

  // PaymentMethodSelector state
  SelectedPaymentInfo? _selectedPaymentInfo;

  // Saved cards list
  final List<Map<String, dynamic>> _savedCards = [];

  // Dummy saved addresses
  late final List<Map<String, String>> _savedAddresses;

  @override
  void initState() {
    super.initState();
    final user = UserService.instance;
    _fullNameController = TextEditingController(text: user.getUserName());
    _phoneController = TextEditingController(text: user.getUserPhone());
    _emailController = TextEditingController(text: user.getUserEmail());
    _streetController = TextEditingController(text: user.getUserAddress());
    _cityController = TextEditingController(text: user.getUserCity());
    _stateController = TextEditingController(text: user.getUserState());
    _zipController = TextEditingController(text: user.getUserZipCode());
    _cardholderNameController = TextEditingController(text: user.getUserName());
    _savedAddresses = [
      {
        'name': user.getUserName(),
        'phone': user.getUserPhone(),
        'address':
            '${user.getUserAddress()}, ${user.getUserCity()}, ${user.getUserState()} ${user.getUserZipCode()}',
      },
      {
        'name': 'Jane Smith',
        'phone': '(555) 987-6543',
        'address': '456 Oak Avenue, Brooklyn, NY 11201',
      },
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _cardholderNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _newCardNumberController.dispose();
    _newCardholderNameController.dispose();
    _newCardExpiryController.dispose();
    _newCardCvvController.dispose();
    super.dispose();
  }

  void _handleConfirmAndPay() {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Check if payment method is selected
    if (_selectedPaymentInfo == null && _selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method to continue'),
          backgroundColor: AppColors.errorMaterialAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate payment details are complete
    if (_selectedPaymentInfo != null) {
      final info = _selectedPaymentInfo!;

      // For card payments
      if (info.type == PaymentSelectionType.card) {
        if (info.isNewCard) {
          // New card must have all details filled
          if (info.cardNumber == null ||
              info.expiryMonth == null ||
              info.expiryYear == null ||
              info.cvc == null ||
              info.cardHolderName == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill in all card details'),
                backgroundColor: AppColors.errorMaterialAccent,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
        } else {
          // Saved card must be selected
          if (info.savedMethodId == null || info.savedMethodId!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a card'),
                backgroundColor: AppColors.errorMaterialAccent,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
        }
      }

      // For wallet payments
      if (info.type == PaymentSelectionType.wallet) {
        if (info.walletMode == WalletPaymentMode.bank) {
          // Bank account must have routing and account number
          if (info.bankRoutingNumber == null ||
              info.bankRoutingNumber!.isEmpty ||
              info.bankAccountNumber == null ||
              info.bankAccountNumber!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill in bank account details'),
                backgroundColor: AppColors.errorMaterialAccent,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
        } else {
          // Wallet app must be selected
          if (info.walletProvider == null || info.walletProvider!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a wallet app'),
                backgroundColor: AppColors.errorMaterialAccent,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
        }
      }
    }

    // Use PaymentMethodSelector info if available
    if (_selectedPaymentInfo != null) {
      final info = _selectedPaymentInfo!;
      if (info.type == PaymentSelectionType.card) {
        _handleCardPayment();
      } else if (info.type == PaymentSelectionType.wallet) {
        if (info.walletProvider == 'apple_pay') {
          _handleApplePayPayment();
        } else if (info.walletProvider == 'google_pay') {
          _handleGooglePayPayment();
        } else if (info.bankRoutingNumber != null &&
            info.bankRoutingNumber!.isNotEmpty) {
          // Bank (ACH) payment
          _processPayment();
        } else {
          // Other wallet apps (PayPal, Venmo, Cash App, Zelle)
          _processPayment();
        }
      } else if (info.type == PaymentSelectionType.installment) {
        _handleInstallmentPayment();
      }
      return;
    }

    // Fallback to legacy payment method handling
    if (_selectedPaymentMethod == 'apple_pay') {
      _handleApplePayPayment();
    } else if (_selectedPaymentMethod == 'google_pay') {
      _handleGooglePayPayment();
    } else if (_selectedPaymentMethod == 'installment') {
      _handleInstallmentPayment();
    } else if (_selectedPaymentMethod == 'credit_card' ||
        _selectedPaymentMethod.startsWith('card_')) {
      // Validate card details before processing
      if (_isCardExpired || !_isCardDetailsValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide valid card details.'),
            backgroundColor: AppColors.errorMaterialAccent,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      _handleCardPayment();
    } else {
      // Handle other payment methods
      _processPayment();
    }
  }

  bool _isPaymentDetailsComplete() {
    if (_selectedPaymentInfo == null && _selectedPaymentMethod.isEmpty) {
      return false;
    }

    if (_selectedPaymentInfo != null) {
      final info = _selectedPaymentInfo!;

      // For card payments
      if (info.type == PaymentSelectionType.card) {
        if (info.isNewCard) {
          // New card must have all details
          return info.cardNumber != null &&
              info.expiryMonth != null &&
              info.expiryYear != null &&
              info.cvc != null &&
              info.cardHolderName != null;
        } else {
          // Saved card must be selected
          return info.savedMethodId != null && info.savedMethodId!.isNotEmpty;
        }
      }

      // For wallet payments
      if (info.type == PaymentSelectionType.wallet) {
        if (info.walletMode == WalletPaymentMode.bank) {
          // Bank account must have routing and account number
          return info.bankRoutingNumber != null &&
              info.bankRoutingNumber!.isNotEmpty &&
              info.bankAccountNumber != null &&
              info.bankAccountNumber!.isNotEmpty;
        } else {
          // Wallet app must be selected
          return info.walletProvider != null && info.walletProvider!.isNotEmpty;
        }
      }

      // For installment payments
      if (info.type == PaymentSelectionType.installment) {
        return info.installmentMonths != null;
      }
    }

    return false;
  }

  void _handleApplePayPayment() {
    // Show Apple Pay mock dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apple_outlined, size: 48, color: _headerColor),
            const SizedBox(height: 16),
            Text(
              'Apple Pay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete payment using your Apple Pay account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Amount: \$${((widget.product['discountPrice'] as int) * widget.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processApplePayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Pay with Apple Pay',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.gray300),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processApplePayment() {
    setState(() => _isProcessingPayment = true);

    // Simulate Apple Pay processing (3 seconds)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        // Simulate random success/failure for demo
        const isSuccess = true; // In real app, would depend on actual payment

        if (isSuccess) {
          _completeOrderWithApplePay();
        }
      }
    });
  }

  void _completeOrderWithApplePay() {
    final savedAddress = _savedAddresses[_selectedAddressIndex];
    // Convert saved address format to confirmation screen format
    final selectedAddress = <String, String>{
      'fullName': savedAddress['name'] ?? '',
      'phone': savedAddress['phone'] ?? '',
      'street': savedAddress['address'] ?? '',
      'city': '',
      'state': '',
      'zip': '',
      'email': '',
    };
    final trackingId =
        'HQ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expectedDelivery = DateTime.now().add(const Duration(days: 6));

    final price = (widget.product['discountPrice'] as int) * widget.quantity;
    final subtotal = price.toDouble();
    final tradeInTotal = (widget.tradeInValue * widget.quantity).toDouble();
    final tax = (subtotal * 0.08).toDouble();
    final totalAmount = subtotal - tradeInTotal + tax;

    final confirmationData = {
      'product': widget.product,
      'quantity': widget.quantity,
      'tradeInValue': widget.tradeInValue,
      'address': selectedAddress,
      'paymentMethod': 'apple_pay',
      'trackingId': trackingId,
      'expectedDelivery': expectedDelivery.toIso8601String(),
      'subtotal': subtotal,
      'tradeInTotal': tradeInTotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'fromUpgradeFlow': true,
      'asset': widget.asset,
    };

    if (mounted) {
      context.push('/checkout-confirmation', extra: confirmationData);
    }
  }

  void _handleGooglePayPayment() {
    // Show Google Pay mock dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment_outlined, size: 48, color: _headerColor),
            const SizedBox(height: 16),
            Text(
              'Google Pay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete payment using your Google Pay account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Product:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                      Text(
                        widget.product['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                      Text(
                        '\$${((widget.product['discountPrice'] as int) * widget.quantity).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _headerColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processGooglePayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Pay with Google Pay',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.gray300),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processGooglePayment() {
    setState(() => _isProcessingPayment = true);

    // Simulate Google Pay processing (3 seconds)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        // Simulate success for demo
        _completeOrderWithGooglePay();
      }
    });
  }

  void _completeOrderWithGooglePay() {
    final savedAddress = _savedAddresses[_selectedAddressIndex];
    // Convert saved address format to confirmation screen format
    final selectedAddress = <String, String>{
      'fullName': savedAddress['name'] ?? '',
      'phone': savedAddress['phone'] ?? '',
      'street': savedAddress['address'] ?? '',
      'city': '',
      'state': '',
      'zip': '',
      'email': '',
    };
    final trackingId =
        'HQ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expectedDelivery = DateTime.now().add(const Duration(days: 6));

    final price = (widget.product['discountPrice'] as int) * widget.quantity;
    final subtotal = price.toDouble();
    final tradeInTotal = (widget.tradeInValue * widget.quantity).toDouble();
    final tax = (subtotal * 0.08).toDouble();
    final totalAmount = subtotal - tradeInTotal + tax;

    final confirmationData = {
      'product': widget.product,
      'quantity': widget.quantity,
      'tradeInValue': widget.tradeInValue,
      'address': selectedAddress,
      'paymentMethod': 'google_pay',
      'trackingId': trackingId,
      'expectedDelivery': expectedDelivery.toIso8601String(),
      'subtotal': subtotal,
      'tradeInTotal': tradeInTotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'fromUpgradeFlow': true,
      'asset': widget.asset,
    };

    if (mounted) {
      context.push('/checkout-confirmation', extra: confirmationData);
    }
  }

  void _handleCardPayment() {
    setState(() => _isProcessingPayment = true);

    // Simulate card payment processing (2 seconds)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        // Simulate success for demo
        _completeOrderWithCard();
      }
    });
  }

  void _completeOrderWithCard() {
    final savedAddress = _savedAddresses[_selectedAddressIndex];
    // Convert saved address format to confirmation screen format
    final selectedAddress = <String, String>{
      'fullName': savedAddress['name'] ?? '',
      'phone': savedAddress['phone'] ?? '',
      'street': savedAddress['address'] ?? '',
      'city': '',
      'state': '',
      'zip': '',
      'email': '',
    };
    final trackingId =
        'HQ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expectedDelivery = DateTime.now().add(const Duration(days: 6));

    final price = (widget.product['discountPrice'] as int) * widget.quantity;
    final subtotal = price.toDouble();
    final tradeInTotal = (widget.tradeInValue * widget.quantity).toDouble();
    final tax = (subtotal * 0.08).toDouble();
    final totalAmount = subtotal - tradeInTotal + tax;

    // Get last 4 digits based on selected card
    String cardLastFour = '4242'; // default
    if (_selectedPaymentMethod.startsWith('card_')) {
      // Find the card in saved cards
      final selectedCard = _savedCards.firstWhere(
        (card) => card['id'] == _selectedPaymentMethod,
        orElse: () => {'lastFour': '4242'},
      );
      cardLastFour = selectedCard['lastFour'] as String;
    }

    final confirmationData = {
      'product': widget.product,
      'quantity': widget.quantity,
      'tradeInValue': widget.tradeInValue,
      'address': selectedAddress,
      'paymentMethod': 'credit_card',
      'cardLastFour': cardLastFour,
      'cardholderName': _cardholderNameController.text,
      'trackingId': trackingId,
      'expectedDelivery': expectedDelivery.toIso8601String(),
      'subtotal': subtotal,
      'tradeInTotal': tradeInTotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'fromUpgradeFlow': true,
      'asset': widget.asset,
    };

    if (mounted) {
      context.push('/checkout-confirmation', extra: confirmationData);
    }
  }

  void _handleInstallmentPayment() {
    if (_selectedInstallmentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an installment plan first.'),
          backgroundColor: AppColors.errorMaterialAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    // Simulate installment payment processing (2 seconds)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        // Simulate success for demo (90% success rate)
        final isSuccess = DateTime.now().millisecond % 10 != 0;

        if (isSuccess) {
          _completeOrderWithInstallment();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Installment payment failed. Please try again or choose another payment method.',
              ),
              backgroundColor: AppColors.errorMaterialAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  void _completeOrderWithInstallment() {
    final savedAddress = _savedAddresses[_selectedAddressIndex];
    // Convert saved address format to confirmation screen format
    final selectedAddress = <String, String>{
      'fullName': savedAddress['name'] ?? '',
      'phone': savedAddress['phone'] ?? '',
      'street': savedAddress['address'] ?? '',
      'city': '',
      'state': '',
      'zip': '',
      'email': '',
    };
    final trackingId =
        'HQ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expectedDelivery = DateTime.now().add(const Duration(days: 6));

    final price = (widget.product['discountPrice'] as int) * widget.quantity;
    final subtotal = price.toDouble();
    final tradeInTotal = (widget.tradeInValue * widget.quantity).toDouble();
    final tax = (subtotal * 0.08).toDouble();
    final totalAmount = subtotal - tradeInTotal + tax;

    final confirmationData = {
      'product': widget.product,
      'quantity': widget.quantity,
      'tradeInValue': widget.tradeInValue,
      'address': selectedAddress,
      'paymentMethod': 'installment',
      'installmentPlan': _selectedInstallmentPlan,
      'trackingId': trackingId,
      'expectedDelivery': expectedDelivery.toIso8601String(),
      'subtotal': subtotal,
      'tradeInTotal': tradeInTotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'fromUpgradeFlow': true,
      'asset': widget.asset,
    };

    if (mounted) {
      context.push('/checkout-confirmation', extra: confirmationData);
    }
  }

  void _validateCardExpiry(String value) {
    setState(() {
      if (value.isEmpty) {
        _isCardExpired = true;
        _isCardDetailsValid = false;
        return;
      }

      // Parse MM/YY format
      final parts = value.split('/');
      if (parts.length != 2) {
        _isCardExpired = true;
        _isCardDetailsValid = false;
        return;
      }

      final month = int.tryParse(parts[0]);
      final year = int.tryParse(parts[1]);

      if (month == null || year == null || month < 1 || month > 12) {
        _isCardExpired = true;
        _isCardDetailsValid = false;
        return;
      }

      // Convert YY to YYYY
      final fullYear = 2000 + year;
      final expiryDate = DateTime(fullYear, month);
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      _isCardExpired = expiryDate.isBefore(currentMonth);
      _isCardDetailsValid =
          !_isCardExpired && _cardCvvController.text.length >= 3;
    });
  }

  void _validateCardCvv(String value) {
    setState(() {
      _isCardDetailsValid = value.length >= 3 && !_isCardExpired;
    });
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      // All fields are valid - process payment
      setState(() => _isProcessingPayment = true);

      // Simulate payment processing
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _completeOrder();
        }
      });
    }
  }

  void _completeOrder() {
    final address = <String, String>{
      'fullName': _fullNameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'street': _streetController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zip': _zipController.text,
    };

    final trackingId =
        'HQ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expectedDelivery = DateTime.now().add(const Duration(days: 6));

    final price = (widget.product['discountPrice'] as int) * widget.quantity;
    final subtotal = price.toDouble();
    final tradeInTotal = (widget.tradeInValue * widget.quantity).toDouble();
    final tax = (subtotal * 0.08).toDouble();
    final totalAmount = subtotal - tradeInTotal + tax;

    final confirmationData = {
      'product': widget.product,
      'quantity': widget.quantity,
      'tradeInValue': widget.tradeInValue,
      'address': address,
      'trackingId': trackingId,
      'expectedDelivery': expectedDelivery.toIso8601String(),
      'subtotal': subtotal,
      'tradeInTotal': tradeInTotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'fromUpgradeFlow': true,
      'asset': widget.asset,
    };

    if (mounted) {
      setState(() => _isProcessingPayment = false);
      context.push('/checkout-confirmation', extra: confirmationData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: responsive.padding(horizontal: 20, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Order Summary
                        Container(
                          padding: responsive.padding(all: 16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(12.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowMedium,
                                blurRadius: responsive.spacing(10.0),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORDER SUMMARY',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(11.0),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              responsive.heightBox(12.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.product['name'] as String,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13.0),
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'x${widget.quantity}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(13.0),
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              responsive.heightBox(12.0),
                              const Divider(height: 1),
                              responsive.heightBox(12.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '\$${((widget.product['discountPrice'] as int) * widget.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.tradeInValue > 0) ...[
                                responsive.heightBox(8.0),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Trade-in Credit',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13.0),
                                        color: _textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '-\$${(widget.tradeInValue * widget.quantity).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13.0),
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        responsive.heightBox(24.0),

                        // ========== DELIVERY ADDRESS SECTION ==========
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: responsive.fontSize(16.0),
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showAddressSelectionSheet(
                                context,
                                responsive,
                              ),
                              icon: Icon(
                                Icons.edit_outlined,
                                size: responsive.iconSize(16.0),
                                color: _headerColor,
                              ),
                              label: Text(
                                'Edit address',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  fontWeight: FontWeight.w600,
                                  color: _headerColor,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: responsive.padding(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        responsive.heightBox(12.0),

                        // Address Display Card
                        Container(
                          padding: responsive.padding(all: 16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(12.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowMedium,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _savedAddresses[_selectedAddressIndex]['name']!,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(15.0),
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              responsive.heightBox(8.0),
                              Text(
                                _savedAddresses[_selectedAddressIndex]['address']!,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14.0),
                                  color: _textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              responsive.heightBox(8.0),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: responsive.iconSize(16.0),
                                    color: _textSecondary,
                                  ),
                                  responsive.widthBox(6.0),
                                  Text(
                                    (_savedAddresses[_selectedAddressIndex]['cellPhone'] ??
                                            _savedAddresses[_selectedAddressIndex]['phone'] ??
                                            'N/A')
                                        .toString(),
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        responsive.heightBox(24.0),

                        // ========== PAYMENT METHOD SECTION ==========
                        // Using PaymentMethodSelector for consistent UI across all payment screens
                        PaymentMethodSelector(
                          totalAmount:
                              ((widget.product['discountPrice'] as int) *
                                      widget.quantity)
                                  .toDouble(),
                          onPaymentInfoChanged: (paymentInfo) {
                            setState(() {
                              _selectedPaymentInfo = paymentInfo;
                              // Map to old payment method string for backward compatibility
                              if (paymentInfo.type ==
                                  PaymentSelectionType.card) {
                                _selectedPaymentMethod =
                                    paymentInfo.savedMethodId ?? 'credit_card';
                                _isCardDetailsValid =
                                    paymentInfo.cardNumber != null;
                              } else if (paymentInfo.type ==
                                  PaymentSelectionType.wallet) {
                                _selectedPaymentMethod =
                                    paymentInfo.walletProvider ?? 'wallet';
                              } else if (paymentInfo.type ==
                                  PaymentSelectionType.installment) {
                                _selectedPaymentMethod = 'installment';
                                if (paymentInfo.installmentMonths != null) {
                                  final productPrice =
                                      (widget.product['discountPrice'] as int) *
                                      widget.quantity;
                                  final monthlyAmount =
                                      productPrice /
                                      paymentInfo.installmentMonths!;
                                  _selectedInstallmentPlan = {
                                    'months': paymentInfo.installmentMonths,
                                    'monthlyAmount': monthlyAmount,
                                    'totalAmount': productPrice.toDouble(),
                                  };
                                }
                              }
                            });
                          },
                        ),
                        responsive.heightBox(120.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating CTA Button
          Positioned(
            bottom: 24.0,
            right: 20.0,
            left: 20.0,
            child: SizedBox(
              width: double.infinity,
              height: responsive.buttonHeight(52.0),
              child: ElevatedButton(
                onPressed: !_isPaymentDetailsComplete() || _isProcessingPayment
                    ? null
                    : _handleConfirmAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerColor,
                  disabledBackgroundColor: AppColors.gray300,
                  disabledForegroundColor: AppColors.gray500,
                  foregroundColor: AppColors.white,
                  elevation: 8,
                  shadowColor: AppColors.shadow,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _isProcessingPayment
                        ? 'Processing Payment...'
                        : 'Confirm & Pay',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show Address Selection Bottom Sheet
  void _showAddressSelectionSheet(
    BuildContext context,
    ResponsiveUtils responsive,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsive.borderRadius(20.0)),
            topRight: Radius.circular(responsive.borderRadius(20.0)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: responsive.padding(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: responsive.padding(horizontal: 20, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18.0),
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: _textSecondary,
                      size: responsive.iconSize(24.0),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Address List
            Expanded(
              child: ListView.builder(
                padding: responsive.padding(all: 20),
                itemCount: _savedAddresses.length,
                itemBuilder: (context, index) {
                  final address = _savedAddresses[index];
                  final isSelected = index == _selectedAddressIndex;

                  return Padding(
                    padding: responsive.padding(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAddressIndex = index;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: responsive.padding(all: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowMedium,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: isSelected
                              ? Border.all(color: _headerColor, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        address['name']!,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(15.0),
                                          fontWeight: FontWeight.w700,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        responsive.widthBox(8.0),
                                        Container(
                                          padding: responsive.padding(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _headerColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Selected',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(
                                                11.0,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              color: _headerColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  responsive.heightBox(8.0),
                                  Text(
                                    address['address']!,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      color: _textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  responsive.heightBox(8.0),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: responsive.iconSize(16.0),
                                        color: _textSecondary,
                                      ),
                                      responsive.widthBox(6.0),
                                      Text(
                                        (address['cellPhone'] ??
                                                address['phone'] ??
                                                'N/A')
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(14.0),
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Edit button
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _navigateToAddressForm(
                                      context,
                                      responsive,
                                      existingAddress: address,
                                      index: index,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: _headerColor,
                                    size: responsive.iconSize(20.0),
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                if (isSelected) ...[
                                  responsive.widthBox(12.0),
                                  Icon(
                                    Icons.check_circle,
                                    color: _headerColor,
                                    size: responsive.iconSize(24.0),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Add New Address Button
            Container(
              padding: responsive.padding(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToAddressForm(context, responsive);
                  },
                  icon: Icon(Icons.add, size: responsive.iconSize(20.0)),
                  label: Text(
                    'Add New Address',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerColor,
                    foregroundColor: AppColors.white,
                    padding: responsive.padding(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to Address Form
  void _navigateToAddressForm(
    BuildContext context,
    ResponsiveUtils responsive, {
    Map<String, String>? existingAddress,
    int? index,
  }) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddressFormScreen(existingAddress: existingAddress),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          // Edit existing address
          _savedAddresses[index] = result;
        } else {
          // Add new address
          _savedAddresses.add(result);
          _selectedAddressIndex = _savedAddresses.length - 1;
        }
      });
    }
  }

  // Helper: Build Payment Options
  // ignore: unused_element
  Widget _buildPaymentOptions(ResponsiveUtils responsive) {
    return Column(
      children: [
        // DIGITAL WALLETS SECTION
        _buildPaymentSection(
          responsive: responsive,
          title: null,
          methods: [
            {
              'id': 'apple_pay',
              'label': 'Apple Pay',
              'icon': Icons.apple_outlined,
              'previouslyUsed': true,
            },
            {
              'id': 'google_pay',
              'label': 'Google Pay',
              'icon': Icons.payment_outlined,
              'previouslyUsed': false,
            },
          ],
        ),
        responsive.heightBox(24.0),

        // CREDIT & DEBIT CARDS SECTION
        _buildPaymentSection(
          responsive: responsive,
          title: 'Credit & Debit Cards',
          methods: [
            // Default card
            {
              'id': 'credit_card',
              'label': 'Visa ending in 4242',
              'icon': Icons.credit_card_outlined,
              'previouslyUsed': false,
            },
            // Dynamically added cards
            ..._savedCards.map(
              (card) => {
                'id': card['id'],
                'label': '${card['cardType']} ending in ${card['lastFour']}',
                'icon': Icons.credit_card_outlined,
                'previouslyUsed': false,
                'cardholderName': card['cardholderName'],
                'expiryDate': card['expiryDate'],
              },
            ),
            // Add new card button
            {
              'id': 'debit_card',
              'label': 'Add New Card',
              'icon': Icons.add_outlined,
              'isAddButton': true,
            },
          ],
        ),
        responsive.heightBox(24.0),

        // INSTALLMENTS SECTION
        _buildPaymentSection(
          responsive: responsive,
          title: 'Installments',
          methods: [
            {
              'id': 'installment',
              'label': 'Installment Options',
              'icon': Icons.calendar_month_outlined,
              'isInstallment': true,
            },
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection({
    required ResponsiveUtils responsive,
    required String? title,
    required List<Map<String, dynamic>> methods,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        if (title != null) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              fontWeight: FontWeight.w600,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          responsive.heightBox(12.0),
        ],

        // Payment Method Tiles
        ...methods.map((method) {
          final isAddButton = method['isAddButton'] ?? false;
          final isDisabled = method['isDisabled'] ?? false;
          final isInstallment = method['isInstallment'] ?? false;
          final isSelected =
              _selectedPaymentMethod == method['id'] && !isDisabled;
          final previouslyUsed = method['previouslyUsed'] ?? false;
          final helperText = method['helperText'] as String?;

          if (isAddButton) {
            return Column(
              children: [
                _buildAddMethodTile(responsive, method),
                if (_isAddNewCardExpanded) _buildNewCardForm(responsive),
              ],
            );
          }

          if (isInstallment) {
            return _buildInstallmentTile(responsive, method, isSelected);
          }

          return _buildPaymentMethodTile(
            responsive: responsive,
            method: method,
            isSelected: isSelected,
            isDisabled: isDisabled,
            previouslyUsed: previouslyUsed,
            helperText: helperText,
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required ResponsiveUtils responsive,
    required Map<String, dynamic> method,
    required bool isSelected,
    required bool isDisabled,
    required bool previouslyUsed,
    String? helperText,
  }) {
    final methodId = method['id'] as String;
    final isCard = methodId == 'credit_card' || methodId.startsWith('card_');
    final isExpanded = isCard && _expandedCardId == methodId;

    return Padding(
      padding: responsive.padding(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    setState(() {
                      _selectedPaymentMethod = methodId;
                      if (isCard) {
                        // Toggle expansion
                        _expandedCardId = _expandedCardId == methodId
                            ? null
                            : methodId;
                        // Initialize validation and populate card details when expanded
                        if (_expandedCardId == methodId) {
                          // If it's a dynamically added card, populate its details
                          if (methodId.startsWith('card_')) {
                            _cardholderNameController.text =
                                method['cardholderName'] as String? ?? '';
                            _cardExpiryController.text =
                                method['expiryDate'] as String? ?? '';
                            _cardCvvController
                                .clear(); // CVV always requires re-entry
                          } else {
                            // Default card
                            _cardholderNameController.text = UserService
                                .instance
                                .getUserName();
                            _cardExpiryController.text = '12/25';
                            _cardCvvController.clear();
                          }
                          _validateCardExpiry(_cardExpiryController.text);
                        }
                      } else {
                        _expandedCardId = null;
                      }
                    });
                  },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isSelected
                    ? Border.all(color: _headerColor, width: 2)
                    : null,
              ),
              child: Padding(
                padding: responsive.padding(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          method['icon'] as IconData,
                          size: responsive.iconSize(24.0),
                          color: isDisabled ? AppColors.gray400 : _headerColor,
                        ),
                        responsive.widthBox(12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      method['label'] as String,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(14.0),
                                        fontWeight: FontWeight.w600,
                                        color: isDisabled
                                            ? AppColors.gray500
                                            : _textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (previouslyUsed)
                                    Container(
                                      padding: responsive.padding(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _headerColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusBadge,
                                        ),
                                      ),
                                      child: Text(
                                        'Previously used',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(10.0),
                                          fontWeight: FontWeight.w500,
                                          color: _headerColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (helperText != null) ...[
                                responsive.heightBox(4.0),
                                Text(
                                  helperText,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(12.0),
                                    color: AppColors.gray500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        responsive.widthBox(12.0),
                        if (!isDisabled)
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: responsive.iconSize(24.0),
                            color: isSelected
                                ? _headerColor
                                : AppColors.gray400,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded card details section
          if (isExpanded) _buildCardDetailsSection(responsive),
        ],
      ),
    );
  }

  Widget _buildCardDetailsSection(ResponsiveUtils responsive) {
    return Container(
      margin: responsive.padding(top: 8),
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Number (read-only, masked)
          Text(
            'Card Number',
            style: TextStyle(
              fontSize: responsive.fontSize(12.0),
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          responsive.heightBox(6.0),
          Container(
            padding: responsive.padding(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray100,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  size: responsive.iconSize(18.0),
                  color: _textSecondary,
                ),
                responsive.widthBox(8.0),
                Text(
                  'â€¢â€¢â€¢â€¢ â€¢â€¢â€¢â€¢ â€¢â€¢â€¢â€¢ 4242',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14.0),
                    color: _textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          responsive.heightBox(16.0),

          // Cardholder Name
          Text(
            'Cardholder Name',
            style: TextStyle(
              fontSize: responsive.fontSize(12.0),
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          responsive.heightBox(6.0),
          TextField(
            controller: _cardholderNameController,
            decoration: InputDecoration(
              hintText: 'Enter cardholder name',
              hintStyle: TextStyle(
                fontSize: responsive.fontSize(14.0),
                color: AppColors.gray400,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: _headerColor, width: 2),
              ),
              contentPadding: responsive.padding(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: _textPrimary,
            ),
          ),
          responsive.heightBox(16.0),

          // Expiry Date and CVV
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
                        fontSize: responsive.fontSize(12.0),
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(6.0),
                    TextField(
                      controller: _cardExpiryController,
                      decoration: InputDecoration(
                        hintText: 'MM/YY',
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          color: AppColors.gray400,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(
                            color: _isCardExpired
                                ? AppColors.errorMild
                                : AppColors.gray300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(
                            color: _isCardExpired
                                ? AppColors.errorMild
                                : AppColors.gray300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(
                            color: _isCardExpired
                                ? AppColors.error
                                : _headerColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: responsive.padding(
                          horizontal: 12,
                          vertical: 10,
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
                        ExpiryDateFormatter(),
                      ],
                      onChanged: _validateCardExpiry,
                    ),
                  ],
                ),
              ),
              responsive.widthBox(12.0),
              // CVV
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CVV',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(6.0),
                    TextField(
                      controller: _cardCvvController,
                      decoration: InputDecoration(
                        hintText: 'â€¢â€¢â€¢',
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          color: AppColors.gray400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(color: _headerColor, width: 2),
                        ),
                        contentPadding: responsive.padding(
                          horizontal: 12,
                          vertical: 10,
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
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: _validateCardCvv,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Warning message if card is expired
          if (_isCardExpired) ...[
            responsive.heightBox(12.0),
            Container(
              padding: responsive.padding(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: responsive.iconSize(18.0),
                    color: AppColors.errorDark,
                  ),
                  responsive.widthBox(8.0),
                  Expanded(
                    child: Text(
                      'This card is expired. Please update expiry date.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        color: AppColors.errorDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewCardForm(ResponsiveUtils responsive) {
    return Container(
      margin: responsive.padding(top: 8, bottom: 12),
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Number
          Text(
            'Card Number',
            style: TextStyle(
              fontSize: responsive.fontSize(12.0),
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          responsive.heightBox(6.0),
          TextField(
            controller: _newCardNumberController,
            decoration: InputDecoration(
              hintText: '1234 5678 9012 3456',
              hintStyle: TextStyle(
                fontSize: responsive.fontSize(14.0),
                color: AppColors.gray400,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: _headerColor, width: 2),
              ),
              contentPadding: responsive.padding(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: _textPrimary,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
          ),
          responsive.heightBox(16.0),

          // Cardholder Name
          Text(
            'Cardholder Name',
            style: TextStyle(
              fontSize: responsive.fontSize(12.0),
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          responsive.heightBox(6.0),
          TextField(
            controller: _newCardholderNameController,
            decoration: InputDecoration(
              hintText: 'Enter cardholder name',
              hintStyle: TextStyle(
                fontSize: responsive.fontSize(14.0),
                color: AppColors.gray400,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                borderSide: BorderSide(color: _headerColor, width: 2),
              ),
              contentPadding: responsive.padding(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: _textPrimary,
            ),
          ),
          responsive.heightBox(16.0),

          // Expiry Date and CVV
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
                        fontSize: responsive.fontSize(12.0),
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(6.0),
                    TextField(
                      controller: _newCardExpiryController,
                      decoration: InputDecoration(
                        hintText: 'MM/YY',
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          color: AppColors.gray400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(
                            color: _isNewCardExpired
                                ? AppColors.errorMild
                                : AppColors.gray300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(
                            color: _isNewCardExpired
                                ? AppColors.errorMild
                                : AppColors.gray300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(
                            color: _isNewCardExpired
                                ? AppColors.error
                                : _headerColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: responsive.padding(
                          horizontal: 12,
                          vertical: 10,
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
                        ExpiryDateFormatter(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _isNewCardExpired = false;
                            return;
                          }

                          final parts = value.split('/');
                          if (parts.length != 2) {
                            _isNewCardExpired = true;
                            return;
                          }

                          final month = int.tryParse(parts[0]);
                          final year = int.tryParse(parts[1]);

                          if (month == null || year == null) {
                            _isNewCardExpired = true;
                            return;
                          }

                          if (month < 1 || month > 12) {
                            _isNewCardExpired = true;
                            return;
                          }

                          final now = DateTime.now();
                          final currentYear = now.year % 100;
                          final currentMonth = now.month;

                          if (year < currentYear ||
                              (year == currentYear && month < currentMonth)) {
                            _isNewCardExpired = true;
                            return;
                          }

                          _isNewCardExpired = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              responsive.widthBox(12.0),
              // CVV
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CVV',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(6.0),
                    TextField(
                      controller: _newCardCvvController,
                      decoration: InputDecoration(
                        hintText: 'â€¢â€¢â€¢',
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          color: AppColors.gray400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8.0),
                          ),
                          borderSide: BorderSide(color: _headerColor, width: 2),
                        ),
                        contentPadding: responsive.padding(
                          horizontal: 12,
                          vertical: 10,
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
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Warning message if card is expired
          if (_isNewCardExpired) ...[
            responsive.heightBox(12.0),
            Container(
              padding: responsive.padding(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: responsive.iconSize(18.0),
                    color: AppColors.errorDark,
                  ),
                  responsive.widthBox(8.0),
                  Expanded(
                    child: Text(
                      'This card is expired. Please enter a valid expiry date.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        color: AppColors.errorDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Save Card Button
          responsive.heightBox(16.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isNewCardFormValid()
                  ? () {
                      // Create new card object
                      final newCard = {
                        'id': 'card_${DateTime.now().millisecondsSinceEpoch}',
                        'cardholderName': _newCardholderNameController.text,
                        'expiryDate': _newCardExpiryController.text,
                        'cardNumber': _newCardNumberController.text,
                      };

                      setState(() {
                        _savedCards.add(newCard);
                        // Auto-select the newly added card
                        _selectedPaymentMethod = newCard['id'] as String;
                        _expandedCardId = newCard['id'] as String;
                        // Update card details controllers
                        _cardholderNameController.text =
                            newCard['cardholderName'] as String;
                        _cardExpiryController.text =
                            newCard['expiryDate'] as String;
                        _validateCardExpiry(_cardExpiryController.text);
                        // Collapse add new card form
                        _isAddNewCardExpanded = false;
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _headerColor,
                foregroundColor: Colors.white,
                padding: responsive.padding(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'Save Card',
                style: TextStyle(
                  fontSize: responsive.fontSize(15.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isNewCardFormValid() {
    return _newCardNumberController.text.length == 16 &&
        _newCardholderNameController.text.isNotEmpty &&
        _newCardExpiryController.text.length == 5 &&
        !_isNewCardExpired &&
        _newCardCvvController.text.length >= 3;
  }

  Widget _buildInstallmentTile(
    ResponsiveUtils responsive,
    Map<String, dynamic> method,
    bool isSelected,
  ) {
    return Padding(
      padding: responsive.padding(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _selectedPaymentMethod = method['id'] as String);
              // Show installment options dialog
              _showInstallmentOptions();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isSelected
                    ? Border.all(color: _headerColor, width: 2)
                    : null,
              ),
              child: Padding(
                padding: responsive.padding(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      method['icon'] as IconData,
                      size: responsive.iconSize(24.0),
                      color: _headerColor,
                    ),
                    responsive.widthBox(12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['label'] as String,
                            style: TextStyle(
                              fontSize: responsive.fontSize(14.0),
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          if (isSelected &&
                              _selectedInstallmentPlan != null) ...[
                            responsive.heightBox(4.0),
                            Text(
                              '${_selectedInstallmentPlan!['months']} months Ã— \$${(_selectedInstallmentPlan!['monthlyAmount'] as double).toStringAsFixed(2)}/mo',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12.0),
                                color: _headerColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    responsive.widthBox(12.0),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: responsive.iconSize(24.0),
                      color: isSelected ? _headerColor : AppColors.gray400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Show selected installment plan details below the tile
          if (isSelected && _selectedInstallmentPlan != null)
            _buildSelectedInstallmentDetails(responsive),
        ],
      ),
    );
  }

  Widget _buildSelectedInstallmentDetails(ResponsiveUtils responsive) {
    final plan = _selectedInstallmentPlan!;
    final months = plan['months'] as int;
    final monthlyAmount = plan['monthlyAmount'] as double;
    final totalAmount = plan['totalAmount'] as double;
    final interestRate = plan['interestRate'] as double;
    final description = plan['description'] as String;

    return Container(
      margin: responsive.padding(top: 8),
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Installment Plan',
                style: TextStyle(
                  fontSize: responsive.fontSize(13.0),
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
              TextButton(
                onPressed: _showInstallmentOptions,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13.0),
                    color: _headerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          responsive.heightBox(12.0),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tenure',
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(4.0),
                    Text(
                      '$months months',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(4.0),
                    Text(
                      '\$${monthlyAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        color: _textSecondary,
                      ),
                    ),
                    responsive.heightBox(4.0),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          responsive.heightBox(8.0),
          Container(
            padding: responsive.padding(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: interestRate == 0
                  ? AppColors.successSoft
                  : AppColors.infoBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              border: Border.all(
                color: interestRate == 0
                    ? AppColors.successBorder
                    : AppColors.infoBorder,
              ),
            ),
            child: Text(
              description,
              style: TextStyle(
                fontSize: responsive.fontSize(11.0),
                color: interestRate == 0
                    ? AppColors.successMaterialDark
                    : AppColors.infoDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstallmentOptions() async {
    // Calculate total amount
    final price = (widget.product['discountPrice'] as int) * widget.quantity;
    final subtotal = price.toDouble();
    final tradeInTotal = (widget.tradeInValue * widget.quantity).toDouble();
    final tax = (subtotal * 0.08).toDouble();
    final totalAmount = subtotal - tradeInTotal + tax;

    // Navigate to Installment Options screen
    if (!mounted) return;
    final selectedInstallmentPlan = await context.push(
      '/installment-options?totalAmount=${totalAmount.toStringAsFixed(2)}',
    );

    // If user selected an installment plan, update state
    if (mounted &&
        selectedInstallmentPlan != null &&
        selectedInstallmentPlan is Map<String, dynamic>) {
      setState(() {
        _selectedInstallmentPlan = selectedInstallmentPlan;
      });
    }
  }

  Widget _buildAddMethodTile(
    ResponsiveUtils responsive,
    Map<String, dynamic> method,
  ) {
    return Padding(
      padding: responsive.padding(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isAddNewCardExpanded = !_isAddNewCardExpanded;
            if (_isAddNewCardExpanded) {
              // Collapse any expanded card
              _expandedCardId = null;
              // Clear new card form
              _newCardNumberController.clear();
              _newCardholderNameController.clear();
              _newCardExpiryController.clear();
              _newCardCvvController.clear();
              _isNewCardExpired = false;
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: responsive.padding(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  method['icon'] as IconData,
                  size: responsive.iconSize(24.0),
                  color: _headerColor,
                ),
                responsive.widthBox(12.0),
                Expanded(
                  child: Text(
                    method['label'] as String,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: _headerColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: responsive.iconSize(20.0),
                  color: _headerColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
