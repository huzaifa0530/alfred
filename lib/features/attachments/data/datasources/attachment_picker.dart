import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class AttachmentPicker {
  final ImagePicker _imagePicker;

  AttachmentPicker({
    ImagePicker? imagePicker,
  }) : _imagePicker =
            imagePicker ?? ImagePicker();

  Future<File?> pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  Future<File?> pickFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  Future<File?> pickFile() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: false,
    );

    if (result.isEmpty) {
      return null;
    }

    final path = result.single.path;

    if (path == null) {
      return null;
    }

    return File(path);
  }
}