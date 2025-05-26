import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_tables_provider.dart';
import 'package:jamal/features/restaurant_table/providers/search_restaurant_tables_provider.dart';
import 'package:jamal/features/restaurant_table/widgets/restaurant_table_tile.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class AdminRestaurantTablesScreen extends ConsumerStatefulWidget {
  const AdminRestaurantTablesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminRestaurantTablesScreen> createState() =>
      _AdminRestaurantTablesScreenState();
}

class _AdminRestaurantTablesScreenState
    extends ConsumerState<AdminRestaurantTablesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedSearchBy = 'tableNumber';
  final List<String> _searchByOptions = ['tableNumber', 'description'];

  String _selectedOrderBy = 'createdAt';
  bool _isDescending = true;
  final Map<String, String> _orderByOptions = {
    'createdAt': 'Created Date',
    'updatedAt': 'Updated Date',
    'tableNumber': 'Table Number',
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
          final searchState = ref.read(searchRestaurantTablesProvider);
          if (!searchState.isLoadingMore && searchState.hasMore) {
            ref
                .read(searchRestaurantTablesProvider.notifier)
                .loadMoreRestaurantTables();
          }
        } else {
          final restaurantTablesState = ref.read(restaurantTablesProvider);
          if (!restaurantTablesState.isLoadingMore &&
              restaurantTablesState.hasMore) {
            ref
                .read(restaurantTablesProvider.notifier)
                .loadMoreRestaurantTables();
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
          .read(searchRestaurantTablesProvider.notifier)
          .searchRestaurantTables(query: query, searchBy: _selectedSearchBy);
    } else {
      ref.read(searchRestaurantTablesProvider.notifier).clearSearch();
    }
  }

  void _applyFilters() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    if (isSearching) {
      ref
          .read(searchRestaurantTablesProvider.notifier)
          .searchRestaurantTables(
            query: _searchController.text,
            searchBy: _selectedSearchBy,
          );
    } else {
      ref
          .read(restaurantTablesProvider.notifier)
          .loadRestaurantTablesWithFilter(
            orderBy: _selectedOrderBy,
            descending: _isDescending,
          );
    }
  }

  Future<void> _refreshData() async {
    if (isSearching) {
      ref
          .read(searchRestaurantTablesProvider.notifier)
          .refreshRestaurantTables();
    } else {
      ref.read(restaurantTablesProvider.notifier).refreshRestaurantTables();
    }
  }

  bool get isLoading {
    if (isSearching) {
      final searchState = ref.watch(searchRestaurantTablesProvider);
      return searchState.isLoading && searchState.restaurantTables.isEmpty;
    } else {
      final restaurantTablesState = ref.watch(restaurantTablesProvider);
      return restaurantTablesState.isLoading &&
          restaurantTablesState.restaurantTables.isEmpty;
    }
  }

  List<RestaurantTableModel> get restaurantTables {
    if (isSearching) {
      return ref.watch(searchRestaurantTablesProvider).restaurantTables;
    } else {
      return ref.watch(restaurantTablesProvider).restaurantTables;
    }
  }

  bool get isLoadingMore {
    if (isSearching) {
      return ref.watch(searchRestaurantTablesProvider).isLoadingMore;
    } else {
      return ref.watch(restaurantTablesProvider).isLoadingMore;
    }
  }

  String? get errorMessage {
    if (isSearching) {
      return ref.watch(searchRestaurantTablesProvider).errorMessage;
    } else {
      return ref.watch(restaurantTablesProvider).errorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // * Cara ini akan menghilangkan fokus dari widget apapun yang sedang fokus
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Scaffold(
        appBar: const AdminAppBar(),
        endDrawer: const MyEndDrawer(),
        floatingActionButton: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: context.theme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed:
                  () => context.pushRoute(AdminRestaurantTableUpsertRoute()),
              icon: const Icon(Icons.add),
            ),
          ),
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
                              hintText: 'Search restaurantTables...',
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
                                  _selectedSearchBy = 'tableNumber';
                                  _selectedOrderBy = 'createdAt';
                                  _isDescending = true;
                                });
                                ref
                                    .read(
                                      searchRestaurantTablesProvider.notifier,
                                    )
                                    .clearSearch();
                                ref
                                    .read(restaurantTablesProvider.notifier)
                                    .refreshRestaurantTables();
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
                      child: _buildRestaurantTablesList(skeletonItemCount),
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
      if (_selectedOrderBy != 'createdAt' || !_isDescending) {
        info.add('Sorted by $sortOrder ($direction)');
      } else if (_selectedOrderBy == 'createdAt' && !_isDescending) {
        info.add('Sorted by $sortOrder ($direction)');
      }
    }

    return info.join(' • ');
  }

  Widget _buildRestaurantTablesList(int skeletonItemCount) {
    if (!isLoading && restaurantTables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.food_bank,
              size: 64,
              color:
                  context.isDarkMode
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'No restaurantTables found for "${_searchController.text}"'
                  : 'No restaurantTables available',
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
      child: ListView.builder(
        controller: _scrollController,
        itemCount:
            isLoading
                ? skeletonItemCount
                : restaurantTables.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (!isLoading && index == restaurantTables.length && isLoadingMore) {
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

          final restaurantTable =
              isLoading
                  ? RestaurantTableModel(
                    id: '',
                    tableNumber: '',
                    capacity: 0,
                    isAvailable: false,
                    location: Location.indoor,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  )
                  : restaurantTables[index];

          return RestaurantTableTile(
            restaurantTable: restaurantTable,
            onTap:
                isLoading
                    ? null
                    : () {
                      context.router.push(
                        AdminRestaurantTableUpsertRoute(
                          restaurantTable: restaurantTable,
                        ),
                      );
                    },
          );
        },
      ),
    );
  }
}
