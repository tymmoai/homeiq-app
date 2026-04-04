import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../providers/warranty_status_provider.dart';
import '../../../services/asset_api_service.dart';
import '../../../services/protection_plan_service.dart';
import '../../../theme/app_header_config.dart';
import '../../../theme/asset_detail_colors.dart';
import '../../../utils/responsive_utils.dart';
import '../../maintenance/screens/diy_maintenance_screen.dart';
import '../../maintenance/services/maintenance_service.dart';
import '../../shared/models/maintenance_models.dart';
import '../helpers/asset_detail_helpers.dart';
import '../helpers/document_action_handlers.dart';
import '../widgets/detail_widgets/asset_detail_popups.dart';
import '../widgets/detail_widgets/key_risk_section_widget.dart';
import '../widgets/detail_widgets/maintenance_history_card_widget.dart';
import '../widgets/document_widgets/edit_document_sheet.dart';
import '../widgets/tabs/docs_tab_widget.dart';
import '../widgets/tabs/issues_tab_widget.dart';
import '../widgets/tabs/maintenance_tab_widget.dart';
import '../widgets/tabs/overview_tab_widget.dart';
import './edit_asset_details_screen.dart';

// App Color Theme Constants
// Use AssetDetailColors from theme/asset_detail_colors.dart

class AssetDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> asset; // Asset details
  final String? initialTab; // Optional initial tab to open
  final bool skipPopup; // Skip showing warranty/upgrade popups

  const AssetDetailScreen({
    super.key,
    required this.asset,
    this.initialTab,
    this.skipPopup = false,
  });

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedTab; // Default tab for navigation
  String? _openMenuDocId; // Track which document menu is open (doc identifier)
  final List<Map<String, dynamic>> _uploadedDocuments =
      []; // Store uploaded documents
  final List<Map<String, dynamic>> _defaultDocuments =
      []; // Store default documents (can be deleted)
  Reminder? _overviewMaintenanceReminder; // Mock reminder for overview tab
  final List<MaintenanceRecord> _maintenanceHistory =
      []; // Store maintenance history
  final Map<String, DateTime> _completedTaskMap =
      {}; // Track task names that have been marked as done with completion date
  final Map<String, SkipReason> _skippedTaskMap =
      {}; // Track task names that have been skipped with their reasons
  List<Map<String, dynamic>>?
  _cachedMaintenanceRecords; // Cache for maintenance records

  // Real backend data for Issues and Documents tabs
  List<Map<String, dynamic>> _apiIssues = [];
  bool _isLoadingIssues = false;
  bool _issuesLoadFailed = false;
  bool _isLoadingDocs = false;
  bool _docsLoadFailed = false;

  // Scroll controllers for each tab
  final ScrollController _overviewScrollController = ScrollController();
  final ScrollController _maintenanceScrollController = ScrollController();
  final ScrollController _issueStatusScrollController = ScrollController();
  final ScrollController _docsScrollController = ScrollController();

  // AI assist button pulse animation
  late final AnimationController _aiPulseController;
  late final Animation<double> _aiPulseScale;

  // State to track if scrolled down
  bool _isScrolledDown = false;

  // State to track FAB expanded state (for swipe gesture)
  bool _isFabManuallyCollapsed = false;

  // Auto-collapse FAB after 5 seconds
  bool _fabAutoCollapsed = false;

  // State to track warranty expired popup
  bool _showWarrantyExpiredPopup = false;
  bool _showUpgradePopup = false;
  bool _popupShown = false; // Prevent showing popup multiple times

  // State to track if asset has an active protection plan
  bool _hasActiveProtectionPlan = false;
  Map<String, dynamic>? _protectionPlanData;

  @override
  void initState() {
    super.initState();

    // Set initial tab from widget parameter or default to Overview
    _selectedTab = widget.initialTab ?? 'Overview';

    // Check for active protection plan and update asset warranty status
    _checkAndApplyProtectionPlan();

    _aiPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _aiPulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _aiPulseController, curve: Curves.easeInOut),
    );

    // Auto-collapse FAB after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isScrolledDown && !_isFabManuallyCollapsed) {
        setState(() {
          _fabAutoCollapsed = true;
        });
      }
    });

    // Check if warranty expired and show popup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_popupShown) return; // Prevent showing popup multiple times
      if (widget.skipPopup) {
        return; // Skip if coming back from protection plan flow
      }
      if (_hasActiveProtectionPlan) return; // Skip if already has active plan

      final lifecycleStatus =
          widget.asset['lifecycleStatus']?.toString() ?? 'active';
      final isReplaced = lifecycleStatus == 'replaced';

      // Use the same computeWarrantyStatus() that the list card uses so the
      // popup decision is always consistent with what the badge shows.
      final warrantyStatusEnum = computeWarrantyStatus(widget.asset);
      final isWarrantyExpired = warrantyStatusEnum == WarrantyStatus.expired;

      final healthScore =
          (widget.asset['healthScore'] as num?)?.toDouble() ?? 8.0;
      // Replaced assets are never eligible for upgrade (already replaced)
      final isUpgradeEligible = healthScore <= 6.5 && !isReplaced;

      if (isWarrantyExpired && isUpgradeEligible) {
        // Show both popups sequentially - start with protection plan
        _popupShown = true;
        setState(() {
          _showWarrantyExpiredPopup = true;
        });
      } else if (isWarrantyExpired) {
        // Show only protection plan popup
        _popupShown = true;
        setState(() {
          _showWarrantyExpiredPopup = true;
        });
      } else if (isUpgradeEligible) {
        // Show only upgrade popup
        _popupShown = true;
        setState(() {
          _showUpgradePopup = true;
        });
      }
    });

    // Add scroll listeners
    _overviewScrollController.addListener(_onScroll);
    _maintenanceScrollController.addListener(_onScroll);
    _issueStatusScrollController.addListener(_onScroll);
    _docsScrollController.addListener(_onScroll);
    // Initialize with hardcoded reminder as fallback, then try to load real data
    final bool isNewAsset = widget.asset['isNewAsset'] == true;
    _overviewMaintenanceReminder = isNewAsset
        ? null
        : createAssetSpecificReminder(widget.asset);
    // Load real data from backend
    _loadDocsFromBackend();
    _loadIssuesFromBackend();
    _loadUpcomingMaintenance();
    _refreshAssetFromBackend();
  }

  /// Re-fetch this asset from backend so we always display the latest saved
  /// data, even if the asset map was passed via route with stale values.
  Future<void> _refreshAssetFromBackend() async {
    final assetId = widget.asset['id']?.toString() ?? '';
    if (assetId.isEmpty) return;
    try {
      final freshDto = await AssetApiService.instance.getAsset(assetId);
      if (!mounted) return;
      // Merge all scalar backend fields into the live asset map so every
      // widget re-renders with up-to-date data without requiring a full
      // Riverpod reload while the screen is still open.
      final freshMap = freshDto.toLegacyMap();
      setState(() {
        freshMap.forEach((key, value) {
          if (value != null) widget.asset[key] = value;
        });
      });
    } on Object catch (_) {
      // Non-fatal: screen already shows the route-passed data as fallback.
    }
  }

  /// Load real upcoming/pending maintenance from backend for overview tab.
  Future<void> _loadUpcomingMaintenance() async {
    final assetId = widget.asset['id']?.toString() ?? '';
    if (assetId.isEmpty) return;
    try {
      final records = await AssetApiService.instance.getServiceHistory(assetId);
      // Find first upcoming or pending record
      final upcoming = records.where((r) {
        final status = r['status']?.toString() ?? 'completed';
        return status == 'upcoming' || status == 'pending';
      }).toList();
      if (upcoming.isNotEmpty && mounted) {
        final r = upcoming.first;
        final nextDueAt = DateTime.tryParse(r['nextDueAt']?.toString() ?? '');
        final dueDate =
            nextDueAt ?? DateTime.now().add(const Duration(days: 30));
        // Create a Reminder from the real backend record
        // Use createAssetSpecificReminder as enrichment source for display fields
        final fallback = createAssetSpecificReminder(widget.asset);
        setState(() {
          _overviewMaintenanceReminder = Reminder(
            id: r['id']?.toString() ?? 'overview-$assetId',
            assetId: assetId,
            assetName: widget.asset['name'] as String? ?? 'Asset',
            assetLocation:
                (widget.asset['location'] as String?)?.isNotEmpty == true
                ? widget.asset['location'] as String
                : null,
            taskId: r['id']?.toString() ?? fallback.taskId,
            taskName: r['title']?.toString() ?? fallback.taskName,
            taskDescription:
                r['description']?.toString() ?? fallback.taskDescription,
            whyItMatters: fallback.whyItMatters,
            estimatedEffort: fallback.estimatedEffort,
            dueDate: dueDate,
            status: ReminderStatus.upcoming,
            priority: fallback.priority,
            riskLevel: fallback.riskLevel,
          );
        });
      }
    } on Object catch (_) {
      // Non-fatal: keep the hardcoded fallback reminder
    }
  }

  /// Load documents for this asset from the backend API.
  Future<void> _loadDocsFromBackend() async {
    final assetId = widget.asset['id']?.toString() ?? '';
    if (assetId.isEmpty) return;
    setState(() {
      _isLoadingDocs = true;
      _docsLoadFailed = false;
    });
    try {
      final docs = await AssetApiService.instance.getDocuments(assetId);
      if (!mounted) return;
      final now = DateTime.now();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      setState(() {
        _uploadedDocuments
          ..clear()
          ..addAll(
            docs.map((d) {
              final createdAt = DateTime.tryParse(
                d['createdAt']?.toString() ?? '',
              );
              final dateStr = createdAt != null
                  ? '${months[createdAt.month - 1]} ${createdAt.year}'
                  : '${months[now.month - 1]} ${now.year}';
              final name = d['name'] as String? ?? 'Document';
              final ext = name.contains('.')
                  ? name.split('.').last.toLowerCase()
                  : '';
              final isImage = [
                'jpg',
                'jpeg',
                'png',
                'heic',
                'webp',
              ].contains(ext);
              final sizeBytes = d['sizeBytes'] as int?;
              final sizeStr = sizeBytes != null
                  ? sizeBytes > 1024 * 1024
                        ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                        : '${(sizeBytes / 1024).round()} KB'
                  : '';
              return {
                'id': d['id'],
                'title': name,
                'date': dateStr,
                'fileInfo': [
                  if (isImage) 'Image',
                  if (ext.isNotEmpty) ext.toUpperCase(),
                  if (sizeStr.isNotEmpty) sizeStr,
                ].join(' • '),
                'imagePath': d['url'] ?? '',
                'type': d['type'] ?? 'other',
                'mimeType': d['mimeType'],
                'isLocalFile': false,
                'backendId': d['id'],
              };
            }),
          );
        _isLoadingDocs = false;
      });
    } on Object catch (e) {
      debugPrint('Failed to load documents: $e');
      if (mounted) {
        setState(() {
          _isLoadingDocs = false;
          _docsLoadFailed = true;
        });
      }
    }
  }

  /// Persist a newly-uploaded document to the backend, then refresh the doc list.
  Future<void> _persistDocumentToBackend(Map<String, dynamic> newDoc) async {
    final assetId = widget.asset['id']?.toString() ?? '';
    if (assetId.isEmpty) return;
    try {
      const allowed = {
        'warranty',
        'manual',
        'receipt',
        'invoice',
        'bill',
        'photo',
        'other',
      };
      final rawType = newDoc['type']?.toString().toLowerCase() ?? 'other';
      final docType = allowed.contains(rawType) ? rawType : 'other';
      await AssetApiService.instance.addDocument(
        assetId: assetId,
        name: newDoc['title']?.toString() ?? 'Document',
        type: docType,
        mimeType: newDoc['mimeType'] as String?,
        sizeBytes: newDoc['sizeBytes'] as int?,
      );
      // Reload so backendId is populated and the list is in sync
      await _loadDocsFromBackend();
    } on Object catch (_) {
      debugPrint('Failed to persist document to backend: \$e');
    }
  }

  /// Load issues for this asset from the backend API.
  Future<void> _loadIssuesFromBackend() async {
    final assetId = widget.asset['id']?.toString() ?? '';
    if (assetId.isEmpty) return;
    setState(() {
      _isLoadingIssues = true;
      _issuesLoadFailed = false;
    });
    try {
      final issues = await AssetApiService.instance.getAssetIssues(assetId);
      if (!mounted) return;
      setState(() {
        _apiIssues = issues;
        _isLoadingIssues = false;
      });
    } on Object catch (e) {
      debugPrint('Failed to load issues: $e');
      if (mounted) {
        setState(() {
          _isLoadingIssues = false;
          _issuesLoadFailed = true;
        });
      }
    }
  }

  void _onScroll() {
    ScrollController? currentController;
    switch (_selectedTab) {
      case 'Overview':
        currentController = _overviewScrollController;
        break;
      case 'Maintenance':
        currentController = _maintenanceScrollController;
        break;
      case 'Issue Status':
        currentController = _issueStatusScrollController;
        break;
      case 'Documents':
        currentController = _docsScrollController;
        break;
    }

    if (currentController != null && currentController.hasClients) {
      final scrollPosition = currentController.position.pixels;
      final isScrolled = scrollPosition > 50; // Threshold for scroll detection

      if (isScrolled != _isScrolledDown) {
        setState(() {
          _isScrolledDown = isScrolled;
        });
      }
    }
  }

  /// Check if asset has an active protection plan and update warranty state accordingly
  Future<void> _checkAndApplyProtectionPlan() async {
    final assetId = widget.asset['id']?.toString() ?? '';
    if (assetId.isEmpty) return;

    final hasActivePlan = await ProtectionPlanService.applyPlanToAsset(
      widget.asset,
    );
    final planData = await ProtectionPlanService.getActivePlan(assetId);

    if (mounted && hasActivePlan) {
      setState(() {
        _hasActiveProtectionPlan = true;
        _protectionPlanData = planData;
        // Since we mutated the asset map, prevent warranty expired popup from showing
        _popupShown = true;
      });
    }
  }

  @override
  void didUpdateWidget(AssetDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the asset has changed, reset all asset-specific state
    if (oldWidget.asset['id'] != widget.asset['id']) {
      setState(() {
        // Reset asset-specific data
        _overviewMaintenanceReminder = createAssetSpecificReminder(
          widget.asset,
        );
        _cachedMaintenanceRecords = null;
        _completedTaskMap.clear();
        _skippedTaskMap.clear();
        _maintenanceHistory.clear();
        _hasActiveProtectionPlan = false;
        _protectionPlanData = null;
        _selectedTab = 'Overview'; // Reset to overview tab
      });
      // Re-check protection plan for new asset
      _checkAndApplyProtectionPlan();
      // Reload real data for new asset
      _loadDocsFromBackend();
      _loadIssuesFromBackend();
      _refreshAssetFromBackend();
    }
  }

  @override
  void dispose() {
    _aiPulseController.dispose();
    _overviewScrollController.removeListener(_onScroll);
    _overviewScrollController.dispose();
    _maintenanceScrollController.removeListener(_onScroll);
    _maintenanceScrollController.dispose();
    _issueStatusScrollController.removeListener(_onScroll);
    _issueStatusScrollController.dispose();
    _docsScrollController.removeListener(_onScroll);
    _docsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthScore =
        (widget.asset['healthScore'] as num?)?.toDouble() ?? 8.0;
    final assetName = widget.asset['name'] as String;

    // Show warranty expired popup if needed
    if (_showWarrantyExpiredPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final warranty = widget.asset['warranty']?.toString() ?? '';
        final warrantyEndDate = widget.asset['warrantyEndDate']?.toString();
        final warrantyStatus = getWarrantyStatusFromDate(
          warrantyEndDate,
          warranty,
        );
        final isWarrantyExpired =
            warranty.toLowerCase() == 'expired' || warrantyStatus == 'expired';

        if (!isWarrantyExpired) return;

        final currentYear = DateTime.now().year;
        final rawPurchaseYear = widget.asset['purchaseYear'];
        int purchaseYear;
        if (rawPurchaseYear is int) {
          purchaseYear = rawPurchaseYear;
        } else if (rawPurchaseYear is String) {
          purchaseYear = int.tryParse(rawPurchaseYear) ?? currentYear;
        } else {
          purchaseYear = currentYear;
        }

        final ageYears = currentYear - purchaseYear;
        final lifecycleStatus =
            widget.asset['lifecycleStatus']?.toString() ?? 'active';
        final isReplaced = lifecycleStatus == 'replaced';
        final showUpgradeNext = healthScore <= 6.5 && !isReplaced;

        setState(() {
          _showWarrantyExpiredPopup = false;
        });

        showProtectionPlanModal(
          dialogContext: context,
          mainContext: context,
          warrantyEndDate: warrantyEndDate,
          showUpgradeNext: showUpgradeNext,
          healthScore: healthScore,
          ageYears: ageYears,
          asset: widget.asset,
          onCheckProtectionPlan: _checkAndApplyProtectionPlan,
        );
      });
    }

    // Show upgrade popup if needed
    if (_showUpgradePopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final currentYear = DateTime.now().year;
        final rawPurchaseYear = widget.asset['purchaseYear'];
        int purchaseYear;
        if (rawPurchaseYear is int) {
          purchaseYear = rawPurchaseYear;
        } else if (rawPurchaseYear is String) {
          purchaseYear = int.tryParse(rawPurchaseYear) ?? currentYear;
        } else {
          purchaseYear = currentYear;
        }

        final ageYears = currentYear - purchaseYear;

        setState(() {
          _showUpgradePopup = false;
        });

        showUpgradeModal(
          context: context,
          healthScore: healthScore,
          ageYears: ageYears,
          asset: widget.asset,
        );
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Column(
          children: [
            // Header with Back Button and Asset Name - using centralized config
            AppHeaderConfig.buildFixedHeader(
              context: context,
              child: _buildHeader(context, assetName),
            ),
            // Tab Menu Bar
            _buildTabBar(),
            // Tab Content
            Expanded(child: _buildTabContent(healthScore)),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _aiPulseScale,
          builder: (context, child) => Transform.scale(
            scale: _aiPulseScale.value,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                // Detect left-to-right swipe
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 0) {
                  setState(() {
                    _isFabManuallyCollapsed = !_isFabManuallyCollapsed;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child:
                    (_isScrolledDown ||
                        _isFabManuallyCollapsed ||
                        _fabAutoCollapsed)
                    ? FloatingActionButton(
                        onPressed: () {
                          // Navigate to AI Fix Problem flow
                          context.push('/ai-fix-problem', extra: widget.asset);
                        },
                        backgroundColor: AppColors.primary,
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : FloatingActionButton.extended(
                        onPressed: () {
                          // Navigate to AI Fix Problem flow
                          context.push('/ai-fix-problem', extra: widget.asset);
                        },
                        backgroundColor: AppColors.primary,
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.textOnPrimary,
                        ),
                        label: const Text(
                          AppStrings.aiName,
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String assetName) {
    final responsive = ResponsiveUtils(context);
    return Row(
      children: [
        AppHeaderConfig.buildBackButton(
          context,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        SizedBox(width: responsive.spacing(16.0)),
        Expanded(
          child: Text(
            assetName,
            style: AppHeaderConfig.titleStyle(responsive),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final responsive = ResponsiveUtils(context);
    final tabs = ['Overview', 'Maintenance', 'Issue Status', 'Documents'];

    return Container(
      color: AssetDetailColors.surfaceColor,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(16.0),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.spacing(10.0),
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AssetDetailColors.primaryDark
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13.0),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AssetDetailColors.primaryDark
                          : AssetDetailColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(double healthScore) {
    switch (_selectedTab) {
      case 'Overview':
        return _buildOverviewTab(healthScore);
      case 'Maintenance':
        return _buildMaintenanceTab();
      case 'Issue Status':
        if (_issuesLoadFailed && _apiIssues.isEmpty) {
          return _buildLoadError(
            'Failed to load issues',
            _loadIssuesFromBackend,
          );
        }
        return IssuesTabWidget(
          asset: widget.asset,
          scrollController: _issueStatusScrollController,
          issues: _apiIssues,
          isLoading: _isLoadingIssues,
          onIssueCreated: _loadIssuesFromBackend,
        );
      case 'Documents':
        return _buildDocsTab();
      default:
        return _buildOverviewTab(healthScore);
    }
  }

  // Overview Tab Content
  Widget _buildOverviewTab(double healthScore) {
    return OverviewTabWidget(
      asset: widget.asset,
      healthScore: healthScore,
      scrollController: _overviewScrollController,
      overviewMaintenanceReminder: _overviewMaintenanceReminder,
      isOwner: ref.watch(selectedHomeIsOwnerProvider),
      onEditAssetDetails: _showEditAssetDetailsDrawer,
      onMaintenanceDone: _handleMaintenanceDone,
      onMaintenanceSnooze: _handleMaintenanceSnooze,
      onMaintenanceSkip: _handleMaintenanceSkip,
      onOrderParts: _handleOrderParts,
      onDIY: _handleDIY,
      keyRiskSectionBuilder: (healthScore, ageYears, assetType) =>
          KeyRiskSectionWidget(
            healthScore: healthScore,
            ageYears: ageYears,
            assetType: assetType,
          ),
      gridDetailItemBuilder: (label, value, {valueColor}) =>
          GridDetailItem(label: label, value: value, valueColor: valueColor),
      getBrand: getBrandFromName,
      getWarrantyStatus: getWarrantyStatusFromDate,
      getAssetAge: getAssetAge,
      hasActiveProtectionPlan: _hasActiveProtectionPlan,
      protectionPlanData: _protectionPlanData,
      onProtectionPlanNavigate: () {
        context.push('/warranties', extra: widget.asset).then((_) {
          _checkAndApplyProtectionPlan();
        });
      },
    );
  }

  // Maintenance Tab Content - Only shows Maintenance History
  Widget _buildMaintenanceTab() {
    return MaintenanceTabWidget(
      parentContext: context,
      asset: widget.asset,
      maintenanceScrollController: _maintenanceScrollController,
      cachedMaintenanceRecords: _cachedMaintenanceRecords,
      completedTaskMap: _completedTaskMap,
      skippedTaskMap: _skippedTaskMap,
      maintenanceHistory: _maintenanceHistory,
      onTabMaintenanceDone: _handleTabMaintenanceDone,
      onTabMaintenanceSnooze: _handleTabMaintenanceSnooze,
      onTabMaintenanceSkip: _handleTabMaintenanceSkip,
      onTabOrderParts: _handleTabOrderParts,
      onTabDiy: _handleTabDiy,
      buildMaintenanceHistoryCard: buildMaintenanceHistoryCard,
      onMaintenanceRecordsUpdated: (records) {
        if (mounted) {
          setState(() {
            _cachedMaintenanceRecords = records;
          });
        }
      },
    );
  }

  // Docs Tab Content
  Widget _buildDocsTab() {
    if (_isLoadingDocs && _uploadedDocuments.isEmpty) {
      return Container(
        color: AppColors.backgroundGray50,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_docsLoadFailed && _uploadedDocuments.isEmpty) {
      return _buildLoadError('Failed to load documents', _loadDocsFromBackend);
    }
    final isViewer = ref.watch(selectedHomeIsViewerProvider);
    return DocsTabWidget(
      scrollController: _docsScrollController,
      uploadedDocuments: _uploadedDocuments,
      defaultDocuments: _defaultDocuments,
      openMenuDocId: _openMenuDocId,
      onMenuToggle: (docId) {
        setState(() {
          _openMenuDocId = docId;
        });
      },
      onMenuClose: () {
        setState(() {
          _openMenuDocId = null;
        });
      },
      onEditDocument:
          ({
            required bool isUploaded,
            int? documentIndex,
            int? defaultDocIndex,
          }) => isViewer
          ? _showViewerBlockedSnackBar('edit documents')
          : _showEditDocumentBottomSheet(
              isUploaded: isUploaded,
              documentIndex: documentIndex,
              defaultDocIndex: defaultDocIndex,
            ),
      onDownloadDocument:
          ({
            required bool isUploaded,
            int? documentIndex,
            int? defaultDocIndex,
            required String imagePath,
            required String title,
          }) => handleDocumentDownload(
            context: context,
            imagePath: imagePath,
            title: title,
          ),
      onShareDocument:
          ({
            required bool isUploaded,
            int? documentIndex,
            int? defaultDocIndex,
            required String imagePath,
            required String title,
          }) => handleDocumentShare(
            context: context,
            imagePath: imagePath,
            title: title,
          ),
      onDeleteDocument:
          ({required bool isUploaded, int? uploadedIndex, int? defaultIndex}) =>
              isViewer
              ? _showViewerBlockedSnackBar('delete documents')
              : showDeleteDocumentDialog(
                  context: context,
                  onConfirmDelete: () {
                    // Capture backendId before mutating the list
                    final backendId = isUploaded && uploadedIndex != null
                        ? _uploadedDocuments[uploadedIndex]['backendId']
                              ?.toString()
                        : null;
                    setState(() {
                      if (isUploaded && uploadedIndex != null) {
                        _uploadedDocuments.removeAt(uploadedIndex);
                      } else if (!isUploaded && defaultIndex != null) {
                        _defaultDocuments.removeAt(defaultIndex);
                      }
                      _openMenuDocId = null;
                    });
                    // Delete from backend if we have a backend record ID
                    if (backendId != null) {
                      final assetId = widget.asset['id']?.toString() ?? '';
                      AssetApiService.instance
                          .deleteDocument(assetId, backendId)
                          .then((_) => _loadDocsFromBackend())
                          .catchError((e) {
                            debugPrint('Backend doc delete failed: \$e');
                            return null;
                          });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document deleted successfully'),
                        backgroundColor: AssetDetailColors.successColor,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
      onUploadDocument: isViewer
          ? () => _showViewerBlockedSnackBar('upload documents')
          : _showUploadDocumentBottomSheet,
    );
  }

  void _showViewerBlockedSnackBar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Viewers cannot $action. Contact the home owner to update your permissions.',
        ),
        backgroundColor: AssetDetailColors.warningColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLoadError(String message, VoidCallback onRetry) {
    return Container(
      color: AppColors.backgroundGray50,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AssetDetailColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AssetDetailColors.primaryDark,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDocumentBottomSheet({
    required bool isUploaded,
    int? documentIndex,
    int? defaultDocIndex,
  }) {
    if (isUploaded && documentIndex == null) return;
    if (!isUploaded && defaultDocIndex == null) return;

    final document = isUploaded
        ? _uploadedDocuments[documentIndex!]
        : _defaultDocuments[defaultDocIndex!];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditDocumentBottomSheet(
        document: document,
        onSave: (updatedDocument) {
          setState(() {
            if (isUploaded) {
              _uploadedDocuments[documentIndex!] = updatedDocument;
            } else {
              _defaultDocuments[defaultDocIndex!] = updatedDocument;
            }
            _openMenuDocId = null;
          });
        },
      ),
    );
  }

  void _showUploadDocumentBottomSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await pickAndUploadDocument(
                  context: this.context,
                  source: ImageSource.camera,
                  onDocumentUploaded: (newDoc) {
                    setState(() {
                      _uploadedDocuments.add(newDoc);
                    });
                    _persistDocumentToBackend(newDoc);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await pickAndUploadDocument(
                  context: this.context,
                  source: ImageSource.gallery,
                  onDocumentUploaded: (newDoc) {
                    setState(() {
                      _uploadedDocuments.add(newDoc);
                    });
                    _persistDocumentToBackend(newDoc);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose from Files'),
              onTap: () async {
                Navigator.pop(context);
                await pickAndUploadDocumentFromFiles(
                  context: this.context,
                  onDocumentUploaded: (newDoc) {
                    setState(() {
                      _uploadedDocuments.add(newDoc);
                    });
                    _persistDocumentToBackend(newDoc);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show edit asset details drawer
  void _showEditAssetDetailsDrawer() {
    // Navigate to the edit asset details screen (full screen)
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (ctx) => EditAssetDetailsScreen(
              asset: widget.asset,
              onSave: (updatedFields) async {
                // Update local state immediately for responsive UI
                setState(() {
                  updatedFields.forEach((key, value) {
                    widget.asset[key] = value;
                  });
                });

                // Persist to backend
                final assetId = widget.asset['id']?.toString();
                if (assetId != null) {
                  // Map form field keys to backend field names
                  final backendData = <String, dynamic>{};
                  if (updatedFields.containsKey('name')) {
                    backendData['name'] = updatedFields['name'];
                  }
                  if (updatedFields.containsKey('brand')) {
                    backendData['brand'] = updatedFields['brand'];
                  }
                  if (updatedFields.containsKey('model')) {
                    backendData['model'] = updatedFields['model'];
                  }
                  if (updatedFields.containsKey('serial') ||
                      updatedFields.containsKey('serialNumber')) {
                    backendData['serialNumber'] =
                        updatedFields['serialNumber'] ?? updatedFields['serial'];
                  }
                  if (updatedFields.containsKey('location')) {
                    backendData['location'] = updatedFields['location'];
                  }
                  if (updatedFields.containsKey('manufacturer')) {
                    backendData['manufacturer'] = updatedFields['manufacturer'];
                  }
                  if (updatedFields.containsKey('productColor')) {
                    backendData['productColor'] = updatedFields['productColor'];
                  }
                  if (updatedFields.containsKey('purchasedAt')) {
                    backendData['purchasedAt'] = updatedFields['purchasedAt'];
                  }
                  if (updatedFields.containsKey('purchaseYear')) {
                    backendData['purchaseYear'] = updatedFields['purchaseYear'];
                  }
                  if (updatedFields.containsKey('purchaseMonth')) {
                    backendData['purchaseMonth'] = updatedFields['purchaseMonth'];
                  }
                  if (updatedFields.containsKey('purchaseDate')) {
                    backendData['purchaseDate'] = updatedFields['purchaseDate'];
                  }
                  if (updatedFields.containsKey('warrantyExpiresAt')) {
                    backendData['warrantyExpiresAt'] =
                        updatedFields['warrantyExpiresAt'];
                  }
                  if (updatedFields.containsKey('warrantyEndDate')) {
                    backendData['warrantyEndDate'] =
                        updatedFields['warrantyEndDate'];
                  }

                  if (backendData.isNotEmpty) {
                    try {
                      await AssetApiService.instance
                          .updateAsset(assetId, backendData);
                      // Invalidate the global assets list so the main asset tab
                      // immediately reflects the edit when the user navigates back.
                      if (mounted) {
                        ref.invalidate(assetsProvider);
                        // Small delay to ensure backend processes the update
                        await Future.delayed(const Duration(milliseconds: 300));
                        // Also refresh the current asset detail view
                        _refreshAssetFromBackend();
                      }
                    } on Object catch (e) {
                      debugPrint('Failed to persist asset edit: $e');
                    }
                  }
                }
              },
            ),
          ),
        )
        .then((_) {
          // Refresh local state when returning from edit screen
          setState(() {});
        });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Maintenance action handlers for overview tab
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleMaintenanceDone() async {
    if (_overviewMaintenanceReminder == null) return;

    try {
      // Create maintenance record from reminder
      final completedRecord = MaintenanceRecord(
        id: 'mr_${widget.asset['id']}_${DateTime.now().millisecondsSinceEpoch}',
        assetId: widget.asset['id']?.toString() ?? '1',
        taskId: _overviewMaintenanceReminder!.taskId,
        taskName: _overviewMaintenanceReminder!.taskName,
        scheduledDate: _overviewMaintenanceReminder!.dueDate,
        completedDate: DateTime.now(),
        status: MaintenanceStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to service
      final allRecords = await MaintenanceService.getAllMaintenanceRecords();
      allRecords.add(completedRecord);
      await MaintenanceService.saveMaintenanceRecords(allRecords);

      // Add to local maintenance history
      setState(() {
        _maintenanceHistory.insert(0, completedRecord);
        _overviewMaintenanceReminder = null; // Remove from overview
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance task marked as done'),
            backgroundColor: AssetDetailColors.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AssetDetailColors.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleMaintenanceSnooze() {
    if (_overviewMaintenanceReminder == null) return;

    String selectedOption = '1-week';
    DateTime? customDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Snooze Reminder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When would you like to be reminded again?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedOption,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusBadge,
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: '1-week', child: Text('1 Week')),
                  DropdownMenuItem(value: '1-month', child: Text('1 Month')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Date')),
                ],
                onChanged: (value) {
                  setModalState(() {
                    selectedOption = value ?? '1-week';
                  });
                },
              ),
              if (selectedOption == 'custom') ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setModalState(() {
                        customDate = pickedDate;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                  ),
                  child: Text(
                    customDate == null
                        ? 'Select Date'
                        : 'Selected: ${customDate!.toString().split(' ')[0]}',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        (selectedOption == 'custom' && customDate == null)
                        ? null
                        : () async {
                            if (_overviewMaintenanceReminder == null) return;

                            DateTime snoozeUntil;
                            if (selectedOption == 'custom' &&
                                customDate != null) {
                              snoozeUntil = customDate!;
                            } else if (selectedOption == '1-week') {
                              snoozeUntil = DateTime.now().add(
                                const Duration(days: 7),
                              );
                            } else {
                              snoozeUntil = DateTime.now().add(
                                const Duration(days: 30),
                              );
                            }

                            try {
                              // Create or update maintenance record with snooze
                              final recordId =
                                  'mr_${widget.asset['id']}_${_overviewMaintenanceReminder!.taskId}';
                              final allRecords =
                                  await MaintenanceService.getAllMaintenanceRecords();
                              final existingRecordIndex = allRecords.indexWhere(
                                (r) => r.id == recordId,
                              );

                              if (existingRecordIndex >= 0) {
                                // Update existing record
                                final existing =
                                    allRecords[existingRecordIndex];
                                allRecords[existingRecordIndex] =
                                    MaintenanceRecord(
                                      id: existing.id,
                                      assetId: existing.assetId,
                                      taskId: existing.taskId,
                                      taskName: existing.taskName,
                                      scheduledDate: existing.scheduledDate,
                                      completedDate: existing.completedDate,
                                      status: MaintenanceStatus.snoozed,
                                      skipReason: existing.skipReason,
                                      snoozedUntil: snoozeUntil,
                                      evidence: existing.evidence,
                                      createdAt: existing.createdAt,
                                      updatedAt: DateTime.now(),
                                    );
                              } else {
                                // Create new record
                                allRecords.add(
                                  MaintenanceRecord(
                                    id: recordId,
                                    assetId:
                                        widget.asset['id']?.toString() ?? '1',
                                    taskId:
                                        _overviewMaintenanceReminder!.taskId,
                                    taskName:
                                        _overviewMaintenanceReminder!.taskName,
                                    scheduledDate:
                                        _overviewMaintenanceReminder!.dueDate,
                                    completedDate: null,
                                    status: MaintenanceStatus.snoozed,
                                    skipReason: null,
                                    snoozedUntil: snoozeUntil,
                                    evidence: null,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                              }

                              await MaintenanceService.saveMaintenanceRecords(
                                allRecords,
                              );

                              if (!context.mounted) return;
                              setState(() {
                                _overviewMaintenanceReminder =
                                    null; // Remove from overview
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reminder postponed until ${snoozeUntil.month}/${snoozeUntil.day}/${snoozeUntil.year}',
                                  ),
                                  backgroundColor:
                                      AssetDetailColors.successColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } on Object catch (e) {
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AssetDetailColors.errorColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (selectedOption == 'custom' && customDate == null)
                          ? Colors.grey.shade300
                          : AppColors.primary,
                      foregroundColor:
                          (selectedOption == 'custom' && customDate == null)
                          ? Colors.grey.shade600
                          : Colors.white,
                    ),
                    child: const Text('Snooze'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMaintenanceSkip() {
    if (_overviewMaintenanceReminder == null) return;

    SkipReason? selectedReason;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skip Reminder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Why are you skipping this maintenance?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SkipReason>(
                initialValue: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusBadge,
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Select a reason',
                ),
                items: const [
                  DropdownMenuItem(
                    value: SkipReason.dontKnowHow,
                    child: Text("Don't know how"),
                  ),
                  DropdownMenuItem(
                    value: SkipReason.notNeeded,
                    child: Text('Not needed'),
                  ),
                  DropdownMenuItem(
                    value: SkipReason.willDoLater,
                    child: Text('Will do later'),
                  ),
                ],
                onChanged: (value) {
                  setModalState(() {
                    selectedReason = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectedReason == null
                        ? null
                        : () async {
                            if (_overviewMaintenanceReminder == null ||
                                selectedReason == null) {
                              return;
                            }

                            try {
                              // Create or update maintenance record with skip
                              final recordId =
                                  'mr_${widget.asset['id']}_${_overviewMaintenanceReminder!.taskId}';
                              final allRecords =
                                  await MaintenanceService.getAllMaintenanceRecords();
                              final existingRecordIndex = allRecords.indexWhere(
                                (r) => r.id == recordId,
                              );

                              if (existingRecordIndex >= 0) {
                                // Update existing record
                                final existing =
                                    allRecords[existingRecordIndex];
                                allRecords[existingRecordIndex] =
                                    MaintenanceRecord(
                                      id: existing.id,
                                      assetId: existing.assetId,
                                      taskId: existing.taskId,
                                      taskName: existing.taskName,
                                      scheduledDate: existing.scheduledDate,
                                      completedDate: existing.completedDate,
                                      status: MaintenanceStatus.skipped,
                                      skipReason: selectedReason!,
                                      snoozedUntil: existing.snoozedUntil,
                                      evidence: existing.evidence,
                                      createdAt: existing.createdAt,
                                      updatedAt: DateTime.now(),
                                    );
                              } else {
                                // Create new record
                                allRecords.add(
                                  MaintenanceRecord(
                                    id: recordId,
                                    assetId:
                                        widget.asset['id']?.toString() ?? '1',
                                    taskId:
                                        _overviewMaintenanceReminder!.taskId,
                                    taskName:
                                        _overviewMaintenanceReminder!.taskName,
                                    scheduledDate:
                                        _overviewMaintenanceReminder!.dueDate,
                                    completedDate: null,
                                    status: MaintenanceStatus.skipped,
                                    skipReason: selectedReason!,
                                    snoozedUntil: null,
                                    evidence: null,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                              }

                              await MaintenanceService.saveMaintenanceRecords(
                                allRecords,
                              );

                              if (!context.mounted) return;
                              setState(() {
                                _overviewMaintenanceReminder =
                                    null; // Remove from overview
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Reminder skipped. Health score may be affected.',
                                  ),
                                  backgroundColor:
                                      AssetDetailColors.successColor,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } on Object catch (e) {
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AssetDetailColors.errorColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedReason == null
                          ? Colors.grey.shade300
                          : AppColors.primary,
                      foregroundColor: selectedReason == null
                          ? Colors.grey.shade600
                          : Colors.white,
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOrderParts() {
    if (_overviewMaintenanceReminder != null) {
      context.push(
        '/maintenance/order-parts',
        extra: _overviewMaintenanceReminder,
      );
    }
  }

  void _handleDIY() {
    if (_overviewMaintenanceReminder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DIYMaintenanceScreen(
            reminder: _overviewMaintenanceReminder!,
            onMarkComplete: () => _handleMaintenanceDone(),
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Maintenance Tab Action Handlers
  // ─────────────────────────────────────────────────────────────────────────

  void _handleTabMaintenanceDone(String taskName) async {
    try {
      final assetId = widget.asset['id']?.toString() ?? '';
      final assetName = widget.asset['name']?.toString() ?? 'Asset';
      final assetType = widget.asset['type']?.toString() ?? '';

      // Create completed maintenance record
      final completedRecord = MaintenanceRecord(
        id: 'mr_${assetId}_${DateTime.now().millisecondsSinceEpoch}',
        assetId: assetId,
        taskId: taskName.toLowerCase().replaceAll(' ', '-'),
        taskName: taskName,
        scheduledDate: DateTime.now(),
        completedDate: DateTime.now(),
        status: MaintenanceStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to MaintenanceService
      final allRecords = await MaintenanceService.getAllMaintenanceRecords();
      allRecords.add(completedRecord);
      await MaintenanceService.saveMaintenanceRecords(allRecords);

      // SYNC: Create/update corresponding reminder so it appears in main maintenance tab
      await MaintenanceService.syncRecordToReminder(
        completedRecord,
        assetName: assetName,
        assetLocation: widget.asset['location']?.toString(),
        taskDescription: 'Maintenance task for $assetType',
        whyItMatters: 'Keeps your $assetType in good condition',
        estimatedEffort: '15-30 minutes',
        priority: ReminderPriority.medium,
        riskLevel: 3,
      );

      // Mark this task as completed using taskName as key
      setState(() {
        _completedTaskMap[taskName] = DateTime.now();
        _maintenanceHistory.insert(0, completedRecord);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$taskName marked as done'),
            backgroundColor: AssetDetailColors.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AssetDetailColors.errorColor,
          ),
        );
      }
    }
  }

  void _handleTabMaintenanceSnooze(String taskName) {
    String selectedOption = '1-week';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Snooze "$taskName"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...['1-week', '2-weeks', '1-month'].map((option) {
                final labels = {
                  '1-week': '1 Week',
                  '2-weeks': '2 Weeks',
                  '1-month': '1 Month',
                };
                return RadioListTile<String>(
                  title: Text(labels[option]!),
                  value: option,
                  // ignore: deprecated_member_use
                  groupValue: selectedOption,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    setModalState(() => selectedOption = value!);
                  },
                  activeColor: AssetDetailColors.primaryDark,
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final assetId = widget.asset['id']?.toString() ?? '';
                    final assetName =
                        widget.asset['name']?.toString() ?? 'Asset';
                    final assetType = widget.asset['type']?.toString() ?? '';

                    // Calculate snooze date
                    final now = DateTime.now();
                    DateTime snoozeUntil;
                    if (selectedOption == '1-week') {
                      snoozeUntil = now.add(const Duration(days: 7));
                    } else if (selectedOption == '2-weeks') {
                      snoozeUntil = now.add(const Duration(days: 14));
                    } else {
                      snoozeUntil = now.add(const Duration(days: 30));
                    }

                    try {
                      // Create or update snoozed maintenance record
                      final recordId =
                          'mr_${assetId}_${taskName.toLowerCase().replaceAll(' ', '-')}';
                      final allRecords =
                          await MaintenanceService.getAllMaintenanceRecords();
                      final existingIndex = allRecords.indexWhere(
                        (r) => r.id == recordId,
                      );

                      MaintenanceRecord snoozedRecord;
                      if (existingIndex >= 0) {
                        // Update existing record
                        final existing = allRecords[existingIndex];
                        snoozedRecord = MaintenanceRecord(
                          id: existing.id,
                          assetId: existing.assetId,
                          taskId: existing.taskId,
                          taskName: existing.taskName,
                          scheduledDate: existing.scheduledDate,
                          completedDate: existing.completedDate,
                          status: MaintenanceStatus.snoozed,
                          skipReason: existing.skipReason,
                          snoozedUntil: snoozeUntil,
                          evidence: existing.evidence,
                          createdAt: existing.createdAt,
                          updatedAt: DateTime.now(),
                        );
                        allRecords[existingIndex] = snoozedRecord;
                      } else {
                        // Create new snoozed record
                        snoozedRecord = MaintenanceRecord(
                          id: recordId,
                          assetId: assetId,
                          taskId: taskName.toLowerCase().replaceAll(' ', '-'),
                          taskName: taskName,
                          scheduledDate: now,
                          completedDate: null,
                          status: MaintenanceStatus.snoozed,
                          skipReason: null,
                          snoozedUntil: snoozeUntil,
                          evidence: null,
                          createdAt: now,
                          updatedAt: now,
                        );
                        allRecords.add(snoozedRecord);
                      }

                      await MaintenanceService.saveMaintenanceRecords(
                        allRecords,
                      );

                      // SYNC: Update corresponding reminder
                      await MaintenanceService.syncRecordToReminder(
                        snoozedRecord,
                        assetName: assetName,
                        assetLocation: widget.asset['location']?.toString(),
                        taskDescription: 'Maintenance task for $assetType',
                        whyItMatters: 'Keeps your $assetType in good condition',
                        estimatedEffort: '15-30 minutes',
                        priority: ReminderPriority.medium,
                        riskLevel: 3,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      setState(() {}); // Refresh the list

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$taskName postponed until ${snoozeUntil.month}/${snoozeUntil.day}/${snoozeUntil.year}',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } on Object catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AssetDetailColors.errorColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AssetDetailColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Snooze',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTabMaintenanceSkip(String taskName) {
    SkipReason? selectedReason;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skip Reminder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Why are you skipping this maintenance?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SkipReason>(
                initialValue: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusBadge,
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Select a reason',
                ),
                items: const [
                  DropdownMenuItem(
                    value: SkipReason.dontKnowHow,
                    child: Text("Don't know how"),
                  ),
                  DropdownMenuItem(
                    value: SkipReason.notNeeded,
                    child: Text('Not needed'),
                  ),
                  DropdownMenuItem(
                    value: SkipReason.willDoLater,
                    child: Text('Will do later'),
                  ),
                ],
                onChanged: (value) {
                  setModalState(() {
                    selectedReason = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectedReason != null
                        ? () async {
                            final assetId =
                                widget.asset['id']?.toString() ?? '';
                            final assetName =
                                widget.asset['name']?.toString() ?? 'Asset';
                            final assetType =
                                widget.asset['type']?.toString() ?? '';

                            try {
                              // Create or update skipped maintenance record
                              final recordId =
                                  'mr_${assetId}_${taskName.toLowerCase().replaceAll(' ', '-')}';
                              final allRecords =
                                  await MaintenanceService.getAllMaintenanceRecords();
                              final existingIndex = allRecords.indexWhere(
                                (r) => r.id == recordId,
                              );

                              MaintenanceRecord skippedRecord;
                              if (existingIndex >= 0) {
                                // Update existing record
                                final existing = allRecords[existingIndex];
                                skippedRecord = MaintenanceRecord(
                                  id: existing.id,
                                  assetId: existing.assetId,
                                  taskId: existing.taskId,
                                  taskName: existing.taskName,
                                  scheduledDate: existing.scheduledDate,
                                  completedDate: existing.completedDate,
                                  status: MaintenanceStatus.skipped,
                                  skipReason: selectedReason!,
                                  snoozedUntil: existing.snoozedUntil,
                                  evidence: existing.evidence,
                                  createdAt: existing.createdAt,
                                  updatedAt: DateTime.now(),
                                );
                                allRecords[existingIndex] = skippedRecord;
                              } else {
                                // Create new skipped record
                                skippedRecord = MaintenanceRecord(
                                  id: recordId,
                                  assetId: assetId,
                                  taskId: taskName.toLowerCase().replaceAll(
                                    ' ',
                                    '-',
                                  ),
                                  taskName: taskName,
                                  scheduledDate: DateTime.now(),
                                  completedDate: null,
                                  status: MaintenanceStatus.skipped,
                                  skipReason: selectedReason!,
                                  snoozedUntil: null,
                                  evidence: null,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                                allRecords.add(skippedRecord);
                              }

                              await MaintenanceService.saveMaintenanceRecords(
                                allRecords,
                              );

                              // SYNC: Update corresponding reminder
                              await MaintenanceService.syncRecordToReminder(
                                skippedRecord,
                                assetName: assetName,
                                assetLocation: widget.asset['location']
                                    ?.toString(),
                                taskDescription:
                                    'Maintenance task for $assetType',
                                whyItMatters:
                                    'Keeps your $assetType in good condition',
                                estimatedEffort: '15-30 minutes',
                                priority: ReminderPriority.medium,
                                riskLevel: 3,
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              setState(() {
                                _skippedTaskMap[taskName] = selectedReason!;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$taskName skipped'),
                                  backgroundColor: Colors.red.shade600,
                                ),
                              );
                            } on Object catch (e) {
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AssetDetailColors.errorColor,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTabOrderParts(String taskName) {
    // Create a Reminder object for the order parts screen
    final reminder = Reminder(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      assetId: widget.asset['id']?.toString() ?? '',
      assetName: widget.asset['name'] ?? 'Asset',
      assetLocation: widget.asset['location'] ?? 'Home',
      taskId: taskName.toLowerCase().replaceAll(' ', '-'),
      taskName: taskName,
      taskDescription: 'Maintenance task for ${widget.asset['name']}',
      whyItMatters: 'Important for asset maintenance and longevity',
      estimatedEffort: '30 minutes',
      dueDate: DateTime.now(),
      status: ReminderStatus.upcoming,
      priority: ReminderPriority.medium,
      riskLevel: 5,
    );

    // Navigate to order parts screen
    context.push('/maintenance/order-parts', extra: reminder).then((_) {
      _markMaintenanceCompleted(taskName, 'Parts ordered');
    });
  }

  void _handleTabDiy(String taskName) {
    // Create a Reminder object for the DIY screen
    final reminder = Reminder(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      assetId: widget.asset['id']?.toString() ?? '',
      assetName: widget.asset['name'] ?? 'Asset',
      assetLocation: widget.asset['location'] ?? 'Home',
      taskId: taskName.toLowerCase().replaceAll(' ', '-'),
      taskName: taskName,
      taskDescription: 'Maintenance task for ${widget.asset['name']}',
      whyItMatters: 'Important for asset maintenance and longevity',
      estimatedEffort: '30 minutes',
      dueDate: DateTime.now(),
      status: ReminderStatus.upcoming,
      priority: ReminderPriority.medium,
      riskLevel: 5,
    );

    // Navigate to DIY maintenance screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIYMaintenanceScreen(
          reminder: reminder,
          onMarkComplete: () =>
              _markMaintenanceCompleted(taskName, 'DIY completed'),
        ),
      ),
    );
  }

  void _markMaintenanceCompleted(String taskName, String completionType) async {
    try {
      final assetId = widget.asset['id']?.toString() ?? '';

      // Create completed record
      final completedRecord = MaintenanceRecord(
        id: 'mr_${assetId}_${DateTime.now().millisecondsSinceEpoch}',
        assetId: assetId,
        taskId: taskName.toLowerCase().replaceAll(' ', '-'),
        taskName: taskName,
        scheduledDate: DateTime.now(),
        completedDate: DateTime.now(),
        status: MaintenanceStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to local maintenance history AND mark as completed in task map
      setState(() {
        _maintenanceHistory.insert(0, completedRecord);
        _completedTaskMap[taskName] = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$taskName - $completionType'),
            backgroundColor: AssetDetailColors.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AssetDetailColors.errorColor,
          ),
        );
      }
    }
  }
}