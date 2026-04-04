import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../services/payment_service.dart' show PaymentMethod, PaymentService;
import 'payment_card_input.dart';
import 'payment_expiry_formatter.dart';

/// Payment type enum for selecting payment method
enum PaymentSelectionType { card, wallet, installment }

/// Wallet mode enum for selecting wallet payment mode
enum WalletPaymentMode { bank, app }

/// Data class to hold selected payment details
class SelectedPaymentInfo {
  final PaymentSelectionType? type;
  final String? savedMethodId;
  final bool isNewCard;
  final String? cardNumber;
  final int? expiryMonth;
  final int? expiryYear;
  final String? cvc;
  final String? cardHolderName;
  final WalletPaymentMode? walletMode;
  final String? bankRoutingNumber;
  final String? bankAccountNumber;
  final String? bankAccountType;
  final String? walletProvider;
  final int? installmentMonths;

  const SelectedPaymentInfo({
    this.type,
    this.savedMethodId,
    this.isNewCard = false,
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvc,
    this.cardHolderName,
    this.walletMode,
    this.bankRoutingNumber,
    this.bankAccountNumber,
    this.bankAccountType,
    this.walletProvider,
    this.installmentMonths,
  });
}

/// Reusable payment method selector widget that matches the protection plan payment UI.
/// This widget can be embedded in any payment screen to provide consistent payment method selection.
class PaymentMethodSelector extends StatefulWidget {
  /// Total amount for installment calculation
  final double totalAmount;

  /// Callback when payment info changes
  final ValueChanged<SelectedPaymentInfo>? onPaymentInfoChanged;

  /// Callback when user taps pay button (if showPayButton is true)
  final VoidCallback? onPayPressed;

  /// Whether to show the pay button at the bottom
  final bool showPayButton;

  /// Pay button text
  final String payButtonText;

  /// Whether payment is processing
  final bool isProcessing;

  const PaymentMethodSelector({
    super.key,
    required this.totalAmount,
    this.onPaymentInfoChanged,
    this.onPayPressed,
    this.showPayButton = false,
    this.payButtonText = 'Pay Now',
    this.isProcessing = false,
  });

  @override
  State<PaymentMethodSelector> createState() => PaymentMethodSelectorState();
}

class PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  final _paymentService = PaymentService();

  bool _isLoading = true;
  bool _showNewCardForm = false;
  bool _isCardValid = false;

  // Payment type selection - no default, user must select
  PaymentSelectionType? _selectedPaymentType;

  // Card payment state
  List<PaymentMethod> _savedMethods = [];
  String? _selectedMethodId;
  String? _cardNumber;
  int? _expiryMonth;
  int? _expiryYear;
  String? _cvc;
  String? _cardHolderName;

  // Digital wallet payment state
  WalletPaymentMode _walletMode = WalletPaymentMode.bank;
  String _bankRoutingNumber = '';
  String _bankAccountNumber = '';
  String _bankAccountType = 'checking';

  String _walletProvider = '';
  String? _bankRoutingError;
  String? _bankAccountError;

  // Installment payment state
  int _installmentMonths = 3;

  // Saved card editable details
  String _selectedCardExpiry = '';
  String _selectedCardCvv = '';
  String? _selectedCardExpiryError;
  String? _selectedCardCvvError;

  final TextEditingController _selectedExpiryController =
      TextEditingController();
  final TextEditingController _selectedCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _selectedExpiryController.dispose();
    _selectedCvvController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _paymentService.getSavedPaymentMethods();
      if (!mounted) return;
      setState(() {
        _savedMethods = methods;
        // No default selection - user must explicitly select a payment method
        _selectedMethodId = null;
        _isLoading = false;
      });
    } on Object catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _notifyPaymentInfoChanged() {
    widget.onPaymentInfoChanged?.call(
      SelectedPaymentInfo(
        type: _selectedPaymentType,
        savedMethodId: _selectedMethodId,
        isNewCard: _showNewCardForm,
        cardNumber: _cardNumber,
        expiryMonth: _expiryMonth,
        expiryYear: _expiryYear,
        cvc: _cvc,
        cardHolderName: _cardHolderName,
        walletMode: _walletMode,
        bankRoutingNumber: _bankRoutingNumber,
        bankAccountNumber: _bankAccountNumber,
        bankAccountType: _bankAccountType,
        walletProvider: _walletProvider,
        installmentMonths: _installmentMonths,
      ),
    );
  }

  /// Get current selected payment info
  SelectedPaymentInfo getSelectedPaymentInfo() {
    return SelectedPaymentInfo(
      type: _selectedPaymentType,
      savedMethodId: _selectedMethodId,
      isNewCard: _showNewCardForm,
      cardNumber: _cardNumber,
      expiryMonth: _expiryMonth,
      expiryYear: _expiryYear,
      cvc: _cvc,
      cardHolderName: _cardHolderName,
      walletMode: _walletMode,
      bankRoutingNumber: _bankRoutingNumber,
        bankAccountNumber: _bankAccountNumber,
        bankAccountType: _bankAccountType,
      walletProvider: _walletProvider,
      installmentMonths: _installmentMonths,
    );
  }

  /// Validate the current payment selection
  String? validate() {
    if (_selectedPaymentType == PaymentSelectionType.wallet) {
      if (_walletMode == WalletPaymentMode.bank) {
        if (_bankRoutingNumber.trim().isEmpty) {
          return 'Please enter your routing number';
        }
        if (!_isValidRoutingNumber(_bankRoutingNumber)) {
          return 'Enter a valid 9-digit routing number';
        }
        if (_bankAccountNumber.trim().isEmpty) {
          return 'Please enter your account number';
        }
        if (!_isValidAccountNumber(_bankAccountNumber)) {
          return 'Enter a valid account number (8-17 digits)';
        }
      }
      if (_walletMode == WalletPaymentMode.app && _walletProvider.isEmpty) {
        return 'Please select a wallet app';
      }
    }

    if (_selectedPaymentType == PaymentSelectionType.card &&
        !_showNewCardForm) {
      if (_selectedMethodId == null || _selectedMethodId!.isEmpty) {
        return 'Please select a saved card';
      }

      final selectedMethod = _savedMethods
          .where((method) => method.id == _selectedMethodId)
          .toList();
      if (selectedMethod.isEmpty) {
        return 'Selected card not found';
      }

      final expiryValue = _selectedCardExpiry.isNotEmpty
          ? _selectedCardExpiry
          : selectedMethod.first.expiryDate;
      final expiryError = _validateSavedCardExpiry(expiryValue);
      final cvvError = _validateSavedCardCvv(_selectedCardCvv);

      if (expiryError != null) return expiryError;
      if (cvvError != null) return cvvError;
    }

    if (_selectedPaymentType == PaymentSelectionType.card && _showNewCardForm) {
      if (!_isCardValid) {
        return 'Please enter valid card details';
      }
    }

    return null;
  }

  bool _isValidRoutingNumber(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\D'), '');
    if (trimmed.length != 9) return false;
    // ABA routing number checksum validation
    final digits = trimmed.split('').map(int.parse).toList();
    final checksum = (3 * (digits[0] + digits[3] + digits[6]) +
            7 * (digits[1] + digits[4] + digits[7]) +
            (digits[2] + digits[5] + digits[8])) %
        10;
    return checksum == 0;
  }

  bool _isValidAccountNumber(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\D'), '');
    return trimmed.length >= 8 && trimmed.length <= 17;
  }

  String _formatExpiryShort(int month, int year) {
    final twoDigitYear = (year % 100).toString().padLeft(2, '0');
    return '${month.toString().padLeft(2, '0')}/$twoDigitYear';
  }

  String? _validateSavedCardExpiry(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Expiry is required';

    final parts = trimmed.split('/');
    if (parts.length != 2) return 'Enter expiry as MM/YY';

    final month = int.tryParse(parts[0].trim());
    final yearPart = int.tryParse(parts[1].trim());
    if (month == null || yearPart == null || month < 1 || month > 12) {
      return 'Enter valid expiry';
    }

    if (parts[1].trim().length != 2 && parts[1].trim().length != 4) {
      return 'Enter expiry as MM/YY';
    }

    final year = yearPart < 100 ? 2000 + yearPart : yearPart;
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'Card expiry has passed';
    }

    return null;
  }

  String? _validateSavedCardCvv(String value) {
    final trimmed = value.trim();
    if (trimmed == '***') return null;
    if (trimmed.length != 3 || int.tryParse(trimmed) == null) {
      return 'Enter 3-digit CVV';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final responsive = context.responsive;

    return Column(
      children: [
        _buildPaymentMethodAccordion(
          responsive,
          type: PaymentSelectionType.card,
          icon: Icons.credit_card,
          title: 'Credit/Debit Card',
          subtitle: 'Pay securely with your card',
          badge: 'Most used',
          badgeColor: AppColors.success,
        ),
        responsive.heightBox(12.0),
        _buildPaymentMethodAccordion(
          responsive,
          type: PaymentSelectionType.wallet,
          icon: Icons.account_balance_wallet,
          title: 'Digital Wallet',
          subtitle: 'Pay by bank or with Apple Pay, Venmo & more',
          badge: 'Fast',
          badgeColor: AppColors.purple,
        ),
        responsive.heightBox(12.0),
        _buildPaymentMethodAccordion(
          responsive,
          type: PaymentSelectionType.installment,
          icon: Icons.calendar_today,
          title: 'Monthly Installments',
          subtitle:
              '\$${(widget.totalAmount / _installmentMonths).toStringAsFixed(0)}/month for $_installmentMonths months',
          badge: 'Optional',
          badgeColor: AppColors.warningOrange,
        ),
        if (widget.showPayButton) ...[
          responsive.heightBox(24.0),
          _buildPayButton(responsive),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodAccordion(
    ResponsiveUtils responsive, {
    required PaymentSelectionType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _selectedPaymentType == type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentTypeOption(
          responsive,
          type: type,
          icon: icon,
          title: title,
          subtitle: subtitle,
          badge: badge,
          badgeColor: badgeColor,
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
                  child: _buildPaymentMethodContent(responsive, type),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeOption(
    ResponsiveUtils responsive, {
    required PaymentSelectionType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _selectedPaymentType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentType = type;
          if (type == PaymentSelectionType.card) {
            _showNewCardForm = false;
          }
          _notifyPaymentInfoChanged();
        });
      },
      child: Container(
        padding: responsive.padding(all: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: responsive.spacing(8.0),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: responsive.spacing(20.0),
              height: responsive.spacing(20.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                color: Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: responsive.spacing(8.0),
                        height: responsive.spacing(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            responsive.widthBox(12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: responsive.fontSize(15.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  responsive.heightBox(2.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(8.0),
                vertical: responsive.spacing(4.0),
              ),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12.0),
                ),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: responsive.fontSize(10.0),
                  fontWeight: FontWeight.w600,
                  color: badgeColor.withValues(alpha: 0.9),
                ),
              ),
            ),
            responsive.widthBox(6.0),
            Icon(
              isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodContent(
    ResponsiveUtils responsive,
    PaymentSelectionType type,
  ) {
    switch (type) {
      case PaymentSelectionType.card:
        return _buildCardPaymentSection(responsive);
      case PaymentSelectionType.wallet:
        return _buildWalletPaymentSection(responsive);
      case PaymentSelectionType.installment:
        return _buildEmiPaymentSection(responsive);
    }
  }

  Widget _buildCardPaymentSection(ResponsiveUtils responsive) {
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
          if (_savedMethods.isNotEmpty) ...[
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
            ..._savedMethods.map(
              (method) => Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                child: _buildPaymentMethodItem(responsive, method),
              ),
            ),
            responsive.heightBox(16.0),
          ],
          GestureDetector(
            onTap: () {
              setState(() {
                _showNewCardForm = !_showNewCardForm;
                if (_showNewCardForm) _selectedMethodId = null;
                _notifyPaymentInfoChanged();
              });
            },
            child: Text(
              '+ Add new payment card',
              style: TextStyle(
                fontSize: responsive.fontSize(15.0),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          if (_showNewCardForm) ...[
            responsive.heightBox(16.0),
            _buildNewCardForm(responsive),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    ResponsiveUtils responsive,
    PaymentMethod method,
  ) {
    final isSelected = _selectedMethodId == method.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethodId = method.id;
          _showNewCardForm = false;
          _selectedCardExpiry = _formatExpiryShort(
            method.expiryMonth,
            method.expiryYear,
          );
          _selectedCardCvv = '***';
          _selectedCardExpiryError = null;
          _selectedCardCvvError = null;
          _selectedExpiryController.text = _selectedCardExpiry;
          _selectedCvvController.text = _selectedCardCvv;
          _notifyPaymentInfoChanged();
        });
      },
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
                                          fontSize: responsive.fontSize(11.0),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      responsive.heightBox(6.0),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                            responsive.borderRadius(8.0),
                                          ),
                                          border: Border.all(
                                            color:
                                                _selectedCardExpiryError != null
                                                ? AppColors.error
                                                : AppColors.border,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _selectedExpiryController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                            PaymentExpiryDateFormatter(),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: 'MM/YY',
                                            border: InputBorder.none,
                                            contentPadding: responsive.padding(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(14.0),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCardExpiry = value;
                                              _selectedCardExpiryError = null;
                                            });
                                          },
                                        ),
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
                                          fontSize: responsive.fontSize(11.0),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      responsive.heightBox(6.0),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                            responsive.borderRadius(8.0),
                                          ),
                                          border: Border.all(
                                            color: _selectedCardCvvError != null
                                                ? AppColors.error
                                                : AppColors.border,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _selectedCvvController,
                                          keyboardType: TextInputType.number,
                                          obscureText: true,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(3),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: '***',
                                            border: InputBorder.none,
                                            contentPadding: responsive.padding(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(14.0),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCardCvv = value;
                                              _selectedCardCvvError = null;
                                            });
                                          },
                                        ),
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
    final brandLower = brand.toLowerCase();
    IconData iconData;
    Color iconColor;

    switch (brandLower) {
      case 'visa':
        iconData = Icons.credit_card;
        iconColor = AppColors.info;
        break;
      case 'mastercard':
        iconData = Icons.credit_card;
        iconColor = AppColors.error;
        break;
      case 'amex':
      case 'american express':
        iconData = Icons.credit_card;
        iconColor = AppColors.success;
        break;
      default:
        iconData = Icons.credit_card;
        iconColor = AppColors.textSecondary;
    }

    return Icon(iconData, size: responsive.iconSize(18.0), color: iconColor);
  }

  Widget _buildNewCardForm(ResponsiveUtils responsive) {
    return PaymentCardInput(
      onCardComplete:
          (
            String cardNumber,
            int expiryMonth,
            int expiryYear,
            String cvc,
            String cardHolderName,
          ) {
            setState(() {
              _cardNumber = cardNumber;
              _expiryMonth = expiryMonth;
              _expiryYear = expiryYear;
              _cvc = cvc;
              _cardHolderName = cardHolderName;
              _isCardValid = true;
              _notifyPaymentInfoChanged();
            });
          },
      onValidationChanged: (bool isValid) {
        setState(() {
          _isCardValid = isValid;
          _notifyPaymentInfoChanged();
        });
      },
    );
  }

  Widget _buildWalletPaymentSection(ResponsiveUtils responsive) {
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
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _walletMode = WalletPaymentMode.bank;
                    _walletProvider = '';
                    _notifyPaymentInfoChanged();
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: responsive.spacing(20.0),
                      height: responsive.spacing(20.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _walletMode == WalletPaymentMode.bank
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                        color: Colors.transparent,
                      ),
                      child: _walletMode == WalletPaymentMode.bank
                          ? Center(
                              child: Container(
                                width: responsive.spacing(8.0),
                                height: responsive.spacing(8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    responsive.widthBox(8.0),
                    Text(
                      'Pay by Bank',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              responsive.widthBox(24.0),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _walletMode = WalletPaymentMode.app;
                    _bankRoutingNumber = '';
                    _bankAccountNumber = '';
                    _notifyPaymentInfoChanged();
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: responsive.spacing(20.0),
                      height: responsive.spacing(20.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _walletMode == WalletPaymentMode.app
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                        color: Colors.transparent,
                      ),
                      child: _walletMode == WalletPaymentMode.app
                          ? Center(
                              child: Container(
                                width: responsive.spacing(8.0),
                                height: responsive.spacing(8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    responsive.widthBox(8.0),
                    Text(
                      'Select Wallet App',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          responsive.heightBox(16.0),
          if (_walletMode == WalletPaymentMode.bank) ...[
            // Account Type Toggle
            Row(
              children: [
                _buildAccountTypeChip(responsive, 'Checking', 'checking'),
                responsive.widthBox(12.0),
                _buildAccountTypeChip(responsive, 'Savings', 'savings'),
              ],
            ),
            responsive.heightBox(12.0),
            // Routing Number Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: responsive.spacing(8.0),
                    offset: Offset(0, responsive.spacing(2.0)),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _bankRoutingNumber = value;
                    _bankRoutingError = null;
                    _notifyPaymentInfoChanged();
                  });
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  labelText: 'Routing Number',
                  hintText: '9-digit ABA routing number',
                  errorText: _bankRoutingError,
                  prefixIcon: Icon(
                    Icons.account_balance,
                    color: AppColors.textSecondary,
                    size: responsive.iconSize(20.0),
                  ),
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
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            responsive.heightBox(12.0),
            // Account Number Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: responsive.spacing(8.0),
                    offset: Offset(0, responsive.spacing(2.0)),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _bankAccountNumber = value;
                    _bankAccountError = null;
                    _notifyPaymentInfoChanged();
                  });
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(17),
                ],
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Enter your account number',
                  errorText: _bankAccountError,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                    size: responsive.iconSize(20.0),
                  ),
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
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            responsive.heightBox(8.0),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: responsive.iconSize(14.0), color: AppColors.success),
                responsive.widthBox(6.0),
                Expanded(
                  child: Text(
                    'Your bank details are encrypted and securely processed via ACH.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(11.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Column(
              children: [
                _buildWalletAppButton(responsive, 'Apple Pay', 'applePay'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Google Pay', 'googlePay'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'PayPal', 'paypal'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Venmo', 'venmo'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Cash App', 'cashApp'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Zelle', 'zelle'),
              ],
            ),
          ],
          responsive.heightBox(12.0),
          Container(
            padding: responsive.padding(all: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: responsive.spacing(8.0),
                  offset: Offset(0, responsive.spacing(2.0)),
                ),
              ],
            ),
            child: Text(
              'You will be redirected to your wallet app to complete payment. After approval, you will return here and your order will be placed.',
              style: TextStyle(
                fontSize: responsive.fontSize(11.0),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAppButton(
    ResponsiveUtils responsive,
    String label,
    String value,
  ) {
    final isSelected = _walletProvider == value;
    final iconData = _getWalletAppIcon(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          _walletProvider = value;
          _notifyPaymentInfoChanged();
        });
      },
      child: Container(
        padding: responsive.padding(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(10.0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: responsive.spacing(8.0),
              offset: Offset(0, responsive.spacing(2.0)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: responsive.spacing(20.0),
              height: responsive.spacing(20.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                color: Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: responsive.spacing(8.0),
                        height: responsive.spacing(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            responsive.widthBox(12.0),
            CircleAvatar(
              radius: responsive.spacing(16.0),
              backgroundColor: isSelected
                  ? AppColors.white
                  : AppColors.surfaceLight,
              child: Icon(
                iconData,
                size: responsive.iconSize(16.0),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            responsive.widthBox(12.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: responsive.iconSize(18.0),
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletAppIcon(String value) {
    switch (value) {
      case 'applePay':
        return Icons.apple;
      case 'googlePay':
        return Icons.g_mobiledata;
      case 'paypal':
        return Icons.payments;
      case 'venmo':
        return Icons.account_balance_wallet;
      case 'cashApp':
        return Icons.attach_money;
      case 'zelle':
        return Icons.swap_horiz;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildAccountTypeChip(
    ResponsiveUtils responsive,
    String label,
    String value,
  ) {
    final isSelected = _bankAccountType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bankAccountType = value;
          _notifyPaymentInfoChanged();
        });
      },
      child: Container(
        padding: responsive.padding(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(20.0)),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(13.0),
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmiPaymentSection(ResponsiveUtils responsive) {
    final total = widget.totalAmount;

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
          Text(
            'Installment Duration',
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          responsive.heightBox(12.0),
          Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: responsive.spacing(8.0),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<int>(
              initialValue: _installmentMonths,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              decoration: InputDecoration(
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
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              items: [3, 6, 9, 12].map((months) {
                return DropdownMenuItem(
                  value: months,
                  child: Text(
                    '$months Months - \$${(total / months).toStringAsFixed(0)}/month',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _installmentMonths = value;
                    _notifyPaymentInfoChanged();
                  });
                }
              },
            ),
          ),
          responsive.heightBox(16.0),
          Container(
            padding: responsive.padding(all: 12),
            decoration: BoxDecoration(
              color: AppColors.primary05,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: responsive.iconSize(16.0),
                  color: AppColors.primary,
                ),
                responsive.widthBox(8.0),
                Expanded(
                  child: Text(
                    'or \$${(total / _installmentMonths).toStringAsFixed(0)}/month for $_installmentMonths months',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12.0),
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
    );
  }

  Widget _buildPayButton(ResponsiveUtils responsive) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isProcessing ? null : widget.onPayPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: responsive.padding(vertical: 16),
          elevation: 0,
        ),
        child: widget.isProcessing
            ? SizedBox(
                width: responsive.spacing(20.0),
                height: responsive.spacing(20.0),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                widget.payButtonText,
                style: TextStyle(
                  fontSize: responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}