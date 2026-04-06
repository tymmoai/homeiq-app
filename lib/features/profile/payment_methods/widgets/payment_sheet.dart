import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../services/payment_service.dart';
import 'payment_card_input.dart';

/// A full-screen payment sheet for processing payments
class PaymentSheet extends StatefulWidget {
  final double amount;
  final String serviceName;
  final String? bookingId;
  final Function(PaymentResult result) onPaymentComplete;
  final VoidCallback onCancel;

  const PaymentSheet({
    super.key,
    required this.amount,
    required this.serviceName,
    this.bookingId,
    required this.onPaymentComplete,
    required this.onCancel,
  });

  /// Show the payment sheet as a modal bottom sheet
  static Future<PaymentResult?> show({
    required BuildContext context,
    required double amount,
    required String serviceName,
    String? bookingId,
  }) async {
    return await showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.transparent,
      builder: (context) => PaymentSheet(
        amount: amount,
        serviceName: serviceName,
        bookingId: bookingId,
        onPaymentComplete: (result) {
          Navigator.of(context).pop(result);
        },
        onCancel: () {
          Navigator.of(context).pop(null);
        },
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final _paymentService = PaymentService();

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showNewCardForm = false;
  bool _isCardValid = false;

  List<PaymentMethod> _savedMethods = [];
  String? _selectedMethodId;

  // Card input values
  String? _cardNumber;
  int? _expiryMonth;
  int? _expiryYear;
  String? _cvc;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _paymentService.getSavedPaymentMethods();
      setState(() {
        _savedMethods = methods;
        _selectedMethodId = methods
            .firstWhere(
              (m) => m.isDefault,
              orElse: () => methods.isNotEmpty
                  ? methods.first
                  : const PaymentMethod(
                      id: '',
                      type: PaymentMethodType.creditCard,
                      last4: '',
                      brand: '',
                      expiryMonth: 0,
                      expiryYear: 0,
                    ),
            )
            .id;
        _showNewCardForm = methods.isEmpty;
        _isLoading = false;
      });
    } on Object catch (_) {
      setState(() {
        _isLoading = false;
        _showNewCardForm = true;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      PaymentResult result;

      if (_showNewCardForm && _cardNumber != null) {
        // Add new card and pay
        final newMethod = await _paymentService.addPaymentMethod(
          cardNumber: _cardNumber!,
          expiryMonth: _expiryMonth!,
          expiryYear: _expiryYear!,
          cvc: _cvc!,
        );

        if (newMethod == null) {
          result = PaymentResult.failed('Failed to add payment method');
        } else {
          result = await _paymentService.processPayment(
            amount: widget.amount,
            paymentMethodId: newMethod.id,
            bookingId: widget.bookingId,
            description: 'Payment for ${widget.serviceName}',
          );
        }
      } else {
        // Pay with saved method
        result = await _paymentService.processPayment(
          amount: widget.amount,
          paymentMethodId: _selectedMethodId,
          bookingId: widget.bookingId,
          description: 'Payment for ${widget.serviceName}',
        );
      }

      widget.onPaymentComplete(result);
    } on Object catch (e) {
      widget.onPaymentComplete(PaymentResult.failed(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(),
                        const SizedBox(height: 24),
                        if (!_showNewCardForm && _savedMethods.isNotEmpty) ...[
                          SavedPaymentMethodSelector(
                            paymentMethods: _savedMethods,
                            selectedMethodId: _selectedMethodId,
                            onMethodSelected: (id) {
                              setState(() {
                                _selectedMethodId = id;
                              });
                            },
                            onAddNewMethod: () {
                              setState(() {
                                _showNewCardForm = true;
                              });
                            },
                          ),
                        ] else ...[
                          if (_savedMethods.isNotEmpty) ...[
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showNewCardForm = false;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Use saved card'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          PaymentCardInput(
                            onCardComplete:
                                (
                                  cardNumber,
                                  expiryMonth,
                                  expiryYear,
                                  cvc,
                                  cardHolderName,
                                ) {
                                  _cardNumber = cardNumber;
                                  _expiryMonth = expiryMonth;
                                  _expiryYear = expiryYear;
                                  _cvc = cvc;
                                },
                            onValidationChanged: (isValid) {
                              setState(() {
                                _isCardValid = isValid;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Your information is encrypted',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            color: AppColors.gray600,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.serviceName,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.bookingId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Booking #${widget.bookingId}',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                _paymentService.formatAmount(widget.amount),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final canPay = _showNewCardForm ? _isCardValid : _selectedMethodId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canPay && !_isProcessing ? _processPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.gray300,
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Pay ${_paymentService.formatAmount(widget.amount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Quick pay button that can be added to confirmation screens
class QuickPayButton extends StatefulWidget {
  final double amount;
  final String serviceName;
  final String? bookingId;
  final Function(PaymentResult result)? onPaymentComplete;

  const QuickPayButton({
    super.key,
    required this.amount,
    required this.serviceName,
    this.bookingId,
    this.onPaymentComplete,
  });

  @override
  State<QuickPayButton> createState() => _QuickPayButtonState();
}

class _QuickPayButtonState extends State<QuickPayButton> {
  bool _isPaid = false;

  Future<void> _handlePayment() async {
    if (_isPaid) return;

    final result = await PaymentSheet.show(
      context: context,
      amount: widget.amount,
      serviceName: widget.serviceName,
      bookingId: widget.bookingId,
    );

    if (result != null) {
      widget.onPaymentComplete?.call(result);
      if (result.success) {
        setState(() {
          _isPaid = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPaid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outlined,
              color: AppColors.successDark,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Payment Successful',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.successDark,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Pay Now \$${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
