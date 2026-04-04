import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../theme/app_header_config.dart';
import '../../../../utils/responsive_utils.dart';

/// The full (expanded) home header shown at the top of the Home tab.
///
/// Contains the user avatar, selected home name with dropdown, greeting,
/// and the search bar. Pass the required state & callbacks from the parent.
class HomeHeaderSection extends ConsumerWidget {
  /// The current home name displayed in the header.
  final String selectedHomeName;

  /// The address line shown below the home name.
  final String selectedHomeAddress;

  /// Current search query text (used to toggle between hint and text field).
  final String homeSearchQuery;

  /// Controller for the search [TextField].
  final TextEditingController homeSearchController;

  /// Focus node for the search [TextField].
  final FocusNode homeSearchFocusNode;

  /// Number of unread notifications – drives the badge dot.
  final int unreadCount;

  /// Called when the user taps the search bar or types.
  final ValueChanged<String> onSearchChanged;

  /// Called when the notification bell is tapped.
  final VoidCallback onNotificationTap;

  /// Called when the drawer avatar is tapped.
  final VoidCallback onDrawerTap;

  /// Called when the home-name dropdown is tapped.
  final VoidCallback onHomeNameTap;

  /// Optional max height constraint. When provided the content is clipped.
  final double? maxHeight;

  const HomeHeaderSection({
    super.key,
    required this.selectedHomeName,
    required this.selectedHomeAddress,
    required this.homeSearchQuery,
    required this.homeSearchController,
    required this.homeSearchFocusNode,
    required this.unreadCount,
    required this.onSearchChanged,
    required this.onNotificationTap,
    required this.onDrawerTap,
    required this.onHomeNameTap,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final responsive = ResponsiveUtils(context);
    final profile = ref.watch(userProfileProvider);

    // Time-based greeting
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : hour < 21
                ? 'Good Evening'
                : 'Good Night';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row with Profile and Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Profile Section
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: onDrawerTap,
                        child: ProfileAvatar(
                          size: isSmallScreen ? 36.0 : 42.0,
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                          backgroundColor: AppColors.textOnPrimary.withValues(
                            alpha: 0.24,
                          ),
                          textColor: AppColors.textOnPrimary,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: isSmallScreen ? 8.0 : 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: onHomeNameTap,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  selectedHomeName,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14.0 : 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textOnPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Icon(
                                Icons.expand_more,
                                color: AppColors.textOnPrimary,
                                size: isSmallScreen ? 18.0 : 20.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          selectedHomeAddress,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11.0 : 13.0,
                            color: AppColors.textOnPrimary.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Notification Bell
            GestureDetector(
              onTap: onNotificationTap,
              child: Stack(
                children: [
                  Container(
                    width: isSmallScreen ? 36.0 : 42.0,
                    height: isSmallScreen ? 36.0 : 42.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textOnPrimary.withValues(alpha: 0.24),
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      color: AppColors.textOnPrimary,
                      size: isSmallScreen ? 18.0 : 22.0,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: responsive.spacing(12.0),
                        height: responsive.spacing(12.0),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(12.0)),
        // Greeting
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$greeting, ${profile.getFirstName()}',
            style: TextStyle(
              fontSize: responsive.fontSize(32.0),
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(4.0)),
        Text(
          'How can I help you today?',
          style: TextStyle(
            fontSize: responsive.fontSize(16.0),
            color: AppColors.textOnPrimary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: responsive.spacing(20.0)),
        // Search Bar
        _buildSearchBar(context, responsive),
      ],
    );

    // If maxHeight is provided, wrap in ConstrainedBox to prevent overflow
    if (maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!, minHeight: 0),
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildSearchBar(BuildContext context, ResponsiveUtils responsive) {
    return GestureDetector(
      onTap: () {
        homeSearchFocusNode.requestFocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: responsive.spacing(8.0),
              offset: Offset(0, responsive.spacing(2.0)),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16.0),
          vertical: responsive.spacing(16.0),
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
              child: homeSearchQuery.isEmpty
                  ? Text(
                      'Search services...',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        color: AppColors.textPlaceholder,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : TextField(
                      controller: homeSearchController,
                      focusNode: homeSearchFocusNode,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(16.0),
                          color: AppColors.textPlaceholder,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
            GestureDetector(
              onTap: () {
                if (homeSearchQuery.isEmpty) {
                  homeSearchFocusNode.requestFocus();
                } else {
                  onSearchChanged('');
                }
              },
              child: Icon(
                homeSearchQuery.isEmpty ? Icons.send : Icons.clear,
                color: homeSearchQuery.isEmpty
                    ? AppColors.primary
                    : AppColors.textPlaceholder,
                size: responsive.iconSize(20.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The compact (collapsed) home header shown after scrolling down.
///
/// Shows the user avatar, selected home name with dropdown, and the
/// notification bell in a single row.
class HomeCompactHeader extends StatelessWidget {
  /// The current home name displayed in the compact header.
  final String selectedHomeName;

  /// Number of unread notifications – drives the badge dot.
  final int unreadCount;

  /// Called when the notification bell is tapped.
  final VoidCallback onNotificationTap;

  /// Called when the drawer avatar is tapped.
  final VoidCallback onDrawerTap;

  /// Called when the home-name dropdown is tapped.
  final VoidCallback onHomeNameTap;

  const HomeCompactHeader({
    super.key,
    required this.selectedHomeName,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.onDrawerTap,
    required this.onHomeNameTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive font size - smaller on smaller screens to prevent overflow
    final homeFontSize = screenWidth < 360
        ? 16.0
        : screenWidth < 400
        ? 18.0
        : 20.0;

    return SizedBox(
      height: AppHeaderConfig.compactHeaderHeight, // 32 px — matches maintenance/assets/services tab content height
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Section - Simplified
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: onDrawerTap,
                      child: ProfileAvatar(
                        size: responsive.iconSize(40.0),
                        fontSize: responsive.fontSize(14.0),
                        backgroundColor: AppColors.textOnPrimary.withValues(
                          alpha: 0.24,
                        ),
                        textColor: AppColors.textOnPrimary,
                      ),
                    );
                  },
                ),
                SizedBox(width: responsive.spacing(10.0)),
                Expanded(
                  child: GestureDetector(
                    onTap: onHomeNameTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            selectedHomeName,
                            style: TextStyle(
                              fontSize: responsive.fontSize(homeFontSize),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: responsive.spacing(4.0)),
                        Icon(
                          Icons.expand_more,
                          color: AppColors.textOnPrimary,
                          size: responsive.iconSize(20.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notification Bell - Smaller to fit in compact header
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: responsive.iconSize(40.0),
                  height: responsive.iconSize(40.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textOnPrimary.withValues(alpha: 0.24),
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    color: AppColors.textOnPrimary,
                    size: responsive.iconSize(24.0),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: responsive.iconSize(8.0),
                      height: responsive.iconSize(8.0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animates between [HomeHeaderSection] (full) and [HomeCompactHeader]
/// based on [scrollProgress] (0.0 = full, 1.0 = compact).
class HomeHeaderWithTransition extends StatelessWidget {
  /// 0.0 → full header, 1.0 → compact header.
  final double scrollProgress;

  /// Available pixel height the header can occupy.
  final double availableHeight;

  /// The current home name.
  final String selectedHomeName;

  /// The current home address.
  final String selectedHomeAddress;

  /// Current search query.
  final String homeSearchQuery;

  /// Controller for the search field.
  final TextEditingController homeSearchController;

  /// Focus node for the search field.
  final FocusNode homeSearchFocusNode;

  /// Number of unread notifications.
  final int unreadCount;

  /// Called on search text change.
  final ValueChanged<String> onSearchChanged;

  /// Called when the notification bell is tapped.
  final VoidCallback onNotificationTap;

  /// Called when the drawer avatar is tapped.
  final VoidCallback onDrawerTap;

  /// Called when the home-name dropdown is tapped.
  final VoidCallback onHomeNameTap;

  const HomeHeaderWithTransition({
    super.key,
    required this.scrollProgress,
    required this.availableHeight,
    required this.selectedHomeName,
    required this.selectedHomeAddress,
    required this.homeSearchQuery,
    required this.homeSearchController,
    required this.homeSearchFocusNode,
    required this.unreadCount,
    required this.onSearchChanged,
    required this.onNotificationTap,
    required this.onDrawerTap,
    required this.onHomeNameTap,
  });

  @override
  Widget build(BuildContext context) {
    final transitionCurve = Curves.easeInOutCubic.transform(scrollProgress);

    if (scrollProgress < 0.05) {
      return HomeHeaderSection(
        selectedHomeName: selectedHomeName,
        selectedHomeAddress: selectedHomeAddress,
        homeSearchQuery: homeSearchQuery,
        homeSearchController: homeSearchController,
        homeSearchFocusNode: homeSearchFocusNode,
        unreadCount: unreadCount,
        onSearchChanged: onSearchChanged,
        onNotificationTap: onNotificationTap,
        onDrawerTap: onDrawerTap,
        onHomeNameTap: onHomeNameTap,
        maxHeight: availableHeight,
      );
    }

    if (scrollProgress > 0.95) {
      return HomeCompactHeader(
        selectedHomeName: selectedHomeName,
        unreadCount: unreadCount,
        onNotificationTap: onNotificationTap,
        onDrawerTap: onDrawerTap,
        onHomeNameTap: onHomeNameTap,
      );
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: (1 - transitionCurve).clamp(0.0, 1.0),
            child: IgnorePointer(
              ignoring: transitionCurve > 0.3,
              child: HomeHeaderSection(
                selectedHomeName: selectedHomeName,
                selectedHomeAddress: selectedHomeAddress,
                homeSearchQuery: homeSearchQuery,
                homeSearchController: homeSearchController,
                homeSearchFocusNode: homeSearchFocusNode,
                unreadCount: unreadCount,
                onSearchChanged: onSearchChanged,
                onNotificationTap: onNotificationTap,
                onDrawerTap: onDrawerTap,
                onHomeNameTap: onHomeNameTap,
                maxHeight: availableHeight,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: transitionCurve.clamp(0.0, 1.0),
            child: IgnorePointer(
              ignoring: transitionCurve < 0.7,
              child: HomeCompactHeader(
                selectedHomeName: selectedHomeName,
                unreadCount: unreadCount,
                onNotificationTap: onNotificationTap,
                onDrawerTap: onDrawerTap,
                onHomeNameTap: onHomeNameTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
