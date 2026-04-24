// lib/utils/format_helper.dart
import 'package:intl/intl.dart';

class FormatHelper {
  // Memformat timestamp (detik) ke format lengkap (Contoh: 22 Apr 2026, 08:30:00)
  static String formatTimestamp(int unixSeconds) {
    if (unixSeconds <= 0) return '-';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000,
      isUtc: true,
    ).toLocal();

    return DateFormat('dd MMM yyyy, HH:mm:ss').format(dateTime);
  }

  // BARU: Memformat timestamp (detik) hanya jam saja (Contoh: 08:30)
  // Digunakan untuk bagian "Updated: ..." di History Page
  static String formatTime(int unixSeconds) {
    if (unixSeconds <= 0) return '--:--';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000,
      isUtc: true,
    ).toLocal();

    return DateFormat('HH:mm').format(dateTime);
  }

  // BARU: Memformat String tanggal (Contoh: "2026-04-22" menjadi "22 Apr 2026")
  static String formatDate(String dateStr) {
    try {
      // Mencoba parse string YYYY-MM-DD
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      // Jika gagal (misal data bukan format tanggal), kembalikan apa adanya
      return dateStr;
    }
  }

  // Memformat waktu relatif (Contoh: 5 menit lalu)
  static String formatRelative(int unixSeconds) {
    if (unixSeconds <= 0) return '-';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000,
      isUtc: true,
    ).toLocal();

    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return '${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
