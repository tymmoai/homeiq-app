// Member Detail Screen — view & edit a family member's access

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/api_models.dart';
import '../../../models/family_models.dart';
import '../../../providers/data_providers.dart';
import '../../../services/asset_api_service.dart';
import '../../../services/family_api_service.dart';
import '../../../utils/responsive_utils.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  bool _isLoading = true;
  String? _loadError;
  FamilyMemberAccessDto? _member;
  List<AssetDto> _allHomeAssets = [];

  // Edit mode state
  bool _isEditing = false;
  bool _isSaving = false;
  String? _editRole;
  String? _editRelation;
  bool _editGrantFuture = false;
  final Set<String> _editAssetIds = {};
  final Set<String> _editServiceTypes = {};

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final member = await FamilyApiService.instance.getMemberAccess(
        widget.memberId,
      );
      // Also load all assets for this home so edit mode can add new ones
      List<AssetDto> homeAssets = [];
      try {
        homeAssets = await AssetApiService.instance.getAssets(
          homeId: member.homeId,
        );
      } on Object catch (_) {
        // Non-fatal: edit mode just won't show extra assets
      }
      setState(() {
        _member = member;
        _allHomeAssets = homeAssets;
        _isLoading = false;
        _resetEditState(member);
      });
    } on Object catch (_) {
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load member details.';
      });
    }
  }

  void _resetEditState(FamilyMemberAccessDto member) {
    _editRole = member.role;
    _editRelation = member.relation;
    _editGrantFuture = member.grantFutureAssets;
    _editAssetIds
      ..clear()
      ..addAll(member.grantedAssetIds);
    _editServiceTypes
      ..clear()
      ..addAll(member.grantedServiceTypes);
  }

  void _toggleEdit() {
    if (_isEditing && _member != null) {
      _resetEditState(_member!);
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveChanges() async {
    if (_member == null) return;
    setState(() => _isSaving = true);
    try {
      await FamilyApiService.instance.updateMemberAccess(
        widget.memberId,
        role: _editRole,
        relation: _editRelation,
        grantFutureAssets: _editGrantFuture,
        assetIds: _editAssetIds.toList(),
        serviceTypes: _editServiceTypes.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
        _loadMember();
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeMember() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${_member?.user?.name ?? 'this member'}? '
          'This will revoke all their access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FamilyApiService.instance.removeMember(widget.memberId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed'),
            backgroundColor: AppColors.success,
          ),
        );
        // Invalidate access caches so the removed member's permissions
        // are cleared immediately if they are currently using the app.
        ref.invalidate(grantedServiceTypesProvider);
        ref.invalidate(grantedAssetIdsProvider);
        if (context.canPop()) {
          context.pop(true); // Signal parent to refresh
        } else {
          context.go('/family-members');
        }
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
              context.go('/family-members');
            }
          },
        ),
        title: Text(
          'Member Details',
          style: TextStyle(
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_member != null && !_isLoading)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: AppColors.white,
                size: responsive.iconSize(22.0),
              ),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildErrorState(responsive)
          : RefreshIndicator(
              onRefresh: _loadMember,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(20.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.spacing(20.0)),
                    _buildProfileCard(responsive),
                    SizedBox(height: responsive.spacing(20.0)),
                    if (_isEditing) ...[
                      _buildRolePickerCompact(responsive),
                      SizedBox(height: responsive.spacing(16.0)),
                    ],
                    _buildAssetSection(responsive),
                    SizedBox(height: responsive.spacing(20.0)),
                    _buildServiceSection(responsive),
                    SizedBox(height: responsive.spacing(20.0)),
                    if (_isEditing) ...[
                      _buildFutureAssetsToggle(responsive),
                      SizedBox(height: responsive.spacing(20.0)),
                      _buildSaveButton(responsive),
                      SizedBox(height: responsive.spacing(12.0)),
                    ],
                    _buildRemoveButton(responsive),
                    SizedBox(height: responsive.spacing(40.0)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState(ResponsiveUtils responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(32.0)),
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
              onPressed: _loadMember,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profile Header ─────────────────────────────────────────────────────

  Widget _buildProfileCard(ResponsiveUtils responsive) {
    final user = _member!.user;
    final name = user?.name ?? 'Unknown';
    final email = user?.email ?? '';
    final homeLabel = _member!.home?.displayName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16.0), vertical: responsive.spacing(18.0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circle — tinted, not garish
          Container(
            width: responsive.spacing(68.0),
            height: responsive.spacing(68.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withValues(alpha: 0.12),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: responsive.fontSize(26.0),
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info block — takes remaining width
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row with role badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: responsive.fontSize(17.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleBadge(_member!.role, _primaryColor, responsive),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Email
                if (email.isNotEmpty) ...[
                  _buildInfoRow(Icons.email_outlined, email, responsive),
                  const SizedBox(height: 5),
                ],
                // Home
                if (homeLabel != null)
                  _buildInfoRow(Icons.home_outlined, homeLabel, responsive),
                // Relation
                if (_member!.relation != null &&
                    _member!.relation!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(10.0),
                      vertical: responsive.spacing(3.0),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _member!.relation!,
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildInfoRow(IconData icon, String text, ResponsiveUtils responsive) {
    return Row(
      children: [
        Icon(icon, size: responsive.iconSize(14.0), color: AppColors.gray400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: responsive.fontSize(12.5),
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Role Picker (edit mode only, compact) ───────────────────────────────

  Widget _buildRolePickerCompact(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(14.0)),
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
          Text(
            'Role',
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(10.0)),
          Row(
            children: ['owner', 'member', 'viewer'].map((role) {
              final isSelected = _editRole == role;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _editRole = role),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(8.0),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primaryColor.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _primaryColor : AppColors.gray200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _roleLabel(role),
                            style: TextStyle(
                              fontSize: responsive.fontSize(12.5),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? _primaryColor
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _roleDescription(role),
                            style: TextStyle(
                              fontSize: responsive.fontSize(10.5),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Asset Section ──────────────────────────────────────────────────────

  Widget _buildAssetSection(ResponsiveUtils responsive) {
    final assets = _member!.assetAccess;
    return _buildSection(
      title:
          'Asset Access (${_isEditing ? _editAssetIds.length : assets.length})',
      responsive: responsive,
      child: _isEditing
          ? _allHomeAssets.isEmpty
                ? _buildEmptyTag('No assets in this home', responsive)
                : Column(
                    children: _allHomeAssets.map((asset) {
                      final isSelected = _editAssetIds.contains(asset.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _editAssetIds.remove(asset.id);
                              } else {
                                _editAssetIds.add(asset.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(12.0),
                              vertical: responsive.spacing(10.0),
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryColor.withValues(alpha: 0.08)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? _primaryColor
                                    : AppColors.gray200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.devices,
                                  size: responsive.iconSize(18.0),
                                  color: isSelected
                                      ? _primaryColor
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(width: responsive.spacing(10.0)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset.name,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(14.0),
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (asset.category.isNotEmpty)
                                        Text(
                                          asset.category,
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(12.0),
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _editAssetIds.add(asset.id);
                                      } else {
                                        _editAssetIds.remove(asset.id);
                                      }
                                    });
                                  },
                                  activeColor: _primaryColor,
                                  checkColor: AppColors.white,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
          : assets.isEmpty
          ? _buildEmptyTag('No asset access granted', responsive)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: assets.map((entry) {
                return _buildChip(
                  entry.asset?.name ?? entry.assetId,
                  Icons.devices,
                  responsive,
                );
              }).toList(),
            ),
    );
  }

  // ─── Service Section ────────────────────────────────────────────────────

  Widget _buildServiceSection(ResponsiveUtils responsive) {
    final services = _member!.serviceAccess;
    return _buildSection(
      title:
          'Service Access (${_isEditing ? _editServiceTypes.length : services.length})',
      responsive: responsive,
      child: _isEditing
          ? Column(
              children: FamilyServiceTypes.all.map((type) {
                final isSelected = _editServiceTypes.contains(type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _editServiceTypes.remove(type);
                        } else {
                          _editServiceTypes.add(type);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(12.0),
                        vertical: responsive.spacing(10.0),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primaryColor.withValues(alpha: 0.08)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _primaryColor : AppColors.gray200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _serviceIcon(type),
                            size: responsive.iconSize(18.0),
                            color: isSelected
                                ? _primaryColor
                                : AppColors.textSecondary,
                          ),
                          SizedBox(width: responsive.spacing(10.0)),
                          Expanded(
                            child: Text(
                              FamilyServiceTypes.label(type),
                              style: TextStyle(
                                fontSize: responsive.fontSize(14.0),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _editServiceTypes.add(type);
                                } else {
                                  _editServiceTypes.remove(type);
                                }
                              });
                            },
                            activeColor: _primaryColor,
                            checkColor: AppColors.white,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          : services.isEmpty
          ? _buildEmptyTag('No service access granted', responsive)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services.map((entry) {
                return _buildChip(
                  FamilyServiceTypes.label(entry.serviceType),
                  _serviceIcon(entry.serviceType),
                  responsive,
                );
              }).toList(),
            ),
    );
  }

  // ─── Future Assets Toggle ───────────────────────────────────────────────

  Widget _buildFutureAssetsToggle(ResponsiveUtils responsive) {
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
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: responsive.iconSize(20.0),
            color: _primaryColor,
          ),
          SizedBox(width: responsive.spacing(12.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-grant future assets',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Automatically grant access when new assets are added.',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _editGrantFuture,
            onChanged: (v) => setState(() => _editGrantFuture = v),
            activeThumbColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  // ─── Buttons ────────────────────────────────────────────────────────────

  Widget _buildSaveButton(ResponsiveUtils responsive) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(14.0)),
          elevation: 0,
        ),
        child: _isSaving
            ? SizedBox(
                height: responsive.iconSize(18.0),
                width: responsive.iconSize(18.0),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildRemoveButton(ResponsiveUtils responsive) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _removeMember,
        icon: Icon(Icons.person_remove, size: responsive.iconSize(18.0)),
        label: Text(
          'Remove Member',
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(14.0)),
        ),
      ),
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required ResponsiveUtils responsive,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacing(12.0)),
          child,
        ],
      ),
    );
  }

  Widget _buildRoleBadge(
    String role,
    Color primaryColor,
    ResponsiveUtils responsive,
  ) {
    Color bgColor;
    IconData icon;
    switch (role) {
      case 'owner':
        bgColor = primaryColor;
        icon = Icons.shield;
        break;
      case 'member':
        bgColor = const Color(0xFF0D7377);
        icon = Icons.people;
        break;
      default:
        bgColor = AppColors.textSecondary;
        icon = Icons.visibility;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            _roleLabel(role),
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

  Widget _buildChip(String label, IconData icon, ResponsiveUtils responsive) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTag(String text, ResponsiveUtils responsive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

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

  String _roleDescription(String role) {
    switch (role) {
      case 'owner':
        return 'Full access';
      case 'member':
        return 'View & book';
      case 'viewer':
        return 'View only';
      default:
        return '';
    }
  }

  IconData _serviceIcon(String type) {
    switch (type) {
      case FamilyServiceTypes.maintenance:
        return Icons.build;
      case FamilyServiceTypes.warranty:
        return Icons.verified_user;
      case FamilyServiceTypes.bookings:
        return Icons.calendar_today;
      case FamilyServiceTypes.issues:
        return Icons.report_problem;
      case FamilyServiceTypes.orders:
        return Icons.shopping_cart;
      case FamilyServiceTypes.protectionPlans:
        return Icons.security;
      default:
        return Icons.help;
    }
  }
}