// lib/utils/cloudinary_helper.dart
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class CloudinaryHelper {
  static final cloudinary = CloudinaryPublic(
    'dovv0fdeh', // Replace with your cloud name
    'KantinKu', // Replace with your upload preset
    cache: false,
  );

  static Future<String> uploadImage(File image) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print(e);
      throw Exception('Failed to upload image');
    }
  }
}