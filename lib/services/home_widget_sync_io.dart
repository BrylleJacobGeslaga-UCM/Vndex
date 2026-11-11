import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/utils/format.dart';
import '../data/repository/vn_repository.dart';
import '../models/app_settings.dart';
import '../models/vn_status.dart';

/// Sends "Currently playing" to the Android home screen widget.
///
/// Saves a few text values (count, up to 3 titles and dates) plus the
/// newest VN's cover as a file, then asks Android to redraw the widget.
/// The Kotlin side (VndexWidgetProvider.kt) reads the same keys.
class HomeWidgetSync {
  HomeWidgetSync(this._repo, this._settings);

  final VnRepository _repo;
  final AppSettings Function() _settings;

  static const _androidName = 'VndexWidgetProvider';
  static const _maxRows = 3;

  Future<void> sync() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final settings = _settings();
      // Most recently changed first, same as the Playing tab's default.
      final playing = await _repo.getList(VnStatus.playing);
      final top = playing.take(_maxRows).toList();

      // Saved as strings: simplest to read back on the Kotlin side.
      await HomeWidget.saveWidgetData<String>('playing_count', '${playing.length}');
      for (var i = 0; i < _maxRows; i++) {
        final e = i < top.length ? top[i] : null;
        final started = e?.entry.startedAt;
        await HomeWidget.saveWidgetData<String>('title_${i + 1}', e?.vn.title ?? '');
        await HomeWidget.saveWidgetData<String>(
          'sub_${i + 1}',
          e == null
              ? ''
              : started != null
                  ? 'Started ${formatDate(started, settings.dateStyle)}'
                  : 'Added ${formatDate(e.entry.addedAt, settings.dateStyle)}',
        );
      }

      // Cover of the first VN, unless it should be blurred.
      final first = top.isEmpty ? null : top.first.vn;
      final showCover = first?.imageUrl != null &&
          !(settings.blurSensitiveCovers && first!.isCoverSensitive);
      final coverPath = showCover ? await _saveCover(first!.imageUrl!) : null;
      await HomeWidget.saveWidgetData<String>('cover_path', coverPath ?? '');

      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (e) {
      // The widget is a nice extra; never let it break the app.
      debugPrint('Home widget update failed: $e');
    }
  }

  /// Downloads the cover once per URL into the app's private folder.
  Future<String?> _saveCover(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'widget_cover.jpg'));
    final urlFile = File(p.join(dir.path, 'widget_cover.url'));

    // Same cover as last time? Reuse it.
    if (await file.exists() &&
        await urlFile.exists() &&
        await urlFile.readAsString() == url) {
      return file.path;
    }

    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    await file.writeAsBytes(res.bodyBytes, flush: true);
    await urlFile.writeAsString(url, flush: true);
    return file.path;
  }
}
