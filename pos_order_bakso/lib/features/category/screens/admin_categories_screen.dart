import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/features/category/providers/categories_provider.dart';
import 'package:jamal/features/category/providers/category_mutation_provider.dart'; // Asumsi provider ini ada
import 'package:jamal/features/category/providers/category_mutation_state.dart';
import 'package:jamal/features/category/providers/search_categories_provider.dart';
import 'package:jamal/features/category/widgets/category_card.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSelectionMode = false;
  final Set<String> _selectedCategoryIds = {};

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
          final searchState = ref.read(searchCategoriesProvider);
          if (!searchState.isLoadingMore && searchState.hasMore) {
            ref.read(searchCategoriesProvider.notifier).loadMoreCategories();
          }
        } else {
          final categoriesState = ref.read(categoriesProvider);
          if (!categoriesState.isLoadingMore && categoriesState.hasMore) {
            ref.read(categoriesProvider.notifier).loadMoreCategories();
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
          .read(searchCategoriesProvider.notifier)
          .searchCategories(query: query, searchBy: _selectedSearchBy);
    } else {
      ref.read(searchCategoriesProvider.notifier).clearSearch();
    }
  }

  void _applyFilters() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    if (isSearching) {
      ref
          .read(searchCategoriesProvider.notifier)
          .searchCategories(
            query: _searchController.text,
            searchBy: _selectedSearchBy,
          );
    } else {
      ref
          .read(categoriesProvider.notifier)
          .loadCategoriesWithFilter(
            orderBy: _selectedOrderBy,
            descending: _isDescending,
          );
    }
  }

  Future<void> _refreshData() async {
    if (_isSelectionMode) _exitSelectionMode();

    if (isSearching) {
      await ref.read(searchCategoriesProvider.notifier).refreshCategories();
    } else {
      await ref.read(categoriesProvider.notifier).refreshCategories();
    }
  }

  void _enterSelectionMode(String categoryId) {
    if (_isSelectionMode) return;
    setState(() {
      _isSelectionMode = true;
      _selectedCategoryIds.add(categoryId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedCategoryIds.clear();
    });
  }

  void _onSelectItem(String categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
      if (_selectedCategoryIds.isEmpty) {
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
              'Anda yakin ingin menghapus ${_selectedCategoryIds.length} kategori yang dipilih?',
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
                      .read(categoryMutationProvider.notifier)
                      .batchDeleteCategories(_selectedCategoryIds.toList());
                  Navigator.of(ctx).pop();
                  _exitSelectionMode();
                },
              ),
            ],
          ),
    );
  }

  void _deleteAllItems() {
    final allCategoryIds = categories.map((cat) => cat.id).toList();

    if (allCategoryIds.isEmpty) {
      ToastUtils.showError(
        context: context,
        message: 'Tidak ada kategori untuk dihapus',
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Hapus Semua'),
            content: Text(
              'Anda yakin ingin menghapus SEMUA ${allCategoryIds.length} kategori? Menu item yang terkait akan kehilangan kategorinya. Tindakan ini tidak dapat dibatalkan.',
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
                      .read(categoryMutationProvider.notifier)
                      .batchDeleteCategories(allCategoryIds);
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
                'Category Utilities',
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
                title: const Text('Add Category'),
                subtitle: const Text('Tambah kategori baru'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.pushRoute(AdminCategoryUpsertRoute());
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
                  _isSelectionMode
                      ? 'Exit Selection Mode'
                      : 'Select Categories',
                ),
                subtitle: Text(
                  _isSelectionMode
                      ? 'Keluar dari mode seleksi'
                      : 'Masuk ke mode seleksi untuk menghapus kategori',
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
                title: const Text('Delete All Categories'),
                subtitle: const Text('Hapus semua kategori'),
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
      title: Text('${_selectedCategoryIds.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed:
              _selectedCategoryIds.isNotEmpty ? _deleteSelectedItems : null,
        ),
      ],
    );
  }

  bool get isLoading {
    if (isSearching) {
      final searchState = ref.watch(searchCategoriesProvider);
      return searchState.isLoading && searchState.categories.isEmpty;
    } else {
      final categoriesState = ref.watch(categoriesProvider);
      return categoriesState.isLoading && categoriesState.categories.isEmpty;
    }
  }

  List<CategoryModel> get categories {
    if (isSearching) {
      return ref.watch(searchCategoriesProvider).categories;
    } else {
      return ref.watch(categoriesProvider).categories;
    }
  }

  bool get isLoadingMore {
    if (isSearching) {
      return ref.watch(searchCategoriesProvider).isLoadingMore;
    } else {
      return ref.watch(categoriesProvider).isLoadingMore;
    }
  }

  String? get errorMessage {
    if (isSearching) {
      return ref.watch(searchCategoriesProvider).errorMessage;
    } else {
      return ref.watch(categoriesProvider).errorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CategoryMutationState>(categoryMutationProvider, (_, state) {
      if (state.successMessage != null) {
        ToastUtils.showSuccess(
          context: context,
          message: state.successMessage!,
        );
        ref.read(categoryMutationProvider.notifier).resetSuccessMessage();
      }
      if (state.errorMessage != null) {
        ToastUtils.showError(context: context, message: state.errorMessage!);
        ref.read(categoryMutationProvider.notifier).resetErrorMessage();
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
          tooltip: 'Category Utilities',
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
                              hintText: 'Search categories...',
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
                                    .read(searchCategoriesProvider.notifier)
                                    .clearSearch();
                                ref
                                    .read(categoriesProvider.notifier)
                                    .refreshCategories();
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
                    Expanded(child: _buildCategoriesGrid(skeletonItemCount)),
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

  Widget _buildCategoriesGrid(int skeletonItemCount) {
    if (!isLoading && categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.category_outlined,
              size: 64,
              color:
                  context.isDarkMode
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'No categories found for "${_searchController.text}"'
                  : 'No categories available',
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
          childAspectRatio: 1.2, // Adjusted aspect ratio for categories
        ),
        itemCount:
            isLoading
                ? skeletonItemCount
                : categories.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (!isLoading && index == categories.length && isLoadingMore) {
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

          final category =
              isLoading ? CategoryModel.dummy() : categories[index];
          final isSelected = _selectedCategoryIds.contains(category.id);

          return Stack(
            fit: StackFit.expand,
            children: [
              CategoryCard(
                category: category,
                onTap:
                    isLoading
                        ? null
                        : () {
                          if (_isSelectionMode) {
                            _onSelectItem(category.id);
                          } else {
                            context.router.push(
                              AdminCategoryUpsertRoute(category: category),
                            );
                          }
                        },
                onLongPress:
                    isLoading ? null : () => _enterSelectionMode(category.id),
              ),
              if (_isSelectionMode)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _onSelectItem(category.id),
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
