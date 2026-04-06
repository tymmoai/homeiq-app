import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingScheduleStep extends StatelessWidget {
  final String dateSelectionType;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final List<String> timeSlots;
  final void Function(String type, DateTime date) onDateOptionSelected;
  final ValueChanged<DateTime> onCustomDatePicked;
  final ValueChanged<String> onTimeSlotSelected;

  const BookingScheduleStep({
    super.key,
    required this.dateSelectionType,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.timeSlots,
    required this.onDateOptionSelected,
    required this.onCustomDatePicked,
    required this.onTimeSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final customDates = List.generate(
      14,
      (i) => today.add(Duration(days: i + 2)),
    );
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
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

    String formatQuickDate(DateTime date) {
      return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you need this service?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a date and time slot',
          style: TextStyle(
            fontSize: 14,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Quick Date Selection - Today/Tomorrow/Custom
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Today Option
        GestureDetector(
          onTap: () => onDateOptionSelected('today', today),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
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
              border: dateSelectionType == 'today'
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dateSelectionType == 'today'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundGray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.today_outlined,
                    color: dateSelectionType == 'today'
                        ? AppColors.primary
                        : AppColors.gray600,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dateSelectionType == 'today'
                              ? AppColors.primary
                              : AssetDetailColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatQuickDate(today),
                        style: TextStyle(
                          fontSize: 13,
                          color: AssetDetailColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dateSelectionType == 'today'
                          ? AppColors.primary
                          : AppColors.gray300,
                      width: 2,
                    ),
                    color: dateSelectionType == 'today'
                        ? AppColors.primary
                        : AppColors.white,
                  ),
                  child: dateSelectionType == 'today'
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Tomorrow Option
        GestureDetector(
          onTap: () => onDateOptionSelected('tomorrow', tomorrow),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
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
              border: dateSelectionType == 'tomorrow'
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dateSelectionType == 'tomorrow'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundGray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_outlined,
                    color: dateSelectionType == 'tomorrow'
                        ? AppColors.primary
                        : AppColors.gray600,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tomorrow',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dateSelectionType == 'tomorrow'
                              ? AppColors.primary
                              : AssetDetailColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatQuickDate(tomorrow),
                        style: TextStyle(
                          fontSize: 13,
                          color: AssetDetailColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dateSelectionType == 'tomorrow'
                          ? AppColors.primary
                          : AppColors.gray300,
                      width: 2,
                    ),
                    color: dateSelectionType == 'tomorrow'
                        ? AppColors.primary
                        : AppColors.white,
                  ),
                  child: dateSelectionType == 'tomorrow'
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Custom Date Option
        GestureDetector(
          onTap: () {
            // Determine the date to use when switching to custom
            DateTime customDate;
            if (selectedDate == null ||
                selectedDate!.day == today.day ||
                selectedDate!.day == tomorrow.day) {
              customDate = customDates.first;
            } else {
              customDate = selectedDate!;
            }
            onDateOptionSelected('custom', customDate);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
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
              border: dateSelectionType == 'custom'
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dateSelectionType == 'custom'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundGray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: dateSelectionType == 'custom'
                        ? AppColors.primary
                        : AppColors.gray600,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a Date',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dateSelectionType == 'custom'
                              ? AppColors.primary
                              : AssetDetailColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateSelectionType == 'custom' && selectedDate != null
                            ? formatQuickDate(selectedDate!)
                            : 'Select from calendar',
                        style: TextStyle(
                          fontSize: 13,
                          color: AssetDetailColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dateSelectionType == 'custom'
                          ? AppColors.primary
                          : AppColors.gray300,
                      width: 2,
                    ),
                    color: dateSelectionType == 'custom'
                        ? AppColors.primary
                        : AppColors.white,
                  ),
                  child: dateSelectionType == 'custom'
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Custom Date Picker (shown when custom is selected)
        if (dateSelectionType == 'custom') ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: customDates.length,
              itemBuilder: (context, index) {
                final date = customDates[index];
                final isSelected =
                    selectedDate?.day == date.day &&
                    selectedDate?.month == date.month &&
                    selectedDate?.year == date.year;

                return GestureDetector(
                  onTap: () => onCustomDatePicked(date),
                  child: Container(
                    width: 65,
                    margin: EdgeInsets.only(
                      right: index < customDates.length - 1 ? 10 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          days[date.weekday % 7],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.8)
                                : AssetDetailColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.white
                                : AssetDetailColors.textPrimary,
                          ),
                        ),
                        Text(
                          months[date.month - 1],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.8)
                                : AssetDetailColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 28),

        // Time Slot Selection
        Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final slot = timeSlots[index];
            final isSelected = selectedTimeSlot == slot;
            return GestureDetector(
              onTap: () => onTimeSlotSelected(slot),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.gray300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Estimated Duration
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.access_time, color: AppColors.amber, size: 20),
              SizedBox(width: 12),
              Text(
                'Estimated duration: 1-2 hours',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.amber,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
