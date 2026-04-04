// Invite Member Screen — full-screen multi-step invite flow
//
// • Supports selecting MULTIPLE homes for one member
// • Validation fires ONLY on the final "Send Invite" button
// • "Next" and "Back" navigate freely without any validation

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/api_models.dart';
import '../../../models/family_models.dart';
import '../../../services/asset_api_service.dart';
import '../../../services/family_api_service.dart';
import '../../../services/home_api_service.dart';
import '../../../utils/responsive_utils.dart';

class InviteMemberScreen extends StatefulWidget {
  /// Called after a successful invite is sent, so the caller can refresh.
  final VoidCallback? onInviteSent;

  const InviteMemberScreen({super.key, this.onInviteSent});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  // ─── Step tracking ──────────────────────────────────────────────────────
  int _currentStep = 0; // 0=info, 1=assets, 2=services, 3=review
  static const _totalSteps = 4;

  // ─── Form ───────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'member';
  String _selectedRelation = '';
  bool _grantFutureAssets = false;

  // ─── Home data ──────────────────────────────────────────────────────────
  bool _isLoadingHomes = true;
  List<HomeDto> _homes = [];

  /// Multiple homes selected by the user
  final Set<String> _selectedHomeIds = {};

  // ─── Asset data (per-home) ───────────────────────────────────────────────
  /// Assets loaded for each home: homeId → list of assets
  final Map<String, List<AssetDto>> _assetsByHome = {};
  final Map<String, bool> _loadingAssetsByHome = {};

  /// Selected asset IDs per home
  final Map<String, Set<String>> _selectedAssetIdsByHome = {};

  // ─── Service selection ───────────────────────────────────────────────────
  final Set<String> _selectedServiceTypes = {};

  // ─── Submission ─────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ─── Validation ─────────────────────────────────────────────────────────
  /// Errors shown only after the user presses "Send Invite"
  String? _emailError;
  String? _homeError;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Data loading ────────────────────────────────────────────────────────

  Future<void> _loadHomes() async {
    try {
      final homes = await HomeApiService.instance.getHomes();
      final owned = homes.where((h) => h.isOwner).toList();
      setState(() {
        _homes = owned;
        _isLoadingHomes = false;
        // Pre-select if only one home
        if (owned.length == 1) {
          _selectedHomeIds.add(owned.first.id);
          _loadAssetsForHome(owned.first.id);
        }
      });
    } on Object catch (_) {
      setState(() => _isLoadingHomes = false);
    }
  }

  Future<void> _loadAssetsForHome(String homeId) async {
    if (_assetsByHome.containsKey(homeId)) return; // already loaded
    setState(() => _loadingAssetsByHome[homeId] = true);
    try {
      final assets = await AssetApiService.instance.getAssets(homeId: homeId);
      setState(() {
        _assetsByHome[homeId] = assets;
        _loadingAssetsByHome[homeId] = false;
        _selectedAssetIdsByHome.putIfAbsent(homeId, () => {});
      });
    } on Object catch (_) {
      setState(() => _loadingAssetsByHome[homeId] = false);
    }
  }

  void _toggleHome(HomeDto home) {
    setState(() {
      if (_selectedHomeIds.contains(home.id)) {
        _selectedHomeIds.remove(home.id);
      } else {
        _selectedHomeIds.add(home.id);
        _loadAssetsForHome(home.id);
      }
      _homeError = null;
    });
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _nextStep() {
    // No validation on Next — free navigation
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _scrollTop();
    }
  }

  void _scrollTop() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Submission ──────────────────────────────────────────────────────────

  /// Validates and submits — called ONLY from the "Send Invite" button.
  Future<void> _submit() async {
    // ── Validate ──
    final email = _emailController.text.trim();
    String? emailErr;
    String? homeErr;

    if (email.isEmpty) {
      emailErr = 'Email address is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailErr = 'Please enter a valid email address';
    }
    if (_selectedHomeIds.isEmpty) {
      homeErr = 'Please select at least one home';
    }

    if (emailErr != null || homeErr != null) {
      setState(() {
        _emailError = emailErr;
        _homeError = homeErr;
      });
      // If errors are on step 0, jump back there
      if (emailErr != null || homeErr != null) {
        setState(() => _currentStep = 0);
        _scrollTop();
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Send one invite per selected home
      await Future.wait(
        _selectedHomeIds.map((homeId) {
          final assetIds = _selectedAssetIdsByHome[homeId]?.toList() ?? [];
          final name = _nameController.text.trim();
          return FamilyApiService.instance.inviteMember(
            email: email,
            homeId: homeId,
            role: _selectedRole,
            relation: _selectedRelation.isNotEmpty ? _selectedRelation : null,
            inviteeName: name.isNotEmpty ? name : null,
            grantFutureAssets: _grantFutureAssets,
            assetIds: assetIds.isNotEmpty ? assetIds : null,
            serviceTypes: _selectedServiceTypes.isNotEmpty
                ? _selectedServiceTypes.toList()
                : null,
          );
        }),
      );

      if (mounted) {
        widget.onInviteSent?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedHomeIds.length == 1
                  ? 'Invitation sent to $email'
                  : 'Invitations sent to $email for ${_selectedHomeIds.length} homes',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/family-members');
        }
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invite: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

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
            if (_currentStep > 0) {
              setState(() => _currentStep--);
              _scrollTop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/family-members');
            }
          },
        ),
        title: Text(
          'Invite Family Member',
          style: TextStyle(
            fontSize: responsive.fontSize(17.0),
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_currentStep > 0)
            IconButton(
              icon: Icon(
                Icons.close,
                color: AppColors.white,
                size: responsive.iconSize(24.0),
              ),
              tooltip: 'Close',
              onPressed: () => context.go('/family-members'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress bar ──
          _buildStepProgressBar(responsive),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(responsive.spacing(20.0)),
              child: _buildStepContent(responsive),
            ),
          ),

          // ── Bottom buttons ──
          _buildBottomButtons(responsive),
        ],
      ),
    );
  }

  // ─── Step progress bar ───────────────────────────────────────────────────

  Widget _buildStepProgressBar(ResponsiveUtils responsive) {
    return Container(
      color: _primaryColor,
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(20.0),
        0,
        responsive.spacing(20.0),
        responsive.spacing(12.0),
      ),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isCompleted = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Container(
              height: responsive.spacing(4.0),
              margin: EdgeInsets.only(
                right: i < _totalSteps - 1 ? responsive.spacing(6.0) : 0,
              ),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.white
                    : isCurrent
                    ? AppColors.white.withValues(alpha: 0.7)
                    : AppColors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Step content dispatcher ─────────────────────────────────────────────

  Widget _buildStepContent(ResponsiveUtils responsive) {
    switch (_currentStep) {
      case 0:
        return _buildInfoStep(responsive);
      case 1:
        return _buildAssetStep(responsive);
      case 2:
        return _buildServiceStep(responsive);
      case 3:
        return _buildReviewStep(responsive);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Bottom navigation buttons ────────────────────────────────────────────

  Widget _buildBottomButtons(ResponsiveUtils responsive) {
    final isLastStep = _currentStep == _totalSteps - 1;
    // Step 0: Next is only enabled when email is filled and at least one home selected
    final bool isNextEnabled =
        _currentStep != 0 ||
        (_emailController.text.trim().isNotEmpty &&
            _selectedHomeIds.isNotEmpty);

    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(20.0),
        responsive.spacing(12.0),
        responsive.spacing(20.0),
        responsive.spacing(20.0) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isSubmitting || !isNextEnabled)
              ? null
              : isLastStep
              ? _submit
              : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            disabledBackgroundColor: _primaryColor.withValues(alpha: 0.4),
            padding: EdgeInsets.symmetric(vertical: responsive.spacing(14.0)),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isLastStep ? 'Send Invite' : 'Next',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Step 0: Member Info ──────────────────────────────────────────────────

  Widget _buildInfoStep(ResponsiveUtils responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionIntro(
          icon: Icons.person_add_outlined,
          title: 'Who are you inviting?',
          subtitle:
              'Enter the details of the person you want to invite. They\'ll receive an email with a link to join.',
          responsive: responsive,
        ),
        SizedBox(height: responsive.spacing(24.0)),

        // ── Name ──
        _buildLabel('Full Name (optional)', responsive),
        SizedBox(height: responsive.spacing(6.0)),
        _buildTextField(
          controller: _nameController,
          hint: 'e.g. John Smith',
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: responsive.spacing(20.0)),

        // ── Email ──
        _buildLabel('Email Address *', responsive),
        SizedBox(height: responsive.spacing(6.0)),
        _buildTextField(
          controller: _emailController,
          hint: 'email@example.com',
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          onChanged: (_) => setState(() => _emailError = null),
        ),
        SizedBox(height: responsive.spacing(20.0)),

        // ── Home selection (multi-select) ──
        _buildLabel('Select Homes *', responsive),
        SizedBox(height: responsive.spacing(4.0)),
        Text(
          'Choose one or more homes this member can access.',
          style: TextStyle(
            fontSize: responsive.fontSize(12.0),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(10.0)),
        if (_homeError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _homeError!,
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                color: AppColors.error,
              ),
            ),
          ),
        _isLoadingHomes
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            : _buildMultiHomeSelector(responsive),

        SizedBox(height: responsive.spacing(20.0)),

        // ── Role & Relation ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Role', responsive),
                  SizedBox(height: responsive.spacing(6.0)),
                  _buildDropdown(
                    value: _selectedRole,
                    items: const {
                      'member': 'Member',
                      'viewer': 'Viewer',
                      'owner': 'Owner',
                    },
                    onChanged: (v) =>
                        setState(() => _selectedRole = v ?? 'member'),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.spacing(12.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Relation', responsive),
                  SizedBox(height: responsive.spacing(6.0)),
                  _buildDropdown(
                    value: _selectedRelation,
                    items: const {
                      '': 'None',
                      'Spouse': 'Spouse',
                      'Parent': 'Parent',
                      'Child': 'Child',
                      'Sibling': 'Sibling',
                      'Caretaker': 'Caretaker',
                      'Tenant': 'Tenant',
                      'Other': 'Other',
                    },
                    onChanged: (v) =>
                        setState(() => _selectedRelation = v ?? ''),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiHomeSelector(ResponsiveUtils responsive) {
    if (_homes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.warningOrange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No homes found. Please create a home first.',
                style: TextStyle(
                  fontSize: responsive.fontSize(13.0),
                  color: AppColors.warningOrange,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _homes.map((home) {
        final isSelected = _selectedHomeIds.contains(home.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _toggleHome(home),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(14.0),
                vertical: responsive.spacing(12.0),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: isSelected
                    ? Border.all(color: _primaryColor, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryColor.withValues(alpha: 0.12)
                          : AppColors.backgroundGray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      size: 20,
                      color: isSelected
                          ? _primaryColor
                          : AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          home.address,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${home.city}, ${home.state}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12.0),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _primaryColor : AppColors.gray300,
                        width: 2,
                      ),
                      color: isSelected ? _primaryColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Step 1: Asset Access (per-home) ─────────────────────────────────────

  Widget _buildAssetStep(ResponsiveUtils responsive) {
    final selectedHomes = _homes
        .where((h) => _selectedHomeIds.contains(h.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionIntro(
          icon: Icons.devices_outlined,
          title: 'Asset Access',
          subtitle:
              'Choose which appliances and devices this member can view. Leave empty for no asset access.',
          responsive: responsive,
        ),
        SizedBox(height: responsive.spacing(16.0)),

        if (selectedHomes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'No homes selected. Go back to Step 1 and select at least one home.',
              style: TextStyle(
                fontSize: responsive.fontSize(13.0),
                color: AppColors.warningOrange,
              ),
            ),
          )
        else ...[
          // Per-home asset sections — separated by faded dividers
          ...selectedHomes.asMap().entries.map((entry) {
            final i = entry.key;
            final home = entry.value;
            return Column(
              children: [
                if (i > 0)
                  Divider(color: AppColors.gray100, height: 24, thickness: 1),
                _buildHomeAssetSection(home, responsive),
              ],
            );
          }),

          // Auto-grant future assets checkbox at the bottom
          _buildAutoGrantCheckbox(responsive),
        ],
      ],
    );
  }

  Widget _buildHomeAssetSection(HomeDto home, ResponsiveUtils responsive) {
    final assets = _assetsByHome[home.id] ?? [];
    final isLoading = _loadingAssetsByHome[home.id] ?? false;
    final selectedIds = _selectedAssetIdsByHome.putIfAbsent(home.id, () => {});
    final totalAssets = assets.length;
    final selectedCount = selectedIds.length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Home header inside card
            Row(
              children: [
                Icon(Icons.home_outlined, size: 18, color: _primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    home.address,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isLoading && assets.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        final ids = _selectedAssetIdsByHome[home.id]!;
                        if (ids.length == assets.length) {
                          ids.clear();
                        } else {
                          ids
                            ..clear()
                            ..addAll(assets.map((a) => a.id));
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      selectedCount == totalAssets
                          ? 'Deselect All'
                          : 'Select All',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!isLoading && assets.isNotEmpty)
                  Text(
                    ' ($selectedCount/$totalAssets)',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Assets list
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (assets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.devices, size: 20, color: AppColors.gray300),
                    const SizedBox(width: 10),
                    Text(
                      'No assets in this home yet.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13.0),
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: assets.map((asset) {
                  final isSelected = selectedIds.contains(asset.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildAssetTile(
                      asset: asset,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedIds.remove(asset.id);
                          } else {
                            selectedIds.add(asset.id);
                          }
                        });
                      },
                      responsive: responsive,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetTile({
    required AssetDto asset,
    required bool isSelected,
    required VoidCallback onTap,
    required ResponsiveUtils responsive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(10.0),
          vertical: responsive.spacing(8.0),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: isSelected
              ? Border.all(color: _primaryColor, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.devices,
              size: responsive.iconSize(16.0),
              color: isSelected ? _primaryColor : AppColors.textSecondary,
            ),
            SizedBox(width: responsive.spacing(10.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (asset.brand != null || asset.category.isNotEmpty)
                    Text(
                      [
                        if (asset.brand != null) asset.brand!,
                        asset.category,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryColor : AppColors.gray300,
                  width: 2,
                ),
                color: isSelected ? _primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoGrantCheckbox(ResponsiveUtils responsive) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: CheckboxListTile(
        value: _grantFutureAssets,
        onChanged: (v) => setState(() => _grantFutureAssets = v ?? false),
        activeColor: _primaryColor,
        checkColor: AppColors.white,
        side: BorderSide(color: AppColors.textSecondary, width: 1.5),
        title: Text(
          'Auto-grant future assets',
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Automatically give access when new assets are added.',
          style: TextStyle(
            fontSize: responsive.fontSize(12.0),
            color: AppColors.textSecondary,
          ),
        ),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  // ─── Step 2: Service Access ───────────────────────────────────────────────

  Widget _buildServiceStep(ResponsiveUtils responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionIntro(
          icon: Icons.miscellaneous_services_outlined,
          title: 'Service Access',
          subtitle:
              'Choose which services this member can book and manage. Leave empty for no service access.',
          responsive: responsive,
        ),
        SizedBox(height: responsive.spacing(16.0)),

        // Select all / Deselect all row
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedServiceTypes.length ==
                      FamilyServiceTypes.all.length) {
                    _selectedServiceTypes.clear();
                  } else {
                    _selectedServiceTypes
                      ..clear()
                      ..addAll(FamilyServiceTypes.all);
                  }
                });
              },
              icon: Icon(
                _selectedServiceTypes.length == FamilyServiceTypes.all.length
                    ? Icons.deselect
                    : Icons.select_all,
                size: responsive.iconSize(16.0),
              ),
              label: Text(
                _selectedServiceTypes.length == FamilyServiceTypes.all.length
                    ? 'Deselect All'
                    : 'Select All',
                style: TextStyle(fontSize: responsive.fontSize(13.0)),
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedServiceTypes.length} of ${FamilyServiceTypes.all.length} selected',
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(8.0)),

        ...FamilyServiceTypes.all.map((type) {
          final isSelected = _selectedServiceTypes.contains(type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServiceTypes.remove(type);
                  } else {
                    _selectedServiceTypes.add(type);
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(14.0),
                  vertical: responsive.spacing(12.0),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: isSelected
                      ? Border.all(color: _primaryColor, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _serviceIcon(type),
                      size: responsive.iconSize(22.0),
                      color: isSelected
                          ? _primaryColor
                          : AppColors.textSecondary,
                    ),
                    SizedBox(width: responsive.spacing(12.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FamilyServiceTypes.label(type),
                            style: TextStyle(
                              fontSize: responsive.fontSize(14.0),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _serviceDescription(type),
                            style: TextStyle(
                              fontSize: responsive.fontSize(12.0),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _primaryColor : AppColors.gray300,
                          width: 2,
                        ),
                        color: isSelected ? _primaryColor : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Step 3: Review ───────────────────────────────────────────────────────

  Widget _buildReviewStep(ResponsiveUtils responsive) {
    final selectedHomes = _homes
        .where((h) => _selectedHomeIds.contains(h.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionIntro(
          icon: Icons.checklist_outlined,
          title: 'Review & Send',
          subtitle:
              'Double-check everything before sending the invitation. An email will be sent to the address below.',
          responsive: responsive,
        ),
        SizedBox(height: responsive.spacing(20.0)),

        // ── Summary card ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(16.0)),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_nameController.text.trim().isNotEmpty) ...[
                _buildReviewRow(
                  icon: Icons.person_outlined,
                  label: 'Name',
                  value: _nameController.text.trim(),
                  responsive: responsive,
                ),
                _buildDivider(),
              ],
              _buildReviewRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: _emailController.text.trim().isEmpty
                    ? '—'
                    : _emailController.text.trim(),
                responsive: responsive,
              ),
              _buildDivider(),
              _buildReviewRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: _roleLabel(_selectedRole),
                responsive: responsive,
              ),
              if (_selectedRelation.isNotEmpty) ...[
                _buildDivider(),
                _buildReviewRow(
                  icon: Icons.people_outlined,
                  label: 'Relation',
                  value: _selectedRelation,
                  responsive: responsive,
                ),
              ],
              _buildDivider(),
              // ── Homes + their assets ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: responsive.iconSize(18.0),
                          color: _primaryColor,
                        ),
                        SizedBox(width: responsive.spacing(12.0)),
                        Text(
                          'Homes',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12.0),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedHomes.isEmpty
                              ? 'None'
                              : '${selectedHomes.length} home${selectedHomes.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    // Per-home cards below, full-width
                    if (selectedHomes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: selectedHomes.map((home) {
                            final assetIds =
                                _selectedAssetIdsByHome[home.id] ?? {};
                            final assets = _assetsByHome[home.id] ?? [];
                            final selectedAssets = assets
                                .where((a) => assetIds.contains(a.id))
                                .toList();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Home address line
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.home_outlined,
                                        size: 15,
                                        color: _primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          home.address,
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(13.0),
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Assets count + chips
                                  Padding(
                                    padding: const EdgeInsets.only(left: 21),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedAssets.isEmpty
                                              ? 'No assets selected'
                                              : '${selectedAssets.length} asset${selectedAssets.length != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(12.0),
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (selectedAssets.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: selectedAssets
                                                  .map(
                                                    (a) => _buildChip(
                                                      a.name,
                                                      responsive,
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.miscellaneous_services_outlined,
                      size: responsive.iconSize(18.0),
                      color: _primaryColor,
                    ),
                    SizedBox(width: responsive.spacing(12.0)),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Services',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12.0),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedServiceTypes.isEmpty
                                ? 'None'
                                : '${_selectedServiceTypes.length} service${_selectedServiceTypes.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14.0),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_selectedServiceTypes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: _selectedServiceTypes
                                    .map(
                                      (t) => _buildChip(
                                        FamilyServiceTypes.label(t),
                                        responsive,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              _buildReviewRow(
                icon: Icons.auto_awesome,
                label: 'Future Assets',
                value: _grantFutureAssets
                    ? 'Auto-grant enabled'
                    : 'Manual only',
                responsive: responsive,
              ),
            ],
          ),
        ),

        SizedBox(height: responsive.spacing(16.0)),

        // Info note
        Container(
          padding: EdgeInsets.all(responsive.spacing(14.0)),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.infoDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The invite link expires in 7 days. Resend if they don\'t accept in time.',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared section intro ─────────────────────────────────────────────────

  Widget _buildSectionIntro({
    required IconData icon,
    required String title,
    required String subtitle,
    required ResponsiveUtils responsive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
        SizedBox(width: responsive.spacing(12.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(17.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: responsive.fontSize(13.0),
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Reusable widgets ─────────────────────────────────────────────────────

  Widget _buildLabel(String text, ResponsiveUtils responsive) {
    return Text(
      text,
      style: TextStyle(
        fontSize: responsive.fontSize(13.0),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        dropdownColor: cs.surface,
        iconEnabledColor: AppColors.textPrimary,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
        ),
        items: items.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
    required ResponsiveUtils responsive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: responsive.iconSize(18.0), color: _primaryColor),
          SizedBox(width: responsive.spacing(12.0)),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(14.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: AppColors.gray100);

  Widget _buildChip(String label, ResponsiveUtils responsive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: responsive.fontSize(11.0),
          color: _primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'viewer':
        return 'Viewer';
      default:
        return 'Member';
    }
  }

  IconData _serviceIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build_outlined;
      case 'repair':
        return Icons.home_repair_service_outlined;
      case 'booking':
        return Icons.calendar_today_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }

  String _serviceDescription(String type) {
    switch (type) {
      case 'maintenance':
        return 'View and manage maintenance tasks';
      case 'repair':
        return 'Book and track repair services';
      case 'booking':
        return 'Schedule home service appointments';
      case 'shopping':
        return 'Browse and purchase products';
      default:
        return 'Access ${FamilyServiceTypes.label(type)} features';
    }
  }
}