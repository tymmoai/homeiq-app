import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../core/base/view_model_mixin.dart';
import '../../../core/utils/logger.dart';
import '../../shared/models/home_models.dart';
import '../services/booking_service.dart';

class ActiveServicesScreen extends StatefulWidget {
  final String? homeId;

  const ActiveServicesScreen({super.key, this.homeId});

  @override
  State<ActiveServicesScreen> createState() => _ActiveServicesScreenState();
}

class _ActiveServicesScreenState extends State<ActiveServicesScreen>
    with ViewModelMixin {
  String _searchQuery = '';
  final String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<ActiveService> _userBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload bookings when screen becomes visible again
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await BookingService.getBookings(homeId: widget.homeId);
      safeSetState(() {
        _userBookings = bookings;
        _isLoading = false;
      });
    } on Object catch (e) {
      AppLogger.error(
        'Error loading bookings: $e',
        tag: 'ActiveServices',
        error: e,
      );
      safeSetState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActiveService> _getFilteredServices() {
    // Use only real bookings from backend/local storage — no mock data
    final filteredUserBookings = _userBookings
        .where((b) => widget.homeId == null || b.homeId == widget.homeId)
        .toList();
    var services = [...filteredUserBookings];

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      services = services.where((service) {
        final searchLower = _searchQuery.toLowerCase();
        return service.assetName.toLowerCase().contains(searchLower) ||
            service.technicianName.toLowerCase().contains(searchLower) ||
            service.issueCategory.toLowerCase().contains(searchLower) ||
            service.bookingId.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != 'All') {
      switch (_selectedStatusFilter) {
        case 'Scheduled':
          services = services
              .where((s) => s.status == ServiceStatus.scheduled)
              .toList();
          break;
        case 'In Progress':
          services = services
              .where(
                (s) =>
                    s.status == ServiceStatus.technicianAssigned ||
                    s.status == ServiceStatus.technicianOnWay ||
                    s.status == ServiceStatus.inProgress,
              )
              .toList();
          break;
        case 'Today':
          services = services.where((s) => s.isToday).toList();
          break;
      }
    }

    // Show all services for the selected home (same as home tab)
    return services;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'My Services',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: responsive.fontSize(18.0),
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final services = _getFilteredServices();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Services',
          style: TextStyle(
            color: AppColors.white,
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar - full width
          Container(
            width: double.infinity,
            padding: responsive.padding(left: 14, top: 8, right: 14, bottom: 8),
            color: AppColors.white,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: MediaQuery.of(context).size.height < 700 ? 10 : 16,
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: AppColors.iconSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Services...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Handle send action if needed
                    },
                    child: Icon(Icons.send, color: AppColors.primary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Services list
          Expanded(
            child: services.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: responsive.padding(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 16,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      return _buildServiceCard(context, services[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final responsive = context.responsive;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: responsive.iconSize(80.0),
            color: AppColors.iconDisabled,
          ),
          responsive.heightBox(16.0),
          Text(
            'No Active Services',
            style: TextStyle(
              fontSize: responsive.fontSize(18.0),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          responsive.heightBox(8.0),
          Text(
            'Everything is running smoothly',
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: AppColors.textSecondary,
            ),
          ),
          responsive.heightBox(24.0),
          ElevatedButton(
            onPressed: () {
              context.push('/services');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Book a Service',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ActiveService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to booking detail screen
          context.push('/booking/${service.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category Badge, Today Indicator, and Chevron
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                    ),
                    child: Text(
                      service.issueCategory.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (service.isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Asset name and Location
              Text(
                service.assetName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    service.assetLocation,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Issue summary
              Text(
                service.issueSummary,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              // Progress Bar
              Row(
                children: [
                  Text(
                    'Job Completion',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getCompletionPercentage(service),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getCompletionValue(service),
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 14),
              // Details in compact grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today_outlined,
                      service.getFormattedDate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time_outlined,
                      service.scheduledTimeSlot,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.person_outline,
                      service.technicianName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.attach_money,
                      '\$${service.visitFee.toStringAsFixed(0)} visit fee',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getCompletionPercentage(ActiveService service) {
    switch (service.status) {
      case ServiceStatus.scheduled:
        return '0%';
      case ServiceStatus.technicianAssigned:
        return '25%';
      case ServiceStatus.technicianOnWay:
        return '50%';
      case ServiceStatus.inProgress:
        return '75%';
      case ServiceStatus.completed:
        return '100%';
      default:
        return '0%';
    }
  }

  double _getCompletionValue(ActiveService service) {
    switch (service.status) {
      case ServiceStatus.scheduled:
        return 0.0;
      case ServiceStatus.technicianAssigned:
        return 0.25;
      case ServiceStatus.technicianOnWay:
        return 0.5;
      case ServiceStatus.inProgress:
        return 0.75;
      case ServiceStatus.completed:
        return 1.0;
      default:
        return 0.0;
    }
  }
}
