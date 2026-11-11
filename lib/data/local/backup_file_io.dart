import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Android: opens the system "Save as" screen (Downloads, Google Drive…).
/// Returns false if you cancel.
Future<bool> saveBackupFile(String fileName, Uint8List bytes) async {
  final saved = await FilePicker.saveFile(
    dialogTitle: 'Save Vndex backup',
    fileName: fileName,
    bytes: bytes,
  );
  return saved != null;
}

/// Lets you pick a backup file. Returns null if you cancel.
Future<Uint8List?> pickBackupFile() async {
  // FileType.any: some phones grey out .json files with a custom filter.
  final files = await FilePicker.pickFiles(type: FileType.any);
  if (files.isEmpty) return null;
  return files.first.readAsBytes();
}
