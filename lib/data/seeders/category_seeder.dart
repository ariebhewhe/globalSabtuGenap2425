import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/data/repositories/category_repo.dart';

class CategorySeeder {
  final CategoryRepo _categoryRepo;

  CategorySeeder(this._categoryRepo);

  Future<Either<ErrorResponse, SuccessResponse<List<CategoryModel>>>>
  seed() async {
    print('Starting category seeding...');

    final defaultPicture =
        "https://i.pinimg.com/736x/6e/59/4d/6e594dca31e96b87a593cb0923fe6c22.jpg";

    final List<CreateCategoryDto> categoriesToSeed = [
      CreateCategoryDto(
        name: 'Makanan Utama',
        description: 'Berbagai hidangan utama yang mengenyangkan.',
        picture: defaultPicture,
      ),
      CreateCategoryDto(
        name: 'Minuman Segar',
        description: 'Aneka minuman dingin dan panas.',
        picture: defaultPicture,
      ),
      CreateCategoryDto(
        name: 'Makanan Ringan',
        description: 'Camilan lezat untuk teman bersantai.',
        picture: defaultPicture,
      ),
      CreateCategoryDto(
        name: 'Hidangan Penutup',
        description: 'Pemanis mulut setelah makan.',
        picture: defaultPicture,
      ),
      CreateCategoryDto(
        name: 'Sarapan Pagi',
        description: 'Menu untuk memulai hari dengan energi.',
        picture: defaultPicture,
      ),
    ];

    if (categoriesToSeed.isEmpty) {
      print('No categories defined for seeding.');
      return Right(
        SuccessResponse(
          data: [],
          message: 'No categories defined for seeding.',
        ),
      );
    }

    final result = await _categoryRepo.batchAddCategories(categoriesToSeed);

    result.fold(
      (error) => print('Category seeding failed: ${error.message}'),
      (success) => print(
        'Category seeding successful: ${success.message} - Total ${success.data.length} categories seeded.',
      ),
    );
    return result;
  }
}
