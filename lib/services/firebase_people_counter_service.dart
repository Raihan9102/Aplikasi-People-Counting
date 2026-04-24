import 'package:firebase_database/firebase_database.dart';

import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/daily_history.dart';
import '../models/detection_event.dart';
import '../models/live_status.dart';

class FirebasePeopleCounterService {
  FirebasePeopleCounterService._();

  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ─── Broadcast stream cache ───────────────────────────────────────────────
  // Firebase .onValue adalah single-subscription stream.
  // Kita convert sekali ke broadcast dan cache-nya agar semua listener
  // (termasuk beberapa StreamBuilder) bisa subscribe tanpa error
  // "Bad state: Stream has already been listened to".

  static Stream<LiveStatus>? _liveStatusStream;
  static final Map<int, Stream<List<DetectionEvent>>> _recentEventsCache = {};

  // ─── Live Status ──────────────────────────────────────────────────────────
  static Stream<LiveStatus> liveStatusStream() {
    _liveStatusStream ??= _database.ref('live_status').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return LiveStatus.empty();
      return LiveStatus.fromMap(Map<dynamic, dynamic>.from(value));
    }).asBroadcastStream();

    return _liveStatusStream!;
  }

  // ─── Recent Events ────────────────────────────────────────────────────────
  // Setiap limit unik punya satu broadcast stream yang di-cache.
  // limit:1, limit:5, limit:120 masing-masing subscribe sekali ke Firebase,
  // tapi bisa dipakai oleh banyak StreamBuilder sekaligus.
  static Stream<List<DetectionEvent>> recentEventsStream({int limit = 20}) {
    if (_recentEventsCache.containsKey(limit)) {
      return _recentEventsCache[limit]!;
    }

    final stream = _database
        .ref('events')
        .orderByKey()
        .limitToLast(limit)
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return <DetectionEvent>[];

      final rawMap = Map<dynamic, dynamic>.from(value);
      final items = rawMap.entries.map((entry) {
        return DetectionEvent.fromMap(
          entry.key.toString(),
          Map<dynamic, dynamic>.from(entry.value),
        );
      }).toList();

      items.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      return items;
    }).asBroadcastStream();

    _recentEventsCache[limit] = stream;
    return stream;
  }

  // ─── Daily History ────────────────────────────────────────────────────────
  static Stream<List<DailyHistory>> dailyHistoryStream() {
    return _database.ref('history_daily').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return <DailyHistory>[];

      final rawMap = Map<dynamic, dynamic>.from(value);
      final items = rawMap.entries.map((entry) {
        return DailyHistory.fromMap(
          entry.key.toString(),
          Map<dynamic, dynamic>.from(entry.value),
        );
      }).toList();

      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    }).asBroadcastStream();
  }

  // ─── User ─────────────────────────────────────────────────────────────────
  static Stream<AppUser> userStream(String userId) {
    return _database.ref('users/$userId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return AppUser.empty();
      return AppUser.fromMap(userId, Map<dynamic, dynamic>.from(value));
    }).asBroadcastStream();
  }

  // ─── Settings ─────────────────────────────────────────────────────────────
  static Stream<AppSettings> settingsStream() {
    return _database.ref('settings').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return AppSettings.empty();
      return AppSettings.fromMap(Map<dynamic, dynamic>.from(value));
    }).asBroadcastStream();
  }

  // ─── Reset ────────────────────────────────────────────────────────────────
  static Future<void> resetDailyCount() async {
    await _database.ref('live_status').update({
      'orang_masuk': 0,
      'orang_keluar': 0,
      'orang_didalam': 0,
      'last_detected_at': ServerValue.timestamp,
    });
  }
}
