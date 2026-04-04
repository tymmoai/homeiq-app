import 'package:flutter/material.dart';

/// Centralized mock data for the Home screen.
///
/// Houses static asset data and notification generators that were
/// previously inlined in [HomeScreen].
class HomeScreenMockData {
  HomeScreenMockData._();

  /// Mock asset catalogue used for existing (non-new) users.
  static const List<Map<String, dynamic>> assets = [
    // Asset 1: Health score < 6.5, Warranty Expired (5 year warranty expired)
    {
      'id': '1',
      'name': 'Refrigerator',
      'brand': 'Samsung',
      'type': 'Refrigerator',
      'location': 'Kitchen',
      'model': 'RT28M3022S8',
      'serial': 'SN-RF-2019-84723',
      'healthScore': 6.2,
      'lastService': '2 months ago',
      'warranty': 'Expired',
      'warrantyEndDate': '2024-01-15', // 5 years after purchase
      'purchaseYear': 2019,
      'purchaseDate': 'Jan 2019',
      'pastRepairs': 1,
      'status': 'Need Attention',
      'image': 'refrigerator',
    },
    // Asset 2: UPGRADED - Purchased 3 months ago (Nov 2025)
    {
      'id': '2',
      'name': 'Sony Smart TV',
      'brand': 'Sony',
      'type': 'Television',
      'location': 'Living Room',
      'model': 'KD-55X80J',
      'serial': 'SN-TV-2025-39105',
      'healthScore': 9.5,
      'lastService': 'Never',
      'warranty': 'Active',
      'warrantyEndDate': '2030-11-15', // 5 years after purchase
      'purchaseYear': 2025,
      'purchaseDate': 'Nov 2025',
      'pastRepairs': 0,
      'status': 'Good',
      'image': 'television',
      'lifecycleStatus': 'active',
      'replacedAssetId': 10,
      'replacedAssetName': 'Old Samsung TV',
    },
    // Asset 3: Warranty Expired (3 year warranty expired)
    {
      'id': '3',
      'name': 'Microwave Oven',
      'brand': 'Whirlpool',
      'type': 'Microwave',
      'location': 'Kitchen',
      'model': 'WMC30516HZ',
      'serial': 'SN-MW-2020-56281',
      'healthScore': 8.0,
      'lastService': '1 month ago',
      'warranty': 'Expired',
      'warrantyEndDate': '2023-04-20', // 3 years after purchase
      'purchaseYear': 2020,
      'purchaseDate': 'Apr 2020',
      'pastRepairs': 0,
      'status': 'Good',
      'image': 'microwave',
    },
    // Asset 4: Health score < 6.5, Warranty Active (10 year warranty)
    {
      'id': '4',
      'name': 'AC Living',
      'brand': 'LG',
      'type': 'Air Conditioner',
      'location': 'Living Room',
      'model': 'LS-Q18YNZA',
      'serial': 'SN-AC-2019-67452',
      'healthScore': 4.5,
      'lastService': '5 months ago',
      'warranty': 'Active',
      'warrantyEndDate': '2029-03-20', // 10 years after purchase
      'purchaseYear': 2019,
      'purchaseDate': 'Mar 2019',
      'pastRepairs': 3,
      'status': 'Critical',
      'image': 'air_conditioner',
    },
    // Asset 7: Health score good, Warranty Active (5 year warranty)
    {
      'id': '7',
      'name': 'AC Bedroom',
      'brand': 'LG',
      'type': 'Air Conditioner',
      'location': 'Bedroom',
      'model': 'AS-Q12YNZA',
      'serial': 'SN-AC-2022-12038',
      'healthScore': 7.5,
      'lastService': '3 months ago',
      'warranty': 'Active',
      'warrantyEndDate': '2027-06-15', // 5 years after purchase
      'purchaseYear': 2022,
      'purchaseDate': 'Jun 2022',
      'pastRepairs': 0,
      'status': 'Need Attention',
      'image': 'air_conditioner',
    },
    // Replaced asset - Old Samsung TV (purchased Jan 2018, replaced Nov 2025)
    {
      'id': '10',
      'name': 'Old Samsung TV',
      'brand': 'Samsung',
      'type': 'Television',
      'location': 'Living Room',
      'model': 'UA32T4450',
      'serial': 'SN-TV-2018-90374',
      'healthScore': 3.2,
      'lastService': 'Jun 2022',
      'warranty': 'Expired',
      'warrantyEndDate': '2020-01-15', // 2 years after purchase
      'purchaseYear': 2018,
      'purchaseDate': 'Jan 2018',
      'pastRepairs': 4,
      'status': 'Critical',
      'image': 'television',
      'lifecycleStatus': 'replaced',
      'replacedByAssetId': 2,
      'replacedByAssetName': 'Sony Smart TV',
      'replacementDate': 'Nov 2025',
    },
  ];

  /// Generates a fresh list of mock notifications with timestamps relative
  /// to [DateTime.now].
  static List<Map<String, dynamic>> notifications() => [
    {
      'id': 'notif_1',
      'title': 'Booking Confirmed',
      'message':
          'Your service for AC Bedroom is scheduled for Jan 10, 9 AM - 12 PM',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'icon': Icons.check_circle,
      'isRead': false,
    },
    {
      'id': 'notif_2',
      'title': 'Order Confirmed',
      'message':
          'Your maintenance parts order #12345 has been confirmed and will ship soon',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'icon': Icons.shopping_cart,
      'isRead': false,
    },
    {
      'id': 'notif_3',
      'title': 'Asset Added',
      'message':
          'Samsung Refrigerator has been successfully added to your home',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'icon': Icons.add_circle,
      'isRead': false,
    },
    {
      'id': 'notif_4',
      'title': 'Technician On the Way',
      'message':
          'John Mitchell is on the way to your location. Expected arrival: 10:00 AM',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'icon': Icons.location_on,
      'isRead': false,
    },
    {
      'id': 'notif_5',
      'title': 'Service Reminder',
      'message':
          'Your service for Microwave Oven is scheduled tomorrow at 3 PM - 6 PM',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'icon': Icons.access_time,
      'isRead': true,
    },
    {
      'id': 'notif_6',
      'title': 'Payment Successful',
      'message':
          'Your payment of \$299.00 for Premium Protection Plan has been processed',
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
      'icon': Icons.payment,
      'isRead': true,
    },
    {
      'id': 'notif_7',
      'title': 'Maintenance Due',
      'message':
          'Your AC Living is due for scheduled maintenance. Book a service to keep it running efficiently',
      'timestamp': DateTime.now().subtract(const Duration(days: 10)),
      'icon': Icons.build_circle,
      'isRead': true,
    },
    {
      'id': 'notif_8',
      'title': 'Maintenance Completed',
      'message':
          'Your scheduled maintenance for Refrigerator has been completed successfully',
      'timestamp': DateTime.now().subtract(const Duration(days: 15)),
      'icon': Icons.build,
      'isRead': true,
    },
    {
      'id': 'notif_9',
      'title': 'Protection Plan Renewed',
      'message':
          'Your Ultimate Protection Plan has been automatically renewed for another year',
      'timestamp': DateTime.now().subtract(const Duration(days: 25)),
      'icon': Icons.verified,
      'isRead': true,
    },
  ];
}
