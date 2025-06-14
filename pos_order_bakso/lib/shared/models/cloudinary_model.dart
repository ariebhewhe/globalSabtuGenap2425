class CloudinaryUploadResponse {
  final String publicId;
  final String secureUrl;
  final String originalFilename;
  final String format;
  final int bytes;
  final String resourceType;
  final String url;
  final Map<String, dynamic> rawData;

  CloudinaryUploadResponse({
    required this.publicId,
    required this.secureUrl,
    required this.originalFilename,
    required this.format,
    required this.bytes,
    required this.resourceType,
    required this.url,
    required this.rawData,
  });

  factory CloudinaryUploadResponse.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResponse(
      publicId: json['public_id'] ?? '',
      secureUrl: json['secure_url'] ?? '',
      originalFilename: json['original_filename'] ?? '',
      format: json['format'] ?? '',
      bytes: json['bytes'] ?? 0,
      resourceType: json['resource_type'] ?? '',
      url: json['url'] ?? '',
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'secure_url': secureUrl,
      'original_filename': originalFilename,
      'format': format,
      'bytes': bytes,
      'resource_type': resourceType,
      'url': url,
    };
  }
}

class CloudinaryDeleteResponse {
  final String result;
  final Map<String, dynamic> rawData;

  CloudinaryDeleteResponse({required this.result, required this.rawData});

  factory CloudinaryDeleteResponse.fromJson(Map<String, dynamic> json) {
    return CloudinaryDeleteResponse(
      result: json['result'] ?? '',
      rawData: json,
    );
  }

  bool get isSuccess => result == 'ok';
}

class CloudinaryBatchDeleteResponse {
  final List<String> deleted;
  final List<String> partial;
  final List<String> failed;
  final Map<String, dynamic> rawData;

  CloudinaryBatchDeleteResponse({
    required this.deleted,
    required this.partial,
    required this.failed,
    required this.rawData,
  });

  factory CloudinaryBatchDeleteResponse.fromJson(Map<String, dynamic> json) {
    List<String> extractList(dynamic data) {
      if (data is List) {
        return data.cast<String>();
      }
      return [];
    }

    return CloudinaryBatchDeleteResponse(
      deleted: extractList(json['deleted'] ?? []),
      partial: extractList(json['partial'] ?? []),
      failed: extractList(json['failed'] ?? []),
      rawData: json,
    );
  }

  bool get hasErrors => failed.isNotEmpty || partial.isNotEmpty;
}
