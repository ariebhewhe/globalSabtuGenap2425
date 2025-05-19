import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/features/category/providers/categories_provider.dart';
import 'package:jamal/features/category/widgets/category_card.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/admin_end_drawer.dart';
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
      // * Ketika pengguna scroll mendekati bawah, muat lebih banyak data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoriesState = ref.watch(categoriesProvider);

        // * Periksa apakah sedang loading more dan masih ada data untuk dimuat
        if (!categoriesState.isLoadingMore && categoriesState.hasMore) {
          ref.read(categoriesProvider.notifier).loadMoreCategories();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const AdminEndDrawer(),
      body: MyScreenContainer(
        child: Consumer(
          builder: (context, ref, child) {
            final categoriesState = ref.watch(categoriesProvider);
            final categories = categoriesState.categories;
            final isLoading = categoriesState.isLoading;
            const int skeletonItemCount = 6;

            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref.read(categoriesProvider.notifier).refreshCategories(),
              child: Column(
                children: [
                  if (categoriesState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.red.shade100,
                      width: double.infinity,
                      child: Text(
                        categoriesState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  Expanded(
                    child: Skeletonizer(
                      enabled: isLoading,
                      child: GridView.builder(
                        controller: _scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 0.8,
                            ),
                        itemCount:
                            isLoading
                                ? skeletonItemCount
                                : categories.length +
                                    (categoriesState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (!isLoading &&
                              index == categories.length &&
                              categoriesState.isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final category =
                              isLoading
                                  ? CategoryModel(
                                    id: '',
                                    name: 'Loading Item',
                                    description: '',
                                    picture: null,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  )
                                  : categories[index];

                          return CategoryCard(
                            category: category,
                            // onTap:
                            //     isLoading
                            //         ? null
                            //         : () {
                            //           // if (index < categories.length) {
                            //           //   context.router.push(
                            //           //     CategoryDetailRoute(
                            //           //       category: categories[index],
                            //           //     ),
                            //           //   );
                            //           // }
                            //         },
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
}
