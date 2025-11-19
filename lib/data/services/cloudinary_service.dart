import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final Dio _dio = Dio();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get _apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  String get _apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  String get _uploadUrl {
    if (_cloudName.isEmpty) {
      throw Exception('CLOUDINARY_CLOUD_NAME chưa được cấu hình');
    }
    return 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  }

  /// Upload image to Cloudinary
  ///
  /// [file] - The image file to upload
  /// [folder] - Optional folder path in Cloudinary (e.g., 'book_covers', 'user_avatars')
  /// [publicId] - Optional public ID for the image (if not provided, will be auto-generated)
  /// Returns the secure URL of the uploaded image
  Future<String?> uploadImage(
    File file, {
    String? folder,
    String? publicId,
  }) async {
    try {
      if (_cloudName.isEmpty) {
        throw Exception(
          'Cloudinary chưa được cấu hình. Vui lòng thêm CLOUDINARY_CLOUD_NAME vào file .env',
        );
      }

      if (!await file.exists()) {
        throw Exception('File không tồn tại');
      }

      // Generate public_id if not provided
      // If folder is specified separately, public_id should NOT include folder path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalPublicId = publicId ?? 'img_$timestamp';

      // Prepare form data
      final formDataMap = <String, dynamic>{
        'file': await MultipartFile.fromFile(file.path),
      };

      // Option 1: Use unsigned upload with upload preset (simplest, recommended)
      if (_uploadPreset.isNotEmpty) {
        formDataMap['upload_preset'] = _uploadPreset;
        if (folder != null) {
          formDataMap['folder'] = folder;
        }
        if (publicId != null || finalPublicId.isNotEmpty) {
          formDataMap['public_id'] = finalPublicId;
        }
      }
      // Option 2: Use signed upload with API key and secret
      else if (_apiKey.isNotEmpty && _apiSecret.isNotEmpty) {
        final timestampSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Build parameters for signature (only include non-empty values)
        final signatureParams = <String, String>{
          'timestamp': timestampSeconds.toString(),
        };

        if (folder != null && folder.isNotEmpty) {
          signatureParams['folder'] = folder;
        }

        if (finalPublicId.isNotEmpty) {
          signatureParams['public_id'] = finalPublicId;
        }

        final signature = _generateSignatureFromParams(signatureParams);

        formDataMap['timestamp'] = timestampSeconds;
        formDataMap['api_key'] = _apiKey;
        formDataMap['signature'] = signature;

        if (folder != null) {
          formDataMap['folder'] = folder;
        }
        if (finalPublicId.isNotEmpty) {
          formDataMap['public_id'] = finalPublicId;
        }
      }
      // Option 3: Unsigned upload without preset (may require account settings)
      else {
        if (folder != null) {
          formDataMap['folder'] = folder;
        }
        if (finalPublicId.isNotEmpty) {
          formDataMap['public_id'] = finalPublicId;
        }
      }

      final formData = FormData.fromMap(formDataMap);

      // Upload to Cloudinary
      final response = await _dio.post(
        _uploadUrl,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null) {
          return secureUrl;
        }
        throw Exception('Không nhận được URL từ Cloudinary');
      } else {
        throw Exception('Upload thất bại: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Lỗi upload ảnh lên Cloudinary: ${e.toString()}');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages(
    List<File> files, {
    String? folder,
  }) async {
    List<String> urls = [];

    for (var i = 0; i < files.length; i++) {
      try {
        final url = await uploadImage(
          files[i],
          folder: folder,
          publicId:
              '${folder ?? 'uploads'}/${DateTime.now().millisecondsSinceEpoch}_$i',
        );
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        // Continue with other files even if one fails
        print('Lỗi upload file $i: $e');
      }
    }

    return urls;
  }

  /// Delete image from Cloudinary
  ///
  /// [publicId] - The public ID of the image to delete (extracted from URL or provided)
  Future<bool> deleteImage(String publicId) async {
    try {
      if (_cloudName.isEmpty || _apiKey.isEmpty || _apiSecret.isEmpty) {
        throw Exception('Cloudinary chưa được cấu hình');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateDeleteSignature(publicId, timestamp);

      final deleteUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy';

      final response = await _dio.post(
        deleteUrl,
        data: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      return response.statusCode == 200 && response.data['result'] == 'ok';
    } catch (e) {
      print('Lỗi xóa ảnh từ Cloudinary: $e');
      return false;
    }
  }

  /// Extract public ID from Cloudinary URL
  String? extractPublicId(String url) {
    try {
      // Cloudinary URL format: https://res.cloudinary.com/{cloud_name}/image/upload/{version}/{public_id}.{format}
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find 'upload' in path
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return null;
      }

      // Get public_id (everything after 'upload' and version if exists)
      // Skip version if it's a number
      var publicIdIndex = uploadIndex + 1;
      if (publicIdIndex < pathSegments.length) {
        final possibleVersion = pathSegments[publicIdIndex];
        if (RegExp(r'^v\d+$').hasMatch(possibleVersion)) {
          publicIdIndex++;
        }
      }

      if (publicIdIndex < pathSegments.length) {
        final publicIdWithFormat = pathSegments
            .sublist(publicIdIndex)
            .join('/');
        // Remove file extension
        return publicIdWithFormat.replaceAll(RegExp(r'\.[^.]+$'), '');
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate signature from parameters map
  /// Cloudinary signature format: sort all parameters alphabetically,
  /// create string "param1=value1&param2=value2", append API secret, then SHA1 hash
  String _generateSignatureFromParams(Map<String, String> params) {
    // Sort parameters alphabetically by key
    final sortedKeys = params.keys.toList()..sort();

    // Create string to sign: key1=value1&key2=value2
    final stringToSign = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Append API secret and hash with SHA1
    final stringToSignWithSecret = '$stringToSign$_apiSecret';
    final bytes = utf8.encode(stringToSignWithSecret);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  /// Generate signature for delete
  String _generateDeleteSignature(String publicId, int timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
