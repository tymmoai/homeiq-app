import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../theme/asset_detail_colors.dart';
import '../../../utils/responsive_utils.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  late String scheduledDate;
  late String scheduledTime;

  @override
  void initState() {
    super.initState();
    scheduledDate = widget.service['date'] ?? _formatDefaultDate();
    scheduledTime = widget.service['time'] ?? '12 PM - 3 PM';
  }

  /// Generate a dynamic fallback date (tomorrow) instead of a hardcoded date.
  String _formatDefaultDate() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[tomorrow.weekday - 1]}, ${months[tomorrow.month - 1]} ${tomorrow.day}, ${tomorrow.year}';
  }

  /// Format a DateTime to short "Mon DD" format.
  String _formatShortDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _showReschedulePicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return _RescheduleDrawer(initialDate: DateTime.now());
      },
    );

    if (result != null && mounted) {
      setState(() {
        scheduledDate = result['date'] as String;
        scheduledTime = result['time'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.headerForeground,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.service['title'] ?? 'Service Detail',
          style: TextStyle(
            color: AppColors.headerForeground,
            fontWeight: FontWeight.bold,
            fontSize: responsive.fontSize(20),
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
        elevation: 2,
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerForeground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.headerForeground),
      ),
      backgroundColor: AppColors.backgroundGray50,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Header Card - Asset Name, Location, ID, Reschedule icon
              Container(
                padding: EdgeInsets.all(responsive.spacing(15)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Asset Name
                              Text(
                                widget.service['assetName'] ??
                                    'Samsung Refrigerator',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: responsive.fontSize(16),
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(4)),
                              // Asset Location
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.gray600,
                                    size: responsive.iconSize(14),
                                  ),
                                  SizedBox(width: responsive.spacing(4)),
                                  Text(
                                    widget.service['location'] ?? 'Kitchen',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(13),
                                      color: AppColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: responsive.spacing(4)),
                              // Service ID
                              Text(
                                'ID: ${widget.service['id'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13),
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Reschedule Icon in top right
                        IconButton(
                          icon: Icon(
                            Icons.event_repeat_outlined,
                            size: responsive.iconSize(26),
                          ),
                          color: AppColors.primary,
                          onPressed: _showReschedulePicker,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              // Schedule Info Card
              Container(
                padding: EdgeInsets.all(responsive.spacing(15)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 8,
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
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppColors.white,
                        size: responsive.iconSize(20),
                      ),
                    ),
                    SizedBox(width: responsive.spacing(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                              fontSize: responsive.fontSize(13),
                            ),
                          ),
                          Text(
                            scheduledDate,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: responsive.fontSize(15),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time slot
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray100,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Text(
                        scheduledTime,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                          fontSize: responsive.fontSize(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              // Issue Description Card
              Container(
                padding: EdgeInsets.all(responsive.spacing(15)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ISSUE DESCRIPTION',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray600,
                        fontSize: responsive.fontSize(13),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    Text(
                      widget.service['description'] ??
                          'Water is leaking from the bottom of the refrigerator',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              // Technician Card
              Container(
                padding: EdgeInsets.all(responsive.spacing(15)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: responsive.fontSize(22),
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.spacing(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Michael Anderson',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: responsive.fontSize(16),
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: responsive.spacing(6)),
                              Icon(Icons.circle, color: AppColors.success, size: responsive.iconSize(8)),
                            ],
                          ),
                          SizedBox(height: responsive.spacing(4)),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.amber,
                                size: responsive.iconSize(14),
                              ),
                              SizedBox(width: responsive.spacing(2)),
                              Text(
                                '4.6',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: responsive.fontSize(13),
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: responsive.spacing(4)),
                              Text(
                                '(89 reviews) â€¢ 5 years experience',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.spacing(2)),
                          Text(
                            'Specializes in Leakage Issue',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.phone_outlined,
                        color: AppColors.primary,
                        size: responsive.iconSize(20),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              // Service Progress Card
              Container(
                padding: EdgeInsets.all(responsive.spacing(15)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SERVICE PROGRESS',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray600,
                        fontSize: responsive.fontSize(13),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    // Example progress steps
                    _ServiceStep(
                      title: 'Booking Created',
                      subtitle: 'Service request submitted',
                      date: _formatShortDate(DateTime.now().subtract(const Duration(days: 1))),
                      active: true,
                    ),
                    _ServiceStep(
                      title: 'Technician Assigned',
                      subtitle: 'Michael Anderson assigned',
                      date: _formatShortDate(DateTime.now().subtract(const Duration(days: 1))),
                      active: true,
                    ),
                    const _ServiceStep(
                      title: 'On the Way',
                      subtitle: 'Technician en route',
                      date: '',
                      active: false,
                    ),
                    const _ServiceStep(
                      title: 'Service In Progress',
                      subtitle: 'Working on your appliance',
                      date: '',
                      active: false,
                    ),
                    const _ServiceStep(
                      title: 'Completed',
                      subtitle: 'Service finished',
                      date: '',
                      active: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RescheduleDrawer extends StatefulWidget {
  final DateTime initialDate;

  const _RescheduleDrawer({required this.initialDate});

  @override
  State<_RescheduleDrawer> createState() => _RescheduleDrawerState();
}

class _RescheduleDrawerState extends State<_RescheduleDrawer> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  late DateTime selectedDate;
  String? selectedTimeSlot;

  final List<String> timeSlots = [
    '9 AM - 12 PM',
    '12 PM - 3 PM',
    '3 PM - 6 PM',
    '6 PM - 9 PM',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayOfWeek = days[date.weekday - 1];
    final month = months[date.month - 1];
    return '$dayOfWeek, $month ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with icon
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(responsive.spacing(8)),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                            ),
                            child: Icon(
                              Icons.event_repeat,
                              color: AppColors.primary,
                              size: responsive.iconSize(20),
                            ),
                          ),
                          SizedBox(width: responsive.spacing(12)),
                          Text(
                            'Reschedule Service',
                            style: TextStyle(
                              fontSize: responsive.fontSize(20),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(16)),

                      // Selected Date & Time Display
                      Container(
                        padding: EdgeInsets.all(responsive.spacing(16)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary05,
                              AppColors.primary05.withValues(alpha: 0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary10,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(responsive.spacing(8)),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: responsive.iconSize(18),
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected Date',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(11),
                                          color: AppColors.gray600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: responsive.spacing(2)),
                                      Text(
                                        _formatDate(selectedDate),
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(15),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (selectedTimeSlot != null) ...[
                              SizedBox(height: responsive.spacing(12)),
                              Container(
                                height: 1,
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              SizedBox(height: responsive.spacing(12)),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(responsive.spacing(8)),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      size: responsive.iconSize(18),
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: responsive.spacing(12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected Time',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(11),
                                            color: AppColors.gray600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: responsive.spacing(2)),
                                        Text(
                                          selectedTimeSlot!,
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(15),
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: responsive.spacing(20)),

                      // Calendar Section
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          Text(
                            'Pick a Date',
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGray50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: AppColors.white,
                              surface: AppColors.transparent,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            onDateChanged: (DateTime date) {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(20)),

                      // Time Slot Section
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          Text(
                            'Select Time Slot',
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.5,
                        children: timeSlots.map((slot) {
                          final isSelected = selectedTimeSlot == slot;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTimeSlot = slot;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowDark,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  slot,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.fontSize(14),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: responsive.spacing(24)),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowDark,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.fontSize(15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: responsive.spacing(12)),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowDark,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: selectedTimeSlot == null
                                    ? null
                                    : () {
                                        Navigator.of(context).pop({
                                          'date': _formatDate(selectedDate),
                                          'time': selectedTimeSlot!,
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor: AppColors.gray300,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Confirm',
                                  style: TextStyle(
                                    color: selectedTimeSlot == null
                                        ? AppColors.gray600
                                        : AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.fontSize(15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final bool active;
  const _ServiceStep({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.success
                      : AssetDetailColors.backgroundColor,
                  border: Border.all(
                    color: active
                        ? AppColors.success
                        : AssetDetailColors.textSecondary.withValues(
                            alpha: 0.2,
                          ),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  active ? Icons.check : Icons.circle,
                  color: active
                      ? AppColors.white
                      : AssetDetailColors.textSecondary,
                  size: responsive.iconSize(14),
                ),
              ),
              Container(
                width: 2,
                height: 32,
                color: AssetDetailColors.textSecondary.withValues(alpha: 0.15),
              ),
            ],
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.fontSize(15),
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AssetDetailColors.textSecondary,
                      fontSize: responsive.fontSize(13),
                    ),
                  ),
                ],
                if (date.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    date,
                    style: TextStyle(
                      color: AssetDetailColors.textSecondary,
                      fontSize: responsive.fontSize(12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}