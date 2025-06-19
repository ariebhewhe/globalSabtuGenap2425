import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/constants/cloudinary_keys.dart';
import 'package:jamal/shared/models/cloudinary_model.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';

final cloudinaryProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class CloudinaryService {
  Future<CloudinaryUploadResponse> uploadImage({
    required File imageFile,
    required String folder,
  }) async {
    try {
      // * Identifikasi tipe MIME
      final mimeTypeData = lookupMimeType(imageFile.path)?.split('/');
      final imageType = mimeTypeData?[1];

      // * Buat form data untuk upload
      final formData = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryKeys.uploadEndpoint),
      );

      // * Tambahkan file ke request
      final file = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(
          mimeTypeData?[0] ?? 'image',
          imageType ?? 'jpeg',
        ),
      );
      formData.files.add(file);

      // * Tambahkan parameter yang diperlukan
      formData.fields['upload_preset'] = CloudinaryKeys.uploadPreset;
      formData.fields['folder'] = folder;
      formData.fields['api_key'] = CloudinaryKeys.apiKey;

      // * Kirim request
      final response = await formData.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      // * Parse response
      final result = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return CloudinaryUploadResponse.fromJson(result);
      } else {
        throw Exception('Upload failed: ${result['error']['message']}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<List<CloudinaryUploadResponse>> uploadBatchImages({
    required List<File> imageFiles,
    required String folder,
  }) async {
    try {
      final uploadFutures = <Future<CloudinaryUploadResponse>>[];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];

        // Panggil uploadImage untuk setiap file dengan parameter yang sesuai
        uploadFutures.add(
          uploadImage(
            imageFile: file,
            folder: folder, // Gunakan folder yang sama untuk semua file batch
          ),
        );
      }

      final results = await Future.wait(uploadFutures);
      return results;
    } catch (e) {
      throw Exception('Batch upload failed: $e');
    }
  }

  Future<CloudinaryDeleteResponse> deleteImage(String publicId) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryKeys.cloudName}/image/destroy',
      );

      // * Timestamp untuk signature
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final signature = generateSignature({
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      });

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': CloudinaryKeys.apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      final result = jsonDecode(response.body);
      final deleteResponse = CloudinaryDeleteResponse.fromJson(result);

      if (response.statusCode == 200 && result['result'] == 'ok') {
        return deleteResponse;
      } else {
        throw Exception('Delete failed: ${result['error']['message']}');
      }
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  // * Delete multiple images (batch delete)
  Future<CloudinaryBatchDeleteResponse> deleteBatchImages(
    List<String> publicIds,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryKeys.cloudName}/resources/image/upload',
      );

      // * Timestamp untuk signature
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // * Join public IDs sebagai comma-separated string
      final publicIdsStr = publicIds.join(',');

      final signature = generateSignature({
        'public_ids': publicIdsStr,
        'timestamp': timestamp.toString(),
      });

      final response = await http.delete(
        url,
        body: {
          'public_ids[]': publicIdsStr,
          'api_key': CloudinaryKeys.apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      final result = jsonDecode(response.body);
      final batchDeleteResponse = CloudinaryBatchDeleteResponse.fromJson(
        result,
      );

      if (response.statusCode == 200) {
        return batchDeleteResponse;
      } else {
        throw Exception('Batch delete failed: ${result['error']['message']}');
      }
    } catch (e) {
      throw Exception('Batch delete failed: $e');
    }
  }

  // * Generate signature untuk secure API calls
  String generateSignature(Map<String, String> params) {
    // * Sort parameter berdasarkan key
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // * Gabungkan parameter menjadi satu string
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // * Tambahkan API secret ke akhir string
    final stringToSign = paramString + CloudinaryKeys.apiSecret;

    // * Generate SHA-1 hash dan konversi ke hex
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes); // Butuh crypto package

    return digest.toString();
  }

  String getImageUrl({
    required String publicId,
    String format = 'auto',
    int? width,
    int? height,
    String crop = 'fill',
    String quality = 'auto',
    String? effect,
  }) {
    final List<String> transformations = [];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');

    transformations.add('c_$crop');
    transformations.add('q_$quality');

    if (effect != null) transformations.add('e_$effect');

    final transformString = transformations.join(',');

    return 'https://res.cloudinary.com/${CloudinaryKeys.cloudName}/image/upload/$transformString/$publicId.$format';
  }
}
