import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';
import './lifestyle_booking_flow.dart';

class LifestyleStep3Schedule extends StatefulWidget {
  final LifestyleBookingFormData formData;
  final String categoryName;
  final int totalSteps;
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LifestyleStep3Schedule({
    super.key,
    required this.formData,
    required this.categoryName,
    required this.totalSteps,
    required this.currentStep,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<LifestyleStep3Schedule> createState() => _LifestyleStep3ScheduleState();
}

class _LifestyleStep3ScheduleState extends State<LifestyleStep3Schedule> {
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
        if (now.hour < 18) slots.add('04:00 PM - 06:00 PM');
        if (now.hour < 20) slots.add('06:00 PM - 08:00 PM');
      } else {
        slots.addAll([
          '08:00 AM - 10:00 AM',
          '10:00 AM - 12:00 PM',
          '12:00 PM - 02:00 PM',
          '02:00 PM - 04:00 PM',
          '04:00 PM - 06:00 PM',
          '06:00 PM - 08:00 PM',
        ]);
      }

      final key =
          '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';
      _timeSlotsByDate[key] = slots;
    }
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
        _buildHeader(),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select time slot',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a convenient time for your service.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCalendarGrid(),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Available Time Slots for ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlots(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final responsive = ResponsiveUtils(context);
    final now = DateTime.now();
    final currentMonth = _calendarMonth;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(currentMonth)} ${currentMonth.year}',
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed:
                        currentMonth.month == now.month &&
                            currentMonth.year == now.year
                        ? null
                        : () {
                            setState(() {
                              _calendarMonth = DateTime(
                                currentMonth.year,
                                currentMonth.month - 1,
                              );
                            });
                          },
                    icon: const Icon(Icons.chevron_left_outlined),
                    iconSize: responsive.iconSize(24),
                    color: AppColors.primary,
                    disabledColor: AppColors.gray300,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(
                          currentMonth.year,
                          currentMonth.month + 1,
                        );
                      });
                    },
                    icon: const Icon(Icons.chevron_right_outlined),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeekDaysHeader(),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: startingWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startingWeekday) {
                return const SizedBox();
              }

              final day = index - startingWeekday + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final normalizedNow = DateTime(now.year, now.month, now.day);
              final isPast = normalizedDate.isBefore(normalizedNow);
              final isToday = normalizedDate == normalizedNow;
              final isSelected =
                  _selectedDate != null &&
                  normalizedDate ==
                      DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day,
                      );

              return _buildDateCell(
                day,
                date,
                isPast,
                isToday,
                isSelected,
                normalizedDate,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDateCell(
    int day,
    DateTime date,
    bool isPast,
    bool isToday,
    bool isSelected,
    DateTime normalizedDate,
  ) {
    return GestureDetector(
      onTap: isPast
          ? null
          : () {
              setState(() {
                _selectedDate = normalizedDate;
                _selectedTimeSlot = null;
                widget.formData.selectedDate = normalizedDate;
                widget.formData.selectedTimeSlot = null;
              });
            },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary05
              : isToday
              ? AppColors.primary10
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected || isToday
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: isPast
                  ? AppColors.gray400
                  : isSelected
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_selectedDate == null) return const SizedBox();

    final responsive = ResponsiveUtils(context);
    final key =
        '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}';
    final slots = _timeSlotsByDate[key] ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = _selectedTimeSlot == slot;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeSlot = slot;
              widget.formData.selectedTimeSlot = slot;
            });
          },
          child: Container(
            padding: responsive.padding(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: responsive.spacing(8.0),
                        offset: Offset(0, responsive.spacing(2.0)),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                slot,
                style: TextStyle(
                  fontSize: 13,
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

  bool _canContinue() {
    return _selectedDate != null && _selectedTimeSlot != null;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.arrow_back_outlined,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMinimalStepper(widget.currentStep),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.close_outlined,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper(int currentStep) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(widget.totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isCurrent = stepNumber == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              if (index < widget.totalSteps - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton() {
    final bool canContinue = _canContinue();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canContinue ? widget.onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}