import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:perpusglo/features/admin/view/categories/admin_categories_page.dart';
import 'package:perpusglo/features/admin/view/categories/admin_category_books_page.dart';
import 'package:perpusglo/features/admin/view/history/admin_history_page.dart';
import 'package:perpusglo/features/admin/view/overdue_books_page.dart';
import 'package:perpusglo/features/admin/view/settings/admin_settings_page.dart';
import 'package:perpusglo/features/admin/view/user_edit_page.dart';
import 'package:perpusglo/features/admin/view/user_search_results_page.dart';
import 'package:perpusglo/features/borrow/view/debug_overdue_page.dart';
import 'package:perpusglo/features/categories/view/category_detail_page.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/register_page.dart';
import '../features/home/view/main_navigation.dart';
import '../features/books/view/books_page.dart';
import '../features/books/view/book_detail_page.dart';
import '../features/borrow/view/borrow_history_page.dart';
import '../features/borrow/view/borrow_detail_page.dart';
import '../features/history/view/history_page.dart';
import '../features/notification/view/notification_page.dart';
import '../features/payment/view/payment_history_page.dart';
import '../features/payment/view/payment_page.dart';
import '../features/profile/view/profile_page.dart';
import '../features/profile/view/edit_profile_page.dart';
import '../features/profile/view/settings_page.dart';
// Import halaman admin
import '../features/admin/view/admin_dashboard_page.dart';
import '../features/admin/view/admin_login_page.dart';
import '../features/admin/view/books/book_management_page.dart';
import '../features/admin/view/books/add_edit_book_page.dart';
import '../features/admin/view/borrows/borrow_management_page.dart';
import '../features/admin/view/users/user_management_page.dart';

// router.dart digunakan untuk mengatur routing aplikasi menggunakan GoRouter
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  initialLocation: '/login',
  navigatorKey: _rootNavigatorKey,
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // Main navigation route
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationPage(initialIndex: 0),
    ),
    GoRoute(
      path: '/books',
      builder: (context, state) => const MainNavigationPage(initialIndex: 1),
    ),
    GoRoute(
      path: '/borrows',
      builder: (context, state) => const MainNavigationPage(initialIndex: 2),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const MainNavigationPage(initialIndex: 3),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MainNavigationPage(initialIndex: 4),
    ),

    // Detail routes
    GoRoute(
      path: '/books/:id',
      builder: (context, state) => BookDetailPage(
        bookId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/borrow-history',
      builder: (context, state) => const BorrowHistoryPage(),
    ),
    GoRoute(
      path: '/borrow/:id',
      builder: (context, state) {
        final borrowId = state.pathParameters['id'] ?? '';
        return BorrowDetailPage(borrowId: borrowId);
      },
    ),
    GoRoute(
      path: '/payment/:id',
      builder: (context, state) {
        final fineId = state.pathParameters['id'] ?? '';
        final amount =
            double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0.0;
        return PaymentPage(fineId: fineId, amount: amount);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/payment-history',
      builder: (context, state) => const PaymentHistoryPage(),
    ),

    //  Categories routes
    GoRoute(
      path: '/categories/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? '';
        return CategoryDetailPage(categoryId: categoryId);
      },
    ),

    // Profile routes
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const AdminSettingsPage(),
    ),

    // Admin Routes - BARU
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/admin/books',
      builder: (context, state) => const BookManagementPage(),
    ),
    GoRoute(
      path: '/admin/books/add',
      builder: (context, state) => const AddEditBookPage(),
    ),
    GoRoute(
      path: '/admin/books/edit/:id',
      builder: (context, state) {
        final bookId = state.pathParameters['id'] ?? '';
        return AddEditBookPage(bookId: bookId);
      },
    ),
    GoRoute(
      path: '/admin/borrows',
      builder: (context, state) => const BorrowManagementPage(),
    ),
    GoRoute(
      path: '/admin/borrows/overdue',
      builder: (context, state) => const OverdueBooksPage(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const UserManagementPage(),
    ),
    GoRoute(
      path: '/admin/users/:id',
      builder: (context, state) {
        final userId = state.pathParameters['id']!;
        return UserEditPage(userId: userId);
      },
    ),
    GoRoute(
      path: '/admin/users/search/:query',
      builder: (context, state) {
        final query = state.pathParameters['query']!;
        return UserSearchResultsPage(query: query);
      },
    ),
    GoRoute(
      path: '/admin/history',
      builder: (context, state) => const AdminHistoryPage(),
    ),

    // Rute untuk mengelola kategori
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const AdminCategoriesPage(),
    ),

    GoRoute(
      path: '/admin/categories/:id/books',
      builder: (context, state) {
        final categoryId = state.pathParameters['id']!;
        return AdminCategoryBooksPage(categoryId: categoryId);
      },
    ),
    // Di router.dart
    GoRoute(
      path: '/debug-overdue',
      builder: (context, state) => const DebugOverduePage(),
    ),
  ],
  // Redirect to login if not authenticated
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAdminRoute = state.matchedLocation.startsWith('/admin');

    // Kecualikan admin/login dari redirect
    final nonAuthRoutes = ['/login', '/register', '/admin/login'];

    // Admin route logic
    if (isAdminRoute && state.matchedLocation != '/admin/login') {
      // Untuk memeriksa apakah user adalah admin, kita perlu mengecek state usernya
      // Di sini kita sederhanakan dengan mengecek apakah user login
      if (!isLoggedIn) {
        return '/admin/login';
      }

      // Sebenarnya di sini kita perlu cek role user
      // Namun karena keterbatasan akses state di router,
      // kita biarkan pengecekan role dilakukan di halaman admin
    }

    // User route logic (non-admin)
    if (!isAdminRoute) {
      // If not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn && !nonAuthRoutes.contains(state.matchedLocation)) {
        return '/login';
      }

      // If logged in and trying to access login/register, redirect to home
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/home';
      }
    }

    return null;
  },
);