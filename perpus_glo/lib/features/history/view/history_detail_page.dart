import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../model/history_model.dart';

class HistoryDetailPage extends ConsumerWidget {
  final HistoryModel history;
  final dateFormat = DateFormat('dd MMMM yyyy, HH:mm:ss');
  
  HistoryDetailPage({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity type and timestamp
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getActivityColor(history.activityType).withOpacity(0.2),
                      radius: 28,
                      child: Icon(
                        history.activityType.iconData,
                        color: _getActivityColor(history.activityType),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            history.activityType.label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getActivityColor(history.activityType),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(history.timestamp),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Description
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  history.description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            // Metadata if available
            if (history.metadata != null && history.metadata!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Informasi Tambahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: history.metadata!.entries.map((entry) {
                      // Skip reserved keys or complex objects
                      if (['id', 'userId'].contains(entry.key) || 
                          entry.value is Map || 
                          entry.value is List) {
                        return const SizedBox.shrink();
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatKey(entry.key)}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatValue(entry.value),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.borrowBook:
        return Colors.blue;
      case ActivityType.returnBook:
        return Colors.green;
      case ActivityType.payFine:
        return Colors.orange;
      case ActivityType.reserveBook:
        return Colors.purple;
      case ActivityType.cancelReserve:
        return Colors.red;
      case ActivityType.extensionBorrow:
        return Colors.teal;
      case ActivityType.login:
        return Colors.indigo;
      case ActivityType.register:
        return Colors.deepPurple;
      case ActivityType.updateProfile:
        return Colors.pink;
      case ActivityType.other:
        return Colors.grey;
    }
  }
  
  String _formatKey(String key) {
    // Convert camelCase to Title Case
    final words = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).split(' ');
    
    return words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    
    if (value is DateTime) {
      return dateFormat.format(value);
    } else if (value is bool) {
      return value ? 'Ya' : 'Tidak';
    } else {
      return value.toString();
    }
  }
}