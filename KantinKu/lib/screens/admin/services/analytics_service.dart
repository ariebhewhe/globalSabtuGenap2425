import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/order_model.dart';

class AnalyticsResult {
  final int totalOrders;
  final double totalSales;
  final int completedOrders;
  final int cancelledOrders;
  final Map<String, Map<String, dynamic>> itemSales;

  AnalyticsResult({
    required this.totalOrders,
    required this.totalSales,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.itemSales,
  });
}

class AnalyticsService {
  // Chart data
  List<BarChartGroupData> _barGroups = [];
  Map<String, double> _dailySales = {};
  List<DateTime> _chartDates = [];

  // Reset chart data
  void resetChartData() {
    _barGroups = [];
    _dailySales = {};
    _chartDates = [];
  }

  // Getter methods for chart data
  List<BarChartGroupData> getBarGroups() => _barGroups;
  Map<String, double> getDailySales() => _dailySales;
  List<DateTime> getChartDates() => _chartDates;
  
  // Get all chart data as a map
  Map<String, dynamic> getChartData() {
    return {
      'barGroups': _barGroups,
      'dailySales': _dailySales,
      'chartDates': _chartDates,
    };
  }
  
  // Process orders data and generate statistics
  AnalyticsResult processOrdersData(
    List<OrderModel> allOrders,
    String period,
    DateTime now
  ) {
    try {
      // Reset chart data
      resetChartData();
      
      // Define the cutoff date based on the selected period
      DateTime cutoffDate;
      if (period == 'day') {
        cutoffDate = DateTime(now.year, now.month, now.day);
      } else if (period == 'week') {
        // Go back to the start of the current week (assuming week starts on Monday)
        int daysToSubtract = (now.weekday - 1) % 7;
        cutoffDate = DateTime(now.year, now.month, now.day - daysToSubtract);
      } else { // month
        cutoffDate = DateTime(now.year, now.month, 1);
      }
      
      // Filter orders that fall within the selected period
      List<OrderModel> filteredOrders = allOrders.where((order) {
        if (order.date == null) return false;
        
        return order.date!.isAfter(cutoffDate) ||
               (order.date!.day == cutoffDate.day && 
                order.date!.month == cutoffDate.month && 
                order.date!.year == cutoffDate.year);
      }).toList();
      
      // Calculate statistics
      int totalOrders = filteredOrders.length;
      double totalSales = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      Map<String, Map<String, dynamic>> itemSales = {};
      
      for (var order in filteredOrders) {
        if (order.items == null || order.items!.isEmpty) continue;
        
        // Calculate total sales amount
        double orderTotal = 0;
        
        for (var item in order.items!) {
          if (item == null) continue;
          
          double price = item.price ?? 0;
          int quantity = item.quantity ?? 0;
          
          orderTotal += price * quantity;
          
          // Track item popularity
          if (item.name != null && item.name!.isNotEmpty) {
            String itemName = item.name!;
            
            if (!itemSales.containsKey(itemName)) {
              itemSales[itemName] = {
                'count': 0,
                'sales': 0.0,
              };
            }
            
            itemSales[itemName]!['count'] = itemSales[itemName]!['count'] + quantity;
            itemSales[itemName]!['sales'] = itemSales[itemName]!['sales'] + (price * quantity);
          }
        }
        
        totalSales += orderTotal;
        
        // Count by status
        if (order.status == 'completed') {
          completedOrders++;
        } else if (order.status == 'cancelled') {
          cancelledOrders++;
        }
      }
      
      // Generate chart data
      _prepareChartData(period, filteredOrders, now);
      
      return AnalyticsResult(
        totalOrders: totalOrders,
        totalSales: totalSales,
        completedOrders: completedOrders,
        cancelledOrders: cancelledOrders,
        itemSales: itemSales,
      );
    } catch (e) {
      print('Error in processOrdersData: $e');
      // Return default values in case of error
      return AnalyticsResult(
        totalOrders: 0,
        totalSales: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        itemSales: {},
      );
    }
  }
  
  // Prepare chart data based on the selected period
  void _prepareChartData(
    String period, 
    List<OrderModel> filteredOrders,
    DateTime now
  ) {
    try {
      // Define the dates to show based on the selected period
      if (period == 'day') {
        _prepareDayChartData(filteredOrders, now);
      } else if (period == 'week') {
        _prepareWeekChartData(filteredOrders, now);
      } else { // month
        _prepareMonthChartData(filteredOrders, now);
      }
    } catch (e) {
      print('Error in _prepareChartData: $e');
      // Create empty bar groups in case of error
      _barGroups = [];
      _dailySales = {};
      _chartDates = [];
    }
  }
  
  // Prepare chart data for day view (by hour)
  void _prepareDayChartData(List<OrderModel> filteredOrders, DateTime now) {
    // For a day, show sales by hour
    DateTime today = DateTime(now.year, now.month, now.day);
    
    for (int hour = 0; hour < 24; hour++) {
      _chartDates.add(DateTime(today.year, today.month, today.day, hour));
      _dailySales[hour.toString()] = 0;
    }
    
    // Group sales by hour
    for (var order in filteredOrders) {
      if (order.date == null || order.items == null) continue;
      
      DateTime orderDate = order.date!;
      if (orderDate.year == today.year && 
          orderDate.month == today.month && 
          orderDate.day == today.day) {
        String hour = orderDate.hour.toString();
        
        // Calculate order total
        double orderTotal = 0;
        for (var item in order.items!) {
          if (item == null) continue;
          
          double price = item.price ?? 0;
          int quantity = item.quantity ?? 0;
          
          orderTotal += price * quantity;
        }
        
        _dailySales[hour] = (_dailySales[hour] ?? 0) + orderTotal;
      }
    }
    
    // Create bar chart groups
    for (int i = 0; i < 24; i++) {
      _barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _dailySales[i.toString()] ?? 0,
              color: const Color(0xFFDC793B),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }
  }
  
  // Prepare chart data for week view (by day)
  void _prepareWeekChartData(List<OrderModel> filteredOrders, DateTime now) {
    // For a week, get the start of the week
    int daysToSubtract = (now.weekday - 1) % 7;
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - daysToSubtract);
    
    // Create a date entry for each day of the week
    for (int i = 0; i < 7; i++) {
      DateTime date = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);
      _chartDates.add(date);
      _dailySales[_getFormattedDate(date)] = 0;
    }
    
    // Group sales by day
    for (var order in filteredOrders) {
      if (order.date == null || order.items == null) continue;
      
      DateTime orderDate = order.date!;
      String dateKey = _getFormattedDate(orderDate);
      
      // Skip if this date is not in our chart range
      if (!_dailySales.containsKey(dateKey)) continue;
      
      // Calculate order total
      double orderTotal = 0;
      for (var item in order.items!) {
        if (item == null) continue;
        
        double price = item.price ?? 0;
        int quantity = item.quantity ?? 0;
        
        orderTotal += price * quantity;
      }
      
      _dailySales[dateKey] = (_dailySales[dateKey] ?? 0) + orderTotal;
    }
    
    // Create bar chart groups
    for (int i = 0; i < _chartDates.length; i++) {
      String dateKey = _getFormattedDate(_chartDates[i]);
      _barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _dailySales[dateKey] ?? 0,
              color: const Color(0xFFDC793B),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }
  }
  
  // Prepare chart data for month view (by day)
  void _prepareMonthChartData(List<OrderModel> filteredOrders, DateTime now) {
    try {
      // For a month, get the first day of the month
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      
      // Safety check - limit to a reasonable number of days
      if (daysInMonth > 31) daysInMonth = 31;
      
      // Create a date entry for each day of the month up to today
      for (int i = 0; i < daysInMonth; i++) {
        DateTime date = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, firstDayOfMonth.day + i);
        if (date.isAfter(now)) break; // Don't include future dates
        
        _chartDates.add(date);
        _dailySales[_getFormattedDate(date)] = 0;
      }
      
      // Safety check - if there are no dates, avoid further processing
      if (_chartDates.isEmpty) {
        _barGroups = [];
        return;
      }
      
      // Group sales by day
      for (var order in filteredOrders) {
        if (order.date == null || order.items == null) continue;
        
        DateTime orderDate = order.date!;
        String dateKey = _getFormattedDate(orderDate);
        
        // Skip if this date is not in our chart range
        if (!_dailySales.containsKey(dateKey)) continue;
        
        // Calculate order total
        double orderTotal = 0;
        for (var item in order.items!) {
          if (item == null) continue;
          
          double price = item.price ?? 0;
          int quantity = item.quantity ?? 0;
          
          orderTotal += price * quantity;
        }
        
        _dailySales[dateKey] = (_dailySales[dateKey] ?? 0) + orderTotal;
      }
      
      // Create bar chart groups with limit to prevent too many bars
      int maxBars = 15; // Limit the number of bars to prevent overcrowding
      int step = _chartDates.length > maxBars ? (_chartDates.length / maxBars).ceil() : 1;
      
      for (int i = 0; i < _chartDates.length; i += step) {
        if (i >= _chartDates.length) break; // Safety check
        
        String dateKey = _getFormattedDate(_chartDates[i]);
        
        // For stepped approach, sum up the values for skipped days
        double totalValue = _dailySales[dateKey] ?? 0;
        for (int j = 1; j < step && i + j < _chartDates.length; j++) {
          String nextDateKey = _getFormattedDate(_chartDates[i + j]);
          totalValue += _dailySales[nextDateKey] ?? 0;
        }
        
        _barGroups.add(
          BarChartGroupData(
            x: i ~/ step,
            barRods: [
              BarChartRodData(
                toY: totalValue,
                color: const Color(0xFFDC793B),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error in _prepareMonthChartData: $e');
      // Reset the chart data if there's an error
      _barGroups = [];
      _dailySales = {};
      _chartDates = [];
    }
  }
  
  // Helper method to format date as string
  String _getFormattedDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }
  
  // Helper to find the maximum Y value for chart scaling
  double findMaxY() {
    double maxY = 0;
    for (var group in _barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) {
          maxY = rod.toY;
        }
      }
    }
    // Add 10% padding to make the chart look better
    return maxY * 1.1 > 0 ? maxY * 1.1 : 10;
  }
}