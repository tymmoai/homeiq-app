import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../ai_fix_models.dart';

class TechnicianTimeSlotWidget extends StatelessWidget {
  final TechnicianOption? selectedTechnician;
  final DateTime calendarMonth;
  final DateTime? selectedDate;
  final String? selectedSlot;

  /// Helper to check if selected date is before expected delivery date
  bool _isBeforeDeliveryDate(DateTime selectedDate, String expectedDeliveryUS) {
    try {
      final parts = expectedDeliveryUS.split('/');
      if (parts.length != 3) return false;
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final deliveryDate = DateTime(year, month, day);
      return selectedDate.isBefore(deliveryDate);
    } on Object catch (_) {
      return false;
    }
  }
  final bool isStandaloneBooking;
  final bool isCombinedFlow;
  final String? expectedDelivery;
  final void Function(DateTime newMonth) onMonthChanged;
  final void Function(DateTime date) onSelectDate;
  final void Function(String slot) onSelectSlot;
  final VoidCallback onContinue;

  const TechnicianTimeSlotWidget({
    super.key,
    required this.selectedTechnician,
    required this.calendarMonth,
    required this.selectedDate,
    required this.selectedSlot,
    required this.isStandaloneBooking,
    required this.isCombinedFlow,
    required this.expectedDelivery,
    required this.onMonthChanged,
    required this.onSelectDate,
    required this.onSelectSlot,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final tech = selectedTechnician;
    if (tech == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final tech = selectedTechnician!; // ignore: unused_local_variable
    final now = DateTime.now();
    final currentMonth = DateTime(calendarMonth.year, calendarMonth.month);

    DateTime normalizeDate(DateTime date) {
      return DateTime(date.year, date.month, date.day);
    }

    final timeSlotsByDate = {
      normalizeDate(now.add(const Duration(days: 1))): [
        {'time': '10:00 AM - 12:00 PM'},
        {'time': '02:00 PM - 04:00 PM'},
      ],
      normalizeDate(now.add(const Duration(days: 4))): [
        {'time': '01:00 PM - 03:00 PM'},
        {'time': '04:00 PM - 06:00 PM'},
      ],
      normalizeDate(now.add(const Duration(days: 6))): [
        {'time': '09:00 AM - 11:00 AM'},
        {'time': '01:00 PM - 03:00 PM'},
      ],
      normalizeDate(now.add(const Duration(days: 8))): [
        {'time': '10:00 AM - 12:00 PM'},
        {'time': '02:00 PM - 04:00 PM'},
      ],
      normalizeDate(now.add(const Duration(days: 10))): [
        {'time': '09:00 AM - 11:00 AM'},
        {'time': '01:00 PM - 03:00 PM'},
        {'time': '04:00 PM - 06:00 PM'},
      ],
      normalizeDate(now.add(const Duration(days: 12))): [
        {'time': '10:00 AM - 12:00 PM'},
      ],
    };

    String formatDate(DateTime date) {
      return '${date.month}/${date.day}/${date.year}';
    }

    String getMonthName(DateTime date) {
      final months = [
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

    Widget buildCalendarGrid() {
      final firstDayOfMonth = DateTime(
        currentMonth.year,
        currentMonth.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
      );
      final firstDayWeekday = firstDayOfMonth.weekday;
      final daysInMonth = lastDayOfMonth.day;

      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return Container(
        padding: EdgeInsets.all(responsive.spacing(16)),
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Month header with navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      onMonthChanged(
                        DateTime(currentMonth.year, currentMonth.month - 1),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    '${getMonthName(currentMonth)} ${currentMonth.year}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      onMonthChanged(
                        DateTime(currentMonth.year, currentMonth.month + 1),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(16)),
              // Week day headers
              LayoutBuilder(
                builder: (context, constraints) {
                  final dayWidth = constraints.maxWidth / 7;
                  return Row(
                    children: weekDays.map((day) {
                      return SizedBox(
                        width: dayWidth,
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: responsive.spacing(8)),
              // Calendar days
              ...List.generate(6, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dayWidth = constraints.maxWidth / 7;
                      return Row(
                        children: List.generate(7, (dayIndex) {
                          final dayNumber =
                              (weekIndex * 7) +
                              dayIndex -
                              (firstDayWeekday - 1) +
                              1;
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
                              ? normalizeDate(date)
                              : null;
                          final normalizedNow = normalizeDate(now);
                          final isAvailable =
                              normalizedDate != null &&
                              !normalizedDate.isBefore(normalizedNow) &&
                              timeSlotsByDate.containsKey(normalizedDate);
                          final isSelected =
                              normalizedDate != null &&
                              selectedDate != null &&
                              normalizedDate.year == selectedDate!.year &&
                              normalizedDate.month == selectedDate!.month &&
                              normalizedDate.day == selectedDate!.day;
                          final isToday =
                              normalizedDate != null &&
                              normalizedDate.year == normalizedNow.year &&
                              normalizedDate.month == normalizedNow.month &&
                              normalizedDate.day == normalizedNow.day;

                          if (!isCurrentMonth) {
                            return SizedBox(width: dayWidth);
                          }

                          return SizedBox(
                            width: dayWidth,
                            child: InkWell(
                              onTap: isAvailable
                                  ? () {
                                      onSelectDate(normalizedDate);
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : isToday
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                                  border: isToday && !isSelected
                                      ? Border.all(
                                          color: AppColors.primary,
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$dayNumber',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(14),
                                          fontWeight: isSelected || isToday
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : isAvailable
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary
                                                    .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      if (isAvailable && !isSelected)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
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
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'Choose a convenient time for the technician visit.',
          style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textSecondary),
        ),
        SizedBox(height: responsive.spacing(16)),

        // Expected Parts Delivery Info Card (for combined flow) - COMPACT
        if (isCombinedFlow && expectedDelivery != null) ...[
          Container(
            padding: EdgeInsets.symmetric(vertical: responsive.spacing(8), horizontal: responsive.spacing(12)),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(responsive.spacing(6)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: responsive.iconSize(16),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: responsive.spacing(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Parts Delivery',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        expectedDelivery!,
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(12)),
        ],

        // Calendar
        buildCalendarGrid(),

        // Time slots for selected date
        if (selectedDate != null) ...[
          SizedBox(height: responsive.spacing(20)),
          // Date header row
          Text(
            'Available Time Slots for ${formatDate(selectedDate!)}',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(12)),
          if (!isStandaloneBooking &&
              expectedDelivery != null &&
              _isBeforeDeliveryDate(selectedDate!, expectedDelivery!))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  border: Border.all(color: Colors.orange.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: responsive.iconSize(18),
                      color: Colors.orange.shade700,
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    Flexible(
                      child: Text(
                        'Part Arrival: $expectedDelivery',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Time slots in 2-column grid layout like service screen
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
            ),
            itemCount:
                (timeSlotsByDate[normalizeDate(selectedDate!)] ?? []).length,
            itemBuilder: (context, index) {
              final slots = timeSlotsByDate[normalizeDate(selectedDate!)] ?? [];
              final slot = slots[index];
              final slotTime = slot['time'] as String;
              final isSelected =
                  selectedSlot == '${formatDate(selectedDate!)} at $slotTime';

              return GestureDetector(
                onTap: () {
                  onSelectSlot('${formatDate(selectedDate!)} at $slotTime');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      slotTime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        // Selected date/time summary (button will be positioned by main screen at 10% from bottom)
        if (selectedDate != null && selectedSlot != null) ...[
          SizedBox(height: responsive.spacing(12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: responsive.spacing(14), horizontal: responsive.spacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                  size: responsive.iconSize(20),
                ),
                SizedBox(width: responsive.spacing(10)),
                Flexible(
                  child: Text(
                    selectedSlot!,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
// Bottom spacing for floating button
          SizedBox(height: responsive.spacing(80)),
        ],
      ],
    );
  }
}