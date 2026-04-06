import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_step_header.dart';

/// Shared step widget for selecting a date and time slot.
///
/// Displays a calendar grid and available time slots.
/// Reuses the exact same design as the existing Step3Schedule.
class BookingScheduleStep extends StatefulWidget {
  final ServiceBookingFormData formData;
  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  /// Optional extra widget rendered below the time slots section.
  /// Used by Cleaning & Outdoor flows to embed the RecurringToggle.
  final Widget? extraContent;

  /// Optional estimated duration text (e.g. "1 hour", "2 hours 30 min").
  /// When provided, shows an "Estimated Duration" banner below the title.
  final String? estimatedDurationText;

  /// Number of items selected (used in the estimated duration description).
  final int? totalItemCount;

  /// Service name for the duration description (e.g. "mounting", "assembly").
  final String? serviceName;

  const BookingScheduleStep({
    super.key,
    required this.formData,
    this.title = 'When do you need it?',
    this.subtitle = 'Choose a convenient date and time slot',
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
    this.extraContent,
    this.estimatedDurationText,
    this.totalItemCount,
    this.serviceName,
  });

  @override
  State<BookingScheduleStep> createState() => _BookingScheduleStepState();
}

class _BookingScheduleStepState extends State<BookingScheduleStep> {
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  final Map<String, List<String>> _timeSlotsByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.formData.selectedDate;
    _selectedTimeSlot = widget.formData.selectedTimeSlot;
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final slots = <String>[];
      if (i == 0) {
        if (now.hour < 10) slots.add('08:00 AM - 10:00 AM');
        if (now.hour < 12) slots.add('10:00 AM - 12:00 PM');
        if (now.hour < 14) slots.add('12:00 PM - 02:00 PM');
        if (now.hour < 16) slots.add('02:00 PM - 04:00 PM');
      } else {
        slots.addAll([
          '08:00 AM - 10:00 AM',
          '10:00 AM - 12:00 PM',
          '12:00 PM - 02:00 PM',
          '02:00 PM - 04:00 PM',
        ]);
      }

      if (slots.isNotEmpty) {
        _timeSlotsByDate[normalizedDate.toString()] = slots;
      }
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: context.responsive.padding(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(24.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  context.responsive.heightBox(8.0),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(14.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Estimated Duration banner
                  if (widget.estimatedDurationText != null) ...[
                    context.responsive.heightBox(20.0),
                    _buildEstimatedDurationBanner(),
                  ],
                  context.responsive.heightBox(24.0),
                  _buildCalendarGrid(),
                  if (_selectedDate != null) ...[
                    context.responsive.heightBox(24.0),
                    Text(
                      'Available Time Slots for ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: context.responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    context.responsive.heightBox(12.0),
                    _buildTimeSlots(),
                  ],
                  // Extra content (e.g. RecurringToggle for Cleaning/Outdoor)
                  if (widget.extraContent != null) ...[
                    context.responsive.heightBox(24.0),
                    widget.extraContent!,
                  ],
                  context.responsive.heightBox(24.0),
                ],
              ),
            ),
          ),
        ),
        _buildContinueButton(),
      ],
    );
  }

  /// Estimated Duration banner — matches the web's blue info banner.
  /// Shows a clock icon, title, and description with the duration highlighted.
  Widget _buildEstimatedDurationBanner() {
    final itemCount = widget.totalItemCount ?? 1;
    final service = widget.serviceName ?? 'service';

    return Container(
      padding: context.responsive.padding(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(12.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.responsive.spacing(42.0),
            height: context.responsive.spacing(42.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: AppColors.primary,
              size: context.responsive.iconSize(22.0),
            ),
          ),
          context.responsive.widthBox(12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Duration',
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(15.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: context.responsive.spacing(2.0)),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(13.0),
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Based on $itemCount ${itemCount == 1 ? 'item' : 'items'}, $service will take approximately ',
                      ),
                      TextSpan(
                        text: widget.estimatedDurationText!,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final currentMonth = _calendarMonth;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: context.responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(16.0),
        ),
      ),
      child: Column(
        children: [
          // Month header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _calendarMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month - 1,
                    );
                  });
                },
                child: Container(
                  width: context.responsive.spacing(36.0),
                  height: context.responsive.spacing(36.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundGray100,
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                    size: context.responsive.iconSize(24.0),
                  ),
                ),
              ),
              Text(
                '${_getMonthName(currentMonth)} ${currentMonth.year}',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(18.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _calendarMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month + 1,
                    );
                  });
                },
                child: Container(
                  width: context.responsive.spacing(36.0),
                  height: context.responsive.spacing(36.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundGray100,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: context.responsive.iconSize(24.0),
                  ),
                ),
              ),
            ],
          ),
          context.responsive.heightBox(20.0),
          // Week day headers
          Row(
            children: weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(12.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          context.responsive.heightBox(12.0),
          // Calendar days
          ...List.generate(6, (weekIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.responsive.spacing(8.0)),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber =
                      (weekIndex * 7) + dayIndex - (firstDayWeekday - 1) + 1;
                  final isCurrentMonth =
                      dayNumber > 0 && dayNumber <= daysInMonth;
                  final date = isCurrentMonth
                      ? DateTime(
                          currentMonth.year,
                          currentMonth.month,
                          dayNumber,
                        )
                      : null;
                  final normalizedDate = date != null
                      ? _normalizeDate(date)
                      : null;
                  final normalizedNow = _normalizeDate(now);
                  final isAvailable =
                      normalizedDate != null &&
                      !normalizedDate.isBefore(normalizedNow) &&
                      _timeSlotsByDate.containsKey(normalizedDate.toString());
                  final isSelected =
                      normalizedDate != null &&
                      _selectedDate != null &&
                      normalizedDate.year == _selectedDate!.year &&
                      normalizedDate.month == _selectedDate!.month &&
                      normalizedDate.day == _selectedDate!.day;
                  final isToday =
                      normalizedDate != null &&
                      normalizedDate.year == normalizedNow.year &&
                      normalizedDate.month == normalizedNow.month &&
                      normalizedDate.day == normalizedNow.day;

                  if (!isCurrentMonth) {
                    return const Expanded(child: SizedBox());
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: isAvailable
                          ? () {
                              setState(() {
                                _selectedDate = normalizedDate;
                                _selectedTimeSlot = null;
                              });
                            }
                          : null,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: context.responsive.spacing(2.0),
                        ),
                        height: context.responsive.spacing(40.0),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.transparent,
                          borderRadius: BorderRadius.circular(
                            context.responsive.borderRadius(10.0),
                          ),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: context.responsive.fontSize(14.0),
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : isAvailable
                                      ? AppColors.textPrimary
                                      : AppColors.gray400,
                                ),
                              ),
                              if (isAvailable && !isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.info,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    final slots =
        _timeSlotsByDate[_normalizeDate(_selectedDate!).toString()] ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: context.responsive.spacing(12.0),
        mainAxisSpacing: context.responsive.spacing(12.0),
        childAspectRatio: 2.8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = _selectedTimeSlot == slot;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeSlot = slot;
            });
          },
          child: Container(
            padding: context.responsive.padding(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(
                context.responsive.borderRadius(12.0),
              ),
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                slot,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.responsive.fontSize(13.0),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    final isValid = _selectedDate != null && _selectedTimeSlot != null;
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: const BoxDecoration(color: AppColors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected date/time summary
          if (_selectedDate != null && _selectedTimeSlot != null)
            Container(
              padding: context.responsive.padding(vertical: 14, horizontal: 16),
              margin: EdgeInsets.only(bottom: context.responsive.spacing(12.0)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  context.responsive.borderRadius(12.0),
                ),
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
                  Icon(
                    Icons.event_available_outlined,
                    color: AppColors.primary,
                    size: context.responsive.iconSize(20.0),
                  ),
                  context.responsive.widthBox(10.0),
                  Expanded(
                    child: Text(
                      '${DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)} • $_selectedTimeSlot',
                      style: TextStyle(
                        fontSize: context.responsive.fontSize(14.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: context.responsive.buttonHeight(50.0),
            child: ElevatedButton(
              onPressed: isValid
                  ? () {
                      widget.formData.selectedDate = _selectedDate;
                      widget.formData.selectedTimeSlot = _selectedTimeSlot;
                      widget.onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid
                    ? AppColors.primary
                    : AppColors.divider,
                elevation: isValid ? 2 : 0,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: context.responsive.padding(vertical: 14),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: isValid ? AppColors.white : AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
