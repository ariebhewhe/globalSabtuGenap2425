import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:jamal/firebase_options.dart';

import 'package:jamal/data/repositories/category_repo.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';

import 'package:jamal/data/seeders/category_seeder.dart';
import 'package:jamal/data/seeders/menu_item_seeder.dart';

import 'package:jamal/shared/services/cloudinary_service.dart';

Future<void> runSeeder() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');
  } catch (e) {
    print('Error initializing Firebase: $e');
    return;
  }

  final firestoreInstance = FirebaseFirestore.instance;
  final cloudinaryServiceInstance = CloudinaryService();

  final categoryRepo = CategoryRepo(
    firestoreInstance,
    cloudinaryServiceInstance,
  );
  final menuItemRepo = MenuItemRepo(
    firestoreInstance,
    cloudinaryServiceInstance,
  );

  print('\n--- Starting All Seeders ---');

  List<String> seededCategoryIds = [];

  print('\n-- Seeding Categories --');
  try {
    final categorySeeder = CategorySeeder(categoryRepo);
    final categoryResult = await categorySeeder.seed();

    categoryResult.fold(
      (error) {
        print(
          'Category seeding process failed. Menu item seeding will be skipped.',
        );
      },
      (success) {
        seededCategoryIds =
            success.data.map((category) => category.id).toList();
        print('Successfully seeded ${seededCategoryIds.length} categories.');
        if (seededCategoryIds.isEmpty) {
          print(
            'No categories were seeded, menu item seeding will be skipped.',
          );
        }
      },
    );
  } catch (e) {
    print(
      'An error occurred during Category seeding: $e. Menu item seeding will be skipped.',
    );
  }

  if (seededCategoryIds.isNotEmpty) {
    print('\n-- Seeding Menu Items --');
    try {
      final menuItemSeeder = MenuItemSeeder(menuItemRepo, seededCategoryIds);
      await menuItemSeeder.seed();
    } catch (e) {
      print('An error occurred during MenuItem seeding: $e');
    }
  } else {
    print(
      '\nSkipping menu item seeding due to issues with category seeding or no categories available.',
    );
  }

  print('\n--- All Seeding Processes Attempted ---');
}
