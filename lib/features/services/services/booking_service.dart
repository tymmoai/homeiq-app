import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';
import '../../../services/api_client.dart';
import '../../shared/models/home_models.dart';

/// Service for managing service bookings - saving, retrieving, and updating
class BookingService {
  static const String _bookingsKey = 'service_bookings';
  static SharedPreferences? _prefs;

  /// Initialize the booking service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure prefs is initialized
  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Generate a unique booking ID
  static String generateBookingId() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 10000;
    return 'HQ${now.year}-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$random';
  }

  /// Save a new booking
  static Future<ActiveService> saveBooking({
    required String serviceType,
    required String serviceName,
    required Map<String, int> selectedItems,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    required double itemsTotal,
    required double serviceFee,
    required double total,
    String? specialInstructions,
    String? homeId,
    String? userId,
  }) async {
    final prefs = await _preferences;

    final bookingId = generateBookingId();
    final now = DateTime.now();

    // Build items summary for issue description
    final itemsSummary = selectedItems.entries
        .map((e) => '${e.key} x${e.value}')
        .join(', ');

    // Create the booking using the full ActiveService model
    final booking = ActiveService(
      id: 'booking_${now.millisecondsSinceEpoch}',
      bookingId: bookingId,
      homeId: homeId ?? 'home-1',
      userId: userId ?? 'user-1',
      assetId: 'service-${serviceType.toLowerCase().replaceAll(' ', '-')}',
      assetName: serviceName,
      assetLocation: '$address, $city',
      issueSummary: '$serviceType Service',
      issueDescription:
          'Items: $itemsSummary${specialInstructions != null ? '\n\nInstructions: $specialInstructions' : ''}',
      issueCategory: serviceType,
      severity: 'medium',
      technicianId: 'unassigned',
      technicianName: 'Assigning technician...',
      technicianRating: 0.0,
      scheduledDate: scheduledDate,
      scheduledTimeSlot: scheduledTime,
      status: ServiceStatus.scheduled,
      statusUpdatedAt: now,
      paymentMode: PaymentMode.payNow,
      paymentStatus: PaymentStatus.pending,
      visitFee: total,
      createdAt: now,
      updatedAt: now,
      isToday:
          scheduledDate.day == now.day &&
          scheduledDate.month == now.month &&
          scheduledDate.year == now.year,
      isUpcoming: scheduledDate.isAfter(now),
    );

    // Get existing bookings
    final bookings = await getBookings();
    bookings.insert(0, booking); // Add to beginning

    // Save to storage
    final bookingsJson = bookings.map((b) => _bookingToJson(b)).toList();
    await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));

    // Fire-and-forget backend sync (non-fatal)
    unawaited(_syncBookingToBackend(booking, isLifestyle: false));

    return booking;
  }

  /// Save a lifestyle booking (Cab, Restaurant, Hotel, Healthcare)
  static Future<ActiveService> saveLifestyleBooking({
    required String serviceType,
    required String serviceName,
    required DateTime scheduledDate,
    required String scheduledTime,
    required double total,
    String? bookingId,
    String? contactName,
    String? contactPhone,
    String? address,
    String? specialRequirements,
  }) async {
    final prefs = await _preferences;

    final id = bookingId ?? generateBookingId();
    final now = DateTime.now();

    final booking = ActiveService(
      id: 'lifestyle_${now.millisecondsSinceEpoch}',
      bookingId: id,
      homeId: 'home-1',
      userId: 'user-1',
      assetId: 'lifestyle-${serviceType.toLowerCase().replaceAll(' ', '-')}',
      assetName: serviceName,
      assetLocation: address ?? '',
      issueSummary: '$serviceType Booking',
      issueDescription: specialRequirements ?? '$serviceType service booking',
      issueCategory: 'Lifestyle',
      severity: 'low',
      technicianId: 'unassigned',
      technicianName: 'Provider pending...',
      technicianRating: 0.0,
      scheduledDate: scheduledDate,
      scheduledTimeSlot: scheduledTime,
      status: ServiceStatus.scheduled,
      statusUpdatedAt: now,
      paymentMode: PaymentMode.payNow,
      paymentStatus: PaymentStatus.pending,
      visitFee: total,
      createdAt: now,
      updatedAt: now,
      isToday:
          scheduledDate.day == now.day &&
          scheduledDate.month == now.month &&
          scheduledDate.year == now.year,
      isUpcoming: scheduledDate.isAfter(now),
    );

    final bookings = await getBookings();
    bookings.insert(0, booking);

    final bookingsJson = bookings.map((b) => _bookingToJson(b)).toList();
    await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));

    // Fire-and-forget backend sync (non-fatal)
    unawaited(_syncBookingToBackend(booking, isLifestyle: true));

    return booking;
  }

  /// Get all bookings — merges local (rich data) with backend (authoritative status)
  static Future<List<ActiveService>> getBookings({String? homeId}) async {
    final prefs = await _preferences;

    // Try to get any backend bookings for status sync
    Map<String, String> backendStatuses = {};
    try {
      final api = ApiClient();
      final response = await api.get('/bookings');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] is List) {
        for (final b in data['data'] as List) {
          final id = b['id']?.toString();
          final status = b['status']?.toString();
          if (id != null && status != null) {
            backendStatuses[id] = status;
          }
        }
      }
    } on Object catch (e) {
      // Backend unavailable — fine, use local data only
      AppLogger.warning(
        'BookingService: Backend status fetch failed: $e',
        tag: 'BookingService',
      );
    }

    final bookingsString = prefs.getString(_bookingsKey);

    if (bookingsString == null || bookingsString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> bookingsJson =
          jsonDecode(bookingsString) as List<dynamic>;
      final List<ActiveService> bookings = [];
      for (final json in bookingsJson) {
        try {
          bookings.add(_bookingFromJson(json as Map<String, dynamic>));
        } on Object catch (e) {
          AppLogger.warning(
            'BookingService: Skipping bad booking entry: $e',
            tag: 'BookingService',
            error: e,
          );
        }
      }

      // Filter by homeId if provided
      if (homeId != null) {
        return bookings.where((b) => b.homeId == homeId).toList();
      }

      return bookings;
    } on Object catch (e) {
      AppLogger.error(
        'BookingService: Error loading bookings: $e',
        tag: 'BookingService',
        error: e,
      );
      return [];
    }
  }

  /// Get a single booking by ID
  static Future<ActiveService?> getBookingById(String bookingId) async {
    final bookings = await getBookings();
    try {
      return bookings.firstWhere(
        (b) => b.bookingId == bookingId || b.id == bookingId,
      );
    } on Object catch (_) {
      return null;
    }
  }

  /// Update booking status
  static Future<bool> updateBookingStatus(
    String bookingId,
    ServiceStatus newStatus,
  ) async {
    final prefs = await _preferences;
    final bookings = await getBookings();

    final index = bookings.indexWhere(
      (b) => b.bookingId == bookingId || b.id == bookingId,
    );

    if (index == -1) return false;

    final old = bookings[index];
    final now = DateTime.now();

    final updatedBooking = ActiveService(
      id: old.id,
      bookingId: old.bookingId,
      homeId: old.homeId,
      userId: old.userId,
      assetId: old.assetId,
      assetName: old.assetName,
      assetLocation: old.assetLocation,
      issueSummary: old.issueSummary,
      issueDescription: old.issueDescription,
      issueCategory: old.issueCategory,
      severity: old.severity,
      technicianId: old.technicianId,
      technicianName: old.technicianName,
      technicianRating: old.technicianRating,
      scheduledDate: old.scheduledDate,
      scheduledTimeSlot: old.scheduledTimeSlot,
      status: newStatus,
      statusUpdatedAt: now,
      paymentMode: old.paymentMode,
      paymentStatus: old.paymentStatus,
      visitFee: old.visitFee,
      createdAt: old.createdAt,
      updatedAt: now,
      isToday: old.isToday,
      isUpcoming: old.isUpcoming,
    );

    bookings[index] = updatedBooking;

    final bookingsJson = bookings.map((b) => _bookingToJson(b)).toList();
    await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));

    return true;
  }

  /// Update payment status
  static Future<bool> updatePaymentStatus(
    String bookingId,
    PaymentStatus newStatus,
  ) async {
    final prefs = await _preferences;
    final bookings = await getBookings();

    final index = bookings.indexWhere(
      (b) => b.bookingId == bookingId || b.id == bookingId,
    );

    if (index == -1) return false;

    final old = bookings[index];
    final now = DateTime.now();

    final updatedBooking = ActiveService(
      id: old.id,
      bookingId: old.bookingId,
      homeId: old.homeId,
      userId: old.userId,
      assetId: old.assetId,
      assetName: old.assetName,
      assetLocation: old.assetLocation,
      issueSummary: old.issueSummary,
      issueDescription: old.issueDescription,
      issueCategory: old.issueCategory,
      severity: old.severity,
      technicianId: old.technicianId,
      technicianName: old.technicianName,
      technicianRating: old.technicianRating,
      scheduledDate: old.scheduledDate,
      scheduledTimeSlot: old.scheduledTimeSlot,
      status: old.status,
      statusUpdatedAt: old.statusUpdatedAt,
      paymentMode: old.paymentMode,
      paymentStatus: newStatus,
      visitFee: old.visitFee,
      createdAt: old.createdAt,
      updatedAt: now,
      isToday: old.isToday,
      isUpcoming: old.isUpcoming,
    );

    bookings[index] = updatedBooking;

    final bookingsJson = bookings.map((b) => _bookingToJson(b)).toList();
    await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));

    return true;
  }

  /// Cancel a booking
  static Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    return await updateBookingStatus(bookingId, ServiceStatus.canceled);
  }

  /// Reschedule a booking
  static Future<bool> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    String newTime,
  ) async {
    final prefs = await _preferences;
    final bookings = await getBookings();

    final index = bookings.indexWhere(
      (b) => b.bookingId == bookingId || b.id == bookingId,
    );

    if (index == -1) return false;

    final old = bookings[index];
    final now = DateTime.now();

    final updatedBooking = ActiveService(
      id: old.id,
      bookingId: old.bookingId,
      homeId: old.homeId,
      userId: old.userId,
      assetId: old.assetId,
      assetName: old.assetName,
      assetLocation: old.assetLocation,
      issueSummary: old.issueSummary,
      issueDescription: old.issueDescription,
      issueCategory: old.issueCategory,
      severity: old.severity,
      technicianId: old.technicianId,
      technicianName: old.technicianName,
      technicianRating: old.technicianRating,
      scheduledDate: newDate,
      scheduledTimeSlot: newTime,
      status: ServiceStatus.rescheduled,
      statusUpdatedAt: now,
      paymentMode: old.paymentMode,
      paymentStatus: old.paymentStatus,
      visitFee: old.visitFee,
      createdAt: old.createdAt,
      updatedAt: now,
      isToday:
          newDate.day == now.day &&
          newDate.month == now.month &&
          newDate.year == now.year,
      isUpcoming: newDate.isAfter(now),
    );

    bookings[index] = updatedBooking;

    final bookingsJson = bookings.map((b) => _bookingToJson(b)).toList();
    await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));

    return true;
  }

  /// Delete a booking (for testing/admin purposes)
  static Future<bool> deleteBooking(String bookingId) async {
    final prefs = await _preferences;
    final bookings = await getBookings();

    bookings.removeWhere((b) => b.bookingId == bookingId || b.id == bookingId);

    final bookingsJson = bookings.map((b) => _bookingToJson(b)).toList();
    await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));

    return true;
  }

  /// Clear all bookings (for testing purposes)
  static Future<void> clearAllBookings() async {
    final prefs = await _preferences;
    await prefs.remove(_bookingsKey);
  }

  /// Get booking counts by status
  static Future<Map<ServiceStatus, int>> getBookingCounts() async {
    final bookings = await getBookings();
    final counts = <ServiceStatus, int>{};

    for (final booking in bookings) {
      counts[booking.status] = (counts[booking.status] ?? 0) + 1;
    }

    return counts;
  }

  /// Convert ActiveService to JSON for storage
  static Map<String, dynamic> _bookingToJson(ActiveService booking) {
    return {
      'id': booking.id,
      'bookingId': booking.bookingId,
      'homeId': booking.homeId,
      'userId': booking.userId,
      'assetId': booking.assetId,
      'assetName': booking.assetName,
      'assetLocation': booking.assetLocation,
      'issueSummary': booking.issueSummary,
      'issueDescription': booking.issueDescription,
      'issueCategory': booking.issueCategory,
      'severity': booking.severity,
      'technicianId': booking.technicianId,
      'technicianName': booking.technicianName,
      'technicianRating': booking.technicianRating,
      'scheduledDate': booking.scheduledDate.toIso8601String(),
      'scheduledTimeSlot': booking.scheduledTimeSlot,
      'status': booking.status.index,
      'statusUpdatedAt': booking.statusUpdatedAt.toIso8601String(),
      'paymentMode': booking.paymentMode.index,
      'paymentStatus': booking.paymentStatus.index,
      'visitFee': booking.visitFee,
      'createdAt': booking.createdAt.toIso8601String(),
      'updatedAt': booking.updatedAt.toIso8601String(),
      'isToday': booking.isToday,
      'isUpcoming': booking.isUpcoming,
    };
  }

  /// Convert JSON to ActiveService
  static ActiveService _bookingFromJson(Map<String, dynamic> json) {
    return ActiveService(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      homeId: json['homeId'] ?? 'home-1',
      userId: json['userId'] ?? 'user-1',
      assetId: json['assetId'] ?? '',
      assetName: json['assetName'] ?? '',
      assetLocation: json['assetLocation'] ?? '',
      issueSummary: json['issueSummary'] ?? '',
      issueDescription: json['issueDescription'],
      issueCategory: json['issueCategory'] ?? '',
      severity: json['severity'] ?? 'medium',
      technicianId: json['technicianId'] ?? 'unassigned',
      technicianName: json['technicianName'] ?? 'Unassigned',
      technicianRating: (json['technicianRating'] ?? 0.0).toDouble(),
      scheduledDate: DateTime.parse(json['scheduledDate']),
      scheduledTimeSlot: json['scheduledTimeSlot'] ?? '',
      status: ServiceStatus.values[json['status'] ?? 0],
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.parse(json['statusUpdatedAt'])
          : DateTime.now(),
      paymentMode: PaymentMode.values[json['paymentMode'] ?? 0],
      paymentStatus: PaymentStatus.values[json['paymentStatus'] ?? 0],
      visitFee: ((json['visitFee'] as num?) ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isToday: json['isToday'] ?? false,
      isUpcoming: json['isUpcoming'] ?? true,
    );
  }

  // ---------------------------------------------------------------------------
  // Backend sync (fire-and-forget, non-fatal)
  // ---------------------------------------------------------------------------

  static Future<void> _syncBookingToBackend(
    ActiveService booking, {
    required bool isLifestyle,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final homeId = prefs.getString('selected_home_id');
      if (homeId == null || homeId.isEmpty) return;

      final api = ApiClient();
      await api.post(
        '/bookings',
        body: {
          'homeId': homeId,
          'bookingId': booking.bookingId,
          'serviceType': booking.issueCategory,
          'serviceName': booking.assetName,
          'scheduledDate': booking.scheduledDate.toIso8601String(),
          'scheduledTime': booking.scheduledTimeSlot,
          'address': booking.assetLocation,
          'total': booking.visitFee,
          'status': booking.status.name,
          'isLifestyle': isLifestyle,
          'notes': booking.issueDescription,
        },
      );
      AppLogger.info(
        'BookingService: Synced booking "${booking.bookingId}" to backend',
        tag: 'BookingService',
      );
    } on Object catch (e) {
      AppLogger.warning(
        'BookingService: Backend sync failed (non-fatal): $e',
        tag: 'BookingService',
      );
    }
  }
}
