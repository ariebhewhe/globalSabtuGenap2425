import 'dart:math';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';

class MenuItemSeeder {
  final MenuItemRepo _menuItemRepo;
  final List<String> _categoryIds;

  MenuItemSeeder(this._menuItemRepo, this._categoryIds);

  Future<void> seed() async {
    print('Starting menu item seeding (using batch and random categories)...');

    if (_categoryIds.isEmpty) {
      print(
        'Error: No category IDs provided to MenuItemSeeder. Skipping menu item seeding.',
      );
      return;
    }

    final Random random = Random();
    final String defaultImageUrl =
        'https://i.pinimg.com/736x/95/d1/45/95d145d774916fedf9f8c0e827863b8a.jpg';
    final List<CreateMenuItemDto> menuItemsToSeed = [];

    List<Map<String, dynamic>> itemTemplates = [
      {
        'name': 'Nasi Goreng Istimewa',
        'price': 26000.0,
        'veg': false,
        'spice': 2,
        'desc': 'Nasi goreng dengan campuran seafood dan telur mata sapi.',
      },
      {
        'name': 'Mie Kuah Pedas',
        'price': 22000.0,
        'veg': false,
        'spice': 3,
        'desc': 'Mie kuah dengan kaldu ayam pedas dan bakso.',
      },
      {
        'name': 'Ayam Geprek Original',
        'price': 20000.0,
        'veg': false,
        'spice': 2,
        'desc': 'Ayam goreng tepung digeprek dengan sambal bawang.',
      },
      {
        'name': 'Soto Ayam Lamongan',
        'price': 25000.0,
        'veg': false,
        'spice': 0,
        'desc': 'Soto ayam khas Lamongan dengan koya gurih.',
      },
      {
        'name': 'Gado-Gado Komplit',
        'price': 23000.0,
        'veg': true,
        'spice': 1,
        'desc': 'Sayuran segar dengan bumbu kacang, lontong, dan kerupuk.',
      },
      {
        'name': 'Pizza Margherita Classic',
        'price': 55000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Pizza dengan saus tomat, mozzarella, dan basil.',
      },
      {
        'name': 'Burger Daging Sapi Deluxe',
        'price': 45000.0,
        'veg': false,
        'spice': 0,
        'desc': 'Burger dengan patty daging sapi tebal, keju, dan sayuran.',
      },
      {
        'name': 'Pasta Carbonara',
        'price': 60000.0,
        'veg': false,
        'spice': 0,
        'desc':
            'Pasta dengan saus krim, telur, keju parmesan, dan smoked beef.',
      },
      {
        'name': 'Salad Buah Segar',
        'price': 28000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Campuran buah-buahan segar dengan saus yogurt madu.',
      },
      {
        'name': 'Kentang Goreng Keju',
        'price': 18000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Kentang goreng renyah dengan taburan keju parmesan.',
      },
      {
        'name': 'Smoothie Mangga',
        'price': 25000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Minuman smoothie mangga segar dan kental.',
      },
      {
        'name': 'Kopi Susu Gula Aren',
        'price': 22000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Kopi susu kekinian dengan rasa manis gula aren.',
      },
      {
        'name': 'Teh Tarik Malaysia',
        'price': 15000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Teh susu khas Malaysia yang ditarik hingga berbusa.',
      },
      {
        'name': 'Dimsum Hakau Udang',
        'price': 30000.0,
        'veg': false,
        'spice': 0,
        'desc': 'Dimsum hakau dengan isian udang segar.',
      },
      {
        'name': 'Sushi Salmon Roll',
        'price': 65000.0,
        'veg': false,
        'spice': 0,
        'desc': 'Sushi roll dengan isian salmon segar dan alpukat.',
      },
      {
        'name': 'Steak Sirloin Australia',
        'price': 120000.0,
        'veg': false,
        'spice': 0,
        'desc': 'Steak sirloin Australia disajikan dengan saus blackpepper.',
      },
      {
        'name': 'Iga Bakar Madu Pedas',
        'price': 75000.0,
        'veg': false,
        'spice': 2,
        'desc': 'Iga sapi empuk dibakar dengan bumbu madu pedas.',
      },
      {
        'name': 'Lasagna Panggang Keju',
        'price': 68000.0,
        'veg': false,
        'spice': 0,
        'desc':
            'Lasagna panggang dengan lapisan daging, saus bechamel, dan keju.',
      },
      {
        'name': 'Sup Krim Jamur',
        'price': 32000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Sup krim kental dengan potongan jamur champignon.',
      },
      {
        'name': 'Pancake Cokelat Keju',
        'price': 27000.0,
        'veg': true,
        'spice': 0,
        'desc': 'Pancake lembut dengan topping saus cokelat dan parutan keju.',
      },
    ];

    for (int i = 0; i < 20; i++) {
      // Pilih ID kategori secara acak dari daftar yang diberikan
      final String randomCategoryId =
          _categoryIds[random.nextInt(_categoryIds.length)];
      final template = itemTemplates[i % itemTemplates.length];

      menuItemsToSeed.add(
        CreateMenuItemDto(
          name: '${template['name']} #${i + 1}',
          description: '${template['desc']} (Batch Item)',
          price: template['price'] + (random.nextInt(5) * 1000),
          categoryId: randomCategoryId,
          imageUrl: defaultImageUrl,
          isAvailable: true,
          isVegetarian: template['veg'] as bool,
          spiceLevel: template['spice'] as int,
        ),
      );
    }

    if (menuItemsToSeed.isEmpty) {
      print('No menu items generated for seeding.');
      return;
    }

    final result = await _menuItemRepo.batchAddMenuItems(menuItemsToSeed);

    result.fold(
      (error) => print('Menu item batch seeding failed: ${error.message}'),
      (success) => print(
        'Menu item batch seeding successful: ${success.message} - Total ${menuItemsToSeed.length} items.',
      ),
    );

    print('Menu item seeding process completed.');
  }
}
