class DailyHistory {
  final String date;
  final int totalMasuk;
  final int totalKeluar;
  final int updatedAt;

  const DailyHistory({
    required this.date,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.updatedAt,
  });

  factory DailyHistory.fromMap(String date, Map<dynamic, dynamic> map) {
    return DailyHistory(
      date: date,
      totalMasuk: _toInt(map['total_masuk']),
      totalKeluar: _toInt(map['total_keluar']),
      updatedAt: _toInt(map['updated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
