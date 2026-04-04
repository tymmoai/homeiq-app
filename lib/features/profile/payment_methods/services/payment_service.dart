import '../../../../core/utils/logger.dart';

/// Payment method types supported by the app
enum PaymentMethodType {
  creditCard,
  debitCard,
  applePay,
  googlePay,
  bankTransfer,
}

/// Payment status after processing
enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  canceled,
  refunded,
}

/// Model representing a saved payment method
class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String last4;
  final String brand; // Visa, Mastercard, Amex, etc.
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  final String? cardholderName;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
    this.cardholderName,
  });

  String get displayName => '$brand •••• $last4';
  String get expiryDate =>
      '${expiryMonth.toString().padLeft(2, '0')}/$expiryYear';
  bool get isExpired {
    final now = DateTime.now();
    return expiryYear < now.year ||
        (expiryYear == now.year && expiryMonth < now.month);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'last4': last4,
    'brand': brand,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'isDefault': isDefault,
    'cardholderName': cardholderName,
  };

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'] as String,
    type: PaymentMethodType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => PaymentMethodType.creditCard,
    ),
    last4: json['last4'] as String,
    brand: json['brand'] as String,
    expiryMonth: json['expiryMonth'] as int,
    expiryYear: json['expiryYear'] as int,
    isDefault: json['isDefault'] as bool? ?? false,
    cardholderName: json['cardholderName'] as String?,
  );
}

/// Model representing a payment intent/transaction
class PaymentIntent {
  final String id;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? paymentMethodId;
  final String? errorMessage;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const PaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentMethodId,
    this.errorMessage,
    required this.createdAt,
    this.metadata,
  });

  bool get isSuccessful => status == PaymentStatus.succeeded;
  bool get isPending =>
      status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get isFailed => status == PaymentStatus.failed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'status': status.name,
    'paymentMethodId': paymentMethodId,
    'errorMessage': errorMessage,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String,
    status: PaymentStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => PaymentStatus.pending,
    ),
    paymentMethodId: json['paymentMethodId'] as String?,
    errorMessage: json['errorMessage'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// Payment result returned after payment processing
class PaymentResult {
  final bool success;
  final PaymentIntent? paymentIntent;
  final String? errorMessage;
  final String? transactionId;

  const PaymentResult({
    required this.success,
    this.paymentIntent,
    this.errorMessage,
    this.transactionId,
  });

  factory PaymentResult.succeeded(PaymentIntent intent) => PaymentResult(
    success: true,
    paymentIntent: intent,
    transactionId: intent.id,
  );

  factory PaymentResult.failed(String error) =>
      PaymentResult(success: false, errorMessage: error);
}

/// Payment Service for handling all payment operations
///
/// This service provides a framework for integrating payment providers
/// like Stripe, Square, or other payment gateways.
///
/// To integrate with Stripe:
/// 1. Add flutter_stripe package to pubspec.yaml
/// 2. Initialize Stripe in main.dart with publishable key
/// 3. Implement the TODO methods below with actual Stripe API calls
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // TODO: Replace with your Stripe publishable key
  static const String _stripePublishableKey = 'pk_test_YOUR_STRIPE_KEY';

  // TODO: Replace with your backend API URL
  static const String _apiBaseUrl = 'https://api.yourdomain.com';

  bool _isInitialized = false;
  List<PaymentMethod> _savedPaymentMethods = [];

  /// Initialize the payment service
  /// Call this in main.dart before runApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (_stripePublishableKey == 'pk_test_YOUR_STRIPE_KEY') {
        AppLogger.warning('Stripe publishable key not configured.', tag: 'PaymentService');
      }
      if (_apiBaseUrl == 'https://api.yourdomain.com') {
        AppLogger.warning('API base URL not configured.', tag: 'PaymentService');
      }
      // TODO: Initialize Stripe
      // Stripe.publishableKey = _stripePublishableKey;
      // await Stripe.instance.applySettings();

      _isInitialized = true;
      AppLogger.info('PaymentService initialized', tag: 'PaymentService');
    } on Object catch (e) {
      AppLogger.error('PaymentService initialization failed: $e', tag: 'PaymentService', error: e);
      rethrow;
    }
  }

  /// Get list of saved payment methods for the current user
  Future<List<PaymentMethod>> getSavedPaymentMethods() async {
    // TODO: Fetch from your backend API
    // This would typically call your backend which then calls Stripe API
    // to list customer's payment methods

    // Mock data for development
    await Future.delayed(const Duration(milliseconds: 500));
    _savedPaymentMethods = [
      const PaymentMethod(
        id: 'pm_mock_1',
        type: PaymentMethodType.creditCard,
        last4: '4242',
        brand: 'Visa',
        expiryMonth: 12,
        expiryYear: 2027,
        isDefault: true,
        cardholderName: 'Card Holder',
      ),
      const PaymentMethod(
        id: 'pm_mock_2',
        type: PaymentMethodType.creditCard,
        last4: '5555',
        brand: 'Mastercard',
        expiryMonth: 6,
        expiryYear: 2026,
        isDefault: false,
        cardholderName: 'Jane Smith',
      ),
    ];

    return _savedPaymentMethods;
  }

  /// Add a new payment method
  /// Returns the created PaymentMethod on success
  Future<PaymentMethod?> addPaymentMethod({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    String? cardHolderName,
    bool setAsDefault = false,
  }) async {
    try {
      // TODO: Implement with Stripe
      // 1. Create a SetupIntent on your backend
      // 2. Confirm the SetupIntent with card details
      // 3. Attach the payment method to customer

      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));

      final newMethod = PaymentMethod(
        id: 'pm_${DateTime.now().millisecondsSinceEpoch}',
        type: PaymentMethodType.creditCard,
        last4: cardNumber.substring(cardNumber.length - 4),
        brand: _detectCardBrand(cardNumber),
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        isDefault: setAsDefault,
        cardholderName: cardHolderName?.isNotEmpty == true ? cardHolderName : null,
      );

      _savedPaymentMethods.add(newMethod);
      return newMethod;
    } on Object catch (e) {
      AppLogger.error('Failed to add payment method: $e', tag: 'PaymentService', error: e);
      return null;
    }
  }

  /// Remove a saved payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      // TODO: Call your backend to detach payment method from customer

      await Future.delayed(const Duration(milliseconds: 500));
      _savedPaymentMethods.removeWhere((pm) => pm.id == paymentMethodId);
      return true;
    } on Object catch (e) {
      AppLogger.error('Failed to remove payment method: $e', tag: 'PaymentService', error: e);
      return false;
    }
  }

  /// Set a payment method as default
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      // TODO: Update default payment method on your backend

      await Future.delayed(const Duration(milliseconds: 300));
      _savedPaymentMethods = _savedPaymentMethods.map((pm) {
        return PaymentMethod(
          id: pm.id,
          type: pm.type,
          last4: pm.last4,
          brand: pm.brand,
          expiryMonth: pm.expiryMonth,
          expiryYear: pm.expiryYear,
          isDefault: pm.id == paymentMethodId,
          cardholderName: pm.cardholderName,
        );
      }).toList();
      return true;
    } on Object catch (e) {
      AppLogger.error('Failed to set default payment method: $e', tag: 'PaymentService', error: e);
      return false;
    }
  }

  /// Create a payment intent for a service booking
  /// This should be called before showing the payment sheet
  Future<PaymentIntent?> createPaymentIntent({
    required double amount,
    required String currency,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // TODO: Call your backend to create a Stripe PaymentIntent
      // Your backend should:
      // 1. Create a PaymentIntent with Stripe API
      // 2. Return the client_secret and intent ID

      await Future.delayed(const Duration(milliseconds: 500));

      return PaymentIntent(
        id: 'pi_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
        status: PaymentStatus.pending,
        paymentMethodId: paymentMethodId,
        createdAt: DateTime.now(),
        metadata: metadata,
      );
    } on Object catch (e) {
      AppLogger.error('Failed to create payment intent: $e', tag: 'PaymentService', error: e);
      return null;
    }
  }

  /// Process a payment for service booking
  ///
  /// [amount] - Amount in dollars (will be converted to cents for Stripe)
  /// [currency] - ISO currency code (default: USD)
  /// [paymentMethodId] - ID of saved payment method, or null to show payment sheet
  /// [bookingId] - Reference ID for the booking
  /// [description] - Payment description for receipt
  Future<PaymentResult> processPayment({
    required double amount,
    String currency = 'USD',
    String? paymentMethodId,
    String? bookingId,
    String? description,
  }) async {
    try {
      // Validate amount
      if (amount <= 0) {
        return PaymentResult.failed('Invalid payment amount');
      }

      // Create payment intent
      final intent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        paymentMethodId: paymentMethodId,
        metadata: {'bookingId': bookingId, 'description': description},
      );

      if (intent == null) {
        return PaymentResult.failed('Failed to create payment intent');
      }

      // TODO: If no payment method provided, show Stripe payment sheet
      // if (paymentMethodId == null) {
      //   await Stripe.instance.initPaymentSheet(
      //     paymentSheetParameters: SetupPaymentSheetParameters(
      //       paymentIntentClientSecret: clientSecret,
      //       merchantDisplayName: AppStrings.appName,
      //       style: ThemeMode.system,
      //     ),
      //   );
      //   await Stripe.instance.presentPaymentSheet();
      // }

      // TODO: Confirm the payment
      // final result = await Stripe.instance.confirmPayment(
      //   paymentIntentClientSecret: clientSecret,
      //   data: PaymentMethodParams.card(...),
      // );

      // Mock successful payment
      await Future.delayed(const Duration(seconds: 2));

      final completedIntent = PaymentIntent(
        id: intent.id,
        amount: amount,
        currency: currency,
        status: PaymentStatus.succeeded,
        paymentMethodId:
            paymentMethodId ?? _savedPaymentMethods.firstOrNull?.id,
        createdAt: intent.createdAt,
        metadata: intent.metadata,
      );

      return PaymentResult.succeeded(completedIntent);
    } on Object catch (e) {
      AppLogger.error('Payment processing failed: $e', tag: 'PaymentService', error: e);
      return PaymentResult.failed('Payment failed: ${e.toString()}');
    }
  }

  /// Refund a payment
  Future<PaymentResult> refundPayment({
    required String paymentIntentId,
    double? amount, // Partial refund amount, null for full refund
    String? reason,
  }) async {
    try {
      // TODO: Call your backend to create a refund with Stripe

      await Future.delayed(const Duration(seconds: 1));

      return PaymentResult(
        success: true,
        transactionId: 're_${DateTime.now().millisecondsSinceEpoch}',
      );
    } on Object catch (e) {
      AppLogger.error('Refund failed: $e', tag: 'PaymentService', error: e);
      return PaymentResult.failed('Refund failed: ${e.toString()}');
    }
  }

  /// Detect card brand from card number
  String _detectCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanNumber.startsWith('4')) {
      return 'Visa';
    } else if (cleanNumber.startsWith('5') ||
        (cleanNumber.startsWith('2') &&
            int.parse(cleanNumber.substring(0, 4)) >= 2221 &&
            int.parse(cleanNumber.substring(0, 4)) <= 2720)) {
      return 'Mastercard';
    } else if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return 'Amex';
    } else if (cleanNumber.startsWith('6011') || cleanNumber.startsWith('65')) {
      return 'Discover';
    }
    return 'Card';
  }

  /// Validate card number: exactly 16 digits (spaces not counted).
  /// Only length is validated so any 16-digit input is accepted.
  bool validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    return cleanNumber.length == 16;
  }

  /// Validate expiry date: month 01-12, year must be greater than 2024.
  bool validateExpiryDate(int month, int year) {
    if (month < 1 || month > 12) return false;

    // Convert 2-digit year to 4-digit if needed (e.g. 25 → 2025)
    final fullYear = year < 100 ? 2000 + year : year;

    // Expiry must be in the future; year must be greater than 2024
    if (fullYear <= 2024) return false;

    final now = DateTime.now();
    if (fullYear < now.year) return false;
    if (fullYear == now.year && month < now.month) return false;

    return true;
  }

  /// Validate CVC
  bool validateCvc(String cvc, String cardNumber) {
    final cleanCvc = cvc.replaceAll(RegExp(r'\D'), '');
    final isAmex = cardNumber.startsWith('34') || cardNumber.startsWith('37');

    // Amex has 4-digit CVC, others have 3-digit
    final expectedLength = isAmex ? 4 : 3;
    return cleanCvc.length == expectedLength;
  }

  /// Format card number for display (adds spaces)
  String formatCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }

    return buffer.toString();
  }

  /// Format amount for display with currency symbol
  String formatAmount(double amount, {String currency = 'USD'}) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }
}

