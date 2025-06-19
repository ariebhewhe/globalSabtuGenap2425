import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/features/order/providers/order_mutation_provider.dart'; // Asumsi
import 'package:jamal/features/order/providers/order_mutation_state.dart';
import 'package:jamal/features/order/providers/orders_provider.dart';
import 'package:jamal/features/order/providers/orders_state.dart';
import 'package:jamal/features/order/widgets/order_tile.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<String> _selectedOrderIds = {};

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
        final ordersState = ref.read(ordersProvider);
        if (!ordersState.isLoadingMore && ordersState.hasMore) {
          ref.read(ordersProvider.notifier).loadMoreOrders();
        }
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isSelectionMode) _exitSelectionMode();
    await ref.read(ordersProvider.notifier).refreshOrders();
  }

  void _enterSelectionMode(String orderId) {
    if (_isSelectionMode) return;
    setState(() {
      _isSelectionMode = true;
      _selectedOrderIds.add(orderId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedOrderIds.clear();
    });
  }

  void _onSelectItem(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
      if (_selectedOrderIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _deleteSelectedItems() {
    if (_selectedOrderIds.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Anda yakin ingin menghapus ${_selectedOrderIds.length} pesanan yang dipilih?',
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
                      .read(orderMutationProvider.notifier)
                      .batchDeleteOrders(_selectedOrderIds.toList());
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
              'Anda yakin ingin menghapus SEMUA riwayat pesanan? Tindakan ini tidak dapat dibatalkan.',
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
                  ref.read(orderMutationProvider.notifier).deleteAllOrders();
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
                'Order Utilities',
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
                      : 'Pilih pesanan untuk dihapus',
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
                title: const Text('Delete All Orders'),
                subtitle: const Text('Hapus semua riwayat pesanan'),
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
      title: Text('${_selectedOrderIds.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _selectedOrderIds.isNotEmpty ? _deleteSelectedItems : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OrderMutationState>(orderMutationProvider, (_, state) {
      if (state.successMessage != null) {
        ToastUtils.showSuccess(
          context: context,
          message: state.successMessage!,
        );
        ref.read(orderMutationProvider.notifier).resetSuccessMessage();
      }
      if (state.errorMessage != null) {
        ToastUtils.showError(context: context, message: state.errorMessage!);
        ref.read(orderMutationProvider.notifier).resetErrorMessage();
      }
    });

    final ordersState = ref.watch(ordersProvider);
    final orders = ordersState.orders;
    final isLoading = ordersState.isLoading && orders.isEmpty;
    const int skeletonItemCount = 8;

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : const AdminAppBar(),
      endDrawer: _isSelectionMode ? null : const MyEndDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUtilityBottomSheet,
        child: const Icon(Icons.more_vert),
        tooltip: 'Order Utilities',
      ),
      body: MyScreenContainer(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Theme.of(context).primaryColor,
          child: Column(
            children: [
              if (ordersState.errorMessage != null && !isLoading)
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
                          ordersState.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _buildOrderList(
                  isLoading,
                  orders,
                  ordersState,
                  skeletonItemCount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(
    bool isLoading,
    List<OrderModel> orders,
    OrdersState ordersState,
    int skeletonItemCount,
  ) {
    if (orders.isEmpty && !isLoading) {
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
                : orders.length + (ordersState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (!isLoading &&
              index == orders.length &&
              ordersState.isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final order = isLoading ? OrderModel.dummy() : orders[index];
          final isSelected = _selectedOrderIds.contains(order.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Stack(
              children: [
                OrderTile(
                  order: order,
                  onTap:
                      isLoading
                          ? null
                          : () {
                            if (_isSelectionMode) {
                              _onSelectItem(order.id);
                            } else {
                              context.pushRoute(
                                AdminOrderDetailRoute(order: order),
                              );
                            }
                          },
                  onLongPress:
                      isLoading ? null : () => _enterSelectionMode(order.id),
                ),
                if (_isSelectionMode)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _onSelectItem(order.id),
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
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat pesanan dari pelanggan akan muncul di sini.',
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
