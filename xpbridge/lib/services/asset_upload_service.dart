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

    final extension = (file.extension ?? '').toLowerCase();
    final mimeType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    return PickedAsset(
      bytes: file.bytes!,
      fileName: file.name,
      mimeType: mimeType,
    );
  }

  static Future<PickedAsset?> pickLogo() async {
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

    final extension = (file.extension ?? '').toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    return PickedAsset(
      bytes: file.bytes!,
      fileName: file.name,
      mimeType: mimeType,
    );
  }

  static Future<PickedAsset?> pickProfileImage() async {
    return pickLogo(); // Reuse logo picking logic for profile images
  }

  static Future<String> uploadResume(
    String userId,
    PickedAsset asset,
  ) {
    return SupabaseService.uploadBinaryFile(
      bytes: asset.bytes,
      folder: 'resumes/$userId',
      fileName: asset.fileName,
      contentType: asset.mimeType,
    );
  }

  static Future<String> uploadLogo(
    String userId,
    PickedAsset asset,
  ) {
    return SupabaseService.uploadBinaryFile(
      bytes: asset.bytes,
      folder: 'logos/$userId',
      fileName: asset.fileName,
      contentType: asset.mimeType,
    );
  }

  static Future<String> uploadProfileImage(
    String userId,
    PickedAsset asset,
  ) {
    return SupabaseService.uploadBinaryFile(
      bytes: asset.bytes,
      folder: 'profiles/$userId',
      fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.${asset.fileName.split('.').last}',
      contentType: asset.mimeType,
    );
  }
}
