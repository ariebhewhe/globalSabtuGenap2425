import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:fl_chart/fl_chart.dart';

@RoutePage()
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryData = [
      {
        'title': 'Total Pengguna',
        'value': '1,305',
        'icon': Icons.people_alt_outlined,
        'color': context.colors.primary,
      },
      {
        'title': 'Total Pesanan',
        'value': '3,480',
        'icon': Icons.shopping_bag_outlined,
        'color': context.colors.secondary,
      },
      {
        'title': 'Pendapatan Bulan Ini',
        'value': 'Rp 82.150.000',
        'icon': Icons.monetization_on_outlined,
        'color': context.colors.tertiary,
      },
      {
        'title': 'Produk Aktif',
        'value': '729',
        'icon': Icons.inventory_2_outlined,
        'color':
            context.isDarkMode
                ? AppTheme.primaryFocusDark
                : AppTheme.primaryFocusLight,
      },
    ];

    final List<FlSpot> salesSpots = [
      const FlSpot(0, 65),
      const FlSpot(1, 70),
      const FlSpot(2, 85),
      const FlSpot(3, 80),
      const FlSpot(4, 95),
      const FlSpot(5, 90),
    ];

    final List<String> monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'];

    return MyScreenContainer(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Ringkasan Umum',
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textStyles.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 16.0),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 1200
                        ? 4
                        : (MediaQuery.of(context).size.width > 700 ? 2 : 1),
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio:
                    MediaQuery.of(context).size.width > 700 ? 2.0 : 2.4,
              ),
              itemCount: summaryData.length,
              itemBuilder: (context, index) {
                final item = summaryData[index];
                return _buildSummaryCard(
                  context,
                  title: item['title'] as String,
                  value: item['value'] as String,
                  icon: item['icon'] as IconData,
                  iconColor: item['color'] as Color,
                );
              },
            ),
            const SizedBox(height: 24.0),
            Text(
              'Grafik Penjualan (6 Bulan Terakhir)',
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textStyles.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 16.0),
            Card(
              color: context.cardTheme.color ?? context.theme.cardColor,
              elevation: context.cardTheme.elevation ?? 2.0,
              shape: context.cardTheme.shape,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 20,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: context.theme.dividerColor.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: context.theme.dividerColor.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
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
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              // meta ada di sini
                              final index = value.toInt();
                              if (index >= 0 && index < monthLabels.length) {
                                return SideTitleWidget(
                                  // Panggil SideTitleWidget
                                  meta: meta, // FIX 1: Tambahkan meta
                                  space: 8.0,
                                  child: Text(
                                    monthLabels[index],
                                    style: context.textStyles.bodySmall
                                        ?.copyWith(
                                          color:
                                              context
                                                  .textStyles
                                                  .bodySmall
                                                  ?.color,
                                        ),
                                  ),
                                  // FIX 3: Hapus axisSide dari sini
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40, // Lebar area untuk label Y-axis
                            interval: 25,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '${value.toInt()}', // Format label Y-axis
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: context.textStyles.bodySmall?.color,
                                ),
                                textAlign: TextAlign.left,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: context.theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      minX: 0,
                      maxX: (salesSpots.length - 1).toDouble(),
                      minY: 0,
                      maxY: 120,
                      lineBarsData: [
                        LineChartBarData(
                          spots: salesSpots,
                          isCurved: true,
                          color: context.colors.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: context.colors.primary.withOpacity(0.2),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          // FIX 2: Ganti tooltipBgColor dengan getTooltipColor
                          getTooltipColor:
                              (_) =>
                                  context.cardTheme.color ??
                                  context.theme.cardColor,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final flSpot = barSpot;
                              return LineTooltipItem(
                                '${monthLabels[flSpot.x.toInt()]}\n',
                                context.textStyles.bodySmall!.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text:
                                        'Rp ${flSpot.y.toStringAsFixed(0)} Jt',
                                    style: context.textStyles.bodySmall!
                                        .copyWith(
                                          color:
                                              context
                                                  .textStyles
                                                  .bodySmall
                                                  ?.color,
                                        ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Item Baru'),
                    onPressed: () {},
                    style: context.elevatedButtonTheme.style,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Pengaturan'),
                    onPressed: () {},
                    // style: context.outlinedButtonTheme.style,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      color: context.cardTheme.color ?? context.theme.cardColor,
      elevation: context.cardTheme.elevation ?? 2.0,
      shape: context.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.textStyles.titleMedium?.copyWith(
                      color: context.textStyles.titleMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: iconColor, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: context.textStyles.headlineMedium?.copyWith(
                color: context.textStyles.headlineMedium?.color,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
