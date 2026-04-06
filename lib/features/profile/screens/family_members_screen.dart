// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/api_models.dart';
import '../../../models/family_models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../services/family_api_service.dart';
import '../../../services/home_api_service.dart';
import '../../../services/user_service.dart';
import '../../../utils/responsive_utils.dart';

class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() =>
      _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen>
    with SingleTickerProviderStateMixin {
  Color get _headerColor => Theme.of(context).colorScheme.primary;

  // Class-level getter so responsive is accessible everywhere in this state,
  // including inside showModalBottomSheet / showDialog builder closures.
  ResponsiveUtils get responsive => ResponsiveUtils(context);

  late TabController _tabController;
  String _selectedHomeFilter = 'All Homes';

  // Backend-loaded data
  bool _isLoading = true;
  String? _loadError;
  List<HomeDto> _homes = [];
  List<FamilyMemberDto> _allMembers = [];
  List<FamilyInviteDto> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load homes, family members, and pending invites from the backend.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        HomeApiService.instance.getHomes(),
        FamilyApiService.instance.getFamilyMembers(),
        FamilyApiService.instance.getPendingInvites(),
      ]);

      final homes = (results[0] as List<HomeDto>)
          .where((h) => h.isOwner)
          .toList();
      final members = results[1] as List<FamilyMemberDto>;
      final invites = results[2] as List<FamilyInviteDto>;

      setState(() {
        _homes = homes;
        _allMembers = members;
        _pendingInvites = invites;
        _isLoading = false;
      });
    } on Object catch (_) {
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load family members. Pull to refresh.';
      });
    }
  }

  List<FamilyMemberDto> get _filteredMembers {
    if (_selectedHomeFilter == 'All Homes') return _allMembers;
    final selectedHome = _homes.firstWhere(
      (h) => h.displayName == _selectedHomeFilter,
      orElse: () => _homes.first,
    );
    return _allMembers.where((m) => m.homeId == selectedHome.id).toList();
  }

  List<FamilyInviteDto> get _filteredInvites {
    if (_selectedHomeFilter == 'All Homes') return _pendingInvites;
    final selectedHome = _homes.firstWhere(
      (h) => h.displayName == _selectedHomeFilter,
      orElse: () => _homes.first,
    );
    return _pendingInvites.where((i) => i.homeId == selectedHome.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _headerColor,
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
          'Family Members & Access',
          style: TextStyle(
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          // Only home owners can invite new family members
          if (ref.watch(selectedHomeIsOwnerProvider))
            GestureDetector(
              onTap: () => _showAddMemberBottomSheet(context),
              child: Container(
                margin: EdgeInsets.only(right: responsive.spacing(10.0)),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(12.0),
                  vertical: responsive.spacing(8.0),
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add,
                      size: responsive.iconSize(16.0),
                      color: AppColors.white,
                    ),
                    SizedBox(width: responsive.spacing(6.0)),
                    Text(
                      'Invite',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildErrorState(responsive)
          : Column(
              children: [
                // Home overview + filter
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: responsive.spacing(16.0)),
                      _buildHomeAccessOverview(responsive),
                      SizedBox(height: responsive.spacing(16.0)),
                      _buildFilterSection(responsive),
                    ],
                  ),
                ),
                // ── Toggle: Members / Pending ──────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.spacing(20.0),
                    responsive.spacing(16.0),
                    responsive.spacing(20.0),
                    responsive.spacing(8.0),
                  ),
                  child: _buildSegmentedToggle(responsive),
                ),
                // Tab content (no swipe — controlled by toggle)
                Expanded(
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildMembersTab(responsive),
                      _buildPendingInvitesTab(responsive),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState(ResponsiveUtils responsive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Home Access Overview ───────────────────────────────────────────────

  // ─── Segmented Toggle ────────────────────────────────────────────────

  Widget _buildSegmentedToggle(ResponsiveUtils responsive) {
    return Container(
      height: responsive.buttonHeight(44.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildToggleItem(
            label: 'Members (${_groupedMembers.length})',
            icon: Icons.people,
            isSelected: _tabController.index == 0,
            onTap: () => setState(() => _tabController.index = 0),
            responsive: responsive,
          ),
          const SizedBox(width: 4),
          _buildToggleItem(
            label: 'Pending (${_pendingInvites.length})',
            icon: Icons.schedule,
            isSelected: _tabController.index == 1,
            onTap: () => setState(() => _tabController.index = 1),
            responsive: responsive,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ResponsiveUtils responsive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: responsive.iconSize(16.0),
                  color: isSelected ? _headerColor : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13.0),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _headerColor : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeAccessOverview(ResponsiveUtils responsive) {
    if (_homes.isEmpty) return const SizedBox.shrink();
    final totalMembers = _allMembers.length;
    final totalPending = _pendingInvites.length;

    Widget cell(String value, String label, IconData icon) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.white.withValues(alpha: 0.82)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(17.0),
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(10.0),
              color: AppColors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );

    Widget div() => Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.white.withValues(alpha: 0.25),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(14.0),
        vertical: responsive.spacing(10.0),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_headerColor, _headerColor.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          cell('${_homes.length}', 'Homes', Icons.home_outlined),
          div(),
          cell('$totalMembers', 'Members', Icons.people_outline),
          div(),
          cell('$totalPending', 'Pending', Icons.schedule_outlined),
        ],
      ),
    );
  }
  // ─── Filter ─────────────────────────────────────────────────────────────

  Widget _buildFilterSection(ResponsiveUtils responsive) {
    final homeNames = ['All Homes', ..._homes.map((h) => h.displayName)];
    return PopupMenuButton<String>(
      initialValue: _selectedHomeFilter,
      onSelected: (value) {
        setState(() => _selectedHomeFilter = value);
      },
      elevation: 8,
      color: AppColors.white,
      offset: const Offset(0, 8),
      itemBuilder: (context) {
        return homeNames.map((item) {
          final isSelected = item == _selectedHomeFilter;
          return PopupMenuItem<String>(
            value: item,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 18, color: AppColors.primary),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16.0),
          vertical: responsive.spacing(14.0),
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedHomeFilter,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Members Tab ────────────────────────────────────────────────────────

  /// Groups filtered members by userId so one person with access to multiple
  /// homes appears as a single card (instead of one card per home).
  Map<String, List<FamilyMemberDto>> get _groupedMembers {
    final Map<String, List<FamilyMemberDto>> grouped = {};
    for (final m in _filteredMembers) {
      grouped.putIfAbsent(m.userId, () => []).add(m);
    }
    return grouped;
  }

  Widget _buildMembersTab(ResponsiveUtils responsive) {
    final grouped = _groupedMembers;
    final currentEmail = UserService.instance.getUserEmail();

    if (grouped.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        message: 'No family members found',
        responsive: responsive,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(20.0),
          vertical: responsive.spacing(8.0),
        ),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final memberships = grouped.values.elementAt(index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGroupedMemberCard(
              memberships,
              currentEmail,
              responsive,
            ),
          );
        },
      ),
    );
  }

  /// One card per person. Shows all home memberships they have as tappable
  /// home chips at the bottom. Tapping a chip opens that home's detail screen.
  Widget _buildGroupedMemberCard(
    List<FamilyMemberDto> memberships,
    String? currentEmail,
    ResponsiveUtils responsive,
  ) {
    // Use the first membership for the person's identity.
    final first = memberships.first;
    final name = first.user?.name ?? 'Unknown';
    final email = first.user?.email ?? '';
    final isCurrentUser = email.isNotEmpty && email == currentEmail;

    return Container(
      padding: EdgeInsets.all(responsive.spacing(16.0)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + name/email ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: responsive.spacing(50.0),
                height: responsive.spacing(50.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _headerColor,
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: responsive.fontSize(20.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name${isCurrentUser ? ' (You)' : ''}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: responsive.fontSize(15.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRoleBadge(first.role),
            ],
          ),
          const SizedBox(height: 12),
          // ── Home membership chips (one per home) ────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: memberships.map((membership) {
              final homeName =
                  _homes
                      .where((h) => h.id == membership.homeId)
                      .map((h) => h.displayName)
                      .firstOrNull ??
                  'Home';
              return GestureDetector(
                onTap: () async {
                  final result = await context.push<bool>(
                    '/family-members/detail',
                    extra: {'memberId': membership.id},
                  );
                  if (result == true) _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _headerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _headerColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, size: 13, color: _headerColor),
                      const SizedBox(width: 5),
                      Text(
                        homeName,
                        style: TextStyle(
                          fontSize: responsive.fontSize(12.0),
                          fontWeight: FontWeight.w600,
                          color: _headerColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 14, color: _headerColor),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Pending Invites Tab ────────────────────────────────────────────────

  /// Groups the filtered invites by email so that one person invited to
  /// multiple homes appears as a single card with all homes listed.
  List<List<FamilyInviteDto>> get _groupedInvites {
    final Map<String, List<FamilyInviteDto>> grouped = {};
    for (final invite in _filteredInvites) {
      grouped.putIfAbsent(invite.email, () => []).add(invite);
    }
    return grouped.values.toList();
  }

  Widget _buildPendingInvitesTab(ResponsiveUtils responsive) {
    final groups = _groupedInvites;

    if (groups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        message: 'No pending invitations',
        responsive: responsive,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(20.0),
          vertical: responsive.spacing(8.0),
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGroupedInviteCard(groups[index], responsive),
          );
        },
      ),
    );
  }

  /// Renders one card for all invites belonging to the same email.
  /// When the user is invited to multiple homes, each home is shown as a
  /// sub-row inside the same card (with its own details + cancel button).
  Widget _buildGroupedInviteCard(
    List<FamilyInviteDto> invites,
    ResponsiveUtils responsive,
  ) {
    final email = invites.first.email;
    final inviteeName = invites.first.inviteeName;

    // Earliest expiry drives the countdown shown in the header.
    final earliest = invites.reduce(
      (a, b) => a.expiresAt.isBefore(b.expiresAt) ? a : b,
    );
    final allExpired = invites.every((i) => i.isExpired);
    final remaining = earliest.timeRemaining;
    final daysLeft = remaining.inDays;
    final hoursLeft = remaining.inHours % 24;

    return Container(
      padding: EdgeInsets.all(responsive.spacing(16.0)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Email header + expiry badge ───────────────────────────────
          Row(
            children: [
              Icon(
                Icons.mail,
                size: responsive.iconSize(20.0),
                color: _headerColor,
              ),
              SizedBox(width: responsive.spacing(10.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (inviteeName != null && inviteeName.isNotEmpty)
                      Text(
                        inviteeName,
                        style: TextStyle(
                          fontSize: responsive.fontSize(15.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          inviteeName != null && inviteeName.isNotEmpty
                              ? 13.0
                              : 15.0,
                        ),
                        fontWeight:
                            inviteeName != null && inviteeName.isNotEmpty
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: inviteeName != null && inviteeName.isNotEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: allExpired
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusBadge,
                  ),
                ),
                child: Text(
                  allExpired ? 'Expired' : '${daysLeft}d ${hoursLeft}h left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: allExpired
                        ? AppColors.error
                        : AppColors.warningOrange,
                  ),
                ),
              ),
            ],
          ),

          // ── Per-home rows ─────────────────────────────────────────────
          ...invites.map((invite) => _buildHomeInviteRow(invite, responsive)),
        ],
      ),
    );
  }

  /// Sub-row for one home within a grouped invite card.
  /// Tapping the row opens a detail bottom sheet with a cancel option.
  Widget _buildHomeInviteRow(
    FamilyInviteDto invite,
    ResponsiveUtils responsive,
  ) {
    final homeName =
        _homes
            .where((h) => h.id == invite.homeId)
            .map((h) => h.displayName)
            .firstOrNull ??
        'Unknown Home';

    return GestureDetector(
      onTap: () => _showInviteDetailSheet(invite),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          // Home name row — chevron hints it's tappable
          Row(
            children: [
              Icon(Icons.home, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  homeName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildRoleBadge(invite.role),
              if (invite.relation != null && invite.relation!.isNotEmpty)
                _buildRelationBadge(invite.relation!),
              _buildCountBadge(
                '${invite.assetIds.length} asset${invite.assetIds.length != 1 ? 's' : ''}',
                Icons.devices,
              ),
              _buildCountBadge(
                '${invite.serviceTypes.length} service${invite.serviceTypes.length != 1 ? 's' : ''}',
                Icons.miscellaneous_services,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Shows a bottom sheet with invite details and a cancel action.
  void _showInviteDetailSheet(FamilyInviteDto invite) {
    final homeName =
        _homes
            .where((h) => h.id == invite.homeId)
            .map((h) => h.displayName)
            .firstOrNull ??
        'Unknown Home';
    final remaining = invite.timeRemaining;
    final daysLeft = remaining.inDays;
    final hoursLeft = remaining.inHours % 24;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.spacing(24.0),
            responsive.spacing(12.0),
            responsive.spacing(24.0),
            responsive.spacing(24.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray600.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Home name header
              Row(
                children: [
                  Icon(Icons.home, color: _headerColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      homeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Email
              Row(
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      invite.email,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Badges
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildRoleBadge(invite.role),
                  if (invite.relation != null && invite.relation!.isNotEmpty)
                    _buildRelationBadge(invite.relation!),
                  _buildCountBadge(
                    '${invite.assetIds.length} asset${invite.assetIds.length != 1 ? 's' : ''}',
                    Icons.devices,
                  ),
                  _buildCountBadge(
                    '${invite.serviceTypes.length} service${invite.serviceTypes.length != 1 ? 's' : ''}',
                    Icons.miscellaneous_services,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Expiry info
              if (invite.isExpired)
                const Text(
                  'This invite has expired',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  'Expires in ${daysLeft}d ${hoursLeft}h',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warningOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 24),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _cancelInvite(invite);
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel Invite'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelInvite(FamilyInviteDto invite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Invite'),
        content: Text('Cancel the invitation to ${invite.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Invite'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FamilyApiService.instance.cancelInvite(invite.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite to ${invite.email} cancelled'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh owner's invite list AND clear the banner on the invitee's home tab.
        ref.invalidate(myPendingInvitesProvider);
        _loadData();
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel invite: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ─── Badges ─────────────────────────────────────────────────────────────

  Widget _buildRoleBadge(String role) {
    IconData icon;
    Color bgColor;
    String label;
    switch (role) {
      case 'owner':
        icon = Icons.shield;
        bgColor = AppColors.primary;
        label = 'Owner';
        break;
      case 'member':
        icon = Icons.people;
        bgColor = const Color(0xFF0D7377);
        label = 'Member';
        break;
      default:
        icon = Icons.visibility;
        bgColor = AppColors.textSecondary;
        label = 'Viewer';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationBadge(String relation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Text(
        relation,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCountBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gray600),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required ResponsiveUtils responsive,
  }) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: AppColors.gray300),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: responsive.fontSize(16.0),
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Open invite screen ─────────────────────────────────────────────────

  void _showAddMemberBottomSheet(BuildContext context) {
    context
        .push<bool>(
          '/family-members/invite',
          extra: {'onInviteSent': _loadData},
        )
        .then((refreshed) {
          if (refreshed == true) _loadData();
        });
  }
}
