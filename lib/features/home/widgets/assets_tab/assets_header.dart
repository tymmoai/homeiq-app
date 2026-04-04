import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class AssetsHeader extends StatelessWidget {
  const AssetsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'My Assets',
          style: TextStyle(
            fontSize: responsive.fontSize(24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textOnPrimary,
            letterSpacing: -0.3,
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.more_vert,
            color: AppColors.textOnPrimary,
            size: responsive.iconSize(24.0),
          ),
          color: Colors.white,
          offset: const Offset(0, 40),
          onSelected: (value) {
            if (value == 'claims') {
              context.push('/my-claims');
            } else if (value == 'orders') {
              context.push('/orders');
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'claims',
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: responsive.iconSize(20.0),
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Text(
                    'My Claims',
                    style: TextStyle(
                      fontSize: responsive.fontSize(15.0),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'orders',
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: responsive.iconSize(20.0),
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Text(
                    'My Orders',
                    style: TextStyle(
                      fontSize: responsive.fontSize(15.0),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
