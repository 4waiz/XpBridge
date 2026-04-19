import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'supabase_service.dart';

class PickedAsset {
  const PickedAsset({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
}

class AssetUploadService {
  const AssetUploadService._();

  // Keep uploads reasonable so a single file can't fill mobile RAM or bucket.
  static const int _maxResumeBytes = 10 * 1024 * 1024; // 10 MB
  static const int _maxImageBytes = 5 * 1024 * 1024; // 5 MB

  static Future<PickedAsset?> pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return null;
    }
    if (file.bytes!.lengthInBytes > _maxResumeBytes) {
      throw const XpServiceException(
        'CV is too large. Please upload a file under 10 MB.',
      );
    }

    final extension = (file.extension ?? '').toLowerCase();
    final mimeType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    if (mimeType == 'application/octet-stream') {
      throw const XpServiceException(
        'Unsupported file type. Upload a PDF, PNG, JPG, or WebP file.',
      );
    }

    return PickedAsset(
      bytes: file.bytes!,
      fileName: file.name,
      mimeType: mimeType,
    );
  }

  static Future<PickedAsset?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return null;
    }
    if (file.bytes!.lengthInBytes > _maxImageBytes) {
      throw const XpServiceException(
        'Image is too large. Please pick one under 5 MB.',
      );
    }

    final extension = (file.extension ?? '').toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    if (mimeType == 'application/octet-stream') {
      throw const XpServiceException(
        'Unsupported image type. Please pick a PNG, JPG, or WebP.',
      );
    }

    return PickedAsset(
      bytes: file.bytes!,
      fileName: file.name,
      mimeType: mimeType,
    );
  }

  // Legacy aliases kept for older call sites.
  static Future<PickedAsset?> pickLogo() => pickImage();
  static Future<PickedAsset?> pickProfileImage() => pickImage();

  static Future<String> uploadResume(String userId, PickedAsset asset) {
    return SupabaseService.uploadBinaryFile(
      bytes: asset.bytes,
      folder: 'resumes/$userId',
      fileName: asset.fileName,
      contentType: asset.mimeType,
    );
  }

  static Future<String> uploadLogo(String userId, PickedAsset asset) {
    final extension = _extensionForMime(asset.mimeType);
    return SupabaseService.uploadBinaryFile(
      bytes: asset.bytes,
      folder: 'logos/$userId',
      fileName: 'logo.$extension',
      contentType: asset.mimeType,
    );
  }

  static Future<String> uploadProfileImage(String userId, PickedAsset asset) {
    final extension = _extensionForMime(asset.mimeType);
    return SupabaseService.uploadBinaryFile(
      bytes: asset.bytes,
      folder: 'profiles/$userId',
      fileName: 'avatar.$extension',
      contentType: asset.mimeType,
    );
  }

  static String _extensionForMime(String mime) {
    return switch (mime) {
      'image/png' => 'png',
      'image/jpeg' => 'jpg',
      'image/webp' => 'webp',
      'application/pdf' => 'pdf',
      _ => 'bin',
    };
  }
}
