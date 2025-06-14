import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:jamal/features/payment_method/providers/payment_method_mutation_provider.dart'; // Asumsi provider ini ada
import 'package:jamal/features/payment_method/providers/payment_method_mutation_state.dart';
import 'package:jamal/features/payment_method/providers/payment_methods_provider.dart';
import 'package:jamal/features/payment_method/providers/search_payment_methods_provider.dart';
import 'package:jamal/features/payment_method/widgets/payment_method_tile.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class AdminPaymentMethodsScreen extends ConsumerStatefulWidget {
  const AdminPaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminPaymentMethodsScreen> createState() =>
      _AdminPaymentMethodsScreenState();
}

class _AdminPaymentMethodsScreenState
    extends ConsumerState<AdminPaymentMethodsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSelectionMode = false;
  final Set<String> _selectedPaymentMethodIds = {};

  String _selectedSearchBy = 'name';
  final List<String> _searchByOptions = ['name', 'description'];

  String _selectedOrderBy = 'createdAt';
  bool _isDescending = true;
  final Map<String, String> _orderByOptions = {
    'createdAt': 'Created Date',
    'updatedAt': 'Updated Date',
    'name': 'Name',
  };

  bool isSearching = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isSearching) {
          final searchState = ref.read(searchPaymentMethodsProvider);
          if (!searchState.isLoadingMore && searchState.hasMore) {
            ref
                .read(searchPaymentMethodsProvider.notifier)
                .loadMorePaymentMethods();
          }
        } else {
          final paymentMethodsState = ref.read(paymentMethodsProvider);
          if (!paymentMethodsState.isLoadingMore &&
              paymentMethodsState.hasMore) {
            ref.read(paymentMethodsProvider.notifier).loadMorePaymentMethods();
          }
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      isSearching = query.trim().isNotEmpty;
    });

    if (isSearching) {
      ref
          .read(searchPaymentMethodsProvider.notifier)
          .searchPaymentMethods(query: query, searchBy: _selectedSearchBy);
    } else {
      ref.read(searchPaymentMethodsProvider.notifier).clearSearch();
    }
  }

  void _applyFilters() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    if (isSearching) {
      ref
          .read(searchPaymentMethodsProvider.notifier)
          .searchPaymentMethods(
            query: _searchController.text,
            searchBy: _selectedSearchBy,
          );
    } else {
      ref
          .read(paymentMethodsProvider.notifier)
          .loadPaymentMethodsWithFilter(
            orderBy: _selectedOrderBy,
            descending: _isDescending,
          );
    }
  }

  Future<void> _refreshData() async {
    if (_isSelectionMode) _exitSelectionMode();

    if (isSearching) {
      await ref
          .read(searchPaymentMethodsProvider.notifier)
          .refreshPaymentMethods();
    } else {
      await ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();
    }
  }

  void _enterSelectionMode(String paymentMethodId) {
    if (_isSelectionMode) return;
    setState(() {
      _isSelectionMode = true;
      _selectedPaymentMethodIds.add(paymentMethodId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPaymentMethodIds.clear();
    });
  }

  void _onSelectItem(String paymentMethodId) {
    setState(() {
      if (_selectedPaymentMethodIds.contains(paymentMethodId)) {
        _selectedPaymentMethodIds.remove(paymentMethodId);
      } else {
        _selectedPaymentMethodIds.add(paymentMethodId);
      }
      if (_selectedPaymentMethodIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _deleteSelectedItems() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Anda yakin ingin menghapus ${_selectedPaymentMethodIds.length} metode pembayaran yang dipilih?',
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
                      .read(paymentMethodMutationProvider.notifier)
                      .batchDeletePaymentMethods(
                        _selectedPaymentMethodIds.toList(),
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
    final allItemIds = paymentMethods.map((item) => item.id).toList();

    if (allItemIds.isEmpty) {
      ToastUtils.showError(
        context: context,
        message: 'Tidak ada item untuk dihapus',
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Hapus Semua'),
            content: Text(
              'Anda yakin ingin menghapus SEMUA ${allItemIds.length} metode pembayaran? Tindakan ini tidak dapat dibatalkan.',
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
                      .read(paymentMethodMutationProvider.notifier)
                      .batchDeletePaymentMethods(allItemIds);
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
                'Payment Method Utilities',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: Theme.of(context).primaryColor),
                ),
                title: const Text('Add Payment Method'),
                subtitle: const Text('Tambah metode pembayaran baru'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.pushRoute(AdminPaymentMethodUpsertRoute());
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _isSelectionMode
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isSelectionMode ? Icons.check_circle : Icons.select_all,
                    color: _isSelectionMode ? Colors.orange : Colors.blue,
                  ),
                ),
                title: Text(
                  _isSelectionMode ? 'Exit Selection Mode' : 'Select Items',
                ),
                subtitle: Text(
                  _isSelectionMode
                      ? 'Keluar dari mode seleksi'
                      : 'Masuk ke mode seleksi untuk menghapus item',
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_forever, color: Colors.red),
                ),
                title: const Text('Delete All Items'),
                subtitle: const Text('Hapus semua metode pembayaran'),
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
      title: Text('${_selectedPaymentMethodIds.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed:
              _selectedPaymentMethodIds.isNotEmpty
                  ? _deleteSelectedItems
                  : null,
        ),
      ],
    );
  }

  bool get isLoading {
    if (isSearching) {
      final searchState = ref.watch(searchPaymentMethodsProvider);
      return searchState.isLoading && searchState.paymentMethods.isEmpty;
    } else {
      final paymentMethodsState = ref.watch(paymentMethodsProvider);
      return paymentMethodsState.isLoading &&
          paymentMethodsState.paymentMethods.isEmpty;
    }
  }

  List<PaymentMethodModel> get paymentMethods {
    if (isSearching) {
      return ref.watch(searchPaymentMethodsProvider).paymentMethods;
    } else {
      return ref.watch(paymentMethodsProvider).paymentMethods;
    }
  }

  bool get isLoadingMore {
    if (isSearching) {
      return ref.watch(searchPaymentMethodsProvider).isLoadingMore;
    } else {
      return ref.watch(paymentMethodsProvider).isLoadingMore;
    }
  }

  String? get errorMessage {
    if (isSearching) {
      return ref.watch(searchPaymentMethodsProvider).errorMessage;
    } else {
      return ref.watch(paymentMethodsProvider).errorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentMethodMutationState>(paymentMethodMutationProvider, (
      _,
      state,
    ) {
      if (state.successMessage != null) {
        ToastUtils.showSuccess(
          context: context,
          message: state.successMessage!,
        );
        ref.read(paymentMethodMutationProvider.notifier).resetSuccessMessage();
      }
      if (state.errorMessage != null) {
        ToastUtils.showError(context: context, message: state.errorMessage!);
        ref.read(paymentMethodMutationProvider.notifier).resetErrorMessage();
      }
    });

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Scaffold(
        appBar:
            _isSelectionMode ? _buildSelectionAppBar() : const AdminAppBar(),
        endDrawer: _isSelectionMode ? null : const MyEndDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: _showUtilityBottomSheet,
          child: const Icon(Icons.more_vert),
          tooltip: 'Payment Method Utilities',
        ),
        body: MyScreenContainer(
          child: Consumer(
            builder: (context, ref, child) {
              const int skeletonItemCount = 8;

              return RefreshIndicator(
                onRefresh: _refreshData,
                color: context.colors.primary,
                backgroundColor: context.colors.surface,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search payment methods...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: context.textStyles.bodyMedium?.color,
                              ),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color:
                                              context
                                                  .textStyles
                                                  .bodyMedium
                                                  ?.color,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                          if (_searchFocusNode.hasFocus) {
                                            _searchFocusNode.unfocus();
                                          }
                                        },
                                      )
                                      : null,
                            ),
                            onChanged: _onSearchChanged,
                            style: context.textStyles.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _showFilters
                                ? Icons.filter_list
                                : Icons.filter_list_outlined,
                            color:
                                _showFilters
                                    ? context.colors.primary
                                    : context.colors.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                      ],
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _showFilters ? null : 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showFilters ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ).copyWith(bottom: 16.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isSearching) ...[
                                    Text(
                                      'Search In:',
                                      style: context.textStyles.titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children:
                                          _searchByOptions.map((option) {
                                            return ChoiceChip(
                                              label: Text(option.toUpperCase()),
                                              selected:
                                                  _selectedSearchBy == option,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  setState(() {
                                                    _selectedSearchBy = option;
                                                  });
                                                  _applyFilters();
                                                }
                                              },
                                              labelStyle: context
                                                  .textStyles
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        _selectedSearchBy ==
                                                                option
                                                            ? context
                                                                .colors
                                                                .onPrimary
                                                            : context
                                                                .textStyles
                                                                .bodySmall
                                                                ?.color,
                                                  ),
                                              selectedColor:
                                                  context.colors.primary,
                                              backgroundColor:
                                                  context.colors.surfaceVariant,
                                            );
                                          }).toList(),
                                    ),
                                    const Divider(),
                                  ],
                                  Text(
                                    'Sort By:',
                                    style: context.textStyles.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedOrderBy,
                                          decoration: const InputDecoration(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items:
                                              _orderByOptions.entries.map((
                                                entry,
                                              ) {
                                                return DropdownMenuItem(
                                                  value: entry.key,
                                                  child: Text(
                                                    entry.value,
                                                    style:
                                                        context
                                                            .textStyles
                                                            .bodyMedium,
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedOrderBy = value;
                                              });
                                              _applyFilters();
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.keyboard_arrow_up,
                                              color:
                                                  !_isDescending
                                                      ? context.colors.primary
                                                      : context.colors.onSurface
                                                          .withOpacity(0.6),
                                            ),
                                            onPressed: () {
                                              if (_isDescending) {
                                                setState(() {
                                                  _isDescending = false;
                                                });
                                                _applyFilters();
                                              }
                                            },
                                            tooltip: 'Ascending',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.keyboard_arrow_down,
                                              color:
                                                  _isDescending
                                                      ? context.colors.primary
                                                      : context.colors.onSurface
                                                          .withOpacity(0.6),
                                            ),
                                            onPressed: () {
                                              if (!_isDescending) {
                                                setState(() {
                                                  _isDescending = true;
                                                });
                                                _applyFilters();
                                              }
                                            },
                                            tooltip: 'Descending',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isSearching ||
                        _selectedOrderBy != 'createdAt' ||
                        !_isDescending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _buildFilterInfoText(),
                                style: context.textStyles.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  isSearching = false;
                                  _selectedSearchBy = 'name';
                                  _selectedOrderBy = 'createdAt';
                                  _isDescending = true;
                                });
                                ref
                                    .read(searchPaymentMethodsProvider.notifier)
                                    .clearSearch();
                                ref
                                    .read(paymentMethodsProvider.notifier)
                                    .refreshPaymentMethods();
                                if (_searchFocusNode.hasFocus) {
                                  _searchFocusNode.unfocus();
                                }
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ),
                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: context.colors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.colors.error.withOpacity(0.3),
                          ),
                        ),
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: context.colors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: context.colors.error,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _refreshData,
                              child: Text(
                                'Retry',
                                style: TextStyle(color: context.colors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildPaymentMethodsList(skeletonItemCount),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _buildFilterInfoText() {
    List<String> info = [];

    if (isSearching) {
      info.add('Searching "${_searchController.text}" in $_selectedSearchBy');
    }

    if (_selectedOrderBy != 'createdAt' || !_isDescending) {
      String sortOrder = _orderByOptions[_selectedOrderBy] ?? _selectedOrderBy;
      String direction = _isDescending ? "Descending" : "Ascending";
      info.add('Sorted by $sortOrder ($direction)');
    }

    return info.join(' • ');
  }

  Widget _buildPaymentMethodsList(int skeletonItemCount) {
    if (!isLoading && paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.payment_outlined,
              size: 64,
              color:
                  context.isDarkMode
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'No payment methods found for "${_searchController.text}"'
                  : 'No payment methods available',
              style: context.textStyles.titleMedium?.copyWith(
                color:
                    context.isDarkMode
                        ? AppTheme.textTertiaryDark
                        : AppTheme.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isSearching)
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Text('Clear Search'),
              )
            else
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Refresh'),
              ),
          ],
        ),
      );
    }

    return Skeletonizer(
      enabled: isLoading,
      child: ListView.separated(
        controller: _scrollController,
        itemCount:
            isLoading
                ? skeletonItemCount
                : paymentMethods.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (!isLoading && index == paymentMethods.length && isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final paymentMethod =
              isLoading ? PaymentMethodModel.dummy() : paymentMethods[index];
          final isSelected = _selectedPaymentMethodIds.contains(
            paymentMethod.id,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                PaymentMethodTile(
                  paymentMethod: paymentMethod,
                  onTap:
                      isLoading
                          ? null
                          : () {
                            if (_isSelectionMode) {
                              _onSelectItem(paymentMethod.id);
                            } else {
                              context.router.push(
                                AdminPaymentMethodUpsertRoute(
                                  paymentMethod: paymentMethod,
                                ),
                              );
                            }
                          },
                  onLongPress:
                      isLoading
                          ? null
                          : () => _enterSelectionMode(paymentMethod.id),
                ),
                if (_isSelectionMode)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _onSelectItem(paymentMethod.id),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.2),
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
                          color: Colors.black.withOpacity(0.5),
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
}
