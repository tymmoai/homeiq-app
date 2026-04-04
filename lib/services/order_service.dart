import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_strings.dart';
import '../core/utils/logger.dart';
import '../features/shared/models/home_models.dart';
import '../features/shared/models/order_models.dart';
import 'api_client.dart';

/// Centralized Order Service for managing all order types (upgrade + parts).
/// Primary source of truth: backend API (/api/v1/orders).
/// Falls back to SharedPreferences cache when offline.
class OrderService {
  static const String _ordersKey = 'order_history';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Generate a unique order ID
  static String generateOrderId() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 10000;
    return 'HQ-ORD-${now.year}-$random';
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static String? _getHomeId() {
    try {
      return _prefs?.getString('selected_home_id');
    } on Object catch (_) {
      return null;
    }
  }

  /// Parse a backend order JSON into an OrderSummary
  static OrderSummary _fromBackendJson(Map<String, dynamic> json) {
    // Backend uses snake_case enum values (e.g. "out_for_delivery")
    // while the app model uses kebab-case ("out-for-delivery")
    String? statusStr = (json['orderStatus'] as Object?)?.toString();
    if (statusStr != null) {
      statusStr = statusStr.replaceAll('_', '-');
    }

    return OrderSummary(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      homeId: json['homeId'] ?? '',
      orderType: json['orderType'] == 'part'
          ? OrderType.part
          : OrderType.upgrade,
      partCategory: json['partCategory'],
      compatibleWith: json['compatibleWith'],
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'],
      productBrand: json['productBrand'] ?? '',
      productModel: json['productModel'] ?? '',
      orderStatus: OrderSummary.parseOrderStatus(statusStr),
      orderDate: DateTime.tryParse(json['orderDate'] ?? '') ?? DateTime.now(),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'])
          : null,
      actualDelivery: json['actualDelivery'] != null
          ? DateTime.tryParse(json['actualDelivery'])
          : null,
      hasTradeIn: json['hasTradeIn'] ?? false,
      oldAssetId: (json['oldAssetId'] as Object?)?.toString(),
      oldAssetName: json['oldAssetName'],
      tradeInValue: (json['tradeInValue'] as num?)?.toDouble(),
      totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
    );
  }

  // ── Save to backend (with local fallback) ────────────────────────────

  /// Save a product upgrade order
  static Future<void> saveUpgradeOrder({
    required String trackingId,
    required String productName,
    String? productBrand,
    String? productModel,
    String? productId,
    required double totalAmount,
    double subtotal = 0,
    double tax = 0,
    double tradeInTotal = 0,
    int itemCount = 1,
    String? expectedDelivery,
  }) async {
    String? normalizedDelivery = expectedDelivery;
    if (expectedDelivery != null) {
      final parsed = DateTime.tryParse(expectedDelivery);
      if (parsed != null) {
        normalizedDelivery = parsed.toIso8601String();
      }
    }

    final homeId = _getHomeId() ?? '';
    final body = {
      'orderId': trackingId,
      'homeId': homeId,
      'orderType': 'upgrade',
      'productName': productName,
      'productBrand': productBrand ?? 'Unknown',
      'productModel': productModel ?? 'N/A',
      'productId': productId ?? 'N/A',
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'taxAmount': tax,
      'hasTradeIn': tradeInTotal > 0,
      'tradeInValue': tradeInTotal,
      'estimatedDelivery': normalizedDelivery,
    };

    await _createOrderOnBackend(body);
  }

  /// Save a maintenance parts order
  static Future<void> savePartsOrder({
    required String trackingId,
    required List<Map<String, dynamic>> parts,
    required double subtotal,
    required double total,
    required String reminderName,
    String? expectedDelivery,
  }) async {
    String? normalizedDelivery = expectedDelivery;
    if (expectedDelivery != null) {
      final parsed = DateTime.tryParse(expectedDelivery);
      if (parsed != null) {
        normalizedDelivery = parsed.toIso8601String();
      }
    }

    final partNames = parts.map((p) => p['name'] ?? 'Unknown Part').join(', ');
    final firstPart = parts.isNotEmpty ? parts.first : <String, dynamic>{};
    final homeId = _getHomeId() ?? '';

    final body = {
      'orderId': trackingId,
      'homeId': homeId,
      'orderType': 'part',
      'partCategory': 'Maintenance Parts',
      'compatibleWith': reminderName,
      'productName': parts.length == 1
          ? (firstPart['name'] ?? 'Maintenance Part')
          : '${parts.length} Maintenance Parts',
      'productBrand': firstPart['provider'] ?? 'Various',
      'productModel': partNames,
      'productId': firstPart['id'] ?? 'N/A',
      'totalAmount': total,
      'subtotal': subtotal,
      'taxAmount': subtotal * 0.08,
      'hasTradeIn': false,
      'tradeInValue': 0.0,
      'estimatedDelivery': normalizedDelivery,
    };

    await _createOrderOnBackend(body);
  }

  /// Save a protection plan purchase as an order
  static Future<void> saveProtectionPlanOrder({
    required String planName,
    required String assetName,
    required String priceLabel,
    required double totalAmount,
  }) async {
    final homeId = _getHomeId() ?? '';

    final body = {
      'orderId':
          'HQ-PLN-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'homeId': homeId,
      'orderType': 'upgrade',
      'productName': '$planName — $assetName',
      'productBrand': AppStrings.productBrand,
      'productModel': priceLabel,
      'productId': 'plan-${DateTime.now().millisecondsSinceEpoch}',
      'totalAmount': totalAmount,
      'hasTradeIn': false,
      'tradeInValue': 0.0,
    };

    await _createOrderOnBackend(body);
  }

  // ── Backend API calls ────────────────────────────────────────────────

  /// Create order on backend, fall back to local storage if backend is down
  static Future<void> _createOrderOnBackend(Map<String, dynamic> body) async {
    try {
      final api = ApiClient();
      final response = await api.post('/orders', body: body);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        AppLogger.info(
          'OrderService: Order created on backend: ${body['orderId']}',
          tag: 'OrderService',
        );
        // Update local cache
        await _cacheOrder(data['data'] as Map<String, dynamic>);
        return;
      }
    } on Object catch (e) {
      AppLogger.warning(
        'OrderService: Backend create failed, saving locally: $e',
        tag: 'OrderService',
      );
    }
    // Fallback: save to local storage
    await _addOrderLocal({
      ...body,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'orderStatus': 'placed',
      'orderDate': DateTime.now().toIso8601String(),
    });
  }

  /// Cache a backend order in local storage
  static Future<void> _cacheOrder(Map<String, dynamic> order) async {
    try {
      final prefs = await _preferences;
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> orders = jsonDecode(ordersJson) as List<dynamic>;
      final existingIndex = orders.indexWhere(
        (o) => o['orderId'] == order['orderId'] || o['id'] == order['id'],
      );
      if (existingIndex != -1) {
        orders[existingIndex] = order;
      } else {
        orders.insert(0, order);
      }
      await prefs.setString(_ordersKey, jsonEncode(orders));
    } on Object catch (e) {
      AppLogger.warning(
        'OrderService: Cache update failed: $e',
        tag: 'OrderService',
      );
    }
  }

  /// Save order only locally (fallback)
  static Future<void> _addOrderLocal(Map<String, dynamic> order) async {
    try {
      final prefs = await _preferences;
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> orders = jsonDecode(ordersJson) as List<dynamic>;
      final existingIndex = orders.indexWhere(
        (o) => o['orderId'] == order['orderId'],
      );
      if (existingIndex != -1) {
        orders[existingIndex] = order;
      } else {
        orders.insert(0, order);
      }
      await prefs.setString(_ordersKey, jsonEncode(orders));
      AppLogger.info(
        'Order saved locally: ${order['orderId']}',
        tag: 'OrderService',
      );
    } on Object catch (e) {
      AppLogger.error(
        'OrderService: Error saving order locally: $e',
        tag: 'OrderService',
        error: e,
      );
    }
  }

  // ── Read operations ──────────────────────────────────────────────────

  /// Get all orders — backend first, local cache fallback
  static Future<List<OrderSummary>> getOrders() async {
    try {
      final api = ApiClient();
      final homeId = _getHomeId();
      final queryParams = <String, String>{};
      if (homeId != null && homeId.isNotEmpty) {
        queryParams['homeId'] = homeId;
      }
      final response = await api.get('/orders', queryParameters: queryParams);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] is List) {
        final List<dynamic> ordersList = data['data'];
        final results = <OrderSummary>[];
        for (final json in ordersList) {
          try {
            results.add(_fromBackendJson(json as Map<String, dynamic>));
          } on Object catch (e) {
            AppLogger.warning(
              'OrderService: Skipping bad order: $e',
              tag: 'OrderService',
            );
          }
        }
        // Update local cache
        final prefs = await _preferences;
        await prefs.setString(_ordersKey, jsonEncode(ordersList));
        AppLogger.info(
          'OrderService: Loaded ${results.length} orders from backend',
          tag: 'OrderService',
        );
        return results;
      }
    } on Object catch (e) {
      AppLogger.warning(
        'OrderService: Backend fetch failed, using local cache: $e',
        tag: 'OrderService',
      );
    }
    // Fallback to local cache
    return _getOrdersLocal();
  }

  /// Get order by ID — backend first, local cache fallback
  static Future<OrderSummary?> getOrderById(String orderId) async {
    try {
      final api = ApiClient();
      final response = await api.get('/orders/$orderId');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return _fromBackendJson(data['data'] as Map<String, dynamic>);
      }
    } on Object catch (e) {
      AppLogger.warning(
        'OrderService: Backend fetch by ID failed, checking local cache: $e',
        tag: 'OrderService',
      );
    }
    // Fallback to local cache
    final orders = await _getOrdersLocal();
    try {
      return orders.firstWhere((o) => o.orderId == orderId || o.id == orderId);
    } on Object catch (_) {
      return null;
    }
  }

  /// Read orders from local cache only
  static Future<List<OrderSummary>> _getOrdersLocal() async {
    try {
      final prefs = await _preferences;
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> ordersList = jsonDecode(ordersJson) as List<dynamic>;
      final results = <OrderSummary>[];
      for (final json in ordersList) {
        try {
          final map = json as Map<String, dynamic>;
          // Support both backend format and legacy local format
          if (map.containsKey('status') && !map.containsKey('orderStatus')) {
            results.add(_fromBackendJson(map));
          } else {
            results.add(OrderSummary.fromJson(map));
          }
        } on Object catch (e) {
          AppLogger.warning(
            'OrderService: Skipping bad local order: $e',
            tag: 'OrderService',
          );
        }
      }
      return results;
    } on Object catch (e) {
      AppLogger.error(
        'OrderService: Error loading local orders: $e',
        tag: 'OrderService',
        error: e,
      );
      return [];
    }
  }

  /// Clear all orders (for testing)
  static Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_ordersKey);
  }

  /// Get pending deliveries — orders with status shipped or outForDelivery
  static Future<List<PendingDelivery>> getPendingDeliveries({
    String? homeId,
  }) async {
    final orders = await getOrders();
    final pendingStatuses = {OrderStatus.shipped, OrderStatus.outForDelivery};
    return orders
        .where((o) => pendingStatuses.contains(o.orderStatus))
        .where((o) => homeId == null || homeId.isEmpty || o.homeId == homeId)
        .map(
          (o) => PendingDelivery(
            id: o.id,
            homeId: o.homeId,
            orderId: o.orderId,
            productName: o.productName,
            productImage: o.productImage ?? '',
            totalAmount: o.totalAmount,
            status: o.orderStatus.name,
            statusLabel: OrderHelper.getStatusLabel(o.orderStatus),
            statusColor: OrderHelper.getStatusColor(o.orderStatus),
            statusBackgroundColor: OrderHelper.getStatusBackgroundColor(
              o.orderStatus,
            ),
            estimatedDelivery: o.estimatedDelivery,
            isUrgent: o.orderStatus == OrderStatus.outForDelivery,
            isMaintenancePart: o.orderType == OrderType.part,
            forAssetName: o.compatibleWith,
          ),
        )
        .toList();
  }
}