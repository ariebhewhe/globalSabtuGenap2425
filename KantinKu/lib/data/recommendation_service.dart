import 'package:firebase_database/firebase_database.dart';

class RecommendationService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Fetch order history to analyze purchase patterns
  static Future<Map<String, RecommendationData>> getRecommendedItems() async {
    Map<String, RecommendationData> recommendationScores = {};
    
    try {
      // Get all orders
      final ordersSnapshot = await _database.child('orders').get();
      if (!ordersSnapshot.exists) return recommendationScores;
      
      final ordersData = ordersSnapshot.value as Map<dynamic, dynamic>;
      
      // Process each order
      for (var orderEntry in ordersData.entries) {
        final order = orderEntry.value as Map<dynamic, dynamic>;
        if (order['items'] == null) continue;
        
        // Count unique users who ordered each item
        final userId = order['userId'];
        final items = order['items'] as List<dynamic>;
        
        for (var item in items) {
          final String itemName = item['name'];
          final int quantity = item['quantity'] ?? 1;
          
          if (!recommendationScores.containsKey(itemName)) {
            recommendationScores[itemName] = RecommendationData(
              itemName: itemName,
              totalOrders: 0,
              uniqueUsers: {},
            );
          }
          
          recommendationScores[itemName]!.totalOrders += quantity;
          recommendationScores[itemName]!.uniqueUsers[userId] = true;
        }
      }
      
      // Calculate SAW scores
      for (var entry in recommendationScores.entries) {
        var data = entry.value;
        // SAW formula: normalized sum of criteria (unique users count + total orders)
        // We'll use a 60/40 weight distribution between unique users and total orders
        final uniqueUserWeight = 0.6;
        final totalOrdersWeight = 0.4;
        
        // Get the maximum values for normalization
        final maxUniqueUsers = recommendationScores.values
            .map((item) => item.uniqueUsers.length)
            .reduce((a, b) => a > b ? a : b);
        
        final maxTotalOrders = recommendationScores.values
            .map((item) => item.totalOrders)
            .reduce((a, b) => a > b ? a : b);
        
        // Calculate normalized scores
        final normalizedUniqueUsers = data.uniqueUsers.length / (maxUniqueUsers > 0 ? maxUniqueUsers : 1);
        final normalizedTotalOrders = data.totalOrders / (maxTotalOrders > 0 ? maxTotalOrders : 1);
        
        // Calculate weighted sum
        data.sawScore = (normalizedUniqueUsers * uniqueUserWeight) + 
                        (normalizedTotalOrders * totalOrdersWeight);
      }
      
    } catch (e) {
      print('Error getting recommendation data: $e');
    }
    
    return recommendationScores;
  }
  
  // Method to check if an item is recommended (threshold-based)
  static bool isRecommended(Map<String, RecommendationData> recommendations, String itemName, {double threshold = 0.10}) {
    if (!recommendations.containsKey(itemName)) return false;
    return recommendations[itemName]!.sawScore >= threshold && recommendations[itemName]!.uniqueUsers.length >= 2;
  }
  
  // Get top N recommended items from a specific category
  static List<Map<dynamic, dynamic>> getTopRecommendedItems(
    List<Map<dynamic, dynamic>> categoryItems,
    Map<String, RecommendationData> recommendations,
    {int topN = 3}
  ) {
    final recommendedItems = categoryItems.where((item) {
      final name = item['name'];
      return recommendations.containsKey(name) && recommendations[name]!.uniqueUsers.length >= 2;
    }).toList();
    
    // Sort by SAW score
    recommendedItems.sort((a, b) {
      final scoreA = recommendations[a['name']]?.sawScore ?? 0;
      final scoreB = recommendations[b['name']]?.sawScore ?? 0;
      return scoreB.compareTo(scoreA); // Descending order
    });
    
    return recommendedItems.take(topN).toList();
  }
}

class RecommendationData {
  final String itemName;
  int totalOrders;
  Map<dynamic, bool> uniqueUsers;
  double sawScore = 0.0;
  
  RecommendationData({
    required this.itemName,
    required this.totalOrders,
    required this.uniqueUsers,
  });
}