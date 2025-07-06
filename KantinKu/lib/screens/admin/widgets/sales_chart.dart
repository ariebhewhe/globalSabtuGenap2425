import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/order_model.dart';
import 'package:firebase_database/firebase_database.dart';

class SalesChartWidget extends StatelessWidget {
  final String selectedPeriod;
  final List<BarChartGroupData> barGroups;
  final List<DateTime> chartDates;
  final double maxY;
  
  const SalesChartWidget({
    Key? key,
    required this.selectedPeriod,
    required this.barGroups,
    required this.chartDates,
    required this.maxY,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    String periodTitle = 'Hari Ini';
    if (selectedPeriod == 'week') {
      periodTitle = 'Minggu Ini';
    } else if (selectedPeriod == 'month') {
      periodTitle = 'Bulan Ini';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 8.0),
          child: Text(
            'Penjualan $periodTitle',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: barGroups.isEmpty
                ? const Center(child: Text('Tidak ada data penjualan'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.grey.shade800,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String xTitle = '';
                            if (selectedPeriod == 'day') {
                              xTitle = '${group.x}:00';
                            } else {
                              if (groupIndex < chartDates.length) {
                                xTitle = DateFormat('d MMM').format(chartDates[groupIndex]);
                              }
                            }
                            
                            return BarTooltipItem(
                              'Rp ${NumberFormat("#,###").format(rod.toY)}\n$xTitle',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  'Rp${NumberFormat.compact().format(value)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              String text = '';
                              if (selectedPeriod == 'day') {
                                // For day view, show hour numbers for every 4 hours
                                if (value % 4 == 0) {
                                  text = '${value.toInt()}:00';
                                }
                              } else if (selectedPeriod == 'week') {
                                // For week view, show short day names
                                int index = value.toInt();
                                if (index >= 0 && index < chartDates.length) {
                                  text = DateFormat('E').format(chartDates[index]);
                                }
                              } else {
                                // For month view, show dates for selected intervals
                                int index = value.toInt();
                                if (index >= 0 && index < chartDates.length) {
                                  text = chartDates[index].day.toString();
                                }
                              }
                              
                              return Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                          dashArray: [5],
                        ),
                      ),
                      barGroups: barGroups,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}