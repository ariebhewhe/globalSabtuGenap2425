import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final void Function()? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl:
                    category.picture ??
                    "https://i.pinimg.com/736x/a6/97/02/a69702258e5b29508c054167714c1df1.jpg",
                fit: BoxFit.cover,
                placeholder:
                    (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                errorWidget:
                    (context, url, error) => Center(
                      child: Icon(
                        Icons.fastfood_outlined,
                        size: 40,
                        color: context.colors.secondary,
                      ),
                    ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      context.colors.surface.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              // Category name
              Positioned(
                bottom: 10,
                left: 10,
                child: Text(
                  category.name,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
