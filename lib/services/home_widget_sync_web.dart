import '../data/repository/vn_repository.dart';
import '../models/app_settings.dart';

/// Web has no home screen widget; this does nothing.
class HomeWidgetSync {
  HomeWidgetSync(VnRepository repo, AppSettings Function() settings);

  Future<void> sync() async {}
}
