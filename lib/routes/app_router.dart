import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import '../core/constants/app_strings.dart';
import '../features/assets/add_asset_flow/screens/add_asset_flow_screen.dart';
import '../features/assets/protection_plan_flow/screens/deductible_selection_screen.dart';
import '../features/assets/protection_plan_flow/screens/protection_plan_checkout_screen.dart';
import '../features/assets/protection_plan_flow/screens/protection_plan_confirmation_screen.dart';
import '../features/assets/protection_plan_flow/screens/protection_plan_detail_screen.dart';
import '../features/assets/protection_plan_flow/screens/protection_plan_payment_screen.dart';
import '../features/assets/screens/asset_detail_screen.dart';
// Assets
import '../features/assets/screens/network_history_screen.dart';
import '../features/assets/screens/replacement_claim_screen.dart';
import '../features/assets/screens/warranties_screen.dart';
import '../features/assets/screens/warranty_detail_screen.dart';
import '../features/assets/upgrade_flow/screens/upgrade_buy_new_screen.dart';
import '../features/assets/upgrade_flow/screens/upgrade_offer_screen.dart';
import '../features/assets/upgrade_flow/screens/upgrade_replace_screen.dart';
import '../features/authentication/screens/otp_verification_screen.dart';
import '../features/authentication/screens/signin_screen.dart';
import '../features/authentication/screens/signup_screen.dart';
// Authentication
import '../features/authentication/screens/splash_screen.dart';
// Claims
import '../features/claims/screens/my_claims_screen.dart';
import '../features/home/screens/critical_alerts_screen.dart';
// Home
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/notification_screen.dart';
import '../features/home/widgets/shared/home_selector_bottom_sheet.dart';
import '../features/maintenance/parts_order_flow/screens/maintenance_parts_checkout_address_screen.dart';
import '../features/maintenance/parts_order_flow/screens/maintenance_parts_checkout_payment_screen.dart';
import '../features/maintenance/parts_order_flow/screens/maintenance_parts_order_confirmation_screen.dart';
import '../features/maintenance/parts_order_flow/screens/maintenance_parts_order_screen.dart';
// Maintenance
import '../features/maintenance/screens/ai_fix_problem_screen.dart';
import '../features/maintenance/screens/maintenance_dashboard_screen.dart';
import '../features/profile/screens/accept_invite_screen.dart';
import '../features/profile/screens/family_members_screen.dart';
import '../features/profile/screens/invite_member_screen.dart';
import '../features/profile/screens/member_detail_screen.dart';
import '../features/profile/screens/my_family_access_screen.dart';
import '../features/profile/screens/pending_deliveries_screen.dart';
// Profile
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
// Services
import '../features/services/screens/active_services_screen.dart';
import '../features/services/screens/booking_detail_screen.dart';
import '../features/services/screens/service_booking_screen.dart';
import '../features/services/screens/service_history_screen.dart';
import '../features/services/screens/service_subcategory_screen.dart';
import '../features/services/service_booking_flow/assembly/assembly_booking_flow.dart';
import '../features/services/service_booking_flow/cleaning/cleaning_booking_flow.dart';
import '../features/services/service_booking_flow/home_repairs/home_repairs_booking_flow.dart';
import '../features/services/service_booking_flow/lifestyle/lifestyle_booking_flow.dart';
import '../features/services/service_booking_flow/mounting/mounting_booking_flow.dart';
import '../features/services/service_booking_flow/moving/moving_booking_flow.dart';
import '../features/services/service_booking_flow/outdoor/outdoor_booking_flow.dart';
import '../features/services/service_booking_flow/painting/painting_booking_flow.dart';
import '../features/services/service_booking_flow/security/security_booking_flow.dart';
// Models
import '../features/shared/models/maintenance_models.dart';
import '../features/shopping/checkout_flow/screens/add_card_screen.dart';
import '../features/shopping/checkout_flow/screens/checkout_address_screen.dart';
import '../features/shopping/checkout_flow/screens/checkout_confirmation_screen.dart';
import '../features/shopping/checkout_flow/screens/checkout_payment_screen.dart';
import '../features/shopping/checkout_flow/screens/checkout_success_screen.dart';
import '../features/shopping/checkout_flow/screens/installment_options_screen.dart';
import '../features/shopping/checkout_flow/screens/order_detail_screen.dart';
// Shopping
import '../features/shopping/screens/buy_new_asset_screen.dart';
import '../features/shopping/screens/my_orders_screen.dart';
import '../features/shopping/screens/product_detail_screen.dart';
// Family models (for accept-invite route)
import '../models/family_models.dart';
// Auth
import '../providers/auth_provider.dart';
import '../providers/deep_link_provider.dart';
import '../providers/home_selection_provider.dart';
import '../services/deep_link_service.dart'; // for pendingInviteTokenKey
// Route models
import 'route_models.dart';

/// Global navigator key — used by [DeepLinkService] for imperative navigation.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized router configuration for the app.
///
/// Notifies [GoRouter] to re-evaluate its redirect whenever auth state changes
/// OR when a pending deep-link invite token arrives.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      notifyListeners();
    });
    ref.listen<String?>(pendingInviteTokenProvider, (previous, next) {
      if (next != null) notifyListeners();
    });
    // Also re-evaluate when cold-start invite nav data is set (unauthenticated).
    ref.listen<PendingInviteNavData?>(pendingInviteNavDataProvider, (previous, next) {
      if (next != null) notifyListeners();
    });
  }
}

/// Riverpod provider for the app router.
///
/// Watches [authProvider] via [_AuthRefreshNotifier] and redirects
/// to the correct page based on authentication state.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Pending invite token (from deep link or post-login) → intercept and
      // redirect to accept-invite. Clear it immediately so we don't loop.
      final pendingToken = ref.read(pendingInviteTokenProvider);
      if (pendingToken != null && authState == AuthState.authenticated) {
        ref.read(pendingInviteTokenProvider.notifier).state = null;
        final encoded = Uri.encodeComponent(pendingToken);
        return '/accept-invite?token=$encoded';
      }

      // Cold-start (unauthenticated) invite nav data → route to signin/signup
      // with email pre-filled. Clear immediately to avoid looping.
      final pendingNavData = ref.read(pendingInviteNavDataProvider);
      if (pendingNavData != null && authState == AuthState.unauthenticated) {
        ref.read(pendingInviteNavDataProvider.notifier).state = null;
        final emailParam = pendingNavData.email.isNotEmpty
            ? '&prefilledEmail=${Uri.encodeComponent(pendingNavData.email)}'
            : '';
        return pendingNavData.action == 'signup'
            ? '/signup?fromInvite=true$emailParam'
            : '/signin?fromInvite=true$emailParam';
      }
      final location = state.matchedLocation;

      const authPages = ['/splash', '/signin', '/signup', '/otp'];
      final isOnAuthPage = authPages.contains(location);

      // Still loading — stay on or go to splash.
      if (authState == AuthState.loading) {
        return isOnAuthPage ? null : '/splash';
      }

      // Not authenticated — allow auth pages and accept-invite deep links.
      if (authState == AuthState.unauthenticated) {
        if (location == '/signin' ||
            location == '/signup' ||
            location == '/otp' ||
            location == '/accept-invite') {
          return null;
        }
        return '/signin';
      }

      // Authenticated — redirect away from auth pages to home.
      if (authState == AuthState.authenticated && isOnAuthPage) {
        return '/home';
      }

      return null;
    },
    onException: (context, state, router) {
      // GoRouter receives the raw platform deep-link URI (e.g.
      // homeiq://accept-invite/?token=xxx) and can't match it to any route.
      // Intercept here, store the token, then navigate to a valid path.
      final uri = state.uri;
      if (uri.scheme == 'homeiq' && uri.host == 'accept-invite') {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          final container = ProviderScope.containerOf(context, listen: false);
          final authState = container.read(authProvider);
          if (authState == AuthState.authenticated) {
            container.read(pendingInviteTokenProvider.notifier).state = token;
            router.go('/home'); // redirect will fire → /accept-invite
          } else {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString(pendingInviteTokenKey, token);
            });
            // Use action/email params from the deep link (embedded by backend
            // redirect page) to route to signin or signup with email pre-filled.
            final action = uri.queryParameters['action'] ?? 'signin';
            final email = uri.queryParameters['email'] ?? '';
            final emailParam = email.isNotEmpty
                ? '&prefilledEmail=${Uri.encodeComponent(email)}'
                : '';
            if (action == 'signup') {
              router.go('/signup?fromInvite=true$emailParam');
            } else {
              router.go('/signin?fromInvite=true$emailParam');
            }
          }
          return;
        }
      }
      // Fallback for any other unrecognised route.
      router.go('/');
    },
    routes: AppRouter._routes,
  );
});

/// All route error messages reference [AppStrings] for consistency.
/// Route parameters use typed models from [route_models.dart] where possible.
class AppRouter {
  AppRouter._();

  /// Error fallback widget used when required route data is missing.
  static Widget _errorScreen(String message) {
    return Scaffold(body: Center(child: Text(message)));
  }

  /// Shows a "No Home" dialog from the router guard for /add-asset.
  /// After the user creates a home the dialog closes and the route
  /// rebuilds via [selectedHomeIdProvider], now showing AddAssetFlowScreen.
  static bool _noHomeDialogShowing = false;
  static void _showNoHomeGuardDialog(BuildContext context, WidgetRef ref) {
    if (_noHomeDialogShowing) return;
    _noHomeDialogShowing = true;

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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_outlined,
                  size: 34,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Home Added',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'You need to add a home before adding an asset.\n\nTap "Add Home" to set up your first home.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _noHomeDialogShowing = false;
                      Navigator.of(dialogContext).pop();
                      GoRouter.of(context).go('/home');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _noHomeDialogShowing = false;
                      Navigator.of(dialogContext).pop();
                      // Open Add Home bottom sheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (modalContext) {
                          return AddHomeBottomSheet(
                            onAdd: (name, address) async {
                              Navigator.pop(modalContext);
                              try {
                                await ref
                                    .read(homeSelectionProvider.notifier)
                                    .addHome(name, address);
                                // The Consumer will rebuild showing AddAssetFlowScreen
                                // since selectedHomeIdProvider now has a value.
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                            child: Text(
                                              'Home "$name" added! You can now add assets.',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } on Object catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add home: $e'),
                                      backgroundColor: Colors.red.shade600,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  GoRouter.of(context).go('/home');
                                }
                              }
                            },
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add Home'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).then((_) => _noHomeDialogShowing = false);
  }

  static final List<RouteBase> _routes = [
    // ── Authentication ──────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/signin',
      name: 'signin',
      builder: (context, state) => SignInScreen(
        prefilledEmail: state.uri.queryParameters['prefilledEmail'],
        isFromInvite: state.uri.queryParameters['fromInvite'] == 'true',
      ),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => SignUpScreen(
        prefilledEmail: state.uri.queryParameters['prefilledEmail'],
        isFromInvite: state.uri.queryParameters['fromInvite'] == 'true',
      ),
    ),
    GoRoute(
      path: '/otp',
      name: 'otp',
      builder: (context, state) {
        final emailOrPhone = state.uri.queryParameters['emailOrPhone'] ?? '';
        final isFromSignUp =
            state.uri.queryParameters['fromSignUp'] == 'true' ||
            state.uri.queryParameters['isFromSignUp'] == 'true';
        return OtpVerificationScreen(
          emailOrPhone: emailOrPhone,
          isFromSignUp: isFromSignUp,
        );
      },
    ),

    // ── Home ────────────────────────────────────────────────────────
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) {
        return const HomeScreen();
      },
    ),

    // ── Services ────────────────────────────────────────────────────
    GoRoute(
      path: '/service-subcategory',
      name: 'service-subcategory',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null) {
          return _errorScreen(AppStrings.serviceCategoryNotFound);
        }
        final params = ServiceSubcategoryParams.fromMap(data);
        return ServiceSubcategoryScreen(
          categoryName: params.categoryName,
          services: params.services,
        );
      },
    ),
    GoRoute(
      path: '/service-booking',
      name: 'service-booking',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null) {
          return _errorScreen(AppStrings.serviceNotFound);
        }
        final params = ServiceBookingParams.fromMap(data);
        return ServiceBookingScreen(
          categoryName: params.categoryName,
          service: params.service,
        );
      },
    ),
    ..._serviceFlowRoutes(),
    GoRoute(
      path: '/service-history',
      name: 'service-history',
      builder: (context, state) => const ServiceHistoryScreen(),
    ),
    GoRoute(
      path: '/active-services',
      name: 'active-services',
      builder: (context, state) {
        final homeId = state.uri.queryParameters['homeId'];
        return ActiveServicesScreen(homeId: homeId);
      },
    ),
    GoRoute(
      path: '/bookings/:id',
      name: 'bookings-detail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BookingDetailScreen(bookingId: id);
      },
    ),

    // ── Alerts & Notifications ──────────────────────────────────────
    GoRoute(
      path: '/critical-alerts',
      name: 'critical-alerts',
      builder: (context, state) {
        final homeId = state.uri.queryParameters['homeId'];
        return CriticalAlertsScreen(homeId: homeId);
      },
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationScreen(),
    ),

    // ── Profile & Settings ──────────────────────────────────────────
    GoRoute(
      path: '/pending-deliveries',
      name: 'pending-deliveries',
      builder: (context, state) {
        final homeId = state.uri.queryParameters['homeId'];
        return PendingDeliveriesScreen(homeId: homeId);
      },
    ),
    GoRoute(
      path: '/family-members',
      name: 'family-members',
      builder: (context, state) => const FamilyMembersScreen(),
    ),
    GoRoute(
      path: '/family-members/invite',
      name: 'family-members-invite',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        final onInviteSent = data?['onInviteSent'] as VoidCallback?;
        return InviteMemberScreen(onInviteSent: onInviteSent);
      },
    ),
    GoRoute(
      path: '/family-members/detail',
      name: 'family-member-detail',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        final memberId = data?['memberId'] as String? ?? '';
        if (memberId.isEmpty) {
          return _errorScreen('Member ID is required');
        }
        return MemberDetailScreen(memberId: memberId);
      },
    ),
    GoRoute(
      path: '/accept-invite',
      name: 'accept-invite',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        final invite = data?['invite'] as MyInviteDto?;
        final token =
            data?['token'] as String? ?? state.uri.queryParameters['token'];
        if (invite == null && (token == null || token.isEmpty)) {
          return _errorScreen('Invite data is required');
        }
        return AcceptInviteScreen(invite: invite, token: token);
      },
    ),
    GoRoute(
      path: '/my-family-access',
      name: 'my-family-access',
      builder: (context, state) => const MyFamilyAccessScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // ── Assets ──────────────────────────────────────────────────────
    GoRoute(
      path: '/add-asset',
      name: 'add-asset',
      // Guard: if no home is selected, show dialog to add one first.
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final homeId = ref.watch(selectedHomeIdProvider);
          if (homeId == null || homeId.isEmpty) {
            // Show a "No Home" screen with a prominent CTA.
            // Using addPostFrameCallback so we don't call showDialog
            // during build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _showNoHomeGuardDialog(context, ref);
              }
            });
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'A home is required to add assets',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return AddAssetFlowScreen(
            onAssetAdded: (asset) {
              // This route is a fallback; persistence is handled inside
              // the flow via the home-screen FAB path.  Navigate back.
              GoRouter.of(context).go('/home');
            },
          );
        },
      ),
    ),
    GoRoute(
      path: '/asset-detail',
      name: 'asset-detail',
      builder: (context, state) {
        try {
          final params = AssetDetailParams.fromExtra(state.extra);
          return AssetDetailScreen(
            asset: params.asset,
            initialTab: params.initialTab,
            skipPopup: params.skipPopup,
          );
        } on Object catch (_) {
          return _errorScreen(AppStrings.assetNotFound);
        }
      },
    ),
    GoRoute(
      path: '/warranty-detail',
      name: 'warranty-detail',
      builder: (context, state) {
        final assetData = state.extra as Map<String, dynamic>?;
        if (assetData == null) {
          return _errorScreen(AppStrings.assetNotFound);
        }
        return WarrantyDetailScreen(asset: assetData);
      },
    ),
    GoRoute(
      path: '/warranties',
      name: 'warranties',
      builder: (context, state) {
        final assetData = state.extra as Map<String, dynamic>?;
        if (assetData == null) {
          return _errorScreen(AppStrings.assetNotFound);
        }
        return WarrantiesScreen(asset: assetData);
      },
    ),
    GoRoute(
      path: '/replacement-claim',
      name: 'replacement-claim',
      builder: (context, state) {
        final assetData = state.extra as Map<String, dynamic>?;
        if (assetData == null) {
          return _errorScreen(AppStrings.assetNotFound);
        }
        return ReplacementClaimScreen(asset: assetData);
      },
    ),
    GoRoute(
      path: '/network-history',
      name: 'network-history',
      builder: (context, state) => const NetworkHistoryScreen(),
    ),

    // ── Protection Plans ────────────────────────────────────────────
    ..._protectionPlanRoutes(),

    // ── Upgrade Flow ────────────────────────────────────────────────
    ..._upgradeFlowRoutes(),

    // ── Shopping & Checkout ─────────────────────────────────────────
    ..._shoppingRoutes(),

    // ── Maintenance ─────────────────────────────────────────────────
    ..._maintenanceRoutes(),

    // ── Orders & Claims ─────────────────────────────────────────────
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      name: 'order-detail',
      builder: (context, state) {
        final orderId = state.pathParameters['id'];
        if (orderId == null) return const MyOrdersScreen();
        return OrderDetailScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/my-claims',
      name: 'my-claims',
      builder: (context, state) => const MyClaimsScreen(),
    ),

    // ── Services (tab shortcut) ─────────────────────────────────────
    GoRoute(
      path: '/services',
      name: 'services',
      builder: (context, state) => const HomeScreen(),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════
  //  ROUTE GROUP HELPERS — keep the main route list concise
  // ═══════════════════════════════════════════════════════════════════════

  static List<GoRoute> _serviceFlowRoutes() => [
    GoRoute(
      path: '/service-flow/assembly',
      name: 'service-flow-assembly',
      builder: (context, state) =>
          const AssemblyBookingFlow(categoryName: 'Assembly'),
    ),
    GoRoute(
      path: '/service-flow/mounting',
      name: 'service-flow-mounting',
      builder: (context, state) =>
          const MountingBookingFlow(categoryName: 'Mounting'),
    ),
    GoRoute(
      path: '/service-flow/moving',
      name: 'service-flow-moving',
      builder: (context, state) =>
          const MovingBookingFlow(categoryName: 'Moving'),
    ),
    GoRoute(
      path: '/service-flow/cleaning',
      name: 'service-flow-cleaning',
      builder: (context, state) =>
          const CleaningBookingFlow(categoryName: 'Cleaning'),
    ),
    GoRoute(
      path: '/service-flow/outdoor',
      name: 'service-flow-outdoor',
      builder: (context, state) =>
          const OutdoorBookingFlow(categoryName: 'Outdoor'),
    ),
    GoRoute(
      path: '/service-flow/home-repairs',
      name: 'service-flow-home-repairs',
      builder: (context, state) =>
          const HomeRepairsBookingFlow(categoryName: 'Home Repairs'),
    ),
    GoRoute(
      path: '/service-flow/painting',
      name: 'service-flow-painting',
      builder: (context, state) =>
          const PaintingBookingFlow(categoryName: 'Painting'),
    ),
    GoRoute(
      path: '/service-flow/security',
      name: 'service-flow-security',
      builder: (context, state) =>
          const SecurityBookingFlow(categoryName: 'Security'),
    ),
    GoRoute(
      path: '/service-flow/lifestyle',
      name: 'service-flow-lifestyle',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        final params = data != null
            ? LifestyleBookingParams.fromMap(data)
            : const LifestyleBookingParams();
        return LifestyleBookingFlow(
          categoryName: 'Lifestyle',
          preSelectedService: params.preSelectedService,
        );
      },
    ),
  ];

  static List<GoRoute> _protectionPlanRoutes() => [
    GoRoute(
      path: '/protection-plan-detail',
      name: 'protection-plan-detail',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null || args['plan'] == null || args['asset'] == null) {
          return _errorScreen(AppStrings.planOrAssetNotFound);
        }
        final params = ProtectionPlanDetailParams.fromMap(args);
        return ProtectionPlanDetailScreen(
          plan: params.plan,
          asset: params.asset,
          billingPeriod: params.billingPeriod,
        );
      },
    ),
    GoRoute(
      path: '/deductible-selection',
      name: 'deductible-selection',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null ||
            args['plan'] == null ||
            args['asset'] == null ||
            args['billingPeriod'] == null ||
            args['basePrice'] == null) {
          return _errorScreen(AppStrings.requiredDataNotFound);
        }
        final params = DeductibleSelectionParams.fromMap(args);
        return DeductibleSelectionScreen(
          plan: params.plan,
          asset: params.asset,
          billingPeriod: params.billingPeriod,
          basePrice: params.basePrice,
        );
      },
    ),
    GoRoute(
      path: '/protection-plan-checkout',
      name: 'protection-plan-checkout',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null ||
            args['plan'] == null ||
            args['asset'] == null ||
            args['selectedPaymentOption'] == null) {
          return _errorScreen(AppStrings.planDataNotFound);
        }
        final params = ProtectionPlanCheckoutParams.fromMap(args);
        return ProtectionPlanCheckoutScreen(
          plan: params.plan,
          asset: params.asset,
          selectedPaymentOption: params.selectedPaymentOption,
        );
      },
    ),
    GoRoute(
      path: '/protection-plan-payment',
      name: 'protection-plan-payment',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null ||
            args['plan'] == null ||
            args['asset'] == null ||
            args['selectedPaymentOption'] == null) {
          return _errorScreen(AppStrings.planDataNotFound);
        }
        final params = ProtectionPlanCheckoutParams.fromMap(args);
        return ProtectionPlanPaymentScreen(
          plan: params.plan,
          asset: params.asset,
          selectedPaymentOption: params.selectedPaymentOption,
        );
      },
    ),
    GoRoute(
      path: '/protection-plan-confirmation',
      name: 'protection-plan-confirmation',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null ||
            args['plan'] == null ||
            args['asset'] == null ||
            args['selectedPaymentOption'] == null) {
          return _errorScreen(AppStrings.planDataNotFound);
        }
        final params = ProtectionPlanCheckoutParams.fromMap(args);
        return ProtectionPlanConfirmationScreen(
          plan: params.plan,
          asset: params.asset,
          selectedPaymentOption: params.selectedPaymentOption,
        );
      },
    ),
  ];

  static List<GoRoute> _upgradeFlowRoutes() => [
    GoRoute(
      path: '/upgrade-offer',
      name: 'upgrade-offer',
      builder: (context, state) {
        final assetData = state.extra as Map<String, dynamic>?;
        if (assetData == null) {
          return _errorScreen(AppStrings.assetNotFound);
        }
        return UpgradeOfferScreen(asset: assetData);
      },
    ),
    GoRoute(
      path: '/upgrade-offer/replace',
      name: 'upgrade-offer-replace',
      builder: (context, state) {
        final assetData = state.extra as Map<String, dynamic>?;
        if (assetData == null) {
          return _errorScreen(AppStrings.assetNotFound);
        }
        return UpgradeReplaceScreen(asset: assetData);
      },
    ),
    GoRoute(
      path: '/upgrade-offer/buy-new',
      name: 'upgrade-offer-buy-new',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.assetNotFound);
        }
        final params = UpgradeBuyNewParams.fromMap(args);
        return UpgradeBuyNewScreen(
          asset: params.asset,
          tradeInValue: params.tradeInValue,
        );
      },
    ),
  ];

  static List<GoRoute> _shoppingRoutes() => [
    GoRoute(
      path: '/buy-new-asset',
      name: 'buy-new-asset',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null) {
          return _errorScreen(AppStrings.dataNotFound);
        }
        return BuyNewAssetScreen(data: data);
      },
    ),
    GoRoute(
      path: '/product-detail',
      name: 'product-detail',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.productNotFound);
        }
        final params = ProductDetailParams.fromMap(args);
        return ProductDetailScreen(
          product: params.product,
          tradeInValue: params.tradeInValue,
          asset: params.asset,
        );
      },
    ),
    GoRoute(
      path: '/checkout-address',
      name: 'checkout-address',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.checkoutDataNotFound);
        }
        final params = CheckoutAddressParams.fromMap(args);
        return CheckoutAddressScreen(
          product: params.product,
          tradeInValue: params.tradeInValue,
          quantity: params.quantity,
          asset: params.asset,
        );
      },
    ),
    GoRoute(
      path: '/checkout-payment',
      name: 'checkout-payment',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.checkoutDataNotFound);
        }
        final params = CheckoutPaymentParams.fromMap(args);
        return CheckoutPaymentScreen(
          product: params.product,
          tradeInValue: params.tradeInValue,
          quantity: params.quantity,
          address: params.address,
        );
      },
    ),
    GoRoute(
      path: '/add-card',
      name: 'add-card',
      builder: (context, state) => const AddCardScreen(),
    ),
    GoRoute(
      path: '/installment-options',
      name: 'installment-options',
      builder: (context, state) {
        final totalAmount = state.uri.queryParameters['totalAmount'];
        if (totalAmount == null) {
          return _errorScreen(AppStrings.totalAmountNotProvided);
        }
        return InstallmentOptionsScreen(totalAmount: double.parse(totalAmount));
      },
    ),
    GoRoute(
      path: '/checkout-confirmation',
      name: 'checkout-confirmation',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.orderDataNotFound);
        }
        final params = CheckoutConfirmationParams.fromMap(args);
        return CheckoutConfirmationScreen(
          items: params.toItemsList(),
          tradeInValuePerItem: params.tradeInValue,
          subtotal: params.subtotal,
          tradeInTotal: params.tradeInTotal,
          tax: params.tax,
          totalAmount: params.totalAmount,
          address: params.address,
          trackingId: params.trackingId,
          expectedDelivery: params.expectedDelivery,
          fromUpgradeFlow: params.fromUpgradeFlow,
          asset: params.asset,
        );
      },
    ),
    GoRoute(
      path: '/checkout-success',
      name: 'checkout-success',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.orderDataNotFound);
        }
        final params = CheckoutSuccessParams.fromMap(args);
        return CheckoutSuccessScreen(
          trackingId: params.trackingId,
          expectedDelivery: params.expectedDelivery,
          product: params.product,
          quantity: params.quantity,
          subtotal: params.subtotal,
          tradeInTotal: params.tradeInTotal,
          tax: params.tax,
          totalAmount: params.totalAmount,
          address: params.address,
          paymentMethod: params.paymentMethod,
          fromUpgradeFlow: params.fromUpgradeFlow,
          asset: params.asset,
        );
      },
    ),
  ];

  static List<GoRoute> _maintenanceRoutes() => [
    GoRoute(
      path: '/ai-fix-problem',
      name: 'ai-fix-problem',
      builder: (context, state) {
        final assetData = state.extra as Map<String, dynamic>?;
        if (assetData == null) {
          return _errorScreen(AppStrings.assetNotFound);
        }
        final params = AiFixProblemParams.fromMap(assetData);
        return AiFixProblemScreen(
          asset: params.asset,
          fromDiy: params.fromDiy,
          diyContext: params.diyContext,
        );
      },
    ),
    GoRoute(
      path: '/maintenance',
      name: 'maintenance',
      builder: (context, state) => const MaintenanceDashboardScreen(),
    ),
    GoRoute(
      path: '/maintenance/order-parts',
      name: 'maintenance-order-parts',
      builder: (context, state) {
        final extra = state.extra;
        if (extra == null) {
          return _errorScreen(AppStrings.reminderNotFound);
        }
        // Handle both Reminder object and Map format
        if (extra is Map<String, dynamic>) {
          final reminder = Reminder(
            id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
            assetId: (extra['asset']?['id'] ?? 0).toString(),
            assetName: extra['asset']?['name'] ?? 'Asset',
            assetLocation: extra['asset']?['location'] ?? 'Home',
            taskId: 'temp-task',
            taskName: extra['maintenanceTaskName'] ?? 'Maintenance Task',
            taskDescription: 'Maintenance task',
            whyItMatters: 'Important for asset maintenance',
            estimatedEffort: '30 minutes',
            dueDate: DateTime.now(),
            status: ReminderStatus.upcoming,
            priority: ReminderPriority.medium,
            riskLevel: 5,
          );
          return MaintenancePartsOrderScreen(reminder: reminder);
        }
        return MaintenancePartsOrderScreen(reminder: extra as Reminder);
      },
    ),
    GoRoute(
      path: '/maintenance/parts-checkout-address',
      name: 'maintenance-parts-checkout-address',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.orderDataNotFound);
        }
        final params = MaintenancePartsCheckoutParams.fromMap(args);
        return MaintenancePartsCheckoutAddressScreen(
          reminder: params.reminder as Reminder,
          parts: params.parts,
          selectedParts: params.selectedParts,
          subtotal: params.subtotal,
          providerTotals: params.providerTotals,
        );
      },
    ),
    GoRoute(
      path: '/maintenance/parts-checkout-payment',
      name: 'maintenance-parts-checkout-payment',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null) {
          return _errorScreen(AppStrings.orderDataNotFound);
        }
        final params = MaintenancePartsCheckoutParams.fromMap(args);
        return MaintenancePartsCheckoutPaymentScreen(
          reminder: params.reminder as Reminder,
          parts: params.parts,
          selectedParts: params.selectedParts,
          subtotal: params.subtotal,
          providerTotals: params.providerTotals,
          address: params.address!,
        );
      },
    ),
    GoRoute(
      path: '/maintenance/parts-order-confirmation',
      name: 'maintenance-parts-order-confirmation',
      builder: (context, state) {
        try {
          final args = state.extra as Map<String, dynamic>?;
          if (args == null) {
            return _errorScreen(AppStrings.orderDataNotFound);
          }
          final params = MaintenancePartsCheckoutParams.fromMap(args);
          return MaintenancePartsOrderConfirmationScreen(
            reminder: params.reminder as Reminder,
            parts: params.parts,
            selectedParts: params.selectedParts,
            subtotal: params.subtotal,
            providerTotals: params.providerTotals,
            address: params.address!,
            trackingId: params.trackingId!,
            expectedDelivery: params.expectedDelivery!,
          );
        } on Object catch (e) {
          return _errorScreen(AppStrings.routeError('$e'));
        }
      },
    ),
  ];
}