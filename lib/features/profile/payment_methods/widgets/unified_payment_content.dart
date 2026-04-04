import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';
import '../services/payment_service.dart';
import 'payment_card_section.dart';
import 'payment_installment_section.dart';
import 'payment_order_summary.dart';
import 'payment_types.dart';
import 'payment_wallet_section.dart';

export 'payment_types.dart';

/// Reusable payment UI: Order Summary + Saved Payment Methods + Pay button.
/// Matches the Assembly service flow payment screen. Use with flow header in asset tab,
/// or with blue AppBar when used as full screen in service tab.
class UnifiedPaymentContent extends StatefulWidget {
  final double amount;
  final String serviceName;
  final String? bookingId;
  final List<OrderSummaryItem> orderSummaryItems;
  final void Function(PaymentResult? result) onPaymentComplete;

  const UnifiedPaymentContent({
    super.key,
    required this.amount,
    required this.serviceName,
    this.bookingId,
    required this.orderSummaryItems,
    required this.onPaymentComplete,
  });

  @override
  State<UnifiedPaymentContent> createState() => _UnifiedPaymentContentState();
}

class _UnifiedPaymentContentState extends State<UnifiedPaymentContent> {
  final _paymentService = PaymentService();
  
  // Minimum amount required for installment payments ($100)
  static const double _minInstallmentAmount = 100.0;

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showNewCardForm =
      false; // Add new payment method section closed by default
  bool _isCardValid = false;
  bool _isAddingCard = false;

  // Payment type selection - no default, user must select
  PaymentType? _selectedPaymentType;

  // Card payment state
  List<PaymentMethod> _savedMethods = [];
  String? _selectedMethodId;
  String? _cardNumber;
  int? _expiryMonth;
  int? _expiryYear;
  String? _cvc;
  String? _cardHolderName;

  // Digital wallet payment state
  WalletMode _walletMode = WalletMode.bank;
  String _bankRoutingNumber = '';
  String _bankAccountNumber = '';
  String _bankAccountType = 'checking';
  String _walletProvider = '';

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

  String? _bankRoutingError;
  String? _bankAccountError;

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

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    // Validate based on payment type
    if (_selectedPaymentType == PaymentType.wallet) {
      if (_walletMode == WalletMode.bank) {
        if (_bankRoutingNumber.trim().isEmpty) {
          setState(() => _bankRoutingError = 'Please enter your routing number');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter your routing number'),
              backgroundColor: AppColors.primary,
            ),
          );
          return;
        }
        if (!_isValidRoutingNumber(_bankRoutingNumber)) {
          setState(() => _bankRoutingError = 'Enter a valid 9-digit routing number');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enter a valid 9-digit routing number'),
              backgroundColor: AppColors.primary,
            ),
          );
          return;
        }
        if (_bankAccountNumber.trim().isEmpty) {
          setState(() => _bankAccountError = 'Please enter your account number');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter your account number'),
              backgroundColor: AppColors.primary,
            ),
          );
          return;
        }
        if (!_isValidAccountNumber(_bankAccountNumber)) {
          setState(() => _bankAccountError = 'Enter a valid account number (8-17 digits)');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enter a valid account number'),
              backgroundColor: AppColors.primary,
            ),
          );
          return;
        }
        setState(() {
          _bankRoutingError = null;
          _bankAccountError = null;
        });
      }
      if (_walletMode == WalletMode.app && _walletProvider.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a wallet app'),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      }
    }

    if (_selectedPaymentType == PaymentType.card && !_showNewCardForm) {
      if (_selectedMethodId == null || _selectedMethodId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a saved card'),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      }

      final selectedMethod = _savedMethods
          .where((method) => method.id == _selectedMethodId)
          .toList();
      if (selectedMethod.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selected card not found'),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      }

      final expiryValue = _selectedCardExpiry.isNotEmpty
          ? _selectedCardExpiry
          : selectedMethod.first.expiryDate;
      final expiryError = _validateSavedCardExpiry(expiryValue);
      final cvvError = _validateSavedCardCvv(_selectedCardCvv);

      if (expiryError != null || cvvError != null) {
        setState(() {
          _selectedCardExpiryError = expiryError;
          _selectedCardCvvError = cvvError;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(expiryError ?? cvvError!),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      PaymentResult result;

      if (_selectedPaymentType == PaymentType.card) {
        // Card payment logic (existing)
        if (_showNewCardForm && _cardNumber != null) {
          final newMethod = await _paymentService.addPaymentMethod(
            cardNumber: _cardNumber!,
            expiryMonth: _expiryMonth!,
            expiryYear: _expiryYear!,
            cvc: _cvc!,
            cardHolderName: _cardHolderName,
          );

          if (newMethod == null) {
            result = PaymentResult.failed('Failed to add payment method');
          } else {
            final amount = _orderSummaryTotal();
            result = await _paymentService.processPayment(
              amount: amount,
              paymentMethodId: newMethod.id,
              bookingId: widget.bookingId,
              description: 'Payment for ${widget.serviceName}',
            );
          }
        } else {
          final amount = _orderSummaryTotal();
          result = await _paymentService.processPayment(
            amount: amount,
            paymentMethodId: _selectedMethodId,
            bookingId: widget.bookingId,
            description: 'Payment for ${widget.serviceName}',
          );
        }
      } else if (_selectedPaymentType == PaymentType.wallet) {
        // Digital wallet payment - simulate success
        await Future.delayed(const Duration(seconds: 2));
        final mockIntent = PaymentIntent(
          id: 'WALLET-${DateTime.now().millisecondsSinceEpoch}',
          amount: _orderSummaryTotal(),
          currency: 'USD',
          status: PaymentStatus.succeeded,
          createdAt: DateTime.now(),
        );
        result = PaymentResult.succeeded(mockIntent);
      } else {
        // Installment payment - simulate success
        await Future.delayed(const Duration(seconds: 2));
        final mockIntent = PaymentIntent(
          id: 'INSTALLMENT-${DateTime.now().millisecondsSinceEpoch}',
          amount: _orderSummaryTotal(),
          currency: 'USD',
          status: PaymentStatus.succeeded,
          createdAt: DateTime.now(),
        );
        result = PaymentResult.succeeded(mockIntent);
      }

      if (mounted) widget.onPaymentComplete(result);
    } on Object catch (e) {
      if (mounted) widget.onPaymentComplete(PaymentResult.failed(e.toString()));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final responsive = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: responsive.padding(all: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PaymentOrderSummary(
                  orderSummaryItems: widget.orderSummaryItems,
                  total: _orderSummaryTotal(),
                ),
                responsive.heightBox(24.0),
                _buildPaymentMethodSelector(responsive),
                responsive.heightBox(24.0),
              ],
            ),
          ),
        ),
        _buildPayButton(responsive),
      ],
    );
  }

  /// Total from order summary items (accurate); falls back to widget.amount if empty.
  double _orderSummaryTotal() {
    if (widget.orderSummaryItems.isEmpty) return widget.amount;
    return widget.orderSummaryItems.fold(0.0, (sum, i) => sum + i.amount);
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

  Widget _buildPaymentMethodSelector(ResponsiveUtils responsive) {
    return Column(
      children: [
        _buildPaymentMethodAccordion(
          responsive,
          type: PaymentType.card,
          icon: Icons.credit_card,
          title: 'Credit/Debit Card',
          subtitle: 'Pay securely with your card',
          badge: 'Most used',
          badgeColor: AppColors.success,
        ),
        responsive.heightBox(12.0),
        _buildPaymentMethodAccordion(
          responsive,
          type: PaymentType.wallet,
          icon: Icons.account_balance_wallet,
          title: 'Digital Wallet',
          subtitle: 'Pay by bank or with Apple Pay, Venmo & more',
          badge: 'Fast',
          badgeColor: AppColors.purple,
        ),
        responsive.heightBox(12.0),
        _buildPaymentMethodAccordion(
          responsive,
          type: PaymentType.installment,
          icon: Icons.calendar_today,
          title: 'Monthly Installments',
          subtitle: _orderSummaryTotal() >= _minInstallmentAmount
              ? '\$${(_orderSummaryTotal() / _installmentMonths).toStringAsFixed(0)}/month for $_installmentMonths months'
              : 'Available for orders \$${_minInstallmentAmount.toStringAsFixed(0)}+',
          badge: _orderSummaryTotal() >= _minInstallmentAmount ? 'Optional' : 'Not Available',
          badgeColor: _orderSummaryTotal() >= _minInstallmentAmount ? AppColors.warningOrange : AppColors.gray400,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodAccordion(
    ResponsiveUtils responsive, {
    required PaymentType type,
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
    required PaymentType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _selectedPaymentType == type;
    final isInstallmentDisabled = type == PaymentType.installment && _orderSummaryTotal() < _minInstallmentAmount;

    return GestureDetector(
      onTap: isInstallmentDisabled ? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installment plans are available for orders \$${_minInstallmentAmount.toStringAsFixed(0)} or more'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      } : () {
        setState(() {
          _selectedPaymentType = type;
          if (type == PaymentType.card) {
            _showNewCardForm = false;
          }
        });
      },
      child: Opacity(
        opacity: isInstallmentDisabled ? 0.5 : 1.0,
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
      ),
    );
  }

  Widget _buildPaymentMethodContent(
    ResponsiveUtils responsive,
    PaymentType type,
  ) {
    switch (type) {
      case PaymentType.card:
        return PaymentCardSection(
          savedMethods: _savedMethods,
          selectedMethodId: _selectedMethodId,
          showNewCardForm: _showNewCardForm,
          isCardValid: _isCardValid,
          isProcessing: _isProcessing,
          isAddingCard: _isAddingCard,
          selectedCardExpiryError: _selectedCardExpiryError,
          selectedCardCvvError: _selectedCardCvvError,
          selectedExpiryController: _selectedExpiryController,
          selectedCvvController: _selectedCvvController,
          onMethodSelected: (method) {
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
            });
          },
          onToggleNewCardForm: () {
            setState(() {
              _showNewCardForm = !_showNewCardForm;
              if (_showNewCardForm) _selectedMethodId = null;
            });
          },
          onExpiryChanged: (value) {
            setState(() {
              _selectedCardExpiry = value;
              _selectedCardExpiryError = _validateSavedCardExpiry(value);
            });
          },
          onCvvChanged: (value) {
            setState(() {
              _selectedCardCvv = value;
              _selectedCardCvvError = _validateSavedCardCvv(value);
            });
          },
          onCardComplete:
              (cardNumber, expiryMonth, expiryYear, cvc, cardHolderName) {
                _cardNumber = cardNumber;
                _expiryMonth = expiryMonth;
                _expiryYear = expiryYear;
                _cvc = cvc;
                _cardHolderName = cardHolderName;
              },
          onValidationChanged: (isValid) {
            setState(() => _isCardValid = isValid);
          },
          onSaveNewCard: _saveNewCard,
        );
      case PaymentType.wallet:
        return PaymentWalletSection(
          walletMode: _walletMode,
          bankAccountType: _bankAccountType,
          walletProvider: _walletProvider,
          bankRoutingError: _bankRoutingError,
          bankAccountError: _bankAccountError,
          onWalletModeChanged: (mode) {
            setState(() {
              _walletMode = mode;
              if (mode == WalletMode.bank) {
                _walletProvider = '';
              } else {
                _bankRoutingNumber = '';
                _bankAccountNumber = '';
              }
            });
          },
          onBankAccountTypeChanged: (value) {
            setState(() => _bankAccountType = value);
          },
          onBankRoutingChanged: (value) {
            setState(() {
              _bankRoutingNumber = value;
              _bankRoutingError = null;
            });
          },
          onBankAccountChanged: (value) {
            setState(() {
              _bankAccountNumber = value;
              _bankAccountError = null;
            });
          },
          onWalletProviderChanged: (value) {
            setState(() => _walletProvider = value);
          },
        );
      case PaymentType.installment:
        return PaymentInstallmentSection(
          total: _orderSummaryTotal(),
          installmentMonths: _installmentMonths,
          onInstallmentMonthsChanged: (value) {
            setState(() => _installmentMonths = value);
          },
        );
    }
  }

  Future<void> _saveNewCard() async {
    if (!_isCardValid || _cardNumber == null || _isAddingCard) return;

    setState(() {
      _isProcessing = true;
      _isAddingCard = true;
    });

    try {
      final newMethod = await _paymentService.addPaymentMethod(
        cardNumber: _cardNumber!,
        expiryMonth: _expiryMonth!,
        expiryYear: _expiryYear!,
        cvc: _cvc!,
        cardHolderName: _cardHolderName,
      );

      if (newMethod != null && mounted) {
        setState(() {
          // Add only once - avoid duplicate if already in list
          if (!_savedMethods.any((m) => m.id == newMethod.id)) {
            _savedMethods.add(newMethod);
          }
          _selectedMethodId = newMethod.id;
          _showNewCardForm = false;
          _isCardValid = false;
          _cardNumber = null;
          _expiryMonth = null;
          _expiryYear = null;
          _cvc = null;
          _cardHolderName = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Card saved successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save card: $e'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isAddingCard = false;
        });
      }
    }
  }

  /// Check if all payment details are complete and valid
  bool _isPaymentDetailsComplete() {
    if (_selectedPaymentType == null) {
      return false;
    }
    
    switch (_selectedPaymentType!) {
      case PaymentType.card:
        if (_showNewCardForm) {
          // New card must have all details filled and be valid
          return _isCardValid && 
                 _cardNumber != null && 
                 _expiryMonth != null && 
                 _expiryYear != null && 
                 _cvc != null && 
                 _cardHolderName != null;
        } else {
          // Saved card must be selected
          return _selectedMethodId != null && _selectedMethodId!.isNotEmpty;
        }
      
      case PaymentType.wallet:
        if (_walletMode == WalletMode.bank) {
          // Bank account must have routing and account number
          return _bankRoutingNumber.trim().length == 9 && 
                 _bankAccountNumber.trim().length >= 8;
        } else {
          // Wallet app must be selected
          return _walletProvider.isNotEmpty;
        }
      
      case PaymentType.installment:
        // Installments are valid if duration is selected (always true when type selected)
        return true;
    }
  }

  Widget _buildPayButton(ResponsiveUtils responsive) {
    bool canPay = _isPaymentDetailsComplete();

    return Container(
      padding: responsive.padding(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: responsive.buttonHeight(52.0),
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: AppColors.shadowHeavy,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: ElevatedButton(
              onPressed: canPay && !_isProcessing 
                ? _processPayment 
                : () {
                    // Show specific message based on payment state
                    if (_selectedPaymentType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a payment method to continue'),
                          backgroundColor: AppColors.error,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else if (_selectedPaymentType == PaymentType.card) {
                      if (_showNewCardForm && !_isCardValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all card details'),
                            backgroundColor: AppColors.error,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else if (!_showNewCardForm && (_selectedMethodId == null || _selectedMethodId!.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a card'),
                            backgroundColor: AppColors.error,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } else if (_selectedPaymentType == PaymentType.wallet) {
                      if (_walletMode == WalletMode.bank) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in bank account details'),
                            backgroundColor: AppColors.error,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a wallet app'),
                            backgroundColor: AppColors.error,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.4,
                ),
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: responsive.spacing(24.0),
                      height: responsive.spacing(24.0),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      'Pay \$${_orderSummaryTotal().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}