import 'package:easy_localization/easy_localization.dart';

class DetectionEvent {
  final String id;
  final String type;
  final int trackId;
  final double confidence;
  final int detectedAt;
  final String?
      imageName; // TAMBAHAN: Properti untuk menampung nama file gambar

  const DetectionEvent({
    required this.id,
    required this.type,
    required this.trackId,
    required this.confidence,
    required this.detectedAt,
    this.imageName, // Masukkan ke constructor
  });

  bool get isMasuk => type.toLowerCase() == 'masuk';

  String get title => isMasuk ? 'Orang Masuk' : 'Orang Keluar';

  String get typeLabel => isMasuk ? 'Masuk'.tr() : 'Keluar'.tr();

  factory DetectionEvent.fromMap(String id, Map<dynamic, dynamic> map) {
    return DetectionEvent(
      id: id,
      type: (map['type'] ?? '').toString(),
      trackId: _toInt(map['track_id']),
      confidence: _toDouble(map['confidence']),
      detectedAt: _toInt(map['detected_at']),
      imageName: map['image_name']
          ?.toString(), // TAMBAHAN: Ambil data image_name dari Firebase
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
