import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/features/table_reservation/providers/user_table_reservations_provider.dart';
import 'package:jamal/features/table_reservation/widgets/table_reservation_tile.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class TableReservationsScreen extends ConsumerStatefulWidget {
  const TableReservationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TableReservationsScreen> createState() =>
      _TableReservationsScreenState();
}

class _TableReservationsScreenState
    extends ConsumerState<TableReservationsScreen> {
  final ScrollController _scrollController = ScrollController();

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
      // * When user scrolls near the bottom, load more data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tableReservationsState = ref.watch(userTableReservationsProvider);

        // * Check if currently loading more and there's more data to load
        if (!tableReservationsState.isLoadingMore &&
            tableReservationsState.hasMore) {
          ref
              .read(userTableReservationsProvider.notifier)
              .loadMoreTableReservations();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyScreenContainer(
        child: Consumer(
          builder: (context, ref, child) {
            final tableReservationsState = ref.watch(
              userTableReservationsProvider,
            );
            final tableReservations = tableReservationsState.tableReservations;
            final isLoading = tableReservationsState.isLoading;
            const int skeletonItemCount = 8;

            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref
                          .read(userTableReservationsProvider.notifier)
                          .refreshTableReservations(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message if any
                  if (tableReservationsState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: context.theme.colorScheme.error.withValues(
                        alpha: 0.1,
                      ),
                      width: double.infinity,
                      child: Text(
                        tableReservationsState.errorMessage!,
                        style: context.theme.textTheme.bodyMedium?.copyWith(
                          color: context.theme.colorScheme.error,
                        ),
                      ),
                    ),

                  // Main content
                  Expanded(
                    child:
                        tableReservations.isEmpty && !isLoading
                            ? _buildEmptyState(context, context.theme)
                            : Skeletonizer(
                              enabled: isLoading,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount:
                                    isLoading
                                        ? skeletonItemCount
                                        : tableReservations.length +
                                            (tableReservationsState
                                                    .isLoadingMore
                                                ? 1
                                                : 0),
                                itemBuilder: (context, index) {
                                  if (!isLoading &&
                                      index == tableReservations.length &&
                                      tableReservationsState.isLoadingMore) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          color:
                                              context.theme.colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  }

                                  final tableReservation =
                                      isLoading
                                          ? _buildSkeletonTableReservation()
                                          : tableReservations[index];

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: TableReservationTile(
                                      tableReservation: tableReservation,
                                      onTap:
                                          isLoading
                                              ? null
                                              : () {
                                                if (index <
                                                    tableReservations.length) {
                                                  context.router.push(
                                                    TableReservationDetailRoute(
                                                      reservation:
                                                          tableReservation,
                                                    ),
                                                  );
                                                }
                                              },
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: context.theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Pesanan',
            style: context.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat pesanan Anda akan muncul di sini',
            style: context.theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.router.push(const MenuItemsRoute()),
            child: const Text('Lihat Menu'),
          ),
        ],
      ),
    );
  }

  TableReservationModel _buildSkeletonTableReservation() {
    return TableReservationModel(
      id: 'loading-id',
      userId: 'loading-user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tableId: '',
      orderId: '',
      reservationTime: DateTime.now(),
      status: ReservationStatus.reserved,
    );
  }
}
