import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/vndb_api.dart';

/// One shared VNDB API client for the whole app.
final vndbApiProvider = Provider<VndbApi>((ref) => VndbApi());
