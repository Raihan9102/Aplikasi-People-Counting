class LiveStatus {
  final int orangMasuk;
  final int orangKeluar;
  final int orangDidalam;
  final int lastDetectedAt;

  const LiveStatus({
    required this.orangMasuk,
    required this.orangKeluar,
    required this.orangDidalam,
    required this.lastDetectedAt,
  });

  factory LiveStatus.fromMap(Map<dynamic, dynamic> map) {
    return LiveStatus(
      orangMasuk: map['orang_masuk'] ?? 0,
      orangKeluar: map['orang_keluar'] ?? 0,
      orangDidalam: map['orang_didalam'] ?? 0,
      lastDetectedAt: map['last_detected_at'] ?? 0,
    );
  }

  factory LiveStatus.empty() {
    return const LiveStatus(
      orangMasuk: 0,
      orangKeluar: 0,
      orangDidalam: 0,
      lastDetectedAt: 0,
    );
  }

  static int map(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
