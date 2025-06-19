import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/menu_item/presentation/widgets/menu_item_card.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_state.dart';
import 'package:jamal/features/menu_item/providers/menu_items_provider.dart';
import 'package:jamal/features/menu_item/providers/search_menu_items_provider.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class AdminMenuItemsScreen extends ConsumerStatefulWidget {
  const AdminMenuItemsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminMenuItemsScreen> createState() =>
      _AdminMenuItemsScreenState();
}

class _AdminMenuItemsScreenState extends ConsumerState<AdminMenuItemsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

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
          final searchState = ref.read(searchMenuItemsProvider);
          if (!searchState.isLoadingMore && searchState.hasMore) {
            ref.read(searchMenuItemsProvider.notifier).loadMoreMenuItems();
          }
        } else {
          final menuItemsState = ref.read(menuItemsProvider);
          if (!menuItemsState.isLoadingMore && menuItemsState.hasMore) {
            ref.read(menuItemsProvider.notifier).loadMoreMenuItems();
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
          .read(searchMenuItemsProvider.notifier)
          .searchMenuItems(query: query, searchBy: _selectedSearchBy);
    } else {
      ref.read(searchMenuItemsProvider.notifier).clearSearch();
    }
  }

  void _applyFilters() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    if (isSearching) {
      ref
          .read(searchMenuItemsProvider.notifier)
          .searchMenuItems(
            query: _searchController.text,
            searchBy: _selectedSearchBy,
          );
    } else {
      ref
          .read(menuItemsProvider.notifier)
          .loadMenuItemsWithFilter(
            orderBy: _selectedOrderBy,
            descending: _isDescending,
          );
    }
  }

  Future<void> _refreshData() async {
    if (_isSelectionMode) _exitSelectionMode();

    if (isSearching) {
      await ref.read(searchMenuItemsProvider.notifier).refreshMenuItems();
    } else {
      await ref.read(menuItemsProvider.notifier).refreshMenuItems();
    }
  }

  void _enterSelectionMode(String itemId) {
    if (_isSelectionMode) return;
    setState(() {
      _isSelectionMode = true;
      _selectedItemIds.add(itemId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
  }

  void _onSelectItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
      if (_selectedItemIds.isEmpty) {
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
              'Anda yakin ingin menghapus ${_selectedItemIds.length} item yang dipilih?',
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
                      .read(menuItemMutationProvider.notifier)
                      .batchDeleteMenuItems(_selectedItemIds.toList());
                  Navigator.of(ctx).pop();
                  _exitSelectionMode();
                },
              ),
            ],
          ),
    );
  }

  void _deleteAllItems() {
    final allItemIds = menuItems.map((item) => item.id).toList();

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
              'Anda yakin ingin menghapus SEMUA ${allItemIds.length} item menu? Tindakan ini tidak dapat dibatalkan.',
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
                      .read(menuItemMutationProvider.notifier)
                      .batchDeleteMenuItems(allItemIds);
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
                'Menu Utilities',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: Theme.of(context).primaryColor),
                ),
                title: const Text('Add Menu Item'),
                subtitle: const Text('Tambah item menu baru'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.pushRoute(AdminMenuItemUpsertRoute());
                },
              ),
              const Divider(),
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
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_forever, color: Colors.red),
                ),
                title: const Text('Delete All Items'),
                subtitle: const Text('Hapus semua item menu'),
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
      title: Text('${_selectedItemIds.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _selectedItemIds.isNotEmpty ? _deleteSelectedItems : null,
        ),
      ],
    );
  }

  bool get isLoading {
    if (isSearching) {
      final searchState = ref.watch(searchMenuItemsProvider);
      return searchState.isLoading && searchState.menuItems.isEmpty;
    } else {
      final menuItemsState = ref.watch(menuItemsProvider);
      return menuItemsState.isLoading && menuItemsState.menuItems.isEmpty;
    }
  }

  List<MenuItemModel> get menuItems {
    if (isSearching) {
      return ref.watch(searchMenuItemsProvider).menuItems;
    } else {
      return ref.watch(menuItemsProvider).menuItems;
    }
  }

  bool get isLoadingMore {
    if (isSearching) {
      return ref.watch(searchMenuItemsProvider).isLoadingMore;
    } else {
      return ref.watch(menuItemsProvider).isLoadingMore;
    }
  }

  String? get errorMessage {
    final provider = isSearching ? searchMenuItemsProvider : menuItemsProvider;
    return ref.watch(provider).errorMessage;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MenuItemMutationState>(menuItemMutationProvider, (_, state) {
      if (state.successMessage != null) {
        ToastUtils.showSuccess(
          context: context,
          message: state.successMessage!,
        );
        ref.read(menuItemMutationProvider.notifier).resetSuccessMessage();
      }
      if (state.errorMessage != null) {
        ToastUtils.showError(context: context, message: state.errorMessage!);
        ref.read(menuItemMutationProvider.notifier).resetErrorMessage();
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
          tooltip: 'Menu Utilities',
        ),
        body: MyScreenContainer(
          child: Consumer(
            builder: (context, ref, child) {
              const int skeletonItemCount = 6;

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
                              hintText: 'Search menu items...',
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
                                    : context.colors.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                      ],
                    ),

                    // ... Filter UI remains the same ...
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
                                                  context.colors.surfaceContainerHighest,
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
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
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
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
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
                                    .read(searchMenuItemsProvider.notifier)
                                    .clearSearch();
                                ref
                                    .read(menuItemsProvider.notifier)
                                    .refreshMenuItems();
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
                          color: context.colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.colors.error.withValues(alpha: 0.3),
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
                    Expanded(child: _buildMenuItemsGrid(skeletonItemCount)),
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
      if (_selectedOrderBy != 'createdAt' || !_isDescending) {
        info.add('Sorted by $sortOrder ($direction)');
      } else if (_selectedOrderBy == 'createdAt' && !_isDescending) {
        info.add('Sorted by $sortOrder ($direction)');
      }
    }

    return info.join(' • ');
  }

  Widget _buildMenuItemsGrid(int skeletonItemCount) {
    if (!isLoading && menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.food_bank_outlined,
              size: 64,
              color:
                  context.isDarkMode
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'No menu items found for "${_searchController.text}"'
                  : 'No menu items available',
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
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount:
            isLoading
                ? skeletonItemCount
                : menuItems.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (!isLoading && index == menuItems.length && isLoadingMore) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colors.primary,
                  ),
                ),
              ),
            );
          }

          final menuItem = isLoading ? MenuItemModel.dummy() : menuItems[index];

          final isSelected = _selectedItemIds.contains(menuItem.id);

          return Stack(
            fit: StackFit.expand,
            children: [
              MenuItemCard(
                menuItem: menuItem,
                onTap:
                    isLoading
                        ? null
                        : () {
                          if (_isSelectionMode) {
                            _onSelectItem(menuItem.id);
                          } else {
                            context.router.push(
                              AdminMenuItemDetailRoute(menuItem: menuItem),
                            );
                          }
                        },
                onLongPress:
                    isLoading ? null : () => _enterSelectionMode(menuItem.id),
              ),
              if (_isSelectionMode)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _onSelectItem(menuItem.id),
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
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.check_circle, color: Colors.white),
                ),
            ],
          );
        },
      ),
    );
  }
}
