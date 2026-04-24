class AppSettings {
  final bool autoResetHarian;
  final bool notificationsEnabled;

  const AppSettings({
    required this.autoResetHarian,
    required this.notificationsEnabled,
  });

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      autoResetHarian: _toBool(map['auto_reset_harian']),
      notificationsEnabled: _toBool(map['notifications_enabled']),
    );
  }

  factory AppSettings.empty() {
    return const AppSettings(
      autoResetHarian: false,
      notificationsEnabled: false,
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}
