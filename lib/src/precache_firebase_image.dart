import 'package:firebase_core/firebase_core.dart';

import 'cache_refresh_strategy.dart';
import 'firebase_image.dart';

Future<void> precacheFirebaseImage(String location,
    {FirebaseApp firebaseApp,
    int maxSizeBytes = 2500 * 1000,
    CacheRefreshStrategy cacheRefreshStrategy =
        CacheRefreshStrategy.BY_METADATA_DATE}) async {
  assert(location != null);
  final image = FirebaseImage(location, firebaseApp: firebaseApp);
  await image.precache();
}
