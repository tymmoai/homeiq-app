import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class ServicesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const ServicesSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(16.0),
        vertical: MediaQuery.of(context).size.height < 700
            ? responsive.spacing(10.0)
            : responsive.spacing(16.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            color: AppColors.textPlaceholder,
            size: responsive.iconSize(20.0),
          ),
          SizedBox(width: responsive.spacing(12.0)),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search services...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintStyle: TextStyle(
                  fontSize: responsive.fontSize(16.0),
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: TextStyle(
                fontSize: responsive.fontSize(16.0),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Handle send action
            },
            child: Icon(
              Icons.send,
              color: AppColors.primary,
              size: responsive.iconSize(20.0),
            ),
          ),
        ],
      ),
    );
  }
}
