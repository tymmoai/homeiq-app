// Add Member Bottom Sheet — multi-step invite flow wired to backend

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/api_models.dart';
import '../../../../models/family_models.dart';
import '../../../../services/api_client.dart';
import '../../../../services/asset_api_service.dart';
import '../../../../services/family_api_service.dart';
import '../../../../services/home_api_service.dart';
import '../../../../utils/responsive_utils.dart';

class AddMemberBottomSheet extends StatefulWidget {
  /// Optional: pre-select a home (e.g., from filtered view).
  final String? preselectedHomeId;

  /// Called after a successful invite is sent, so the parent can refresh.
  final VoidCallback? onInviteSent;

  const AddMemberBottomSheet({
    super.key,
    this.preselectedHomeId,
    this.onInviteSent,
  });

  @override
  State<AddMemberBottomSheet> createState() => _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends State<AddMemberBottomSheet> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  // ─── Step tracking ──────────────────────────────────────────────────────
  int _currentStep = 0; // 0=info, 1=assets, 2=services, 3=review
  static const _totalSteps = 4;

  // ─── Form controllers ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _emailController = TextEditingController();
  String _selectedRole = 'member';
  String _selectedRelation = '';
  bool _grantFutureAssets = false;

  // ─── Data ──────────────────────────────────────────────────────────────
  bool _isLoadingHomes = true;
  List<HomeDto> _homes = [];
  String? _selectedHomeId;
  bool _isLoadingAssets = false;
  List<AssetDto> _assets = [];
  final Set<String> _selectedAssetIds = {};
  final Set<String> _selectedServiceTypes = {};

  // ─── Submission ────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ─── Error states ───────────────────────────────────────────────────────
  String? _emailServerError;
  bool _homeLoadError = false;
  bool _assetLoadError = false;
  bool _homeSelectionError = false;

  @override
  void initState() {
    super.initState();
    _loadHomes();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    if (_emailServerError != null) {
      setState(() => _emailServerError = null);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadHomes() async {
    setState(() {
      _isLoadingHomes = true;
      _homeLoadError = false;
    });
    try {
      final homes = await HomeApiService.instance.getHomes();
      // Only show homes the user owns
      final ownedHomes = homes.where((h) => h.isOwner).toList();
      setState(() {
        _homes = ownedHomes;
        _isLoadingHomes = false;
        if (widget.preselectedHomeId != null &&
            ownedHomes.any((h) => h.id == widget.preselectedHomeId)) {
          _selectedHomeId = widget.preselectedHomeId;
          _loadAssetsForHome(_selectedHomeId!);
        } else if (ownedHomes.length == 1) {
          _selectedHomeId = ownedHomes.first.id;
          _loadAssetsForHome(_selectedHomeId!);
        }
      });
    } on Object catch (_) {
      setState(() {
        _isLoadingHomes = false;
        _homeLoadError = true;
      });
    }
  }

  Future<void> _loadAssetsForHome(String homeId) async {
    setState(() {
      _isLoadingAssets = true;
      _assetLoadError = false;
    });
    try {
      final assets = await AssetApiService.instance.getAssets(homeId: homeId);
      setState(() {
        _assets = assets;
        _isLoadingAssets = false;
        // Clear previous selections when home changes
        _selectedAssetIds.clear();
      });
    } on Object catch (_) {
      setState(() {
        _isLoadingAssets = false;
        _assetLoadError = true;
      });
    }
  }

  Future<void> _submitInvite() async {
    setState(() => _isSubmitting = true);
    try {
      await FamilyApiService.instance.inviteMember(
        email: _emailController.text.trim(),
        homeId: _selectedHomeId!,
        role: _selectedRole,
        relation: _selectedRelation.isNotEmpty ? _selectedRelation : null,
        grantFutureAssets: _grantFutureAssets,
        assetIds: _selectedAssetIds.isNotEmpty
            ? _selectedAssetIds.toList()
            : null,
        serviceTypes: _selectedServiceTypes.isNotEmpty
            ? _selectedServiceTypes.toList()
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${_emailController.text.trim()}'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onInviteSent?.call();
      }
    } on Object catch (e) {
      if (mounted) {
        final friendly = _friendlyInviteError(e);
        final isEmailError = e is ApiException &&
            (e.statusCode == 409 ||
                (e.statusCode == 400 &&
                    e.message.toLowerCase().contains('yourself')));
        if (isEmailError) {
          setState(() {
            _emailServerError = friendly;
            _currentStep = 0;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendly),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyInviteError(Object e) {
    if (e is ApiException) {
      final msg = e.message.toLowerCase();
      switch (e.statusCode) {
        case 400:
          if (msg.contains('yourself')) {
            return 'You cannot invite your own account.';
          }
          return e.message;
        case 403:
          return "You don't have permission to invite members to this home.";
        case 409:
          if (msg.contains('already a member')) {
            return 'This person is already a member of this home.';
          }
          if (msg.contains('already an owner')) {
            return 'This person already owns this home.';
          }
          if (msg.contains('active invitation')) {
            return 'An invitation has already been sent to this email.';
          }
          return 'This email address cannot be invited at this time.';
        case 422:
          return e.message;
        case 429:
          return 'Too many invitations sent. Please wait a moment before trying again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  // ─── Navigation ─────────────────────────────────────────────────────────

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() == true &&
            _selectedHomeId != null;
      case 1:
        return true; // Asset selection is optional
      case 2:
        return true; // Service selection is optional
      case 3:
        return !_isSubmitting;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
    if (_currentStep == 0 && _selectedHomeId == null) {
      setState(() => _homeSelectionError = true);
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: responsive.spacing(20.0),
        right: responsive.spacing(20.0),
        top: responsive.spacing(20.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(responsive),
          SizedBox(height: responsive.spacing(8.0)),
          // Step indicator
          _buildStepIndicator(responsive),
          SizedBox(height: responsive.spacing(16.0)),
          // Content
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildStepContent(responsive),
            ),
          ),
          SizedBox(height: responsive.spacing(16.0)),
          // Buttons
          _buildButtons(responsive),
          SizedBox(height: responsive.spacing(8.0)),
        ],
      ),
    );
  }

  Widget _buildHeader(ResponsiveUtils responsive) {
    final titles = [
      'Member Info',
      'Asset Access',
      'Service Access',
      'Review & Send',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite Family Member',
              style: TextStyle(
                fontSize: responsive.fontSize(18.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Step ${_currentStep + 1} of $_totalSteps — ${titles[_currentStep]}',
              style: TextStyle(
                fontSize: responsive.fontSize(12.0),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.close,
            size: responsive.iconSize(20.0),
            color: AppColors.textSecondary,
          ),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(ResponsiveUtils responsive) {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final isCompleted = i < _currentStep;
        final isCurrent = i == _currentStep;
        return Expanded(
          child: Container(
            height: responsive.spacing(4.0),
            margin: EdgeInsets.only(
              right: i < _totalSteps - 1 ? responsive.spacing(4.0) : 0,
            ),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isCurrent
                  ? _primaryColor
                  : AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

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

  // ─── Step 0: Member Info ────────────────────────────────────────────────

  Widget _buildInfoStep(ResponsiveUtils responsive) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite a family member or caregiver to help manage your home.',
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacing(16.0)),
          // Email
          _buildLabel('Email Address', responsive),
          SizedBox(height: responsive.spacing(6.0)),
          _buildTextField(
            controller: _emailController,
            hint: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
            serverErrorText: _emailServerError,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an email address';
              }
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: responsive.spacing(16.0)),
          // Home selector
          _buildLabel('Select Home', responsive),
          SizedBox(height: responsive.spacing(6.0)),
          _isLoadingHomes
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _homeLoadError
              ? _buildRetrySection(
                  message: 'Failed to load your homes.',
                  onRetry: _loadHomes,
                  responsive: responsive,
                )
              : _buildHomeSelector(responsive),
          SizedBox(height: responsive.spacing(16.0)),
          // Role & Relation row
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
                    _buildLabel('Relation (Optional)', responsive),
                    SizedBox(height: responsive.spacing(6.0)),
                    _buildDropdown(
                      value: _selectedRelation.isEmpty
                          ? null
                          : _selectedRelation,
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
      ),
    );
  }

  Widget _buildHomeSelector(ResponsiveUtils responsive) {
    if (_homes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No homes found. Please create a home first.',
          style: TextStyle(
            fontSize: responsive.fontSize(13.0),
            color: AppColors.warningOrange,
          ),
        ),
      );
    }
    final homeTiles = _homes.map((home) {
      final isSelected = home.id == _selectedHomeId;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedHomeId = home.id;
              _homeSelectionError = false;
            });
            _loadAssetsForHome(home.id);
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
                  Icons.home,
                  size: responsive.iconSize(18.0),
                  color: isSelected ? _primaryColor : AppColors.textSecondary,
                ),
                SizedBox(width: responsive.spacing(10.0)),
                Expanded(
                  child: Text(
                    home.displayName,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: responsive.iconSize(20.0),
                    color: _primaryColor,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...homeTiles,
        if (_homeSelectionError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Please select a home to continue',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }

  // ─── Step 1: Asset Selection ────────────────────────────────────────────

  Widget _buildAssetStep(ResponsiveUtils responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select which assets this member can access. Leave empty for no asset access.',
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(12.0)),
        // Select all / Deselect all
        if (_assets.isNotEmpty)
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_selectedAssetIds.length == _assets.length) {
                      _selectedAssetIds.clear();
                    } else {
                      _selectedAssetIds
                        ..clear()
                        ..addAll(_assets.map((a) => a.id));
                    }
                  });
                },
                icon: Icon(
                  _selectedAssetIds.length == _assets.length
                      ? Icons.deselect
                      : Icons.select_all,
                  size: responsive.iconSize(18.0),
                ),
                label: Text(
                  _selectedAssetIds.length == _assets.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: TextStyle(fontSize: responsive.fontSize(13.0)),
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedAssetIds.length} of ${_assets.length} selected',
                style: TextStyle(
                  fontSize: responsive.fontSize(12.0),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        SizedBox(height: responsive.spacing(8.0)),
        _isLoadingAssets
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : _assetLoadError
            ? _buildRetrySection(
                message: 'Failed to load assets for this home.',
                onRetry: () => _loadAssetsForHome(_selectedHomeId!),
                responsive: responsive,
              )
            : _assets.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.devices, size: 48, color: AppColors.gray300),
                    const SizedBox(height: 12),
                    Text(
                      'No assets in this home yet.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: _assets.map((asset) {
                  final isSelected = _selectedAssetIds.contains(asset.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedAssetIds.remove(asset.id);
                          } else {
                            _selectedAssetIds.add(asset.id);
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (asset.brand != null ||
                                      asset.category.isNotEmpty)
                                    Text(
                                      [
                                        if (asset.brand != null) asset.brand!,
                                        asset.category,
                                      ].join(' · '),
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
                                    _selectedAssetIds.add(asset.id);
                                  } else {
                                    _selectedAssetIds.remove(asset.id);
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
              ),
        SizedBox(height: responsive.spacing(12.0)),
        // Grant future assets toggle
        Container(
          padding: EdgeInsets.all(responsive.spacing(12.0)),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
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
                value: _grantFutureAssets,
                onChanged: (v) => setState(() => _grantFutureAssets = v),
                activeThumbColor: _primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 2: Service Selection ──────────────────────────────────────────

  Widget _buildServiceStep(ResponsiveUtils responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select which services this member can use. Leave empty for no service access.',
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(12.0)),
        // Select all / Deselect all
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
                size: responsive.iconSize(18.0),
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(12.0),
                  vertical: responsive.spacing(12.0),
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
                      size: responsive.iconSize(20.0),
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
                    Checkbox(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedServiceTypes.add(type);
                          } else {
                            _selectedServiceTypes.remove(type);
                          }
                        });
                      },
                      activeColor: _primaryColor,
                      checkColor: AppColors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  // ─── Step 3: Review ─────────────────────────────────────────────────────

  Widget _buildReviewStep(ResponsiveUtils responsive) {
    final selectedHome = _homes
        .where((h) => h.id == _selectedHomeId)
        .firstOrNull;
    final selectedAssets = _assets
        .where((a) => _selectedAssetIds.contains(a.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review the invitation before sending.',
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(16.0)),
        // Summary card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(16.0)),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
              _buildReviewRow(
                Icons.email,
                'Email',
                _emailController.text.trim(),
                responsive: responsive,
              ),
              _buildDivider(),
              _buildReviewRow(
                Icons.home,
                'Home',
                selectedHome?.displayName ?? 'Unknown',
                responsive: responsive,
              ),
              _buildDivider(),
              _buildReviewRow(
                Icons.badge,
                'Role',
                _roleLabel(_selectedRole),
                responsive: responsive,
              ),
              if (_selectedRelation.isNotEmpty) ...[
                _buildDivider(),
                _buildReviewRow(
                  Icons.people,
                  'Relation',
                  _selectedRelation,
                  responsive: responsive,
                ),
              ],
              _buildDivider(),
              _buildReviewRow(
                Icons.devices,
                'Assets',
                selectedAssets.isEmpty
                    ? 'None'
                    : '${selectedAssets.length} asset${selectedAssets.length != 1 ? 's' : ''}',
                responsive: responsive,
              ),
              if (selectedAssets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 36, top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: selectedAssets
                        .map((a) => _buildChip(a.name, responsive))
                        .toList(),
                  ),
                ),
              _buildDivider(),
              _buildReviewRow(
                Icons.miscellaneous_services,
                'Services',
                _selectedServiceTypes.isEmpty
                    ? 'None'
                    : '${_selectedServiceTypes.length} service${_selectedServiceTypes.length != 1 ? 's' : ''}',
                responsive: responsive,
              ),
              if (_selectedServiceTypes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 36, top: 4),
                  child: Wrap(
                    spacing: 6,
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
              _buildDivider(),
              _buildReviewRow(
                Icons.auto_awesome,
                'Future Assets',
                _grantFutureAssets ? 'Auto-grant enabled' : 'Manual only',
                responsive: responsive,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(
    IconData icon,
    String label,
    String value, {
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
            width: responsive.spacing(80.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(13.0),
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

  Widget _buildDivider() {
    return Divider(color: AppColors.gray200, height: 1);
  }

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
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
      ),
    );
  }

  // ─── Bottom Buttons ─────────────────────────────────────────────────────

  Widget _buildButtons(ResponsiveUtils responsive) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                padding: EdgeInsets.symmetric(
                  vertical: responsive.spacing(14.0),
                ),
                side: BorderSide(color: AppColors.gray300),
                elevation: 0,
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                padding: EdgeInsets.symmetric(
                  vertical: responsive.spacing(14.0),
                ),
                side: BorderSide(color: AppColors.gray300),
                elevation: 0,
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        SizedBox(width: responsive.spacing(12.0)),
        Expanded(
          child: ElevatedButton(
            onPressed: _canProceed()
                ? (_currentStep == _totalSteps - 1 ? _submitInvite : _nextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(14.0)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: responsive.iconSize(18.0),
                    width: responsive.iconSize(18.0),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    _currentStep == _totalSteps - 1 ? 'Send Invite' : 'Next',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Retry helper ─────────────────────────────────────────────────────

  Widget _buildRetrySection({
    required String message,
    required VoidCallback onRetry,
    required ResponsiveUtils responsive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(
              Icons.refresh,
              size: responsive.iconSize(16.0),
              color: AppColors.error,
            ),
            label: Text(
              'Retry',
              style: TextStyle(
                fontSize: responsive.fontSize(13.0),
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared form widgets ────────────────────────────────────────────────

  Widget _buildLabel(String text, ResponsiveUtils responsive) {
    return Text(
      text,
      style: TextStyle(
        fontSize: responsive.fontSize(12.0),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? serverErrorText,
  }) {
    final hasServerError = serverErrorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: hasServerError
                ? Border.all(color: AppColors.error, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            validator: validator,
          ),
        ),
        if (hasServerError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              serverErrorText,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      elevation: 8,
      color: AppColors.white,
      offset: const Offset(0, 8),
      itemBuilder: (context) {
        return items.entries.map((entry) {
          final isSelected = entry.key == value;
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? _primaryColor : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 18, color: _primaryColor),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
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
              items[value ?? ''] ?? items.values.first,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
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

  String _serviceDescription(String type) {
    switch (type) {
      case FamilyServiceTypes.maintenance:
        return 'View & create maintenance records';
      case FamilyServiceTypes.warranty:
        return 'View warranty plans & file claims';
      case FamilyServiceTypes.bookings:
        return 'Book home services';
      case FamilyServiceTypes.issues:
        return 'Report & view issues';
      case FamilyServiceTypes.orders:
        return 'Place orders for the home';
      case FamilyServiceTypes.protectionPlans:
        return 'View protection plans';
      default:
        return '';
    }
  }
}