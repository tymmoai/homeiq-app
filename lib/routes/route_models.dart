/// Typed route parameter models for type-safe navigation.
///
/// These classes replace raw `Map<String, dynamic>` route arguments
/// with compile-time checked, self-documenting parameter objects.
library;

/// Parameters for the service subcategory screen.
class ServiceSubcategoryParams {
  final String categoryName;
  final List<Map<String, dynamic>> services;

  const ServiceSubcategoryParams({
    required this.categoryName,
    required this.services,
  });

  factory ServiceSubcategoryParams.fromMap(Map<String, dynamic> map) {
    return ServiceSubcategoryParams(
      categoryName: map['categoryName'] as String,
      services: (map['services'] as List).cast<Map<String, dynamic>>(),
    );
  }

  Map<String, dynamic> toMap() => {
    'categoryName': categoryName,
    'services': services,
  };
}

/// Parameters for the service booking screen.
class ServiceBookingParams {
  final String categoryName;
  final Map<String, dynamic> service;

  const ServiceBookingParams({
    required this.categoryName,
    required this.service,
  });

  factory ServiceBookingParams.fromMap(Map<String, dynamic> map) {
    return ServiceBookingParams(
      categoryName: map['categoryName'] as String,
      service: map['service'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toMap() => {
    'categoryName': categoryName,
    'service': service,
  };
}

/// Parameters for screens that display a single asset.
class AssetParams {
  final Map<String, dynamic> asset;

  const AssetParams({required this.asset});

  factory AssetParams.fromMap(Map<String, dynamic> map) {
    return AssetParams(asset: map);
  }

  Map<String, dynamic> toMap() => asset;
}

/// Parameters for asset detail screen with optional tab & popup flags.
class AssetDetailParams {
  final Map<String, dynamic> asset;
  final String? initialTab;
  final bool skipPopup;

  const AssetDetailParams({
    required this.asset,
    this.initialTab,
    this.skipPopup = false,
  });

  factory AssetDetailParams.fromExtra(Object? extra) {
    if (extra is Map<String, dynamic>) {
      if (extra.containsKey('asset')) {
        return AssetDetailParams(
          asset: extra['asset'] as Map<String, dynamic>,
          initialTab: extra['initialTab'] as String?,
          skipPopup: extra['skipPopup'] as bool? ?? false,
        );
      }
      return AssetDetailParams(asset: extra);
    }
    throw ArgumentError('Invalid asset detail params');
  }

  Map<String, dynamic> toMap() => {
    'asset': asset,
    'initialTab': initialTab,
    'skipPopup': skipPopup,
  };
}

/// Parameters for the protection plan detail screen.
class ProtectionPlanDetailParams {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final String? billingPeriod;

  const ProtectionPlanDetailParams({
    required this.plan,
    required this.asset,
    this.billingPeriod,
  });

  factory ProtectionPlanDetailParams.fromMap(Map<String, dynamic> map) {
    return ProtectionPlanDetailParams(
      plan: map['plan'] as Map<String, dynamic>,
      asset: map['asset'] as Map<String, dynamic>,
      billingPeriod: map['billingPeriod'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'plan': plan,
    'asset': asset,
    'billingPeriod': billingPeriod,
  };
}

/// Parameters for the deductible selection screen.
class DeductibleSelectionParams {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final String billingPeriod;
  final double basePrice;

  const DeductibleSelectionParams({
    required this.plan,
    required this.asset,
    required this.billingPeriod,
    required this.basePrice,
  });

  factory DeductibleSelectionParams.fromMap(Map<String, dynamic> map) {
    return DeductibleSelectionParams(
      plan: map['plan'] as Map<String, dynamic>,
      asset: map['asset'] as Map<String, dynamic>,
      billingPeriod: map['billingPeriod'] as String,
      basePrice: (map['basePrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'plan': plan,
    'asset': asset,
    'billingPeriod': billingPeriod,
    'basePrice': basePrice,
  };
}

/// Parameters for protection plan checkout/payment/confirmation screens.
class ProtectionPlanCheckoutParams {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final Map<String, dynamic> selectedPaymentOption;

  const ProtectionPlanCheckoutParams({
    required this.plan,
    required this.asset,
    required this.selectedPaymentOption,
  });

  factory ProtectionPlanCheckoutParams.fromMap(Map<String, dynamic> map) {
    return ProtectionPlanCheckoutParams(
      plan: map['plan'] as Map<String, dynamic>,
      asset: map['asset'] as Map<String, dynamic>,
      selectedPaymentOption:
          map['selectedPaymentOption'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toMap() => {
    'plan': plan,
    'asset': asset,
    'selectedPaymentOption': selectedPaymentOption,
  };
}

/// Parameters for the upgrade buy-new screen.
class UpgradeBuyNewParams {
  final Map<String, dynamic> asset;
  final int tradeInValue;

  const UpgradeBuyNewParams({
    required this.asset,
    this.tradeInValue = 0,
  });

  factory UpgradeBuyNewParams.fromMap(Map<String, dynamic> map) {
    return UpgradeBuyNewParams(
      asset: map['asset'] as Map<String, dynamic>,
      tradeInValue: map['tradeInValue'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'asset': asset,
    'tradeInValue': tradeInValue,
  };
}

/// Parameters for the product detail screen.
class ProductDetailParams {
  final Map<String, dynamic> product;
  final int tradeInValue;
  final Map<String, dynamic>? asset;

  const ProductDetailParams({
    required this.product,
    this.tradeInValue = 0,
    this.asset,
  });

  factory ProductDetailParams.fromMap(Map<String, dynamic> map) {
    return ProductDetailParams(
      product: map['product'] as Map<String, dynamic>,
      tradeInValue: map['tradeInValue'] as int? ?? 0,
      asset: map['asset'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'product': product,
    'tradeInValue': tradeInValue,
    'asset': asset,
  };
}

/// Parameters for the checkout address screen.
class CheckoutAddressParams {
  final Map<String, dynamic> product;
  final int tradeInValue;
  final int quantity;
  final Map<String, dynamic>? asset;

  const CheckoutAddressParams({
    required this.product,
    this.tradeInValue = 0,
    this.quantity = 1,
    this.asset,
  });

  factory CheckoutAddressParams.fromMap(Map<String, dynamic> map) {
    return CheckoutAddressParams(
      product: map['product'] as Map<String, dynamic>,
      tradeInValue: map['tradeInValue'] as int? ?? 0,
      quantity: map['quantity'] as int? ?? 1,
      asset: map['asset'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'product': product,
    'tradeInValue': tradeInValue,
    'quantity': quantity,
    'asset': asset,
  };
}

/// Parameters for the checkout payment screen.
class CheckoutPaymentParams {
  final Map<String, dynamic> product;
  final int tradeInValue;
  final int quantity;
  final Map<String, String> address;

  const CheckoutPaymentParams({
    required this.product,
    this.tradeInValue = 0,
    this.quantity = 1,
    this.address = const {},
  });

  factory CheckoutPaymentParams.fromMap(Map<String, dynamic> map) {
    return CheckoutPaymentParams(
      product: map['product'] as Map<String, dynamic>,
      tradeInValue: map['tradeInValue'] as int? ?? 0,
      quantity: map['quantity'] as int? ?? 1,
      address: (map['address'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
    );
  }

  Map<String, dynamic> toMap() => {
    'product': product,
    'tradeInValue': tradeInValue,
    'quantity': quantity,
    'address': address,
  };
}

/// Parameters for the checkout confirmation screen.
class CheckoutConfirmationParams {
  final Map<String, dynamic> product;
  final int quantity;
  final int tradeInValue;
  final double subtotal;
  final double tradeInTotal;
  final double tax;
  final double totalAmount;
  final Map<String, String> address;
  final String trackingId;
  final String expectedDelivery;
  final bool fromUpgradeFlow;
  final Map<String, dynamic>? asset;

  const CheckoutConfirmationParams({
    required this.product,
    this.quantity = 1,
    this.tradeInValue = 0,
    this.subtotal = 0.0,
    this.tradeInTotal = 0.0,
    this.tax = 0.0,
    this.totalAmount = 0.0,
    this.address = const {},
    this.trackingId = '',
    this.expectedDelivery = '',
    this.fromUpgradeFlow = false,
    this.asset,
  });

  factory CheckoutConfirmationParams.fromMap(Map<String, dynamic> map) {
    return CheckoutConfirmationParams(
      product: map['product'] as Map<String, dynamic>,
      quantity: map['quantity'] as int? ?? 1,
      tradeInValue: map['tradeInValue'] as int? ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      tradeInTotal: (map['tradeInTotal'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      address: (map['address'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
      trackingId: map['trackingId'] as String? ?? '',
      expectedDelivery: map['expectedDelivery'] as String? ?? '',
      fromUpgradeFlow: map['fromUpgradeFlow'] as bool? ?? false,
      asset: map['asset'] as Map<String, dynamic>?,
    );
  }

  /// Convert to items list format needed by CheckoutConfirmationScreen.
  List<Map<String, dynamic>> toItemsList() => [
    {'product': product, 'quantity': quantity},
  ];

  Map<String, dynamic> toMap() => {
    'product': product,
    'quantity': quantity,
    'tradeInValue': tradeInValue,
    'subtotal': subtotal,
    'tradeInTotal': tradeInTotal,
    'tax': tax,
    'totalAmount': totalAmount,
    'address': address,
    'trackingId': trackingId,
    'expectedDelivery': expectedDelivery,
    'fromUpgradeFlow': fromUpgradeFlow,
    'asset': asset,
  };
}

/// Parameters for the checkout success screen.
class CheckoutSuccessParams {
  final String trackingId;
  final String expectedDelivery;
  final Map<String, dynamic>? product;
  final int? quantity;
  final double? subtotal;
  final double? tradeInTotal;
  final double? tax;
  final double? totalAmount;
  final Map<String, String>? address;
  final String? paymentMethod;
  final bool fromUpgradeFlow;
  final Map<String, dynamic>? asset;

  const CheckoutSuccessParams({
    this.trackingId = '',
    this.expectedDelivery = '',
    this.product,
    this.quantity,
    this.subtotal,
    this.tradeInTotal,
    this.tax,
    this.totalAmount,
    this.address,
    this.paymentMethod,
    this.fromUpgradeFlow = false,
    this.asset,
  });

  factory CheckoutSuccessParams.fromMap(Map<String, dynamic> map) {
    return CheckoutSuccessParams(
      trackingId: map['trackingId'] as String? ?? '',
      expectedDelivery: map['expectedDelivery'] as String? ?? '',
      product: map['product'] as Map<String, dynamic>?,
      quantity: map['quantity'] as int?,
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      tradeInTotal: (map['tradeInTotal'] as num?)?.toDouble(),
      tax: (map['tax'] as num?)?.toDouble(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble(),
      address:
          (map['address'] as Map<String, dynamic>?)?.cast<String, String>(),
      paymentMethod: map['paymentMethod'] as String?,
      fromUpgradeFlow: map['fromUpgradeFlow'] as bool? ?? false,
      asset: map['asset'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'trackingId': trackingId,
    'expectedDelivery': expectedDelivery,
    'product': product,
    'quantity': quantity,
    'subtotal': subtotal,
    'tradeInTotal': tradeInTotal,
    'tax': tax,
    'totalAmount': totalAmount,
    'address': address,
    'paymentMethod': paymentMethod,
    'fromUpgradeFlow': fromUpgradeFlow,
    'asset': asset,
  };
}

/// Parameters for the AI fix problem screen.
class AiFixProblemParams {
  final Map<String, dynamic> asset;
  final bool fromDiy;
  final Map<String, dynamic>? diyContext;

  const AiFixProblemParams({
    required this.asset,
    this.fromDiy = false,
    this.diyContext,
  });

  factory AiFixProblemParams.fromMap(Map<String, dynamic> map) {
    return AiFixProblemParams(
      asset: map,
      fromDiy: map['fromDiy'] as bool? ?? false,
      diyContext: map['diyContext'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    ...asset,
    'fromDiy': fromDiy,
    'diyContext': diyContext,
  };
}

/// Parameters for the maintenance parts checkout screens.
class MaintenancePartsCheckoutParams {
  final dynamic reminder;
  final List<dynamic> parts;
  final List<bool> selectedParts;
  final int subtotal;
  final Map<String, int> providerTotals;
  final Map<String, String>? address;
  final String? trackingId;
  final String? expectedDelivery;

  const MaintenancePartsCheckoutParams({
    required this.reminder,
    required this.parts,
    required this.selectedParts,
    required this.subtotal,
    required this.providerTotals,
    this.address,
    this.trackingId,
    this.expectedDelivery,
  });

  factory MaintenancePartsCheckoutParams.fromMap(Map<String, dynamic> map) {
    return MaintenancePartsCheckoutParams(
      reminder: map['reminder'],
      parts: map['parts'] as List<dynamic>,
      selectedParts: (map['selectedParts'] as List).cast<bool>(),
      subtotal: map['subtotal'] as int,
      providerTotals: (map['providerTotals'] as Map).cast<String, int>(),
      address: (map['address'] as Map?)?.cast<String, String>(),
      trackingId: map['trackingId'] as String?,
      expectedDelivery: map['expectedDelivery'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'reminder': reminder,
    'parts': parts,
    'selectedParts': selectedParts,
    'subtotal': subtotal,
    'providerTotals': providerTotals,
    if (address != null) 'address': address,
    if (trackingId != null) 'trackingId': trackingId,
    if (expectedDelivery != null) 'expectedDelivery': expectedDelivery,
  };
}

/// Parameters for the lifestyle booking flow.
class LifestyleBookingParams {
  final String? preSelectedService;

  const LifestyleBookingParams({this.preSelectedService});

  factory LifestyleBookingParams.fromMap(Map<String, dynamic> map) {
    return LifestyleBookingParams(
      preSelectedService: map['preSelectedService'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'preSelectedService': preSelectedService,
  };
}

/// Parameters for the buy new asset screen.
class BuyNewAssetParams {
  final Map<String, dynamic> data;

  const BuyNewAssetParams({required this.data});

  factory BuyNewAssetParams.fromMap(Map<String, dynamic> map) {
    return BuyNewAssetParams(data: map);
  }

  Map<String, dynamic> toMap() => data;
}
