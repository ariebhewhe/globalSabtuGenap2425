import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_repository.dart';
import '../model/history_model.dart';

// Provider for user history stream
final userHistoryProvider = StreamProvider<List<HistoryModel>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getUserHistory();
});

// Provider for selected history type
final selectedHistoryTypeProvider = StateProvider<ActivityType?>((ref) => null);

// Provider for date range filter
class DateRangeFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  
  DateRangeFilter({this.startDate, this.endDate});
}

final historyDateRangeProvider = StateProvider<DateRangeFilter>((ref) => DateRangeFilter());

// Provider for filtered history
final filteredHistoryProvider = Provider<List<HistoryModel>>((ref) {
  final historyAsync = ref.watch(userHistoryProvider);
  final selectedType = ref.watch(selectedHistoryTypeProvider);
  final dateRange = ref.watch(historyDateRangeProvider);
  
  return historyAsync.when(
    data: (history) {
      // Apply filters
      var filtered = history;
      
      // Filter by type
      if (selectedType != null) {
        filtered = filtered.where((item) => item.activityType == selectedType).toList();
      }
      
      // Filter by date range
      if (dateRange.startDate != null) {
        filtered = filtered.where(
          (item) => item.timestamp.isAfter(dateRange.startDate!) || 
                    item.timestamp.isAtSameMomentAs(dateRange.startDate!)
        ).toList();
      }
      
      if (dateRange.endDate != null) {
        filtered = filtered.where(
          (item) => item.timestamp.isBefore(dateRange.endDate!) || 
                    item.timestamp.isAtSameMomentAs(dateRange.endDate!)
        ).toList();
      }
      
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Controller for history actions
class HistoryController extends StateNotifier<AsyncValue<void>> {
  final HistoryRepository _repository;
  
  HistoryController(this._repository) : super(const AsyncValue.data(null));
  
  Future<void> addActivity({
    required ActivityType activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addActivity(
        activityType: activityType,
        description: description,
        metadata: metadata,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> deleteHistoryItem(String historyId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteHistoryItem(historyId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> clearHistory() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearHistory();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final historyControllerProvider = StateNotifierProvider<HistoryController, AsyncValue<void>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryController(repository);
});