import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart'; // Tetap di-import jika akan dipakai lagi
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Import untuk formatting angka dan mata uang
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/features/menu_item/providers/menu_item_aggregate_provider.dart';
import 'package:jamal/features/order/providers/order_aggregate_provider.dart';
import 'package:jamal/features/user/providers/user_aggregate_provider.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch semua provider
    final usersCountAsync = ref.watch(usersCountProvider);
    final ordersCountAsync = ref.watch(ordersCountProvider);
    final orderRevenueAsync = ref.watch(orderRevenueProvider);
    final menuItemsCountAsync = ref.watch(menuItemsCountProvider);

    return MyScreenContainer(
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primary,
                      context.colors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard Admin',
                            style: context.textStyles.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ringkasan data dan statistik aplikasi',
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Grid Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(context),
                  crossAxisSpacing: 20.0,
                  mainAxisSpacing: 20.0,
                  childAspectRatio: _getChildAspectRatio(context),
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _buildUsersCard(context, usersCountAsync);
                    case 1:
                      return _buildOrdersCard(context, ordersCountAsync);
                    case 2:
                      return _buildRevenueCard(context, orderRevenueAsync);
                    case 3:
                      return _buildMenuItemsCard(context, menuItemsCountAsync);
                    default:
                      return const SizedBox();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 2;
    return 1;
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 1.3;
    if (width > 800) return 1.4;
    return 1.1;
  }

  Widget _buildUsersCard(BuildContext context, AsyncValue usersCountAsync) {
    return Skeletonizer(
      enabled: usersCountAsync.isLoading,
      child: _buildStatsCard(
        context,
        title: 'Total Pengguna',
        icon: Icons.people_alt_rounded,
        iconColor: context.colors.primary,
        backgroundColor: context.colors.primary.withOpacity(0.1),
        isError: usersCountAsync.hasError,
        errorMessage: 'Gagal memuat data pengguna',
        details: usersCountAsync.when(
          data:
              (data) => {
                'Semua': NumberFormat.decimalPattern(
                  'id_ID',
                ).format(data.allUserCount),
                'Admin': NumberFormat.decimalPattern(
                  'id_ID',
                ).format(data.adminCount),
                'User': NumberFormat.decimalPattern(
                  'id_ID',
                ).format(data.userCount),
              },
          loading: () => _getDummyDetails(),
          error: (_, __) => _getDummyDetails(),
        ),
      ),
    );
  }

  Widget _buildOrdersCard(BuildContext context, AsyncValue ordersCountAsync) {
    return Skeletonizer(
      enabled: ordersCountAsync.isLoading,
      child: _buildStatsCard(
        context,
        title: 'Total Pesanan',
        icon: Icons.shopping_bag_rounded,
        iconColor: context.colors.secondary,
        backgroundColor: context.colors.secondary.withOpacity(0.1),
        isError: ordersCountAsync.hasError,
        errorMessage: 'Gagal memuat data pesanan',
        details: ordersCountAsync.when(
          data:
              (data) => {
                'Semua': NumberFormat.decimalPattern(
                  'id_ID',
                ).format(data.totalOrders),
                ...data.statusCounts.map(
                  (key, value) => MapEntry(
                    key.toString().split('.').last,
                    NumberFormat.decimalPattern('id_ID').format(value),
                  ),
                ),
              },
          loading: () => _getDummyDetails(),
          error: (_, __) => _getDummyDetails(),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context, AsyncValue orderRevenueAsync) {
    return Skeletonizer(
      enabled: orderRevenueAsync.isLoading,
      child: _buildStatsCard(
        context,
        title: 'Total Pendapatan',
        icon: Icons.monetization_on_rounded,
        iconColor: context.colors.tertiary,
        backgroundColor: context.colors.tertiary.withOpacity(0.1),
        isError: orderRevenueAsync.hasError,
        errorMessage: 'Gagal memuat data pendapatan',
        details: orderRevenueAsync.when(
          data:
              (data) => {
                'Bulan Ini': NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(data.totalRevenueThisMonth),
                'Hari Ini': NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(data.totalRevenueToday),
                'Tahun Ini': NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(data.totalRevenueThisYear),
              },
          loading: () => _getDummyDetails(),
          error: (_, __) => _getDummyDetails(),
        ),
      ),
    );
  }

  Widget _buildMenuItemsCard(
    BuildContext context,
    AsyncValue menuItemsCountAsync,
  ) {
    return Skeletonizer(
      enabled: menuItemsCountAsync.isLoading,
      child: _buildStatsCard(
        context,
        title: 'Total Produk',
        icon: Icons.inventory_2_rounded,
        iconColor:
            context.isDarkMode
                ? AppTheme.primaryFocusDark
                : AppTheme.primaryFocusLight,
        backgroundColor: (context.isDarkMode
                ? AppTheme.primaryFocusDark
                : AppTheme.primaryFocusLight)
            .withOpacity(0.1),
        isError: menuItemsCountAsync.hasError,
        errorMessage: 'Gagal memuat data produk',
        details: menuItemsCountAsync.when(
          data:
              (data) => {
                'Semua': NumberFormat.decimalPattern(
                  'id_ID',
                ).format(data.allMenuItemCount),
                'Aktif': NumberFormat.decimalPattern(
                  'id_ID',
                ).format(data.activeMenuItemCount),
                'Non-Aktif': NumberFormat.decimalPattern(
                  'id_ID',
                ).format(data.nonActiveMenuItemCount),
              },
          loading: () => _getDummyDetails(),
          error: (_, __) => _getDummyDetails(),
        ),
      ),
    );
  }

  Map<String, String> _getDummyDetails() {
    return {'Loading': '0', 'Data': '0', 'Please Wait': '0'};
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required bool isError,
    required String errorMessage,
    required Map<String, String> details,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              context.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                context.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textStyles.titleMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Content
                  if (isError)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: context.colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...details.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              context.isDarkMode
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                context.isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: context.textStyles.bodyMedium?.color
                                    ?.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                entry.value,
                                style: context.textStyles.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
