import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/data_providers.dart';
import '../../../../providers/home_selection_provider.dart';
import '../../../../providers/user_profile_provider.dart';

class DrawerWidget extends ConsumerWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isOwner = ref.watch(selectedHomeIsOwnerProvider);
    final grantedSvcAsync = ref.watch(grantedServiceTypesProvider);
    final grantedSvc = grantedSvcAsync.valueOrNull;

    /// Returns true if the current user has access to [serviceType].
    /// Owners always have access. Family members need explicit grant.
    /// While still loading (no value), fail-open to not hide items.
    bool hasAccess(String serviceType) {
      if (isOwner) return true;
      if (!grantedSvcAsync.hasValue) return true; // loading → show
      return grantedSvc?.contains(serviceType) ?? false;
    }

    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(
                  size: 70,
                  fontSize: 28,
                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
                  textColor: AppColors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                // Role badge for family members
                if (!isOwner) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Family Member',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                // My Orders — requires 'orders' service type
                if (hasAccess('orders'))
                  _buildDrawerItem(
                    context,
                    icon: Icons.shopping_bag,
                    title: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/orders');
                    },
                  ),
                // My Services — requires 'bookings' service type
                if (hasAccess('bookings'))
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_repair_service,
                    title: 'My Services',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/service-history');
                    },
                  ),
                // Family Members management — owners only
                if (isOwner)
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: 'Family Members',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/family-members');
                    },
                  ),
                // My Family Access — family members only
                if (!isOwner)
                  _buildDrawerItem(
                    context,
                    icon: Icons.family_restroom,
                    title: 'My Family Access',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/my-family-access');
                    },
                  ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                const Divider(height: 1),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Log out',
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log out'),
                        content: const Text(
                          'Are you sure you want to log out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              // Clear auth state — GoRouter redirect handles navigation.
                              final container = ProviderScope.containerOf(
                                context,
                              );
                              await container
                                  .read(authProvider.notifier)
                                  .logout();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Log out'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}
