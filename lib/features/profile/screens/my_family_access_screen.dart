// My Family Access Screen — shows the logged-in user's own family memberships
// and the specific assets / services they have been granted access to.
//
// Navigated to after accepting a family invite so the member sees THEIR OWN
// restricted profile rather than the owner's full home view.

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/family_models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../services/family_api_service.dart';
import '../../../utils/responsive_utils.dart';

class MyFamilyAccessScreen extends ConsumerStatefulWidget {
  const MyFamilyAccessScreen({super.key});

  @override
  ConsumerState<MyFamilyAccessScreen> createState() =>
      _MyFamilyAccessScreenState();
}

class _MyFamilyAccessScreenState extends ConsumerState<MyFamilyAccessScreen> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  bool _isLoading = true;
  String? _loadError;
  List<MyMembershipDto> _memberships = [];

  @override
  void initState() {
    super.initState();
    _loadMyAccess();
  }

  Future<void> _loadMyAccess() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final memberships = await FamilyApiService.instance.getMyAccess();
      if (mounted) {
        setState(() {
          _memberships = memberships;
          _isLoading = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Failed to load your access. Pull down to refresh.';
        });
      }
    }
  }

  /// Lets the member voluntarily leave a home, calls DELETE /family/leave/:id,
  /// and invalidates all affected providers so the app state is immediately consistent.
  Future<void> _leaveHome(MyMembershipDto membership) async {
    final homeName =
        membership.home?.displayName ?? 'this home';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Home'),
        content: Text(
          'Are you sure you want to leave "$homeName"? '
          'You will lose all access and need a new invite to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave Home'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await FamilyApiService.instance.leaveHome(membership.id);
      // Invalidate all home/access providers so state reflects the departure.
      ref.invalidate(homesProvider);
      ref.invalidate(homeSelectionProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(grantedServiceTypesProvider);
      ref.invalidate(grantedAssetIdsProvider);
      ref.invalidate(myPendingInvitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have left "$homeName"'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/home');
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave home: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Select the given home in the app and navigate to the main home screen.
  Future<void> _openHome(MyMembershipDto membership) async {
    // Select by ID \u2014 this reliably refreshes the home list if it isn\u2019t
    // loaded yet (e.g. right after the very first accept-invite).
    await ref
        .read(homeSelectionProvider.notifier)
        .selectHomeById(membership.homeId);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.white,
            size: responsive.iconSize(24.0),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'My Family Access',
          style: TextStyle(
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMyAccess,
              child: _loadError != null
                  ? _buildErrorState(responsive)
                  : _memberships.isEmpty
                  ? _buildEmptyState(responsive)
                  : _buildMembershipList(responsive),
            ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState(ResponsiveUtils responsive) {
    return ListView(
      padding: EdgeInsets.all(responsive.spacing(32.0)),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: responsive.iconSize(48.0), color: AppColors.gray300),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMyAccess,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(ResponsiveUtils responsive) {
    return ListView(
      padding: EdgeInsets.all(responsive.spacing(32.0)),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: responsive.spacing(80.0),
                height: responsive.spacing(80.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.home_outlined,
                  size: responsive.iconSize(40.0),
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Family Access Yet',
                style: TextStyle(
                  fontSize: responsive.fontSize(20.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You haven\'t been added to any family home yet.\nAsk the home owner to send you an invite.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(32.0),
                    vertical: responsive.spacing(14.0),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go to My Home'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Membership List ─────────────────────────────────────────────────────

  Widget _buildMembershipList(ResponsiveUtils responsive) {
    return ListView(
      padding: EdgeInsets.only(
        left: responsive.spacing(16.0),
        right: responsive.spacing(16.0),
        top: responsive.spacing(16.0),
        bottom: responsive.spacing(32.0),
      ),
      children: [
        // Intro card
        _buildIntroCard(responsive),
        SizedBox(height: responsive.spacing(16.0)),

        // One card per home — all in a vertical list
        for (final membership in _memberships) ...[
          _buildMembershipCard(membership, responsive),
          SizedBox(height: responsive.spacing(16.0)),
        ],
      ],
    );
  }

  Widget _buildIntroCard(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16.0)),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, color: _primaryColor, size: responsive.iconSize(28.0)),
          SizedBox(width: responsive.spacing(12.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_memberships.length} Home${_memberships.length != 1 ? 's' : ''} You Can Access',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15.0),
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Below are the homes you\'ve been invited to and exactly what you can access.',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12.0),
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Single Membership Card ───────────────────────────────────────────────

  Widget _buildMembershipCard(
    MyMembershipDto membership,
    ResponsiveUtils responsive,
  ) {
    final home = membership.home;
    // Title: home name if set, otherwise address
    final homeName = home?.displayName ?? 'Unknown Home';
    // Subtitle: show address separately when a custom name is set
    final homeAddress =
        (home != null && home.name != null && home.name!.isNotEmpty)
        ? '${home.address}, ${home.city}'
        : null;
    final homeLocation = home != null ? '${home.city}, ${home.state}' : '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Home header ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(responsive.spacing(16.0)),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: responsive.spacing(44.0),
                  height: responsive.spacing(44.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    Icons.home,
                    color: AppColors.white,
                    size: responsive.iconSize(24.0),
                  ),
                ),
                SizedBox(width: responsive.spacing(12.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeName,
                        style: TextStyle(
                          fontSize: responsive.fontSize(16.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (homeAddress != null)
                        Text(
                          homeAddress,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12.0),
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (homeLocation.isNotEmpty)
                        Text(
                          homeLocation,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12.0),
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                // Role badge
                _buildRoleBadge(membership.role, responsive),
              ],
            ),
          ),

          // ── Body content ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(responsive.spacing(16.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Relation row
                if (membership.relation != null &&
                    membership.relation!.isNotEmpty) ...[
                  _buildInfoRow(
                    icon: Icons.people_outlined,
                    label: 'Relation',
                    value: membership.relation!,
                    responsive: responsive,
                  ),
                  SizedBox(height: responsive.spacing(12.0)),
                ],

                // Assets section
                _buildAccessSection(
                  icon: Icons.devices_outlined,
                  title: 'Assets You Can View',
                  emptyText: 'No asset access granted',
                  chips: membership.assetAccess.map((entry) {
                    return entry.asset?.name ?? entry.assetId;
                  }).toList(),
                  responsive: responsive,
                ),

                SizedBox(height: responsive.spacing(12.0)),

                // Services section
                _buildAccessSection(
                  icon: Icons.miscellaneous_services_outlined,
                  title: 'Services You Can Access',
                  emptyText: 'No service access granted',
                  chips: membership.serviceAccess
                      .map((s) => FamilyServiceTypes.label(s.serviceType))
                      .toList(),
                  responsive: responsive,
                  chipColor: const Color(0xFF0D7377),
                ),

                // Quick Access shortcuts
                if (membership.serviceAccess.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(12.0)),
                  _buildQuickAccess(membership, responsive),
                ],

                SizedBox(height: responsive.spacing(14.0)),

                // Open Home button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openHome(membership),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open This Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(13.0),
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: responsive.spacing(8.0)),

                // Leave Home button (only for non-owners)
                if (membership.role != 'owner')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveHome(membership),
                      icon: const Icon(
                        Icons.exit_to_app,
                        size: 18,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Leave This Home',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.spacing(13.0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  // ─── Info Row (label + value) ─────────────────────────────────────────────

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ResponsiveUtils responsive,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: responsive.fontSize(13.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Access Section (assets or services) ─────────────────────────────────

  Widget _buildAccessSection({
    required IconData icon,
    required String title,
    required String emptyText,
    required List<String> chips,
    required ResponsiveUtils responsive,
    Color? chipColor,
  }) {
    final color = chipColor ?? _primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: responsive.iconSize(16.0), color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${chips.length}',
                style: TextStyle(
                  fontSize: responsive.fontSize(11.0),
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        chips.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: responsive.iconSize(14.0), color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      emptyText,
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: chips.map((label) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  // ─── Role Badge ───────────────────────────────────────────────────────────

  Widget _buildRoleBadge(String role, ResponsiveUtils responsive) {
    Color bgColor;
    IconData icon;
    switch (role) {
      case 'owner':
        bgColor = AppColors.white;
        icon = Icons.shield;
        break;
      case 'member':
        bgColor = AppColors.white;
        icon = Icons.people;
        break;
      default:
        bgColor = AppColors.white;
        icon = Icons.visibility;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: responsive.iconSize(12.0), color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            _roleLabel(role),
            style: TextStyle(
              fontSize: responsive.fontSize(11.0),
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'member':
        return 'Member';
      case 'viewer':
        return 'Viewer';
      default:
        return role;
    }
  }

  // ─── Quick Access Shortcuts ───────────────────────────────────────────────
  // Shows small tappable chips for each granted service type so the member
  // can jump directly to that module after opening the home.

  Widget _buildQuickAccess(
    MyMembershipDto membership,
    ResponsiveUtils responsive,
  ) {
    final grantedTypes = membership.serviceAccess
        .map((s) => s.serviceType)
        .toSet();

    // Each entry: (serviceType, label, icon, route/action)
    final shortcuts = <_QuickShortcut>[
      if (grantedTypes.contains('bookings'))
        const _QuickShortcut(
          label: 'Services',
          icon: Icons.build_outlined,
          route: '/service-history',
        ),
      if (grantedTypes.contains('maintenance'))
        const _QuickShortcut(
          label: 'Maintenance',
          icon: Icons.home_repair_service_outlined,
          route: '/maintenance',
        ),
      if (grantedTypes.contains('orders'))
        const _QuickShortcut(
          label: 'My Orders',
          icon: Icons.shopping_bag_outlined,
          route: '/orders',
        ),
      if (grantedTypes.contains('issues'))
        const _QuickShortcut(
          label: 'My Claims',
          icon: Icons.assignment_outlined,
          route: '/my-claims',
        ),
      if (grantedTypes.contains('warranty'))
        const _QuickShortcut(
          label: 'Warranties',
          icon: Icons.verified_outlined,
          route: '/warranties',
        ),
      if (grantedTypes.contains('protection_plans'))
        const _QuickShortcut(
          label: 'Protection',
          icon: Icons.shield_outlined,
          route: null, // opens via asset detail
        ),
    ];

    if (shortcuts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, size: responsive.iconSize(15.0), color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Quick Access',
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shortcuts.map((s) {
            return GestureDetector(
              onTap: s.route != null
                  ? () async {
                      // First open the home, then navigate to the route.
                      await _openHome(membership);
                      if (mounted && s.route != null) {
                        context.push(s.route!);
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.icon, size: responsive.iconSize(14.0), color: _primaryColor),
                    const SizedBox(width: 5),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Helper data class for quick access shortcuts.
class _QuickShortcut {
  final String label;
  final IconData icon;
  final String? route;

  const _QuickShortcut({
    required this.label,
    required this.icon,
    required this.route,
  });
}