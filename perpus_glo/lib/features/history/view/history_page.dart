import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../model/history_model.dart';
import '../providers/history_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(userHistoryProvider);
    final selectedType = ref.watch(selectedHistoryTypeProvider);
    final dateRange = ref.watch(historyDateRangeProvider);
    final filteredHistory = ref.watch(filteredHistoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearHistoryDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters indicator
          if (selectedType != null || dateRange.startDate != null || dateRange.endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16),
                  const SizedBox(width: 8),
                  const Text('Filter: '),
                  if (selectedType != null) ...[
                    Chip(
                      label: Text(selectedType.label),
                      onDeleted: () {
                        ref.read(selectedHistoryTypeProvider.notifier).state = null;
                      },
                      backgroundColor: Colors.blue[100],
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (dateRange.startDate != null || dateRange.endDate != null) ...[
                    Expanded(
                      child: Chip(
                        label: Text(
                          dateRange.startDate != null && dateRange.endDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(dateRange.startDate!)} - ${DateFormat('dd/MM/yyyy').format(dateRange.endDate!)}'
                              : dateRange.startDate != null
                                  ? 'Mulai ${DateFormat('dd/MM/yyyy').format(dateRange.startDate!)}'
                                  : 'Sampai ${DateFormat('dd/MM/yyyy').format(dateRange.endDate!)}',
                        ),
                        onDeleted: () {
                          ref.read(historyDateRangeProvider.notifier).state = DateRangeFilter();
                        },
                        backgroundColor: Colors.green[100],
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // History list
          Expanded(
            child: historyAsync.when(
              data: (_) {
                if (filteredHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada riwayat aktivitas',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (selectedType != null || dateRange.startDate != null || dateRange.endDate != null)
                          TextButton(
                            onPressed: () {
                              ref.read(selectedHistoryTypeProvider.notifier).state = null;
                              ref.read(historyDateRangeProvider.notifier).state = DateRangeFilter();
                            },
                            child: const Text('Hapus Filter'),
                          ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final history = filteredHistory[index];
                    return _buildHistoryItem(history);
                  },
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryItem(HistoryModel history) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Dismissible(
        key: Key(history.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          ref.read(historyControllerProvider.notifier)
              .deleteHistoryItem(history.id);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getActivityColor(history.activityType).withOpacity(0.2),
            child: Icon(
              history.activityType.iconData,
              color: _getActivityColor(history.activityType),
            ),
          ),
          title: Text(
            history.description,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                history.activityType.label,
                style: TextStyle(
                  fontSize: 12,
                  color: _getActivityColor(history.activityType),
                ),
              ),
              Text(
                dateFormat.format(history.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          onTap: () {
            _navigateToDetail(history);
          },
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
  
  void _navigateToDetail(HistoryModel history) {
    // Navigate based on activity type and metadata
    if (history.metadata != null) {
      switch (history.activityType) {
        case ActivityType.borrowBook:
        case ActivityType.returnBook:
        case ActivityType.extensionBorrow:
          final borrowId = history.metadata?['borrowId'] as String?;
          if (borrowId != null) {
            context.push('/borrow/$borrowId');
          }
          break;
        case ActivityType.payFine:
          final paymentId = history.metadata?['paymentId'] as String?;
          if (paymentId != null) {
            // No detailed payment view yet, could redirect to payment history
            context.push('/payment-history');
          }
          break;
        case ActivityType.reserveBook:
        case ActivityType.cancelReserve:
          final bookId = history.metadata?['bookId'] as String?;
          if (bookId != null) {
            context.push('/books/$bookId');
          }
          break;
        default:
          // No navigation for other types
          break;
      }
    }
  }
  
  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterBottomSheet(
        selectedType: ref.read(selectedHistoryTypeProvider),
        dateRange: ref.read(historyDateRangeProvider),
        onFilterApplied: (type, range) {
          ref.read(selectedHistoryTypeProvider.notifier).state = type;
          ref.read(historyDateRangeProvider.notifier).state = range;
        },
      ),
    );
  }
  
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat aktivitas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(historyControllerProvider.notifier).clearHistory();
            },
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final ActivityType? selectedType;
  final DateRangeFilter dateRange;
  final Function(ActivityType?, DateRangeFilter) onFilterApplied;
  
  const FilterBottomSheet({
    super.key,
    this.selectedType,
    required this.dateRange,
    required this.onFilterApplied,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ActivityType? _selectedType;
  late DateTime? _startDate;
  late DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _startDate = widget.dateRange.startDate;
    _endDate = widget.dateRange.endDate;
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Filter Riwayat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Activity type filter
          const Text(
            'Tipe Aktivitas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ActivityType.values.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                label: Text(type.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                },
                selectedColor: _getActivityColor(type),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Date range filter
          const Text(
            'Rentang Tanggal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, isStart: true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Dari',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _startDate != null
                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                          : 'Pilih tanggal',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, isStart: false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Sampai',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : 'Pilih tanggal',
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('RESET'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFilterApplied(
                      _selectedType,
                      DateRangeFilter(
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('TERAPKAN'),
                ),
              ),
            ],
          ),
        ],
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
  
  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          
          // If end date is before start date, reset it
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
          
          // If start date is after end date, reset it
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = null;
          }
        }
      });
    }
  }
}