import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/controller/auth_controller.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/login_screen.dart';

import '../features/owner/dashboard/owner_dashboard_screen.dart';
import '../features/owner/customers/customer_list_screen.dart';
import '../features/owner/customers/customer_ledger_screen.dart';
import '../features/owner/transactions/transaction_screen.dart';
import '../features/owner/reports/reports_screen.dart';
import '../features/owner/reports/aging_drilldown_screen.dart';
import '../features/owner/complaints/complaints_screen.dart';
import '../features/owner/profile/profile_screen.dart';
import '../features/owner/profile/security_settings_screen.dart';

import '../features/customer/dashboard/customer_dashboard_screen.dart';
import '../features/customer/history/customer_history_screen.dart';
import '../features/customer/notifications/customer_notifications_screen.dart';
import '../features/customer/profile/customer_profile_screen.dart';

import '../data/models/customer_model.dart';
import '../core/services/reminder_service.dart';
import '../shared/widgets/bottom_nav_scaffold.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (prev, next) {
      if (next.value != null) {
        _ref.read(reminderServiceProvider).checkAndGenerateReminders();
      }
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final isAuth = authState.value != null;
    final isSplash = state.matchedLocation == '/';
    final isLoggingIn = state.matchedLocation == '/login';
    final isSelectingRole = state.matchedLocation == '/role';

    if (authState.isLoading && !authState.hasValue) return null;

    if (!isAuth && !isLoggingIn && !isSelectingRole) {
      return '/role';
    }

    if (isAuth) {
      final actualRole = authState.value?.userMetadata?['role'] as String? ?? 'owner';
      final isOwnerPath = state.matchedLocation.startsWith('/owner');
      final isCustomerPath = state.matchedLocation.startsWith('/customer');

      if (isSplash || isLoggingIn || isSelectingRole) {
        return actualRole == 'owner' ? '/owner' : '/customer';
      }

      if (actualRole == 'owner' && isCustomerPath) {
        return '/owner';
      }
      if (actualRole == 'customer' && isOwnerPath) {
        return '/customer';
      }
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Owner Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(
            navigationShell: navigationShell,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Customers'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Reports'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner',
                builder: (context, state) => const OwnerDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'transactions',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TransactionScreen(),
                  ),
                  GoRoute(
                    path: 'complaints',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ComplaintsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/customers',
                builder: (context, state) => const CustomerListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final customer = state.extra as CustomerModel;
                      return CustomerLedgerScreen(customer: customer);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/reports',
                builder: (context, state) => const ReportsScreen(),
                routes: [
                  GoRoute(
                    path: 'aging/:category',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final category = state.pathParameters['category'] ?? '';
                      final customerIds = (state.extra as List<dynamic>?)?.cast<String>() ?? [];
                      return AgingDrilldownScreen(
                        categoryLabel: Uri.decodeComponent(category),
                        customerIds: customerIds,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'security',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SecuritySettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Customer Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(
            navigationShell: navigationShell,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer',
                builder: (context, state) => const CustomerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/history',
                builder: (context, state) => const CustomerHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/notifications',
                builder: (context, state) => const CustomerNotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                builder: (context, state) => const CustomerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
