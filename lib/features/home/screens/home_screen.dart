// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/asset_api_service.dart';
import '../../../services/order_service.dart';
import '../../../theme/app_header_config.dart';
import '../../../utils/responsive_utils.dart';
import '../../assets/add_asset_flow/screens/add_asset_flow_screen.dart';
import '../../maintenance/screens/diy_maintenance_screen.dart';
import '../../maintenance/services/maintenance_service.dart';
import '../../maintenance/widgets/reminder_card.dart';
import '../../services/screens/service_history_screen.dart';
import '../../claims/models/claim_model.dart';
import '../../shared/models/home_models.dart';
import '../../../services/claims_service.dart';
import '../../shared/models/maintenance_models.dart';
import '../widgets/assets_tab/assets_header.dart';
import '../widgets/assets_tab/assets_list.dart';
import '../widgets/assets_tab/assets_summary.dart';
import '../widgets/home_tab/critical_alerts_section.dart';
import '../widgets/home_tab/todays_tasks_content.dart';
import '../widgets/maintenance_tab/maintenance_header.dart';
import '../widgets/maintenance_tab/maintenance_summary.dart';
import '../widgets/services_tab/service_image_card.dart';
import '../widgets/services_tab/services_data.dart';
import '../widgets/services_tab/services_search_bar.dart';
import '../widgets/shared/drawer_widget.dart';
import '../widgets/shared/home_selector_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedNavIndex = 0; // Home tab is at index 0

  // Assets tab state
  final TextEditingController _assetSearchController = TextEditingController();
  final FocusNode _assetSearchFocusNode = FocusNode();
  String _selectedAssetFilter = 'All Assets';
  String? _selectedSecondaryFilter;

  // Services tab state
  final TextEditingController _serviceSearchController =
      TextEditingController();
  String _selectedServiceCategory = 'Home Services'; // Default to Home Services
  final ScrollController _servicesScrollController = ScrollController();
  final GlobalKey _homeServicesKey = GlobalKey();
  final GlobalKey _propertyServicesKey = GlobalKey();

  // Home tab scroll state
  final ScrollController _homeScrollController = ScrollController();
  double _homeScrollOffset = 0.0;

  // Home tab search state
  final TextEditingController _homeSearchController = TextEditingController();
  final FocusNode _homeSearchFocusNode = FocusNode();
  String _homeSearchQuery = '';

  // Maintenance tab state
  List<Reminder> _allMaintenanceReminders = [];
  List<Reminder> _completedMaintenanceReminders = [];
  bool _isLoadingMaintenance = false;

  // User bookings state (kept for Services tab; not used on Home tab)
  // Active claims state (warranty/protection plan claims)
  List<Claim> _activeClaims = [];

  // Pending deliveries state
  List<PendingDelivery> _pendingDeliveries = [];

  // Carousel state for maintenance sections
  String? _expandedMaintenanceSection =
      'overdue'; // 'overdue', 'upcoming', 'completed', or null - default to overdue

  // Assets data — synced from assetsProvider in build().
  // Kept as a mutable field so that existing filtering/search logic
  // needs no changes.
  List<Map<String, dynamic>> _allAssets = [];

  // Optimistic assets added locally but not yet confirmed by the backend.
  // Merged into _allAssets in build() so the summary updates instantly.
  // Cleared once the backend returns data that includes the new asset.
  final List<Map<String, dynamic>> _optimisticNewAssets = [];
  // Number of confirmed backend assets at last successful fetch.
  int _lastBackendAssetCount = 0;

  // Warranty / upgrade filter state for Assets tab
  final String _selectedWarrantyFilter = 'All';

  // Notification state — loaded from backend on init.
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = false;

  int get _unreadCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  @override
  void initState() {
    super.initState();
    // Add scroll listener to auto-change tabs based on visible section
    _servicesScrollController.addListener(_onServicesScroll);
    // Add scroll listener for home tab header transition
    _homeScrollController.addListener(_onHomeScroll);
    // Load maintenance reminders
    _loadMaintenanceReminders();
    // Load active warranty/protection claims
    _loadActiveClaims();
    // Load pending deliveries from backend
    _loadPendingDeliveries();
    // Load real notifications from backend
    _loadNotifications();
  }

  Future<void> _loadActiveClaims() async {
    if (!mounted) return;
    try {
      final claims = await ClaimsService.getAllClaims();
      final active = claims
          .where(
            (c) =>
                // Include if it has a real asset name OR at least a title
                (c.assetName.isNotEmpty && c.assetName != 'Unknown Asset' ||
                    c.title.isNotEmpty) &&
                [
                  ClaimStatus.submitted,
                  ClaimStatus.underReview,
                  ClaimStatus.approved,
                  ClaimStatus.inProgress,
                ].contains(c.status),
          )
          .toList()
          // Sort newest first
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      if (mounted) {
        setState(() {
          _activeClaims = active;
        });
      }
    } on Object catch (e) {
      debugPrint('Error loading active claims: $e');
    }
  }

  Future<void> _loadPendingDeliveries() async {
    if (!mounted) return;
    try {
      final homeId = ref.read(selectedHomeIdProvider);
      final deliveries = await OrderService.getPendingDeliveries(
        homeId: homeId,
      );
      if (mounted) {
        setState(() {
          _pendingDeliveries = deliveries;
        });
      }
    } on Object catch (e) {
      debugPrint('Error loading pending deliveries: $e');
    }
  }

  /// Fetches notifications for the current user from the backend.
  /// Maps backend data to the local notification format used by this screen.
  Future<void> _loadNotifications() async {
    if (!mounted || _isLoadingNotifications) return;
    setState(() => _isLoadingNotifications = true);

    try {
      final response = await ApiClient().get('/notifications');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];

      final mapped = data.map((rawItem) {
        final item = rawItem as Map<String, dynamic>;
        // Map backend `type` string to a Material icon.
        final type = item['type'] as String? ?? '';
        IconData icon;
        if (type.contains('booking') || type.contains('service')) {
          icon = Icons.build_circle_outlined;
        } else if (type.contains('maintenance') || type.contains('reminder')) {
          icon = Icons.home_repair_service_outlined;
        } else if (type.contains('payment')) {
          icon = Icons.payment_outlined;
        } else if (type.contains('asset')) {
          icon = Icons.inventory_2_outlined;
        } else if (type.contains('warning') || type.contains('alert')) {
          icon = Icons.warning_amber_outlined;
        } else {
          icon = Icons.notifications_none;
        }

        return {
          'id': item['id'] ?? '',
          'title': item['title'] ?? '',
          'message': item['body'] ?? '',
          'timestamp': item['createdAt'] != null
              ? DateTime.tryParse(item['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
          'icon': icon,
          'isRead': item['isRead'] as bool? ?? false,
          'type': type,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(mapped);
          _isLoadingNotifications = false;
        });
      }
    } on Object catch (e) {
      debugPrint('[HomeScreen] Failed to load notifications: $e');
      if (mounted) setState(() => _isLoadingNotifications = false);
    }
  }

  /// Persist a newly-added asset to the backend, then refresh the provider.
  Future<void> _persistNewAsset(
    Map<String, dynamic> asset,
    String homeId,
  ) async {
    try {
      // Parse purchase date from form data
      DateTime? purchasedAt;
      final purchaseYearRaw = asset['purchaseYear'];
      if (purchaseYearRaw != null) {
        final year = purchaseYearRaw is int
            ? purchaseYearRaw
            : int.tryParse(purchaseYearRaw.toString());
        final monthRaw = asset['purchaseMonth'];
        final month = monthRaw != null
            ? (monthRaw is int
                  ? monthRaw
                  : int.tryParse(monthRaw.toString()) ?? 1)
            : 1;
        if (year != null) {
          purchasedAt = DateTime(year, month, 1);
        }
      }

      // Parse warranty end date from form data
      DateTime? warrantyExpiresAt;
      final warrantyEndStr = asset['warrantyEndDate'] as String?;
      if (warrantyEndStr != null) {
        warrantyExpiresAt = DateTime.tryParse(warrantyEndStr);
      }

      // Helper: clean string — returns null if blank or placeholder '-'
      String? s(String key) {
        final v = asset[key];
        if (v == null) return null;
        final str = v.toString().trim();
        return (str.isEmpty || str == '-') ? null : str;
      }

      final created = await AssetApiService.instance.createAsset(
        homeId: homeId,
        name: s('name') ?? 'Unnamed Asset',
        category: s('type') ?? s('productCategory') ?? 'Appliance',
        brand: s('brand'),
        model: s('model'),
        serialNumber: s('serial'),
        purchasedAt: purchasedAt,
        warrantyExpiresAt: warrantyExpiresAt,
        imageUrl: s('productImageUrl'),
        notes: s('description'),
        // ── Enriched fields ──────────────────────────────────────────────
        productTitle: s('productTitle'),
        productDescription: s('description'),
        productCategory: s('productCategory'),
        subCategory: s('subCategory'),
        manufacturer: s('manufacturer'),
        mpn: s('mpn'),
        barcode: s('barcode'),
        productImageUrl: s('productImageUrl'),
        productColor: s('productColor'),
        enrichmentSource: s('enrichmentSource'),
        location: s('location'),
        purchaseYear: purchaseYearRaw is int
            ? purchaseYearRaw
            : int.tryParse(purchaseYearRaw?.toString() ?? ''),
        purchaseMonth: () {
          final m = asset['purchaseMonth'];
          if (m == null) return null;
          return m is int ? m : int.tryParse(m.toString());
        }(),
        networkMac: s('networkMac'),
        networkIp: s('networkIp'),
      );

      // ── Persist attached documents ────────────────────────────────────
      final rawDocs = asset['documentPaths'];
      final rawTypes = asset['documentTypes'];
      final docTypesList = rawTypes is List ? rawTypes : <dynamic>[];
      if (rawDocs is List && rawDocs.isNotEmpty) {
        bool anyUploadFailed = false;
        for (int docIdx = 0; docIdx < rawDocs.length; docIdx++) {
          final filePath = rawDocs[docIdx].toString();
          final fileName = filePath.contains('/') || filePath.contains('\\')
              ? filePath.split(RegExp(r'[\\/]')).last
              : filePath;
          // Use the user-selected document type; fall back to extension inference.
          final String docType;
          if (docIdx < docTypesList.length &&
              docTypesList[docIdx] != null &&
              docTypesList[docIdx].toString().isNotEmpty) {
            docType = docTypesList[docIdx].toString();
          } else {
            final lname = fileName.toLowerCase();
            if (lname.endsWith('.jpg') ||
                lname.endsWith('.jpeg') ||
                lname.endsWith('.png') ||
                lname.endsWith('.heic')) {
              docType = 'photo';
            } else {
              docType = 'other';
            }
          }
          // Read file size/mimeType if the file exists locally
          int? sizeBytes;
          String? mimeType;
          bool fileExists = false;
          try {
            final file = File(filePath);
            fileExists = await file.exists();
            if (fileExists) {
              sizeBytes = await file.length();
              final ext = fileName.toLowerCase().split('.').last;
              mimeType = switch (ext) {
                'pdf' => 'application/pdf',
                'jpg' || 'jpeg' => 'image/jpeg',
                'png' => 'image/png',
                'heic' => 'image/heic',
                'doc' => 'application/msword',
                'docx' =>
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                _ => null,
              };
            }
          } on Object catch (_) {
            // Non-critical — proceed without size/mimeType
          }
          if (!fileExists) {
            debugPrint('Skipping document $fileName: file does not exist');
            continue;
          }
          try {
            // Upload binary so the backend stores the file and sets url in DB
            await AssetApiService.instance.uploadDocumentFile(
              assetId: created.id,
              filePath: filePath,
              name: fileName,
              type: docType,
            );
          } on Object catch (uploadErr) {
            debugPrint('File upload failed for $fileName: $uploadErr');
            anyUploadFailed = true;
            // Fallback: store the metadata record so the doc appears in the
            // list — user can delete and re-upload from the asset detail.
            try {
              await AssetApiService.instance.addDocument(
                assetId: created.id,
                name: fileName,
                type: docType,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
              );
            } on Object catch (e) {
              debugPrint('Failed to record document $fileName: $e');
            }
          }
        }
        if (anyUploadFailed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'One or more documents could not be uploaded. '
                'Delete them from the Documents tab and add again to view.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      // Refresh the assets provider so the list and summary reflect the new asset.
      ref.invalidate(assetsProvider);
      // Reload maintenance reminders — new appliances may generate new tasks.
      if (mounted) {
        await _loadMaintenanceReminders();
      }
    } on Object catch (e) {
      if (e is DuplicateAssetException) {
        // The frontend duplicate check should have already caught this, but
        // if the backend still returns 409 (e.g. race condition), just log it.
        debugPrint('[HomeScreen] Backend duplicate: ${e.existingAsset.name}');
      } else {
        debugPrint('Failed to save asset to backend: $e');
      }
    }
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    _servicesScrollController.removeListener(_onServicesScroll);
    _servicesScrollController.dispose();
    _assetSearchController.dispose();
    _assetSearchFocusNode.dispose();
    _serviceSearchController.dispose();
    _homeSearchController.dispose();
    _homeSearchFocusNode.dispose();
    super.dispose();
  }

  void _onHomeScroll() {
    setState(() {
      _homeScrollOffset = _homeScrollController.hasClients
          ? _homeScrollController.position.pixels
          : 0.0;
    });
  }

  Future<void> _loadMaintenanceReminders() async {
    setState(() {
      _isLoadingMaintenance = true;
    });

    try {
      // Initialize and sync maintenance data first
      await MaintenanceService.initializeMaintenanceData();

      // Then load all reminders (now guaranteed to be in sync)
      final reminders = await MaintenanceService.getAllReminders();

      setState(() {
        _allMaintenanceReminders = reminders
            .where(
              (r) =>
                  r.status != ReminderStatus.completed &&
                  r.status != ReminderStatus.skipped,
            )
            .toList();
        _completedMaintenanceReminders = reminders
            .where((r) => r.status == ReminderStatus.completed)
            .toList();
      });
    } on Object catch (_) {
      // Handle error - try to get mock data
      try {
        final mockReminders = await MaintenanceService.getAllReminders();
        setState(() {
          _allMaintenanceReminders = mockReminders
              .where(
                (r) =>
                    r.status != ReminderStatus.completed &&
                    r.status != ReminderStatus.skipped,
              )
              .toList();
          _completedMaintenanceReminders = mockReminders
              .where((r) => r.status == ReminderStatus.completed)
              .toList();
        });
      } on Object catch (_) {
        // If still fails, set empty lists
        setState(() {
          _allMaintenanceReminders = [];
          _completedMaintenanceReminders = [];
        });
      }
    } finally {
      setState(() {
        _isLoadingMaintenance = false;
      });
    }
  }

  List<Reminder> get _upcomingMaintenanceReminders {
    return _allMaintenanceReminders
        .where((r) => r.status == ReminderStatus.upcoming)
        .toList();
  }

  List<Reminder> get _overdueMaintenanceReminders {
    return _allMaintenanceReminders
        .where((r) => r.status == ReminderStatus.overdue)
        .toList();
  }

  List<Reminder> get _snoozedMaintenanceReminders {
    return _allMaintenanceReminders
        .where((r) => r.status == ReminderStatus.snoozed)
        .toList();
  }

  Map<String, int> get _maintenanceStats {
    return {
      'upcoming': _upcomingMaintenanceReminders.length,
      'overdue': _overdueMaintenanceReminders.length,
      'snoozed': _snoozedMaintenanceReminders.length,
      'completed': _completedMaintenanceReminders.length,
      'total':
          _allMaintenanceReminders.length +
          _completedMaintenanceReminders.length,
    };
  }

  Future<void> _handleMaintenanceMarkDone(String reminderId) async {
    await MaintenanceService.markReminderAsCompleted(reminderId);

    // Reload from service to stay in sync
    await _loadMaintenanceReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maintenance marked as completed! Your appliance condition rating will be updated.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleMaintenanceSnooze(
    String reminderId,
    DateTime until,
  ) async {
    await MaintenanceService.snoozeReminderById(reminderId, until);
    await _loadMaintenanceReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder postponed until ${until.month}/${until.day}/${until.year}',
          ),
        ),
      );
    }
  }

  Future<void> _handleMaintenanceSkip(
    String reminderId,
    SkipReason reason,
  ) async {
    await MaintenanceService.skipReminderById(reminderId, reason);
    await _loadMaintenanceReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reminder skipped. Your appliance condition rating may be affected.',
          ),
        ),
      );
    }
  }

  void _handleMaintenanceGetHelp(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIYMaintenanceScreen(
          reminder: reminder,
          onMarkComplete: () => _handleMaintenanceMarkDone(reminder.id),
        ),
      ),
    );
  }

  void _handleMaintenanceOrderParts(Reminder reminder) {
    context.push('/maintenance/order-parts', extra: reminder);
  }

  void _onServicesScroll() {
    if (!_servicesScrollController.hasClients) return;

    final scrollPosition = _servicesScrollController.position.pixels;

    // Get the positions of each section relative to the scrollable content
    final RenderBox? homeBox =
        _homeServicesKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? propertyBox =
        _propertyServicesKey.currentContext?.findRenderObject() as RenderBox?;

    if (homeBox == null || propertyBox == null) return;

    // Calculate the position of each section's top relative to the scrollable content
    // We need to find the offset of each section within the scrollable viewport
    final homeOffset = homeBox.localToGlobal(Offset.zero);
    final propertyOffset = propertyBox.localToGlobal(Offset.zero);

    // Calculate viewport top (accounting for fixed header height)
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final fixedHeaderHeight =
        statusBarHeight +
        48.0 +
        32.0 +
        40.0 +
        12.0 +
        48.0 +
        12.0; // Approximate fixed header height
    final viewportTop = fixedHeaderHeight;

    // Get section positions relative to the scrollable content start
    final homeTop = homeOffset.dy - viewportTop + scrollPosition;
    final propertyTop = propertyOffset.dy - viewportTop + scrollPosition;

    // Determine which section is currently at the top of the viewport
    String newCategory = 'Home Services'; // Default

    // Use simpler threshold-based detection
    const threshold = 150.0; // Offset threshold

    if (scrollPosition >= propertyTop - threshold) {
      newCategory = 'Property Services';
    } else if (scrollPosition >= homeTop - threshold ||
        scrollPosition <= homeTop + 50) {
      newCategory = 'Home Services';
    }

    // Update selected category if changed
    if (newCategory != _selectedServiceCategory) {
      setState(() {
        _selectedServiceCategory = newCategory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Asset provider sync with optimistic UI ────────────────────────────
    // When fresh backend data arrives, update _allAssets.  If the backend
    // now has more assets than the last confirmed fetch, the optimistic
    // locally-added items have been persisted — clear them.
    // During a re-fetch (isLoading but data not yet back) we keep the
    // existing _allAssets so the summary never flashes to empty.
    final assetsAsync = ref.watch(assetsProvider);
    // Only show the full-screen spinner on the very first load (no data yet).
    final isLoadingAssets = assetsAsync.isLoading && _allAssets.isEmpty;
    final latestAssets = assetsAsync.valueOrNull
        ?.map((a) => a.toLegacyMap())
        .toList();
    if (latestAssets != null) {
      // If the backend returned more assets than last time, the optimistic
      // items have been confirmed — drop them so we don't show duplicates.
      if (latestAssets.length > _lastBackendAssetCount) {
        _optimisticNewAssets.clear();
      }
      _lastBackendAssetCount = latestAssets.length;
      // Merge: prepend any optimistic (unconfirmed) items.
      _allAssets = [..._optimisticNewAssets, ...latestAssets];
    }

    final responsive = context.responsive;

    // ── Family-member access gates ────────────────────────────────────────
    // isOwner = true  =>  full access, no filtering.
    // isOwner = false =>  consult grantedServiceTypesProvider.
    // While the provider is still loading we "fail-open" so the UI
    // never flashes a false "No Access" message.
    final isOwner = ref.watch(selectedHomeIsOwnerProvider);
    final grantedSvcAsync = ref.watch(grantedServiceTypesProvider);
    final grantedAssetAsync = ref.watch(grantedAssetIdsProvider);
    final grantedSvc = grantedSvcAsync.valueOrNull;
    final grantedAssetIds = grantedAssetAsync.valueOrNull;

    final hasServicesAccess =
        !grantedSvcAsync.hasValue ||
        isOwner ||
        (grantedSvc?.contains('bookings') ?? true);
    final hasMaintenanceAccess =
        !grantedSvcAsync.hasValue ||
        isOwner ||
        (grantedSvc?.contains('maintenance') ?? true);

    // Filter assets to only granted ones for family members.
    // grantedAssetIds == null  →  owner or still loading → show all assets.
    final visibleAssets = (grantedAssetIds == null || isOwner)
        ? _allAssets
        : _allAssets
              .where((a) => grantedAssetIds.contains(a['id'] as String?))
              .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        drawer: const DrawerWidget(),
        body: _selectedNavIndex == 3
            ? _buildAssetsTabWithFixedHeader(
                isLoading: isLoadingAssets,
                filteredAssets: visibleAssets,
              )
            : _selectedNavIndex == 1
            ? _buildServicesTabWithFixedHeader(hasAccess: hasServicesAccess)
            : _selectedNavIndex == 4
            ? _buildMaintenanceTabWithFixedHeader(
                hasAccess: hasMaintenanceAccess,
              )
            : _buildHomeTabWithFixedHeader(),
        bottomNavigationBar: _buildBottomNav(responsive: responsive),
        floatingActionButton: GestureDetector(
          onTap: () {
            setState(() {
              _selectedNavIndex = 2;
            });
          },
          child: Container(
            width: responsive.spacing(70.0),
            height: responsive.spacing(70.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedNavIndex == 2
                  ? AppColors
                        .primary // BrandSmart blue when selected
                  : AppColors.primary.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.4,
                  ), // Blue shadow
                  blurRadius: responsive.spacing(12.0),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.textOnPrimary,
                size: responsive.iconSize(32.0),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  /// Builds the bottom nav. All 5 tabs are always visible.
  /// Access restrictions are enforced inside each tab's content area.
  Widget _buildBottomNav({required ResponsiveUtils responsive}) {

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedNavIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDisabled,
        elevation: 0,
        onTap: (index) {
          if (index == 2) return; // FAB placeholder
          setState(() {
            _selectedNavIndex = index;
            if (index == 4) _loadMaintenanceReminders();
            if (index == 0) _loadActiveClaims();
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: responsive.iconSize(24.0)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined, size: responsive.iconSize(24.0)),
            label: 'Services',
          ),
          const BottomNavigationBarItem(icon: SizedBox(), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined, size: responsive.iconSize(24.0)),
            label: 'Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_repair_service_outlined, size: responsive.iconSize(24.0)),
            label: 'Maintenance',
          ),
        ],
      ),
    );
  }

  /// Returns the address of the currently selected home, with full null safety.
  /// Never throws — always returns a displayable string.
  String _getSelectedHomeAddress() {
    try {
      final state = ref.watch(homeSelectionProvider);
      if (state.homes.isEmpty) return 'Add your first home';
      final selectedName = ref.watch(selectedHomeNameProvider);
      final match = state.homes.where((h) => h.name == selectedName);
      if (match.isNotEmpty) return match.first.address;
      return state.homes.first.address;
    } on Object catch (_) {
      return '';
    }
  }

  Widget _buildHomeHeader([double? maxHeight]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final responsive = ResponsiveUtils(context);

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
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
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
                          onTap: () {
                            _showHouseBottomSheet(context);
                          },
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ref.watch(selectedHomeNameProvider),
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
                          _getSelectedHomeAddress(),
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
              onTap: () {
                context.push('/notifications');
              },
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
                  if (_unreadCount > 0)
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
            'Good ${DateTime.now().hour < 12
                ? 'Morning'
                : DateTime.now().hour < 17
                ? 'Afternoon'
                : DateTime.now().hour < 21
                ? 'Evening'
                : 'Night'}, ${ref.watch(userProfileProvider).getFirstName()}',
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
        GestureDetector(
          onTap: () {
            // When tapped, show the search interface
            setState(() {
              _homeSearchFocusNode.requestFocus();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                  color: const Color(0xFFB0BEC5),
                  size: responsive.iconSize(20.0),
                ),
                SizedBox(width: responsive.spacing(12.0)),
                Expanded(
                  child: _homeSearchQuery.isEmpty
                      ? Text(
                          'Search services...',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16.0),
                            color: const Color(0xFFB0BEC5),
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : TextField(
                          controller: _homeSearchController,
                          focusNode: _homeSearchFocusNode,
                          onChanged: (value) {
                            setState(() {
                              _homeSearchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search services...',
                            hintStyle: TextStyle(
                              fontSize: responsive.fontSize(16.0),
                              color: const Color(0xFFB0BEC5),
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
                    if (_homeSearchQuery.isEmpty) {
                      // Handle send/voice action when no search query
                      setState(() {
                        _homeSearchFocusNode.requestFocus();
                      });
                    } else {
                      // Clear search when there's text
                      setState(() {
                        _homeSearchController.clear();
                        _homeSearchQuery = '';
                        _homeSearchFocusNode.unfocus();
                      });
                    }
                  },
                  child: Icon(
                    _homeSearchQuery.isEmpty ? Icons.send : Icons.clear,
                    color: _homeSearchQuery.isEmpty
                        ? AppColors.primary
                        : const Color(0xFFB0BEC5),
                    size: responsive.iconSize(20.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // If maxHeight is provided, wrap in ConstrainedBox to prevent overflow
    if (maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, minHeight: 0),
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

  Widget _buildHomeTabWithFixedHeader() {
    final responsive = ResponsiveUtils(context);
    // Calculate header heights - responsive to screen size
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive header heights based on screen size
    final baseFullHeaderHeight = screenHeight < 700
        ? 180.0
        : screenHeight < 800
        ? 200.0
        : 220.0;

    // Compact header = EXACT same formula as AppHeaderConfig.buildFixedHeader
    // so the home header, when fully collapsed, is pixel-identical to the
    // Maintenance / Assets / Services tab headers.
    //   compactHeaderHeight (32) + headerPaddingVertical*2 (14*2=28) = 60 px
    const compactContentHeight = AppHeaderConfig.compactHeaderHeight; // 32.0
    const compactPaddingV = AppHeaderConfig.headerPaddingVertical; // 14.0
    const baseCompactHeaderHeight =
        compactContentHeight + compactPaddingV * 2; // 60.0

    // Scale full header height based on screen density, keep compact fixed.
    final scaleFactor = (screenHeight / 800.0).clamp(0.8, 1.2);
    final fullHeaderHeight = (baseFullHeaderHeight * scaleFactor).clamp(
      160.0,
      280.0,
    );
    // Compact height is fixed — do NOT scale it so it stays the same as
    // the Services / Maintenance tab headers.
    const compactHeaderHeight = baseCompactHeaderHeight;
    // Collapse after 50 px of scroll so the header shrinks quickly
    final scrollThreshold = screenWidth < 360 ? 34.0 : 50.0;

    // Calculate transition progress (0.0 = full header, 1.0 = compact header)
    final scrollProgress = (_homeScrollOffset / scrollThreshold).clamp(
      0.0,
      1.0,
    );

    // Padding stays at 14 (matches all other tab headers)
    const verticalPad = AppHeaderConfig.headerPaddingVertical;

    // Calculate current header height
    final currentHeaderHeight =
        statusBarHeight +
        (fullHeaderHeight * (1 - scrollProgress) +
            compactHeaderHeight * scrollProgress);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Scrollable content
        Positioned(
          top: currentHeaderHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollMetricsNotification) {
                if (_homeScrollController.hasClients) {
                  final pixels = _homeScrollController.position.pixels;
                  if ((_homeScrollOffset - pixels).abs() > 0.5 || pixels == 0) {
                    setState(() {
                      _homeScrollOffset = pixels;
                    });
                  }
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _homeScrollController,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              child: Container(
                color: Colors.grey.shade50,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        currentHeaderHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                            vertical: responsive.spacing(14.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pending-invite banner — shown when the
                              // logged-in user has unaccepted family invitations.
                              _buildPendingInvitesBanner(responsive),
                              CriticalAlertsSection(allAssets: _allAssets),
                              if (_allAssets.isEmpty) ...[
                                // New user welcome section
                                _buildNewUserWelcome(),
                              ] else ...[
                                SizedBox(height: responsive.spacing(20.0)),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Active Claims',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(20.0),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.push('/my-claims');
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View All',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(
                                                14.0,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          SizedBox(
                                            width: responsive.spacing(2.0),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            size: responsive.iconSize(18.0),
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.spacing(16.0)),
                                _buildActiveClaimsScroll(),
                                SizedBox(height: responsive.spacing(24.0)),
                                _buildPendingDeliveriesSection(),
                                SizedBox(height: responsive.spacing(24.0)),
                                TodaysTasksContent(
                                  searchQuery: _homeSearchQuery,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Fixed header with transition
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 4,
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: currentHeaderHeight - statusBarHeight,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(AppHeaderConfig.headerPaddingHorizontal),
                  responsive.spacing(verticalPad),
                  responsive.spacing(AppHeaderConfig.headerPaddingHorizontal),
                  responsive.spacing(verticalPad),
                ),
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use the ACTUAL animated constraint height rather than
                      // recomputing from the scroll-offset target.  During the
                      // AnimatedContainer's 300 ms transition the two values
                      // differ, causing a RenderFlex overflow because the
                      // ConstrainedBox was telling children they had more room
                      // than the container actually provided.
                      final rawHeight = constraints.maxHeight;
                      // Clamp to avoid negative BoxConstraints; 56 is just
                      // above the compact-header content minimum.
                      final availableHeight = rawHeight.clamp(
                        56.0,
                        double.infinity,
                      );
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: availableHeight,
                          minHeight: 0,
                        ),
                        child: _buildHomeHeaderSafe(
                          scrollProgress,
                          availableHeight,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Wraps [_buildHomeHeaderWithTransition] in a try-catch to prevent
  /// the entire header area from crashing with a red error box.
  Widget _buildHomeHeaderSafe(double scrollProgress, double availableHeight) {
    try {
      return _buildHomeHeaderWithTransition(scrollProgress, availableHeight);
    } on Object catch (_) {
      return _buildHomeCompactHeader();
    }
  }

  Widget _buildHomeHeaderWithTransition(
    double scrollProgress,
    double availableHeight,
  ) {
    final transitionCurve = Curves.easeInOutCubic.transform(scrollProgress);

    if (scrollProgress < 0.05) {
      return _buildHomeHeader(availableHeight);
    }

    if (scrollProgress > 0.95) {
      return _buildHomeCompactHeader();
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
              child: _buildHomeHeader(availableHeight),
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: transitionCurve.clamp(0.0, 1.0),
            child: IgnorePointer(
              ignoring: transitionCurve < 0.7,
              child: _buildHomeCompactHeader(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeCompactHeader() {
    final responsive = ResponsiveUtils(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final homeFontSize = screenWidth < 360
        ? 13.0
        : screenWidth < 400
        ? 14.0
        : 15.0;
    final addressFontSize = screenWidth < 360 ? 10.0 : 11.0;

    final selectedAddress = _getSelectedHomeAddress();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Profile avatar (opens drawer) ─────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: ProfileAvatar(
                      size: responsive.iconSize(36.0),
                      fontSize: responsive.fontSize(13.0),
                      backgroundColor: AppColors.textOnPrimary.withValues(
                        alpha: 0.24,
                      ),
                      textColor: AppColors.textOnPrimary,
                    ),
                  );
                },
              ),
              SizedBox(width: responsive.spacing(8.0)),
              // ── Home name + address with dropdown ──────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () => _showHouseBottomSheet(context),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ref.watch(selectedHomeNameProvider),
                              style: TextStyle(
                                fontSize: responsive.fontSize(homeFontSize),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (selectedAddress.isNotEmpty) ...[
                              Text(
                                selectedAddress,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(
                                    addressFontSize,
                                  ),
                                  color: AppColors.textOnPrimary.withValues(
                                    alpha: 0.72,
                                  ),
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        color: AppColors.textOnPrimary,
                        size: responsive.iconSize(18.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Notification bell with unread badge ───────────────────────────
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: responsive.iconSize(36.0),
                height: responsive.iconSize(36.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.24),
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: AppColors.textOnPrimary,
                  size: responsive.iconSize(20.0),
                ),
              ),
              if (_unreadCount > 0)
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
    );
  }

  // ─── No-access placeholder (family members without the service grant) ────

  Widget _buildNoAccessContent(String feature, IconData icon) {
    final responsive = ResponsiveUtils(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(32.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: responsive.iconSize(80.0),
                height: responsive.iconSize(80.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.08),
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: responsive.iconSize(38.0),
                  color: primaryColor.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: responsive.spacing(20.0)),
              Text(
                'No $feature Access',
                style: TextStyle(
                  fontSize: responsive.fontSize(20.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(8.0)),
              Text(
                'You haven\'t been granted $feature access for this home.\nContact the home owner to update your permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesTabWithFixedHeader({bool hasAccess = true}) {
    final responsive = ResponsiveUtils(context);
    final totalFixedHeight = AppHeaderConfig.getTotalHeaderHeight(context);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: totalFixedHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.grey.shade50, // Same as Assets tab background
            child: !hasAccess
                ? _buildNoAccessContent('Services', Icons.build_outlined)
                : SingleChildScrollView(
                    controller: _servicesScrollController,
                    padding: EdgeInsets.zero,
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar - Full width
                        Container(
                          color: Colors.grey.shade50,
                          padding: EdgeInsets.only(
                            left: responsive.spacing(20.0),
                            right: responsive.spacing(20.0),
                            top: 10.0,
                          ),
                          child: ServicesSearchBar(
                            controller: _serviceSearchController,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16.0)),

                        // Lifestyle Services Section
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: Text(
                            'Lifestyle Services',
                            style: TextStyle(
                              fontSize: responsive.fontSize(20.0),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(12.0)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: responsive.spacing(12.0),
                                  mainAxisSpacing: responsive.spacing(12.0),
                                  childAspectRatio: 1.05,
                                ),
                            itemCount:
                                ServicesData.getLifestyleServices().length,
                            itemBuilder: (context, index) {
                              final service =
                                  ServicesData.getLifestyleServices()[index];
                              return ServiceImageCard(service: service);
                            },
                          ),
                        ),
                        SizedBox(height: responsive.spacing(24.0)),

                        // Home Services Section
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: Text(
                            'Home Services',
                            style: TextStyle(
                              fontSize: responsive.fontSize(20.0),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(12.0)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: responsive.spacing(12.0),
                                  mainAxisSpacing: responsive.spacing(12.0),
                                  childAspectRatio: 1.05,
                                ),
                            itemCount: ServicesData.getHomeServices().length,
                            itemBuilder: (context, index) {
                              final service =
                                  ServicesData.getHomeServices()[index];
                              return ServiceImageCard(service: service);
                            },
                          ),
                        ),
                        SizedBox(height: responsive.spacing(24.0)),
                      ],
                    ),
                  ),
          ),
        ),
        // Fixed header with history button - custom smaller height for Services tab
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 4,
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(20.0),
                  vertical: responsive.spacing(15.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Services',
                      style: TextStyle(
                        fontSize: responsive.fontSize(24.0),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (hasAccess)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ServiceHistoryScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: AppHeaderConfig.profileAvatarSize(responsive),
                        height: AppHeaderConfig.profileAvatarSize(responsive),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textOnPrimary.withValues(
                            alpha: 0.24,
                          ),
                        ),
                        child: Icon(
                          Icons.history,
                          color: AppColors.textOnPrimary,
                          size: responsive.iconSize(22.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsTabWithFixedHeader({
    bool isLoading = false,
    List<Map<String, dynamic>>? filteredAssets,
  }) {
    final responsive = ResponsiveUtils(context);
    final totalHeaderHeight = AppHeaderConfig.getTotalHeaderHeight(context);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Scrollable content - positioned below header
        Positioned(
          top: totalHeaderHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.grey.shade50,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards - placed directly after header
                        Container(
                          color: Colors.grey.shade50,
                          child: AssetsSummary(
                            allAssets: filteredAssets ?? _allAssets,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16.0)),
                        // Search Bar with Filter Button
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: _buildAssetsSearchBar()),
                              SizedBox(width: responsive.spacing(12.0)),
                              GestureDetector(
                                onTap: () {
                                  _showAssetsFilterBottomSheet(context);
                                },
                                child: Container(
                                  width: responsive.iconSize(52.0),
                                  height: responsive.iconSize(52.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(8.0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: responsive.spacing(8.0),
                                        offset: Offset(
                                          0,
                                          responsive.spacing(2.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.tune,
                                    color: AppColors.primary,
                                    size: responsive.iconSize(24.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16.0)),
                        // Assets List
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: AssetsList(
                            assets: _getFilteredAssets(
                              baseAssets: filteredAssets,
                            ),
                            allAssets: filteredAssets ?? _allAssets,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        // Fixed header at top with elevation - using centralized config
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppHeaderConfig.buildFixedHeader(
            context: context,
            child: const AssetsHeader(),
          ),
        ),
        // Add Asset FAB - only visible to home owners (hidden for family members)
        if (ref.watch(selectedHomeIsOwnerProvider))
          Positioned(
            bottom:
                10, // Exactly above the bottom navigation bar (minimal spacing)
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Guard: a home must be selected before an asset can be added.
                // Without a home there is no homeId to link the asset to in the DB.
                final homeId = ref.read(selectedHomeIdProvider);
                if (homeId == null || homeId.isEmpty) {
                  _showNoHomeDialog(context, autoOpenAssetFlow: true);
                  return;
                }
                _openAddAssetFlow();
              },
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.add,
                color: AppColors.textOnPrimary,
                size: responsive.iconSize(28.0),
              ),
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredAssets({
    List<Map<String, dynamic>>? baseAssets,
  }) {
    List<Map<String, dynamic>> filtered = List.from(baseAssets ?? _allAssets);

    // Filter by search query
    if (_assetSearchController.text.isNotEmpty) {
      final query = _assetSearchController.text.toLowerCase();
      filtered = filtered.where((asset) {
        return asset['name'].toString().toLowerCase().contains(query) ||
            asset['type'].toString().toLowerCase().contains(query) ||
            asset['model'].toString().toLowerCase().contains(query);
      }).toList();
    }

    // Filter by primary category
    if (_selectedAssetFilter != 'All Assets') {
      filtered = filtered.where((asset) {
        final assetType = asset['type'] as String;
        switch (_selectedAssetFilter) {
          case 'Appliances':
            return [
              'Refrigerator',
              'Washing Machine',
              'Air Conditioner',
              'Microwave',
              'Dishwasher',
            ].contains(assetType);
          case 'Home Systems':
            return [
              'HVAC System',
              'Water Heater',
              'Garbage Disposal',
              'Garage Door Opener',
              'Water Softener',
              'Sump Pump',
            ].contains(assetType);
          case 'Electronics':
            return [
              'Television',
              'Computer',
              'Audio System',
              'Smart Device',
            ].contains(assetType);
          default:
            return true;
        }
      }).toList();

      // Filter by secondary category
      if (_selectedSecondaryFilter != null &&
          _selectedSecondaryFilter != 'All Types') {
        filtered = filtered.where((asset) {
          return asset['type'] == _selectedSecondaryFilter;
        }).toList();
      }
    }

    // Filter by warranty / upgrade state
    if (_selectedWarrantyFilter != 'All') {
      filtered = filtered.where((asset) {
        final warranty = asset['warranty']?.toString() ?? '';
        final healthScore = (asset['healthScore'] as num?)?.toDouble() ?? 0;
        final ageYears = _getAssetAgeYears(asset);

        final isExpired = warranty.toLowerCase() == 'expired';
        final isUpgradeEligible =
            isExpired || healthScore <= 6.5 || ageYears >= 5;

        switch (_selectedWarrantyFilter) {
          case 'Expired':
            return isExpired;
          case 'Upgrade Available':
            return isUpgradeEligible;
          default:
            return true;
        }
      }).toList();
    }

    // Sort newest first — use createdAt when available, fall back to list order.
    filtered.sort((a, b) {
      final aStr = a['createdAt'] as String?;
      final bStr = b['createdAt'] as String?;
      if (aStr == null && bStr == null) return 0;
      if (aStr == null) return 1;
      if (bStr == null) return -1;
      return DateTime.parse(bStr).compareTo(DateTime.parse(aStr));
    });

    return filtered;
  }

  int _getAssetAgeYears(Map<String, dynamic> asset) {
    final purchaseDateStr = asset['purchaseDate']?.toString();
    if (purchaseDateStr == null) return 0;

    try {
      final purchaseDate = DateTime.parse(purchaseDateStr);
      final now = DateTime.now();
      final ageYears = now.year - purchaseDate.year;
      return ageYears;
    } on Object catch (_) {
      return 0;
    }
  }

  Widget _buildAssetsSearchBar() {
    final responsive = ResponsiveUtils(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(16.0),
        vertical: MediaQuery.of(context).size.height < 700
            ? responsive.spacing(10.0)
            : responsive.spacing(16.0),
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
            child: TextField(
              controller: _assetSearchController,
              focusNode: _assetSearchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search Assets...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintStyle: TextStyle(
                  fontSize: responsive.fontSize(16.0),
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: TextStyle(
                fontSize: responsive.fontSize(16.0),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              // Handle send action
            },
            child: Icon(
              Icons.send,
              color: AppColors.primary,
              size: responsive.iconSize(20.0),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSecondaryCategories() {
    switch (_selectedAssetFilter) {
      case 'Appliances':
        return [
          'All Types',
          'Refrigerator',
          'Washing Machine',
          'Air Conditioner',
          'Microwave',
          'Dishwasher',
        ];
      case 'Home Systems':
        return [
          'All Types',
          'HVAC System',
          'Water Heater',
          'Garbage Disposal',
          'Garage Door Opener',
          'Water Softener',
          'Sump Pump',
        ];
      case 'Electronics':
        return [
          'All Types',
          'Television',
          'Computer',
          'Audio System',
          'Smart Device',
        ];
      default:
        return ['All Types'];
    }
  }

  void _showAssetsFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.zero,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Assets',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppColors.textLight),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Primary Filter Section
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            [
                              'All Assets',
                              'Appliances',
                              'Home Systems',
                              'Electronics',
                            ].map((item) {
                              final isSelected = _selectedAssetFilter == item;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedAssetFilter = item;
                                    if (item == 'All Assets') {
                                      _selectedSecondaryFilter = null;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      // Secondary Filter Section (always visible, disabled when "All Assets" is selected)
                      const SizedBox(height: 24),
                      Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedAssetFilter == 'All Assets'
                              ? Colors.grey.shade400
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: _selectedAssetFilter == 'All Assets'
                            ? 0.5
                            : 1.0,
                        child: IgnorePointer(
                          ignoring: _selectedAssetFilter == 'All Assets',
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _getSecondaryCategories().map((item) {
                              final isSelected =
                                  (_selectedSecondaryFilter ?? 'All Types') ==
                                  item;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedSecondaryFilter =
                                        item == 'All Types' ? null : item;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMaintenanceTabWithFixedHeader({bool hasAccess = true}) {
    final responsive = ResponsiveUtils(context);
    final totalFixedHeight = AppHeaderConfig.getTotalHeaderHeight(context);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Scrollable content - positioned below fixed header
        Positioned(
          top: totalFixedHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.grey.shade50,
            child: !hasAccess
                ? _buildNoAccessContent(
                    'Maintenance',
                    Icons.home_repair_service_outlined,
                  )
                : _isLoadingMaintenance
                ? const Center(child: CircularProgressIndicator())
                : _allAssets.isEmpty
                ? _buildMaintenanceEmptyState()
                : SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards - placed directly after header
                        Container(
                          color: Colors.grey.shade50,
                          child: MaintenanceSummary(stats: _maintenanceStats),
                        ),
                        SizedBox(height: responsive.spacing(24.0)),
                        // Overdue Section - Premium carousel
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: _buildMaintenanceSection(
                            sectionKey: 'overdue',
                            title: 'Overdue Maintenance',
                            icon: Icons.warning_amber_outlined,
                            count: _overdueMaintenanceReminders.length,
                            reminders: _overdueMaintenanceReminders,
                          ),
                        ),
                        // Upcoming Section - Premium carousel
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: _buildMaintenanceSection(
                            sectionKey: 'upcoming',
                            title: 'Upcoming Maintenance',
                            icon: Icons.calendar_today_outlined,
                            count: _upcomingMaintenanceReminders.length,
                            reminders: _upcomingMaintenanceReminders,
                          ),
                        ),
                        // Snoozed Section
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: _buildMaintenanceSection(
                            sectionKey: 'snoozed',
                            title: 'Snoozed Maintenance',
                            icon: Icons.snooze_outlined,
                            count: _snoozedMaintenanceReminders.length,
                            reminders: _snoozedMaintenanceReminders,
                          ),
                        ),
                        // Completed Section - Premium carousel
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(20.0),
                          ),
                          child: _buildMaintenanceCompletedSection(),
                        ),
                        SizedBox(height: responsive.spacing(20.0)),
                      ],
                    ),
                  ),
          ),
        ),
        // Fixed header at top - using centralized config
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppHeaderConfig.buildFixedHeader(
            context: context,
            child: const MaintenanceHeader(),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSection({
    required String sectionKey,
    required String title,
    required IconData icon,
    required int count,
    required List<Reminder> reminders,
  }) {
    // App theme colors
    final headerColor = AppColors.primary;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    final filtered = reminders;
    final isExpanded = _expandedMaintenanceSection == sectionKey;
    final responsive = ResponsiveUtils(context);

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(12.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                // Toggle: if already expanded, close it; otherwise expand this and close others
                _expandedMaintenanceSection = isExpanded ? null : sectionKey;
              });
            },
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(16.0)),
              child: Row(
                children: [
                  Container(
                    width: responsive.iconSize(40.0),
                    height: responsive.iconSize(40.0),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: responsive.iconSize(20.0),
                      color: headerColor,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(16.0)),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: responsive.iconSize(28.0),
                    height: responsive.iconSize(28.0),
                    decoration: BoxDecoration(
                      color: headerColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(13.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12.0)),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: textSecondary,
                      size: responsive.iconSize(20.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 1, color: Colors.grey.shade200),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'No ${title.toLowerCase()} tasks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...filtered.map(
                                (reminder) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ReminderCard(
                                    reminder: reminder,
                                    onMarkDone: () =>
                                        _handleMaintenanceMarkDone(reminder.id),
                                    onSnooze: (id, until) =>
                                        _handleMaintenanceSnooze(id, until),
                                    onSkip: (id, reason) =>
                                        _handleMaintenanceSkip(id, reason),
                                    onGetHelp: () =>
                                        _handleMaintenanceGetHelp(reminder),
                                    onOrderParts: () =>
                                        _handleMaintenanceOrderParts(reminder),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── Pending invitations banner ────────────────────────────────────────────

  /// Shown at the top of the Dashboard tab when the user has pending family
  /// invitations that haven't been accepted yet.
  Widget _buildPendingInvitesBanner(ResponsiveUtils responsive) {
    final invitesAsync = ref.watch(myPendingInvitesProvider);
    return invitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
          child: Column(
            children: invites.map((invite) {
              final homeName = invite.home != null
                  ? '${invite.home!.address}, ${invite.home!.city}'
                  : 'a home';
              return Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(8.0)),
                child: GestureDetector(
                  onTap: () => context.push(
                    '/accept-invite',
                    extra: <String, dynamic>{'invite': invite},
                  ),
                  child: Container(
                    padding: EdgeInsets.all(responsive.spacing(14.0)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.mail_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: responsive.spacing(12.0)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Invitation',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14.0),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'You\'ve been invited to $homeName',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12.0),
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
        child: Container(
          padding: EdgeInsets.all(responsive.spacing(14.0)),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(12.0)),
              Text(
                'Checking invitations...',
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
        child: Container(
          padding: EdgeInsets.all(responsive.spacing(14.0)),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              SizedBox(width: responsive.spacing(12.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failed to load invitations',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        color: AppColors.error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => ref.refresh(myPendingInvitesProvider),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewUserWelcome() {
    final responsive = ResponsiveUtils(context);
    final isOwner = ref.watch(selectedHomeIsOwnerProvider);
    final grantedSvcAsync = ref.watch(grantedServiceTypesProvider);
    final grantedSvc = grantedSvcAsync.valueOrNull;
    final hasServicesAccess =
        !grantedSvcAsync.hasValue ||
        isOwner ||
        (grantedSvc?.contains('bookings') ?? true);
    return Column(
      children: [
        SizedBox(height: responsive.spacing(20.0)),
        // Welcome card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(24.0)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(16.0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: responsive.spacing(12.0),
                offset: Offset(0, responsive.spacing(4.0)),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.waving_hand,
                size: responsive.iconSize(48.0),
                color: AppColors.warningOrange,
              ),
              SizedBox(height: responsive.spacing(16.0)),
              Text(
                'Welcome to HomeIQ!',
                style: TextStyle(
                  fontSize: responsive.fontSize(22.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(8.0)),
              Text(
                'Get started by adding your home and assets\nto unlock maintenance tracking, warranty\nalerts, and smart home management.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              SizedBox(height: responsive.spacing(20.0)),
              // Quick actions
              _buildQuickAction(
                icon: Icons.home_outlined,
                title: 'Set Up Your Home',
                subtitle: 'Add your home address to get started',
                onTap: () {
                  _showHouseBottomSheet(context);
                },
              ),
              SizedBox(height: responsive.spacing(12.0)),
              if (ref.watch(selectedHomeIsOwnerProvider))
                _buildQuickAction(
                  icon: Icons.inventory_2_outlined,
                  title: 'Add Your First Asset',
                  subtitle: 'Register appliances for smart tracking',
                  onTap: () {
                    setState(() {
                      _selectedNavIndex = 3; // Switch to Assets tab
                    });
                  },
                ),
              if (ref.watch(selectedHomeIsOwnerProvider))
                SizedBox(height: responsive.spacing(12.0)),
              if (hasServicesAccess)
                _buildQuickAction(
                  icon: Icons.build_outlined,
                  title: 'Browse Services',
                  subtitle: 'Explore home and lifestyle services',
                  onTap: () {
                    setState(() {
                      _selectedNavIndex = 1; // Switch to Services tab
                    });
                  },
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(24.0)),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final responsive = ResponsiveUtils(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(14.0)),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: responsive.iconSize(40.0),
              height: responsive.iconSize(40.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(10.0),
                ),
              ),
              child: Icon(
                icon,
                size: responsive.iconSize(22.0),
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: responsive.spacing(12.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(2.0)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12.0),
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: responsive.iconSize(20.0),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceEmptyState() {
    final responsive = ResponsiveUtils(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(40.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: responsive.spacing(40.0)),
            Icon(
              Icons.home_repair_service_outlined,
              size: responsive.iconSize(72.0),
              color: Colors.grey.shade300,
            ),
            SizedBox(height: responsive.spacing(20.0)),
            Text(
              'No Maintenance Tasks',
              style: TextStyle(
                fontSize: responsive.fontSize(20.0),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: responsive.spacing(8.0)),
            Text(
              'Add your first asset to get personalized\nmaintenance reminders and schedules.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.fontSize(14.0),
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            SizedBox(height: responsive.spacing(24.0)),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedNavIndex = 3; // Switch to Assets tab
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Asset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(24.0),
                  vertical: responsive.spacing(12.0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCompletedSection() {
    // App theme colors
    final headerColor = AppColors.primary;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    final responsive = ResponsiveUtils(context);
    final displayReminders = _completedMaintenanceReminders;
    final isExpanded = _expandedMaintenanceSection == 'completed';

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(12.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                // Toggle: if already expanded, close it; otherwise expand this and close others
                _expandedMaintenanceSection = isExpanded ? null : 'completed';
              });
            },
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(16.0)),
              child: Row(
                children: [
                  Container(
                    width: responsive.iconSize(40.0),
                    height: responsive.iconSize(40.0),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: responsive.iconSize(20.0),
                      color: headerColor,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(16.0)),
                  Expanded(
                    child: Text(
                      'Completed Maintenance',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: responsive.iconSize(28.0),
                    height: responsive.iconSize(28.0),
                    decoration: BoxDecoration(
                      color: headerColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayReminders.length.toString(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(13.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12.0)),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: textSecondary,
                      size: responsive.iconSize(20.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 1, color: Colors.grey.shade200),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayReminders.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'No completed maintenance tasks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...displayReminders.map(
                                (reminder) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reminder.taskName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${reminder.assetName} Ã¢â‚¬Â¢ ${reminder.assetLocation ?? 'Home'}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: textSecondary,
                                              ),
                                            ),
                                            if (reminder.completedDate !=
                                                null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Completed on ${reminder.completedDate!.month}/${reminder.completedDate!.day}/${reminder.completedDate!.year}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 24,
                                        color: headerColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActiveServicesGrid() {
    return Column(
      children: [
        _buildServiceCard(
          icon: Icons.ac_unit,
          title: 'Not cooling\nproperly',
          location: 'AC Unit Ã¢â‚¬Â¢ Living Room',
          date: '1/10/2026',
          technician: 'John Mitchell',
          status: 'Technician On the Way',
          statusColor: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 12),
        _buildServiceCard(
          icon: Icons.kitchen,
          title: 'Water\nleaking',
          location: 'Refrigerator Ã¢â‚¬Â¢ Kitchen',
          date: '1/11/2026',
          technician: 'Michael Anderson',
          status: 'Scheduled',
          statusColor: AppColors.info,
        ),
        const SizedBox(height: 12),
        _buildServiceCard(
          icon: Icons.microwave,
          title: 'Not heating\nproperly',
          location: 'Microwave Oven Ã¢â‚¬Â¢ Kitchen',
          date: '1/9/2026',
          technician: 'Robert Johnson',
          status: 'Service In Progress',
          statusColor: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String location,
    required String date,
    required String technician,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge and Icon Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              // Icon
              Icon(icon, size: 32, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Location and Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Technician and Details Link Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Technician
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        technician,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Details Link
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primary,
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

  void _showHouseBottomSheet(BuildContext context) {
    final homes = ref.read(homeSelectionProvider).homes;
    final selectedName = ref.read(selectedHomeNameProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext modalContext) {
        return SelectHomeBottomSheet(
          homes: homes
              .map((h) => {
                'name': h.name,
                'address': h.address,
                'accessRole': h.accessRole,
              })
              .toList(),
          selectedHomeName: selectedName,
          onSelect: (name) async {
            // Close modal first
            Navigator.of(modalContext).pop();

            // Use a post-frame callback to avoid disposal issues
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted && context.mounted) {
                try {
                  // Update home selection
                  await ref
                      .read(homeSelectionProvider.notifier)
                      .selectHome(name);

                  // Wait a frame to ensure provider state is updated
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Clear and reload data for new home
                  if (mounted) {
                    setState(() {
                      _pendingDeliveries = [];
                      _allMaintenanceReminders = [];
                      _completedMaintenanceReminders = [];
                      _isLoadingMaintenance = true;
                    });

                    // Reload all data for the new home
                    await Future.wait([
                      _loadPendingDeliveries(),
                      _loadMaintenanceReminders(),
                    ]);
                  }
                } on Object catch (e) {
                  debugPrint('Error switching homes: $e');
                  // Show error message to user
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Failed to switch homes. Please try again.',
                        ),
                        backgroundColor: AppColors.accentDark,
                      ),
                    );
                  }
                }
              }
            });
          },
          onAddNewHome: () {
            Navigator.of(modalContext).pop();
            _showAddHomeBottomSheet(context);
          },
        );
      },
    );
  }

  void _showNoHomeDialog(
    BuildContext context, {
    bool autoOpenAssetFlow = true,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_outlined,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Set Up Your Home First',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Before adding appliances, let\'s get your home set up. It only takes a few seconds!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Not Now',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _showAddHomeBottomSheet(
                        context,
                        onHomeAdded: autoOpenAssetFlow
                            ? _openAddAssetFlow
                            : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Opens the Add Home bottom sheet.
  ///
  /// When [onHomeAdded] is provided it is called after the home has been
  /// created and selected (e.g. to auto-open the Add Asset flow).
  void _showAddHomeBottomSheet(
    BuildContext context, {
    VoidCallback? onHomeAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return AddHomeBottomSheet(
          onAdd: (name, address) async {
            Navigator.pop(modalContext);

            // Capture context-dependent objects before any await
            final messenger = ScaffoldMessenger.of(context);

            try {
              await ref
                  .read(homeSelectionProvider.notifier)
                  .addHome(name, address);

              if (mounted) {
                setState(() {});

                // Show success feedback
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Home "$name" added successfully!'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Auto-continue (e.g. open add-asset flow)
                if (onHomeAdded != null) {
                  // Small delay so the user sees the success message
                  await Future.delayed(const Duration(milliseconds: 400));
                  if (mounted) onHomeAdded();
                }
              }
            } on Object catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to add home: $e'),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  /// Opens the Add Asset flow screen.
  ///
  /// Reads the currently-selected home ID from the provider and
  /// launches [AddAssetFlowScreen]. Called by the FAB and also
  /// auto-invoked after creating a home from the "no home" dialog.
  void _openAddAssetFlow() {
    final homeId = ref.read(selectedHomeIdProvider);
    if (homeId == null || homeId.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAssetFlowScreen(
          existingAssets: ref.read(assetsProvider).valueOrNull ?? [],
          onAssetAdded: (asset) async {
            // Inject homeId so AssetDetailScreen can call issues/docs APIs immediately
            final assetWithHome = {...asset, 'homeId': homeId};
            await _persistNewAsset(assetWithHome, homeId);
            if (mounted) {
              setState(() {
                _optimisticNewAssets.insert(0, assetWithHome);
              });
            }
          },
        ),
      ),
    );
  }

  // Active Claims Horizontal Scroll (warranty/protection plan claims)
  Widget _buildActiveClaimsScroll() {
    final responsive = ResponsiveUtils(context);

    // Filter by search query
    var claims = [..._activeClaims];
    if (_homeSearchQuery.isNotEmpty) {
      claims = claims.where((c) {
        final q = _homeSearchQuery;
        return c.assetName.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            c.claimNumber.toLowerCase().contains(q) ||
            c.issueCategory.toLowerCase().contains(q);
      }).toList();
    }

    // Cap at 3 on the home tab
    if (claims.length > 3) claims = claims.take(3).toList();

    if (claims.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: responsive.iconSize(48),
                color: Colors.grey.shade300,
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                'No Active Claims',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                'Everything is running smoothly',
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1 claim: full-width single card
    if (claims.length == 1) {
      return GestureDetector(
        onTap: () => context.push('/claim-detail', extra: claims.first),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: responsive.spacing(8),
                offset: Offset(0, responsive.spacing(2)),
              ),
            ],
          ),
          child: _buildActiveClaimCard(claims.first, responsive, compact: false),
        ),
      );
    }
    // 2 claims: side-by-side equal-width cards
    if (claims.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildClaimTappableCard(claims[0], responsive)),
          SizedBox(width: responsive.spacing(12)),
          Expanded(child: _buildClaimTappableCard(claims[1], responsive)),
        ],
      );
    }

    // 3 claims: horizontal scroll
    final cardWidth = responsive.isSmallMobile
        ? 220.0
        : responsive.isMediumMobile
        ? 240.0
        : 260.0;
    const cardHeight = 130.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: claims.length,
        itemBuilder: (context, index) {
          final claim = claims[index];
          return GestureDetector(
            onTap: () => context.push('/claim-detail', extra: claim),
            child: Container(
              width: cardWidth,
              margin: EdgeInsets.only(
                right: index < claims.length - 1
                    ? responsive.spacing(12)
                    : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(responsive.borderRadius(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: responsive.spacing(8),
                    offset: Offset(0, responsive.spacing(2)),
                  ),
                ],
              ),
              child: _buildActiveClaimCard(claim, responsive, compact: true),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClaimTappableCard(Claim claim, ResponsiveUtils responsive) {
    return GestureDetector(
      onTap: () => context.push('/claim-detail', extra: claim),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: responsive.spacing(8),
              offset: Offset(0, responsive.spacing(2)),
            ),
          ],
        ),
        child: _buildActiveClaimCard(claim, responsive, compact: true),
      ),
    );
  }

  Widget _buildActiveClaimCard(Claim claim, ResponsiveUtils responsive, {bool compact = false}) {
    Color statusColor;
    switch (claim.status) {
      case ClaimStatus.submitted:
        statusColor = AppColors.info;
      case ClaimStatus.underReview:
        statusColor = AppColors.warning;
      case ClaimStatus.approved:
        statusColor = AppColors.success;
      case ClaimStatus.inProgress:
        statusColor = AppColors.primary;
      default:
        statusColor = AppColors.textSecondary;
    }

    final progress = claim.getProgress();

    return Padding(
      padding: EdgeInsets.all(responsive.spacing(compact ? 12 : 14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: status badge (left) + time elapsed (right) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(8),
                  vertical: responsive.spacing(3),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(responsive.borderRadius(20)),
                ),
                child: Text(
                  claim.getStatusLabel(),
                  style: TextStyle(
                    fontSize: responsive.fontSize(10),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Text(
                claim.getTimeElapsed(),
                style: TextStyle(
                  fontSize: responsive.fontSize(11),
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(8)),
          // ── Row 2: icon + asset name ──
          Row(
            children: [
              Icon(
                claim.getCategoryIcon(),
                size: responsive.iconSize(14),
                color: AppColors.primary,
              ),
              SizedBox(width: responsive.spacing(5)),
              Expanded(
                child: Text(
                  claim.assetName.isNotEmpty ? claim.assetName : claim.title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(compact ? 13 : 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(3)),
          // ── Row 3: claim number (left) + category (right) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                claim.claimNumber,
                style: TextStyle(
                  fontSize: responsive.fontSize(11),
                  color: AppColors.textSecondary,
                ),
              ),
              if (claim.issueCategory.isNotEmpty)
                Flexible(
                  child: Text(
                    claim.issueCategory,
                    style: TextStyle(
                      fontSize: responsive.fontSize(11),
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
          SizedBox(height: responsive.spacing(10)),
          // ── Progress bar ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: responsive.fontSize(10),
                  color: AppColors.textLight,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: responsive.fontSize(10),
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(4)),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // Pending Deliveries Section
  Widget _buildPendingDeliveriesSection() {
    final responsive = ResponsiveUtils(context);
    var deliveries = _pendingDeliveries;

    // Filter by search query
    if (_homeSearchQuery.isNotEmpty) {
      deliveries = deliveries.where((delivery) {
        final productName = delivery.productName.toLowerCase();
        final status = delivery.statusLabel.toLowerCase();
        return productName.contains(_homeSearchQuery) ||
            status.contains(_homeSearchQuery);
      }).toList();
    }

    if (deliveries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Deliveries',
                    style: TextStyle(
                      fontSize: responsive.fontSize(20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Track your orders and replacements',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                final homeId = ref.watch(selectedHomeIdProvider);
                context.push('/pending-deliveries?homeId=$homeId');
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(4)),
                  Icon(
                    Icons.chevron_right,
                    size: responsive.iconSize(18),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(16)),
        ...deliveries
            .take(3)
            .map(
              (delivery) => Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(12)),
                child: _buildDeliveryCard(delivery),
              ),
            ),
      ],
    );
  }

  Widget _buildDeliveryCard(PendingDelivery delivery) {
    final responsive = ResponsiveUtils(context);
    final imgSize = responsive.isSmallMobile ? 48.0 : 56.0;
    return GestureDetector(
      onTap: () {
        context.push('/orders/${delivery.id}');
      },
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: responsive.spacing(8),
              offset: Offset(0, responsive.spacing(2)),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: imgSize,
              height: imgSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(10),
                ),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(10),
                ),
                child: Image.asset(
                  delivery.productImage,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.inventory_2,
                      size: responsive.iconSize(28),
                      color: AppColors.textLight,
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product title
                  Text(
                    delivery.productName,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (delivery.isMaintenancePart &&
                      delivery.maintenanceTaskName != null) ...[
                    SizedBox(height: responsive.spacing(2)),
                    Row(
                      children: [
                        Icon(
                          Icons.build,
                          size: responsive.iconSize(12),
                          color: AppColors.primary,
                        ),
                        SizedBox(width: responsive.spacing(4)),
                        Expanded(
                          child: Text(
                            'For: ${delivery.maintenanceTaskName}${delivery.forAssetName != null ? ' Ã¢â‚¬Â¢ ${delivery.forAssetName}' : ''}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(11),
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: responsive.spacing(8)),
                  // Status badge and ETA directly below title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(6),
                          vertical: responsive.spacing(3),
                        ),
                        decoration: BoxDecoration(
                          color: delivery.statusBackgroundColor,
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(8),
                          ),
                        ),
                        child: Text(
                          delivery.statusLabel,
                          style: TextStyle(
                            fontSize: responsive.fontSize(10),
                            fontWeight: FontWeight.w600,
                            color: delivery.statusColor,
                          ),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(10)),
                      Icon(
                        Icons.local_shipping,
                        size: responsive.iconSize(14),
                        color: AppColors.primary,
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Text(
                        'ETA: ${delivery.getFormattedETA()}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: responsive.iconSize(20),
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// Add Home Dialog Widget
class _AddHomeDialog extends StatefulWidget {
  final Function(String name, String address) onAdd;

  const _AddHomeDialog({required this.onAdd});

  @override
  State<_AddHomeDialog> createState() => _AddHomeDialogState();
}

class _AddHomeDialogState extends State<_AddHomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add New Home',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter a home name',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(fontSize: 14, color: AppColors.primary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a home name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter an address',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(fontSize: 14, color: AppColors.primary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                _nameController.text.trim(),
                _addressController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: Text(
            'Add',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
