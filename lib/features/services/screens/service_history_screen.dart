import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../utils/responsive_utils.dart';
import '../../shared/models/home_models.dart';
import '../services/booking_service.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<Map<String, dynamic>> _serviceHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  // Icon mapping for service types
  static const Map<String, IconData> _serviceIcons = {
    'cab': Icons.local_taxi,
    'restaurant': Icons.restaurant,
    'hotel': Icons.hotel,
    'healthcare': Icons.medical_services,
    'assembly': Icons.build,
    'cleaning': Icons.cleaning_services,
    'plumbing': Icons.plumbing,
    'electrical': Icons.electrical_services,
    'painting': Icons.format_paint,
    'moving': Icons.local_shipping,
    'pest control': Icons.bug_report,
    'landscaping': Icons.yard,
  };

  @override
  void initState() {
    super.initState();
    _loadServiceHistory();
  }

  Future<void> _loadServiceHistory() async {
    try {
      final bookings = await BookingService.getBookings();

      final realEntries = bookings
          .where((booking) => booking.issueCategory != 'Asset Repair')
          .map((booking) {
            final dateStr = DateFormat(
              'MMM d, yyyy',
            ).format(booking.scheduledDate);
            final statusStr = _mapStatus(booking.status);
            final category = booking.issueCategory == 'Lifestyle'
                ? 'Lifestyle'
                : 'Home Services';
            final iconKey = booking.assetName.toLowerCase();

            return <String, dynamic>{
              'id': booking.id,
              'serviceName': booking.assetName,
              'category': category,
              'date': dateStr,
              'status': statusStr,
              'amount': '\$${booking.visitFee.toStringAsFixed(2)}',
              'icon': _serviceIcons[iconKey] ?? Icons.miscellaneous_services,
            };
          })
          .toList();

      setState(() {
        _serviceHistory = realEntries;
        _isLoading = false;
      });
    } on Object catch (_) {
      setState(() {
        _serviceHistory = [];
        _isLoading = false;
      });
    }
  }

  /// Map ServiceStatus enum to display string
  String _mapStatus(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return 'Scheduled';
      case ServiceStatus.technicianAssigned:
        return 'Technician Assigned';
      case ServiceStatus.technicianOnWay:
        return 'Technician On Way';
      case ServiceStatus.inProgress:
        return 'In Progress';
      case ServiceStatus.completed:
        return 'Completed';
      case ServiceStatus.canceled:
        return 'Canceled';
      case ServiceStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final filteredHistory = _getFilteredHistory();

    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Service History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Container(
                  color: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20.0),
                    vertical: responsive.spacing(12.0),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        SizedBox(width: responsive.spacing(8.0)),
                        _buildFilterChip('Lifestyle'),
                        SizedBox(width: responsive.spacing(8.0)),
                        _buildFilterChip('Home Services'),
                        SizedBox(width: responsive.spacing(8.0)),
                        _buildFilterChip('Completed'),
                        SizedBox(width: responsive.spacing(8.0)),
                        _buildFilterChip('Canceled'),
                      ],
                    ),
                  ),
                ),

                // History list
                Expanded(
                  child: filteredHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(responsive.spacing(16.0)),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final service = filteredHistory[index];
                            return _buildHistoryCard(service, responsive);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    final responsive = ResponsiveUtils(context);
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16.0),
          vertical: responsive.spacing(8.0),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.gray200,
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> service,
    ResponsiveUtils responsive,
  ) {
    final status = service['status'] as String;
    final isCanceled = status == 'Canceled';
    final isCompleted = status == 'Completed';

    // Status badge colors
    final Color badgeBg;
    final Color badgeText;
    if (isCanceled) {
      badgeBg = AppColors.errorLight;
      badgeText = AppColors.errorDark;
    } else if (isCompleted) {
      badgeBg = AppColors.success.withValues(alpha: 0.1);
      badgeText = AppColors.success;
    } else {
      // Scheduled, Confirmed, In Progress, On Hold
      badgeBg = AppColors.warningLight;
      badgeText = AppColors.warningOrange;
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final bookingId = service['id'] as String?;
          if (bookingId != null) {
            context.push('/booking/$bookingId');
          }
        },
        child: Container(
          margin: EdgeInsets.only(bottom: responsive.spacing(12.0)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(responsive.spacing(16.0)),
            child: Row(
              children: [
                // Service icon
                Container(
                  width: responsive.iconSize(50.0),
                  height: responsive.iconSize(50.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    service['icon'] as IconData,
                    color: AppColors.primary,
                    size: responsive.iconSize(28.0),
                  ),
                ),
                SizedBox(width: responsive.spacing(16.0)),

                // Service details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['serviceName'] as String,
                        style: TextStyle(
                          fontSize: responsive.fontSize(16.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(4.0)),
                      Text(
                        '${service['category']} â€¢ ${service['date']}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(4.0)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(8.0),
                          vertical: responsive.spacing(4.0),
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                        ),
                        child: Text(
                          service['status'] as String,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12.0),
                            fontWeight: FontWeight.w600,
                            color: badgeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  service['amount'] as String,
                  style: TextStyle(
                    fontSize: responsive.fontSize(16.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final responsive = ResponsiveUtils(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: responsive.iconSize(80.0),
            color: AppColors.gray400,
          ),
          SizedBox(height: responsive.spacing(16.0)),
          Text(
            'No service history',
            style: TextStyle(
              fontSize: responsive.fontSize(18.0),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacing(8.0)),
          Text(
            'Your completed services will appear here',
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    if (_selectedFilter == 'All') {
      return _serviceHistory;
    } else if (_selectedFilter == 'Lifestyle') {
      return _serviceHistory
          .where((s) => s['category'] == 'Lifestyle')
          .toList();
    } else if (_selectedFilter == 'Home Services') {
      return _serviceHistory
          .where((s) => s['category'] == 'Home Services')
          .toList();
    } else if (_selectedFilter == 'Completed') {
      return _serviceHistory.where((s) => s['status'] == 'Completed').toList();
    } else if (_selectedFilter == 'Canceled') {
      return _serviceHistory.where((s) => s['status'] == 'Canceled').toList();
    }
    return _serviceHistory;
  }
}