import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_mutation_provider.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_mutation_state.dart';
import 'package:jamal/features/table_reservation/providers/table_reservations_provider.dart';
import 'package:jamal/features/table_reservation/providers/table_reservations_state.dart';
import 'package:jamal/features/table_reservation/widgets/table_reservation_tile.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class AdminTableReservationsScreen extends ConsumerStatefulWidget {
  const AdminTableReservationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminTableReservationsScreen> createState() =>
      _AdminTableReservationsScreenState();
}

class _AdminTableReservationsScreenState
    extends ConsumerState<AdminTableReservationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<String> _selectedReservationIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(tableReservationsProvider);
        if (!state.isLoadingMore && state.hasMore) {
          ref
              .read(tableReservationsProvider.notifier)
              .loadMoreTableReservations();
        }
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isSelectionMode) _exitSelectionMode();
    await ref
        .read(tableReservationsProvider.notifier)
        .refreshTableReservations();
  }

  void _enterSelectionMode(String reservationId) {
    if (_isSelectionMode) return;
    setState(() {
      _isSelectionMode = true;
      _selectedReservationIds.add(reservationId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedReservationIds.clear();
    });
  }

  void _onSelectItem(String reservationId) {
    setState(() {
      if (_selectedReservationIds.contains(reservationId)) {
        _selectedReservationIds.remove(reservationId);
      } else {
        _selectedReservationIds.add(reservationId);
      }
      if (_selectedReservationIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _deleteSelectedItems() {
    if (_selectedReservationIds.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Anda yakin ingin menghapus ${_selectedReservationIds.length} reservasi yang dipilih?',
            ),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              FilledButton(
                child: const Text('Hapus'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ref
                      .read(tableReservationMutationProvider.notifier)
                      .batchDeleteTableReservations(
                        _selectedReservationIds.toList(),
                      );
                  Navigator.of(ctx).pop();
                  _exitSelectionMode();
                },
              ),
            ],
          ),
    );
  }

  void _deleteAllItems() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Hapus Semua'),
            content: const Text(
              'Anda yakin ingin menghapus SEMUA riwayat reservasi? Tindakan ini tidak dapat dibatalkan.',
            ),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              FilledButton(
                child: const Text('Hapus Semua'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ref
                      .read(tableReservationMutationProvider.notifier)
                      .deleteAllTableReservations();
                  Navigator.of(ctx).pop();
                  if (_isSelectionMode) _exitSelectionMode();
                },
              ),
            ],
          ),
    );
  }

  void _showUtilityBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Reservation Utilities',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _isSelectionMode
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isSelectionMode
                        ? Icons.cancel_outlined
                        : Icons.check_box_outlined,
                    color: _isSelectionMode ? Colors.orange : Colors.blue,
                  ),
                ),
                title: Text(
                  _isSelectionMode ? 'Exit Selection Mode' : 'Select Items',
                ),
                subtitle: Text(
                  _isSelectionMode
                      ? 'Keluar dari mode seleksi'
                      : 'Pilih reservasi untuk dihapus',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (_isSelectionMode) {
                    _exitSelectionMode();
                  } else {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.red,
                  ),
                ),
                title: const Text('Delete All Reservations'),
                subtitle: const Text('Hapus semua riwayat reservasi'),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteAllItems();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedReservationIds.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed:
              _selectedReservationIds.isNotEmpty ? _deleteSelectedItems : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TableReservationMutationState>(
      tableReservationMutationProvider,
      (_, state) {
        if (state.successMessage != null) {
          ToastUtils.showSuccess(
            context: context,
            message: state.successMessage!,
          );
          ref
              .read(tableReservationMutationProvider.notifier)
              .resetSuccessMessage();
        }
        if (state.errorMessage != null) {
          ToastUtils.showError(context: context, message: state.errorMessage!);
          ref
              .read(tableReservationMutationProvider.notifier)
              .resetErrorMessage();
        }
      },
    );

    final reservationsState = ref.watch(tableReservationsProvider);
    final reservations = reservationsState.tableReservations;
    final isLoading = reservationsState.isLoading && reservations.isEmpty;
    const int skeletonItemCount = 8;

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : const AdminAppBar(),
      endDrawer: _isSelectionMode ? null : const MyEndDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUtilityBottomSheet,
        child: const Icon(Icons.more_vert),
        tooltip: 'Reservation Utilities',
      ),
      body: MyScreenContainer(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Theme.of(context).primaryColor,
          child: Column(
            children: [
              if (reservationsState.errorMessage != null && !isLoading)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.all(16).copyWith(bottom: 0),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reservationsState.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _buildReservationList(
                  isLoading,
                  reservations,
                  reservationsState,
                  skeletonItemCount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationList(
    bool isLoading,
    List<TableReservationModel> reservations,
    TableReservationsState reservationsState,
    int skeletonItemCount,
  ) {
    if (reservations.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount:
            isLoading
                ? skeletonItemCount
                : reservations.length +
                    (reservationsState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (!isLoading &&
              index == reservations.length &&
              reservationsState.isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final reservation =
              isLoading ? TableReservationModel.dummy() : reservations[index];
          final isSelected = _selectedReservationIds.contains(reservation.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Stack(
              children: [
                TableReservationTile(
                  tableReservation: reservation,
                  onTap:
                      isLoading
                          ? null
                          : () {
                            if (_isSelectionMode) {
                              _onSelectItem(reservation.id);
                            } else {
                              context.pushRoute(
                                AdminTableReservationDetailRoute(
                                  reservation: reservation,
                                ),
                              );
                            }
                          },
                  onLongPress:
                      isLoading
                          ? null
                          : () => _enterSelectionMode(reservation.id),
                ),
                if (_isSelectionMode)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _onSelectItem(reservation.id),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_seat_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Reservasi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Data reservasi meja akan muncul di sini.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}
