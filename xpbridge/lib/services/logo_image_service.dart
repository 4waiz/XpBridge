import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Utility helpers for picking, cropping, and encoding a company logo.
class LogoImageService {
  static const storageKey = 'startup_logo_base64';
  static final _picker = ImagePicker();

  static Future<Uint8List?> pickAndEdit({
    required BuildContext context,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return null;
    if (!context.mounted) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.png,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit logo',
          toolbarColor: Colors.black87,
          toolbarWidgetColor: Colors.white,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Edit logo',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        WebUiSettings(context: context, presentStyle: WebPresentStyle.dialog),
      ],
    );

    if (cropped == null) return null;
    return cropped.readAsBytes();
  }

  static String encode(Uint8List data) => base64Encode(data);

  static Uint8List? decode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }
}
