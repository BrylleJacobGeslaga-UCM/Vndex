import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

/// Web: downloads the file like any browser download.
Future<bool> saveBackupFile(String fileName, Uint8List bytes) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  link.click();
  web.URL.revokeObjectURL(url);
  return true;
}

/// Opens the browser's file chooser. Returns null if you cancel.
Future<Uint8List?> pickBackupFile() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (files.isEmpty) return null;
  return files.first.readAsBytes();
}
