import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/daily_history.dart';
import '../models/detection_event.dart';
import '../services/firebase_people_counter_service.dart';
import '../utils/format_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // Helper untuk melengkapi data agar tidak ada tanggal yang melompat (Daily Summary)
  List<DailyHistory> _fillMissingDays(
      List<DailyHistory> existingData, int daysCount) {
    List<DailyHistory> filledList = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < daysCount; i++) {
      DateTime targetDate = now.subtract(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(targetDate);
      var existing = existingData.where((e) => e.date == formattedDate);
      if (existing.isNotEmpty) {
        filledList.add(existing.first);
      } else {
        filledList.add(DailyHistory(
          date: formattedDate,
          totalMasuk: 0,
          totalKeluar: 0,
          updatedAt: targetDate.millisecondsSinceEpoch ~/ 1000,
        ));
      }
    }
    return filledList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('analytics_&_history'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<DailyHistory>>(
        stream: FirebasePeopleCounterService.dailyHistoryStream(),
        builder: (context, snapshot) {
          final rawItems = snapshot.data ?? [];
          // Trend mingguan (7 hari terakhir dari hari ini)
          final weeklyData = _fillMissingDays(rawItems, 7).reversed.toList();
          // Summary harian (30 hari terakhir)
          final dailySummaryData = _fillMissingDays(rawItems, 30);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("today_activity".tr(),
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<List<DetectionEvent>>(
                  stream: FirebasePeopleCounterService.recentEventsStream(
                      limit: 150),
                  builder: (context, eventSnapshot) {
                    final events = eventSnapshot.data ?? [];
                    return _RecentActivityChart(events: events);
                  },
                ),
                const SizedBox(height: 24),
                Text("weekly_trend".tr(),
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildWeeklyTrend(weeklyData, context),
                const SizedBox(height: 24),
                Text("daily_summary".tr(),
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildDailySummaryList(dailySummaryData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyTrend(List<DailyHistory> data, BuildContext context) {
    int maxVal =
        data.isEmpty ? 1 : data.map((e) => e.totalMasuk).reduce(math.max);
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((e) {
            double barHeight = (e.totalMasuk / maxVal) * 90;
            DateTime dateObj = DateTime.parse(e.date);

            // Lokalisasi nama hari (Sen, Sel... / Mon, Tue...)
            String dayName =
                DateFormat('E', context.locale.toString()).format(dateObj);

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(e.totalMasuk.toString(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  width: 25,
                  height: barHeight.clamp(4, 90),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: e.totalMasuk > 0
                          ? [Colors.blue.shade400, Colors.blue.shade100]
                          : [Colors.grey.shade200, Colors.grey.shade50],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(dayName,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd/MM').format(dateObj),
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDailySummaryList(List<DailyHistory> items) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isToday = item.date == todayStr;
        String statusLabel;
        Color statusColor;
        // Logika Status Berdasarkan Data Summary Harian
        if (item.totalMasuk == 0) {
          statusLabel = "empty".tr();
          statusColor = Colors.grey;
        } else if (item.totalMasuk <= 10) {
          statusLabel = "normal".tr();
          statusColor = Colors.green;
        } else if (item.totalMasuk <= 20) {
          statusLabel = "warning".tr();
          statusColor = Colors.orange;
        } else {
          statusLabel = "crowded".tr();
          statusColor = Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              // Logo Kalender: Hijau jika hari ini, Biru jika hari lain
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color:
                        (isToday ? Colors.green : Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.calendar_today,
                    color: isToday ? Colors.green : Colors.blue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(FormatHelper.formatDate(item.date),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      item.totalMasuk > 0
                          ? "${'update'.tr()}: ${FormatHelper.formatTime(item.updatedAt)}"
                              .tr()
                          : "no_activity".tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${item.totalMasuk}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142))),
                  Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentActivityChart extends StatelessWidget {
  final List<DetectionEvent> events;
  const _RecentActivityChart({required this.events});

  @override
  Widget build(BuildContext context) {
    final points = _buildHourlyPoints(events);
    final maxValue =
        points.isEmpty ? 0 : points.map((p) => p.value).reduce(math.max);
    final maxY = _niceMaxY(maxValue);
    final yLabels = [
      maxY,
      (maxY * 3 / 4).round(),
      (maxY / 2).round(),
      (maxY / 4).round(),
      0
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('hourly_people_count'.tr(),
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: yLabels
                      .map((l) => Text('$l',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))))
                      .toList(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          // Menggunakan painter yang sudah diperbarui dengan kurva
                          painter: _CurveLineChartPainter(
                              points: points, maxY: maxY.toDouble()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(points.length, (index) {
                          final showLabel =
                              index % 2 == 0 || index == points.length - 1;
                          return Expanded(
                              child: Text(showLabel ? points[index].label : '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))));
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_HourlyPoint> _buildHourlyPoints(List<DetectionEvent> events) {
    const totalHours = 9;
    final now = DateTime.now();
    final firstHour =
        DateTime(now.year, now.month, now.day, now.hour - (totalHours - 1));
    final buckets = <DateTime, int>{};
    for (var i = 0; i < totalHours; i++) {
      buckets[DateTime(firstHour.year, firstHour.month, firstHour.day,
          firstHour.hour + i)] = 0;
    }
    for (final event in events) {
      final dt = DateTime.fromMillisecondsSinceEpoch(event.detectedAt * 1000)
          .toLocal();
      final key = DateTime(dt.year, dt.month, dt.day, dt.hour);
      if (buckets.containsKey(key)) buckets[key] = (buckets[key] ?? 0) + 1;
    }
    return buckets.entries
        .map((e) => _HourlyPoint(
            label: '${e.key.hour.toString().padLeft(2, '0')}:00',
            value: e.value))
        .toList();
  }

  int _niceMaxY(int value) => (value <= 7) ? 7 : ((value + 6) ~/ 7) * 7;
}

// --- PAINTER YANG DIPERBARUI DENGAN KURVA MELENGKUNG ---

class _CurveLineChartPainter extends CustomPainter {
  final List<_HourlyPoint> points;
  final double maxY;
  _CurveLineChartPainter({required this.points, required this.maxY});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Warna untuk grid dan sumbu
    final paintGrid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    double dx = size.width / (points.length - 1);

    // 1. Gambar Grid Horizontal (Putus-putus)
    for (int i = 0; i <= 4; i++) {
      double y = size.height * i / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // 2. Gambar Grid Vertikal (Putus-putus)
    for (int i = 0; i < points.length; i++) {
      double x = i * dx;
      _drawDashedVerticalLine(
          canvas, Offset(x, 0), Offset(x, size.height), paintGrid);
    }

    // Hitung koordinat titik-titik (Offset)
    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      double x = i * dx;
      // Normalisasi nilai Y agar sesuai dengan skala maxY
      double normalizedY = maxY <= 0 ? 0.0 : (points[i].value / maxY);
      double y = size.height - (normalizedY * size.height);
      offsets.add(Offset(x, y));
    }

    // 3. Area Fill (Gradasi di bawah kurva)
    final paintFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Gradasi dari biru transparan ke sangat transparan
        colors: [Color(0x332563EB), Color(0x052563EB)],
      ).createShader(Offset.zero & size);

    final fillPath = Path();
    fillPath.moveTo(
        offsets.first.dx, size.height); // Mulai dari pojok kiri bawah
    fillPath.lineTo(
        offsets.first.dx, offsets.first.dy); // Naik ke titik pertama

    // Gambar kurva untuk area fill
    for (var i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      // Hitung control point di tengah-tengah untuk membuat bezier curve
      final controlX = (current.dx + next.dx) / 2;

      fillPath.cubicTo(
          controlX,
          current.dy, // Control point 1 (mengikuti tinggi titik saat ini)
          controlX,
          next.dy, // Control point 2 (mengikuti tinggi titik selanjutnya)
          next.dx,
          next.dy // Titik tujuan
          );
    }
    // Tutup path ke pojok kanan bawah
    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, paintFill);

    // 4. Garis Utama (Kurva Melengkung)
    final paintLine = Paint()
      ..color = const Color(0xFF2563EB) // Warna biru utama
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round // Ujung garis membulat
      ..strokeJoin = StrokeJoin.round; // Sambungan garis membulat

    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);

    // Gambar kurva untuk garis utama
    for (var i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final controlX = (current.dx + next.dx) / 2;

      // Menggunakan cubicTo untuk membuat kurva melengkung mulus (Cubic Bezier)
      linePath.cubicTo(
          controlX,
          current.dy, // Control point 1
          controlX,
          next.dy, // Control point 2
          next.dx,
          next.dy // Titik tujuan
          );
    }
    canvas.drawPath(linePath, paintLine);
  }

  // Fungsi pembantu untuk menggambar garis horizontal putus-putus
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4;
    const dashSpace = 4;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
          Offset(startX, p1.dy), Offset(startX + dashWidth, p1.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  // Fungsi pembantu untuk menggambar garis vertikal putus-putus
  void _drawDashedVerticalLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashHeight = 4;
    const dashSpace = 4;
    double startY = p1.dy;
    while (startY < p2.dy) {
      canvas.drawLine(
          Offset(p1.dx, startY), Offset(p1.dx, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _CurveLineChartPainter oldDelegate) {
    // Repaint jika data berubah
    if (oldDelegate.maxY != maxY ||
        oldDelegate.points.length != points.length) {
      return true;
    }
    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].value != points[i].value ||
          oldDelegate.points[i].label != points[i].label) {
        return true;
      }
    }
    return false;
  }
}

class _HourlyPoint {
  final String label;
  final int value;
  _HourlyPoint({required this.label, required this.value});
}
