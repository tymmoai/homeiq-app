// Order Models for SquareTrade App
// These models match the web version order types and structures

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum OrderStatus {
  placed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  installed,
  completed,
  canceled,
}

enum OrderType { upgrade, part }

enum TradeInStatus { pending, scheduled, pickedUp, inspected, credited }

enum TradeInCondition { excellent, good, fair, poor }

class OrderSummary {
  final String id;
  final String orderId; // Display ID like "HQ-ORD-2026-1234"
  final String userId;
  final String homeId;

  // Order Type
  final OrderType orderType;
  final String?
  partCategory; // For parts: 'Filter', 'Motor', 'Compressor', etc.
  final String? compatibleWith; // For parts: which asset it's for

  // Product Info
  final String productId;
  final String productName;
  final String? productImage;
  final String productBrand;
  final String productModel;

  // Order Details
  final OrderStatus orderStatus;
  final DateTime orderDate;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;

  // Trade-In Details (if applicable)
  final bool hasTradeIn;
  final String? oldAssetId;
  final String? oldAssetName;
  final double? tradeInValue;

  // Pricing
  final double totalAmount;

  OrderSummary({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.homeId,
    required this.orderType,
    this.partCategory,
    this.compatibleWith,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.productBrand,
    required this.productModel,
    required this.orderStatus,
    required this.orderDate,
    this.estimatedDelivery,
    this.actualDelivery,
    required this.hasTradeIn,
    this.oldAssetId,
    this.oldAssetName,
    this.tradeInValue,
    required this.totalAmount,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
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
      orderStatus: _parseOrderStatus(json['orderStatus']),
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

  static OrderStatus _parseOrderStatus(String? status) {
    return parseOrderStatus(status);
  }

  static OrderStatus parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'placed':
        return OrderStatus.placed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out-for-delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'installed':
        return OrderStatus.installed;
      case 'completed':
        return OrderStatus.completed;
      case 'canceled':
        return OrderStatus.canceled;
      default:
        return OrderStatus.processing;
    }
  }
}

class ReplacementOrder extends OrderSummary {
  final String shippingAddress;
  final String? trackingNumber;
  final String? carrier;

  // Trade-In Details (if applicable)
  final TradeInStatus? tradeInStatus;
  final DateTime? tradeInPickupDate;
  final DateTime? tradeInActualPickup;
  final TradeInCondition? tradeInCondition;
  final double? tradeInAdjustedValue;

  // Pricing breakdown
  final double productPrice;
  final double tradeInDiscount;
  final double taxAmount;
  final double shippingCost;

  // Installation
  final bool requiresInstallation;
  final String? installationBookingId;
  final DateTime? installationDate;
  final String? installationStatus;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  ReplacementOrder({
    required super.id,
    required super.orderId,
    required super.userId,
    required super.homeId,
    required super.orderType,
    super.partCategory,
    super.compatibleWith,
    required super.productId,
    required super.productName,
    super.productImage,
    required super.productBrand,
    required super.productModel,
    required super.orderStatus,
    required super.orderDate,
    super.estimatedDelivery,
    super.actualDelivery,
    required super.hasTradeIn,
    super.oldAssetId,
    super.oldAssetName,
    super.tradeInValue,
    required super.totalAmount,
    required this.shippingAddress,
    this.trackingNumber,
    this.carrier,
    this.tradeInStatus,
    this.tradeInPickupDate,
    this.tradeInActualPickup,
    this.tradeInCondition,
    this.tradeInAdjustedValue,
    required this.productPrice,
    required this.tradeInDiscount,
    required this.taxAmount,
    required this.shippingCost,
    required this.requiresInstallation,
    this.installationBookingId,
    this.installationDate,
    this.installationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReplacementOrder.fromJson(Map<String, dynamic> json) {
    return ReplacementOrder(
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
      orderStatus: OrderSummary._parseOrderStatus(json['orderStatus']),
      orderDate: DateTime.parse(
        json['orderDate'] ?? DateTime.now().toIso8601String(),
      ),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'])
          : null,
      actualDelivery: json['actualDelivery'] != null
          ? DateTime.parse(json['actualDelivery'])
          : null,
      hasTradeIn: json['hasTradeIn'] ?? false,
      oldAssetId: (json['oldAssetId'] as Object?)?.toString(),
      oldAssetName: json['oldAssetName'],
      tradeInValue: (json['tradeInValue'] as num?)?.toDouble(),
      totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
      shippingAddress: json['shippingAddress'] ?? '',
      trackingNumber: json['trackingNumber'],
      carrier: json['carrier'],
      tradeInStatus: json['tradeInStatus'] != null
          ? _parseTradeInStatus(json['tradeInStatus'])
          : null,
      tradeInPickupDate: json['tradeInPickupDate'] != null
          ? DateTime.parse(json['tradeInPickupDate'])
          : null,
      tradeInActualPickup: json['tradeInActualPickup'] != null
          ? DateTime.parse(json['tradeInActualPickup'])
          : null,
      tradeInCondition: json['tradeInCondition'] != null
          ? _parseTradeInCondition(json['tradeInCondition'])
          : null,
      tradeInAdjustedValue: (json['tradeInAdjustedValue'] as num?)?.toDouble(),
      productPrice: ((json['productPrice'] as num?) ?? 0).toDouble(),
      tradeInDiscount: ((json['tradeInDiscount'] as num?) ?? 0).toDouble(),
      taxAmount: ((json['taxAmount'] as num?) ?? 0).toDouble(),
      shippingCost: ((json['shippingCost'] as num?) ?? 0).toDouble(),
      requiresInstallation: json['requiresInstallation'] ?? false,
      installationBookingId: json['installationBookingId'],
      installationDate: json['installationDate'] != null
          ? DateTime.parse(json['installationDate'])
          : null,
      installationStatus: json['installationStatus'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static TradeInStatus _parseTradeInStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TradeInStatus.pending;
      case 'scheduled':
        return TradeInStatus.scheduled;
      case 'picked-up':
        return TradeInStatus.pickedUp;
      case 'inspected':
        return TradeInStatus.inspected;
      case 'credited':
        return TradeInStatus.credited;
      default:
        return TradeInStatus.pending;
    }
  }

  static TradeInCondition _parseTradeInCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return TradeInCondition.excellent;
      case 'good':
        return TradeInCondition.good;
      case 'fair':
        return TradeInCondition.fair;
      case 'poor':
        return TradeInCondition.poor;
      default:
        return TradeInCondition.good;
    }
  }
}

class OrderTimelineEvent {
  final String id;
  final String orderId;
  final String status;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final bool isCurrent;

  OrderTimelineEvent({
    required this.id,
    required this.orderId,
    required this.status,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
  });

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isCompleted: json['isCompleted'] ?? false,
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}

// Helper functions
class OrderHelper {
  static String getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.installed:
        return 'Installed';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.canceled:
        return 'Canceled';
    }
  }

  /// Alias for getStatusLabel — used by OrderDetailScreen
  static String getStatusText(OrderStatus status) => getStatusLabel(status);

  static Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.processing:
        return AppColors.warning; // Orange
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return AppColors.info; // Blue
      case OrderStatus.delivered:
      case OrderStatus.installed:
      case OrderStatus.completed:
        return AppColors.success; // Green
      case OrderStatus.canceled:
        return AppColors.error; // Red
    }
  }

  static Color getStatusBackgroundColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.processing:
        return AppColors.warningLight;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return AppColors.infoLight;
      case OrderStatus.delivered:
      case OrderStatus.installed:
      case OrderStatus.completed:
        return AppColors.successLight;
      case OrderStatus.canceled:
        return AppColors.errorLight;
    }
  }
}
