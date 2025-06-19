import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/data/repositories/user_repo.dart';
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
    return MyScreenContainer(
      child: Scaffold(
        backgroundColor: context.colors.surface.withValues(alpha: 0.95),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildRevenueSection(context, ref),
              const SizedBox(height: 24),
              _buildOrderStatusSection(context, ref),
              const SizedBox(height: 24),
              _buildUserAndProductSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.dashboard_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: context.textStyles.headlineMedium),
            Text(
              'Ringkasan data dan statistik aplikasi',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.textStyles.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueSection(BuildContext context, WidgetRef ref) {
    final orderRevenueAsync = ref.watch(orderRevenueProvider);
    final color = context.colors.tertiary;

    return Skeletonizer(
      enabled: orderRevenueAsync.isLoading,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analisis Pendapatan', style: context.textStyles.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Perbandingan pendapatan dalam berbagai periode.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.textStyles.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              orderRevenueAsync.when(
                data:
                    (data) => AspectRatio(
                      aspectRatio: 1.7,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor:
                                  (_) => context.colors.primary.withValues(
                                    alpha: 0.8,
                                  ),
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                return BarTooltipItem(
                                  'Rp ${NumberFormat.compactCurrency(locale: 'id_ID', symbol: '', decimalDigits: 2).format(rod.toY)}',
                                  context.textStyles.bodySmall!.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final titles = [
                                    'Hari Ini',
                                    'Bulan Ini',
                                    'Tahun Ini',
                                  ];
                                  // ! INI PERBAIKANNYA
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 4,
                                    child: Text(
                                      titles[value.toInt()],
                                      style: context.textStyles.labelSmall,
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('');
                                  return Text(
                                    NumberFormat.compact(
                                      locale: 'id_ID',
                                    ).format(value),
                                    style: context.textStyles.labelSmall,
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _makeGroupData(
                              0,
                              data.totalRevenueToday,
                              color.withValues(alpha: 0.6),
                            ),
                            _makeGroupData(
                              1,
                              data.totalRevenueThisMonth,
                              color,
                            ),
                            _makeGroupData(
                              2,
                              data.totalRevenueThisYear,
                              color.withValues(alpha: 0.8),
                            ),
                          ],
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: data.totalRevenueThisYear / 4,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color:
                                      context.isDarkMode
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(alpha: 0.1),
                                  strokeWidth: 1,
                                ),
                          ),
                        ),
                      ),
                    ),
                loading:
                    () => const AspectRatio(
                      aspectRatio: 1.7,
                      child: SizedBox.shrink(),
                    ),
                error:
                    (e, s) => AspectRatio(
                      aspectRatio: 1.7,
                      child: Center(
                        child: Text(
                          'Gagal memuat data pendapatan: ${e.toString()}',
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color barColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusSection(BuildContext context, WidgetRef ref) {
    final ordersCountAsync = ref.watch(ordersCountProvider);
    final Map<OrderStatus, Color> statusColors = {
      OrderStatus.pending: Colors.orange,
      OrderStatus.confirmed: Colors.cyan,
      OrderStatus.preparing: Colors.blue,
      OrderStatus.ready: Colors.purple,
      OrderStatus.completed: Colors.green,
      OrderStatus.cancelled: Colors.red,
    };

    return Skeletonizer(
      enabled: ordersCountAsync.isLoading,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ordersCountAsync.when(
            data:
                (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Pesanan',
                      style: context.textStyles.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  data.totalOrders.toString(),
                                  style: context.textStyles.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 4,
                                    centerSpaceRadius: double.infinity,
                                    startDegreeOffset: -90,
                                    sections:
                                        data.statusCounts.entries.map((entry) {
                                          return PieChartSectionData(
                                            color:
                                                statusColors[entry.key] ??
                                                Colors.grey,
                                            value: entry.value.toDouble(),
                                            title: '',
                                            radius: 25,
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                data.statusCounts.entries.map((entry) {
                                  final statusName =
                                      entry.key.name[0].toUpperCase() +
                                      entry.key.name.substring(1);
                                  return _Indicator(
                                    color:
                                        statusColors[entry.key] ?? Colors.grey,
                                    text: statusName,
                                    value: entry.value.toString(),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            loading: () => const SizedBox(height: 180),
            error:
                (e, s) => SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('Gagal memuat data pesanan: ${e.toString()}'),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAndProductSection(BuildContext context, WidgetRef ref) {
    final usersCountAsync = ref.watch(usersCountProvider);
    final menuItemsCountAsync = ref.watch(menuItemsCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildUserDistributionCard(context, usersCountAsync),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildProductStatusCard(context, menuItemsCountAsync),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildUserDistributionCard(context, usersCountAsync),
            const SizedBox(height: 20),
            _buildProductStatusCard(context, menuItemsCountAsync),
          ],
        );
      },
    );
  }

  Widget _buildUserDistributionCard(
    BuildContext context,
    AsyncValue<UsersCountAggregate> usersCountAsync,
  ) {
    final color = context.colors.primary;
    return Skeletonizer(
      enabled: usersCountAsync.isLoading,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: usersCountAsync.when(
            data:
                (data) => Column(
                  children: [
                    Text(
                      'Distribusi Pengguna',
                      style: context.textStyles.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            data.allUserCount.toString(),
                            style: context.textStyles.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: double.infinity,
                              sections: [
                                PieChartSectionData(
                                  color: color,
                                  value: data.adminCount.toDouble(),
                                  title: 'Admin\n${data.adminCount}',
                                  titleStyle: context.textStyles.bodySmall
                                      ?.copyWith(color: Colors.white),
                                  radius: 25,
                                ),
                                PieChartSectionData(
                                  color: color.withValues(alpha: 0.5),
                                  value: data.userCount.toDouble(),
                                  title: 'User\n${data.userCount}',
                                  titleStyle: context.textStyles.bodySmall
                                      ?.copyWith(color: Colors.white),
                                  radius: 25,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            loading: () => const SizedBox(height: 158),
            error:
                (e, s) => SizedBox(
                  height: 158,
                  child: Center(
                    child: Text(
                      'Gagal memuat data pengguna: ${e.toString()}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductStatusCard(
    BuildContext context,
    AsyncValue<MenuItemsCountAggregate> menuItemsCountAsync,
  ) {
    final color =
        context.isDarkMode
            ? AppTheme.primaryFocusDark
            : AppTheme.primaryFocusLight;

    return Skeletonizer(
      enabled: menuItemsCountAsync.isLoading,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: menuItemsCountAsync.when(
            data:
                (data) => Column(
                  children: [
                    Text(
                      'Status Produk',
                      style: context.textStyles.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            data.allMenuItemCount.toString(),
                            style: context.textStyles.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: double.infinity,
                              sections: [
                                PieChartSectionData(
                                  color: color,
                                  value: data.activeMenuItemCount.toDouble(),
                                  title: 'Aktif\n${data.activeMenuItemCount}',
                                  titleStyle: context.textStyles.bodySmall
                                      ?.copyWith(color: Colors.white),
                                  radius: 25,
                                ),
                                PieChartSectionData(
                                  color: color.withValues(alpha: 0.5),
                                  value: data.nonActiveMenuItemCount.toDouble(),
                                  title:
                                      'Non-Aktif\n${data.nonActiveMenuItemCount}',
                                  titleStyle: context.textStyles.bodySmall
                                      ?.copyWith(color: Colors.white),
                                  radius: 25,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            loading: () => const SizedBox(height: 158),
            error:
                (e, s) => SizedBox(
                  height: 158,
                  child: Center(
                    child: Text(
                      'Gagal memuat data produk: ${e.toString()}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.color,
    required this.text,
    required this.value,
  });

  final Color color;
  final String text;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
          Text(
            value,
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
