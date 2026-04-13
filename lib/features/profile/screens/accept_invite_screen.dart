// Accept Invite Screen â€” shown when a user taps an invite link / views their pending invites.

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/family_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../services/family_api_service.dart';
import '../../../utils/responsive_utils.dart';

class AcceptInviteScreen extends ConsumerStatefulWidget {
  /// Pre-loaded invite (when navigating from My Invites list).
  final MyInviteDto? invite;


  /// Direct token (e.g. deep link).
  final String? token;

  const AcceptInviteScreen({super.key, this.invite, this.token});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  bool _isLoading = false;
  bool _isDeclining = false;
  InvitePreviewDto? _preview;
  bool _isLoadingPreview = false;

  MyInviteDto? get _invite => widget.invite;
  String get _token => widget.invite?.token ?? widget.token ?? '';

  @override
  void initState() {
    super.initState();
    // Always try to fetch a full preview (gives us assetIds + serviceTypes)
    // whether we arrived via a pre-loaded invite or a raw token deep-link.
    if (widget.token != null && widget.token!.isNotEmpty) {
      _fetchPreview();
    } else if (widget.invite != null && widget.invite!.token.isNotEmpty) {
      _fetchPreview();
    }
  }

  Future<void> _fetchPreview() async {
    setState(() => _isLoadingPreview = true);
    try {
      final preview = await FamilyApiService.instance.validateInvite(_token);
      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoadingPreview = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  Future<void> _acceptInvite() async {
    if (_token.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FamilyApiService.instance.acceptInvite(_token);
      // Invalidate all home/asset providers so the new home and its
      // granted assets appear immediately without a cold restart.
      ref.invalidate(homeSelectionProvider);
      ref.invalidate(homesProvider);
      ref.invalidate(assetsProvider);
      // Remove this invite from the pending-invites banner on the home screen.
      ref.invalidate(myPendingInvitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite accepted! You now have access.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/my-family-access');
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invite: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declineInvite() async {
    if (_token.isEmpty) return;
    setState(() => _isDeclining = true);
    try {
      await FamilyApiService.instance.declineInvite(_token);
      ref.invalidate(myPendingInvitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invite declined.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _isDeclining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invite: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isAuthenticated = ref.watch(authProvider) == AuthState.authenticated;

    // Resolve data from whichever source is available
    final MyInviteDto? invite = _invite;
    final InvitePreviewDto? preview = _preview;

    final inviterName = preview?.invitedBy?.name ??
        preview?.invitedBy?.email ??
        invite?.invitedBy?.name ??
        invite?.invitedBy?.email ??
        'Someone';
    final inviterInitial =
        inviterName.isNotEmpty ? inviterName[0].toUpperCase() : '?';
    final String homeName = () {
      final h = preview?.home ?? invite?.home;
      if (h == null) return 'A home';
      if (h.name != null && h.name!.isNotEmpty) return h.name!;
      return '${h.address}, ${h.city}';
    }();
    final String homeAddress = () {
      final h = preview?.home ?? invite?.home;
      if (h == null) return '';
      return '${h.city}, ${h.state}';
    }();

    final role = preview?.role ?? invite?.role ?? 'member';
    final relation = preview?.relation ?? invite?.relation;
    final isExpired =
        preview?.isExpired ?? invite?.isExpired ?? false;
    final isAccepted = preview?.isAccepted ?? false;
    final emailMatch = preview?.emailMatch ?? true;
    final grantFutureAssets = preview?.grantFutureAssets ?? false;
    final serviceTypes = preview?.serviceTypes ?? const <String>[];
    final assetIds = preview?.assetIds ?? const <String>[];

    final canAct = isAuthenticated &&
        !isExpired &&
        !isAccepted &&
        emailMatch &&
        _token.isNotEmpty;

    // Bottom action bar
    Widget bottomBar = const SizedBox.shrink();
    if (isAuthenticated) {
      if (canAct) {
        bottomBar = _buildActionBar(responsive);
      } else if (!isAuthenticated) {
        bottomBar = _buildAuthBar(responsive);
      }
    } else {
      bottomBar = _buildAuthBar(responsive);
    }

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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Family Invite',
          style: TextStyle(
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: false,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.spacing(16),
            responsive.spacing(12),
            responsive.spacing(16),
            responsive.spacing(16),
          ),
          child: bottomBar,
        ),
      ),
      body: SafeArea(
        child: _isLoadingPreview && invite == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(16),
                  vertical: responsive.spacing(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // â”€â”€ Hero banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _buildHero(
                      responsive,
                      inviterName: inviterName,
                      inviterInitial: inviterInitial,
                      homeName: homeName,
                      isExpired: isExpired,
                      isAccepted: isAccepted,
                      emailMatch: emailMatch,
                    ),
                    SizedBox(height: responsive.spacing(16)),

                    // â”€â”€ Status warning â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (isExpired || isAccepted || !emailMatch)
                      _buildStatusBanner(
                        responsive,
                        isExpired: isExpired,
                        isAccepted: isAccepted,
                        emailMatch: emailMatch,
                      ),
                    if (isExpired || isAccepted || !emailMatch)
                      SizedBox(height: responsive.spacing(14)),

                    // â”€â”€ Home card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _buildHomeCard(responsive, homeName: homeName, homeAddress: homeAddress),
                    SizedBox(height: responsive.spacing(14)),

                    // â”€â”€ Details card (role + relation + expiry) â”€â”€â”€â”€â”€
                    _buildDetailsCard(
                      responsive,
                      role: role,
                      relation: relation,
                      expiresAt: preview?.expiresAt ?? invite?.expiresAt,
                    ),
                    SizedBox(height: responsive.spacing(14)),

                    // â”€â”€ Module access â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (serviceTypes.isNotEmpty || grantFutureAssets) ...[
                      _buildModulesCard(responsive, serviceTypes: serviceTypes),
                      SizedBox(height: responsive.spacing(14)),
                    ],

                    // â”€â”€ Asset access â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (assetIds.isNotEmpty || grantFutureAssets) ...[
                      _buildAssetsCard(
                        responsive,
                        assetCount: assetIds.length,
                        grantFutureAssets: grantFutureAssets,
                      ),
                      SizedBox(height: responsive.spacing(14)),
                    ],

                    // â”€â”€ Loading preview shimmer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (_isLoadingPreview && invite != null) ...[
                      _buildShimmerNote(responsive),
                      SizedBox(height: responsive.spacing(14)),
                    ],

                    // Extra space so content isn't hidden behind bottom bar
                    SizedBox(height: responsive.spacing(8)),
                  ],
                ),
              ),
      ),
    );
  }

  // â”€â”€ Hero â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHero(
    ResponsiveUtils responsive, {
    required String inviterName,
    required String inviterInitial,
    required String homeName,
    required bool isExpired,
    required bool isAccepted,
    required bool emailMatch,
  }) {
    final bool hasIssue = isExpired || isAccepted || !emailMatch;
    final Color statusColor = hasIssue ? AppColors.error : AppColors.success;
    final String statusLabel = isExpired
        ? 'Expired'
        : isAccepted
            ? 'Accepted'
            : !emailMatch
                ? 'Wrong Account'
                : 'Pending';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                inviterInitial,
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inviterName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Text(
                  'has invited you to their home',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.white.withValues(alpha: 0.72),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: responsive.fontSize(11),
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Status banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildStatusBanner(
    ResponsiveUtils responsive, {
    required bool isExpired,
    required bool isAccepted,
    required bool emailMatch,
  }) {
    final String message = isExpired
        ? 'This invite has expired and can no longer be accepted.'
        : isAccepted
            ? 'This invite has already been accepted.'
            : 'This invite was sent to a different email address. Please sign in with the correct account.';

    return Container(
      padding: EdgeInsets.all(responsive.spacing(14)),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: responsive.iconSize(20),
            color: AppColors.error,
          ),
          SizedBox(width: responsive.spacing(10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Home card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHomeCard(
    ResponsiveUtils responsive, {
    required String homeName,
    required String homeAddress,
  }) {
    return _card(
      child: Row(
        children: [
          Container(
            width: responsive.spacing(46),
            height: responsive.spacing(46),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_rounded,
              size: responsive.iconSize(24),
              color: _primaryColor,
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (homeAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    homeAddress,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AppColors.textSecondary,
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

  // â”€â”€ Details card (role / relation / expiry) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildDetailsCard(
    ResponsiveUtils responsive, {
    required String role,
    String? relation,
    DateTime? expiresAt,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Details',
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: responsive.spacing(14)),
          _detailRow(
            responsive,
            icon: Icons.shield_rounded,
            label: 'Role',
            value: _capitalizeRole(role),
            valueColor: _primaryColor,
          ),
          if (relation != null && relation.isNotEmpty) ...[
            Divider(height: responsive.spacing(20), color: AppColors.gray300),
            _detailRow(
              responsive,
              icon: Icons.people_alt_rounded,
              label: 'Relation',
              value: relation,
            ),
          ],
          if (expiresAt != null) ...[
            Divider(height: responsive.spacing(20), color: AppColors.gray300),
            _detailRow(
              responsive,
              icon: Icons.schedule_rounded,
              label: 'Expires',
              value: _formatExpiry(expiresAt),
              valueColor: expiresAt.isBefore(DateTime.now())
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ],
        ],
      ),
    );
  }

  // â”€â”€ Module access card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildModulesCard(
    ResponsiveUtils responsive, {
    required List<String> serviceTypes,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.apps_rounded,
                size: responsive.iconSize(18),
                color: _primaryColor,
              ),
              SizedBox(width: responsive.spacing(8)),
              Text(
                'Module Access',
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          Wrap(
            spacing: responsive.spacing(8),
            runSpacing: responsive.spacing(8),
            children: serviceTypes
                .map((st) => _moduleChip(responsive, st))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _moduleChip(ResponsiveUtils responsive, String serviceType) {
    final IconData icon = _serviceIcon(serviceType);
    final label = FamilyServiceTypes.label(serviceType);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(10),
        vertical: responsive.spacing(6),
      ),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: responsive.iconSize(14), color: _primaryColor),
          SizedBox(width: responsive.spacing(5)),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Asset access card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAssetsCard(
    ResponsiveUtils responsive, {
    required int assetCount,
    required bool grantFutureAssets,
  }) {
    final String subtitle = grantFutureAssets
        ? 'All current & future assets'
        : '$assetCount asset${assetCount == 1 ? '' : 's'}';

    return _card(
      child: Row(
        children: [
          Container(
            width: responsive.spacing(46),
            height: responsive.spacing(46),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.devices_other_rounded,
              size: responsive.iconSize(22),
              color: AppColors.success,
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asset Access',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (grantFutureAssets)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Auto-grant',
                style: TextStyle(
                  fontSize: responsive.fontSize(11),
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // â”€â”€ Loading shimmer note â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildShimmerNote(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryColor,
            ),
          ),
          SizedBox(width: responsive.spacing(10)),
          Text(
            'Loading full invite detailsâ€¦',
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Action bar (Accept + Decline in one row) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildActionBar(ResponsiveUtils responsive) {
    return Row(
      children: [
        // Decline
        Expanded(
          child: OutlinedButton(
            onPressed: (_isLoading || _isDeclining) ? null : _declineInvite,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.gray300, width: 1.5),
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isDeclining
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: responsive.fontSize(15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(width: responsive.spacing(12)),
        // Accept
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _acceptInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                      SizedBox(width: responsive.spacing(6)),
                      Text(
                        'Accept Invite',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthBar(ResponsiveUtils responsive) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.go('/signup'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: BorderSide(color: _primaryColor, width: 1.5),
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: responsive.spacing(12)),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => context.go('/signin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Sign In to Accept',
              style: TextStyle(
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // â”€â”€ Shared helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailRow(
    ResponsiveUtils responsive, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.iconSize(18),
          color: AppColors.textSecondary,
        ),
        SizedBox(width: responsive.spacing(10)),
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _capitalizeRole(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'member':
        return 'Member';
      case 'viewer':
        return 'Viewer';
      default:
        return role.isNotEmpty
            ? role[0].toUpperCase() + role.substring(1)
            : role;
    }
  }

  String _formatExpiry(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  IconData _serviceIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build_rounded;
      case 'warranty':
        return Icons.verified_user_rounded;
      case 'bookings':
        return Icons.calendar_today_rounded;
      case 'issues':
        return Icons.report_problem_rounded;
      case 'orders':
        return Icons.shopping_cart_rounded;
      case 'protection_plans':
        return Icons.security_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

