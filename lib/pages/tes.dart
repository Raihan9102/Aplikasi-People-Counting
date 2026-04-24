import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/detection_event.dart';
import '../models/live_status.dart';
import '../services/firebase_people_counter_service.dart';
import '../utils/format_helper.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Monitoring')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Preview kamera belum tersedia dari Firebase.\n\n'
                  'Jika Anda ingin tampilkan kamera asli di sini, backend perlu mengirim '
                  'snapshot_url atau stream_url ke database / API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<LiveStatus>(
            stream: FirebasePeopleCounterService.liveStatusStream(),
            builder: (context, snapshot) {
              final live = snapshot.data ?? LiveStatus.empty();
              return _RoomStatusCard(live: live);
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<DetectionEvent>>(
            stream: FirebasePeopleCounterService.recentEventsStream(limit: 120),
            builder: (context, snapshot) {
              final events = snapshot.data ?? [];
              return _RecentActivityCard(events: events);
            },
          ),
          const SizedBox(height: 16),
          Text(
            '5 Event Terakhir',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<DetectionEvent>>(
            stream: FirebasePeopleCounterService.recentEventsStream(limit: 5),
            builder: (context, snapshot) {
              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada event.'),
                  ),
                );
              }

              return Column(
                children: events.map((event) {
                  final color = event.isMasuk ? Colors.green : Colors.orange;
                  final icon = event.isMasuk
                      ? Icons.login_rounded
                      : Icons.logout_rounded;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(event.title),
                        subtitle: Text(
                          'Track ID ${event.trackId} • '
                          '${FormatHelper.formatTimestamp(event.detectedAt)}',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoomStatusCard extends StatelessWidget {
  final LiveStatus live;

  const _RoomStatusCard({required this.live});

  @override
  Widget build(BuildContext context) {
    final status = _roomStatus(live.orangDidalam);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: status.lightColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: status.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${live.orangDidalam} orang di dalam',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Terakhir terdeteksi ${FormatHelper.formatTimestamp(live.lastDetectedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  title: 'Masuk',
                  value: live.orangMasuk.toString(),
                  icon: Icons.login_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  title: 'Keluar',
                  value: live.orangKeluar.toString(),
                  icon: Icons.logout_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<DetectionEvent> events;

  const _RecentActivityCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final points = _buildHourlyPoints(events);
    final maxValue =
        points.fold<int>(0, (prev, item) => math.max(prev, item.value));
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hourly People Count',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: yLabels
                        .map(
                          (label) => Text(
                            '$label',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: _LineChartPainter(
                            points: points,
                            maxY: maxY.toDouble(),
                          ),
                          child: Container(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(points.length, (index) {
                          final point = points[index];
                          final showLabel =
                              index.isEven || index == points.length - 1;

                          return Expanded(
                            child: Text(
                              showLabel ? point.label : '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          );
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
}

class _MetricChip extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_HourlyPoint> points;
  final double maxY;

  const _LineChartPainter({
    required this.points,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const gridColor = Color(0xFFD9E2F1);
    const axisColor = Color(0xFFD9E2F1);
    const lineColor = Color(0xFF2563EB);
    const pointColor = Color(0xFF2F6BFF);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x332563EB), Color(0x052563EB)],
      ).createShader(Offset.zero & size);

    final pointPaint = Paint()..color = pointColor;
    final pointStrokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rowCount = 4;
    final colCount = math.max(points.length - 1, 1);

    for (var i = 0; i <= rowCount; i++) {
      final y = size.height * i / rowCount;
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    for (var i = 0; i <= colCount; i++) {
      final x = size.width * i / colCount;
      _drawDashedLine(
        canvas,
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final normalized =
          maxY <= 0 ? 0.0 : (points[i].value / maxY).clamp(0.0, 1.0);
      final y = size.height - (normalized * size.height);
      offsets.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    final fillPath = Path()..moveTo(offsets.first.dx, size.height);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);

    for (var i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final controlX = (current.dx + next.dx) / 2;

      linePath.cubicTo(
          controlX, current.dy, controlX, next.dy, next.dx, next.dy);
      fillPath.cubicTo(
          controlX, current.dy, controlX, next.dy, next.dx, next.dy);
    }

    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    for (final offset in offsets) {
      canvas.drawCircle(offset, 5.5, pointPaint);
      canvas.drawCircle(offset, 5.5, pointStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
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

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final totalDistance = (end - start).distance;
    final direction = (end - start) / totalDistance;
    double distance = 0;

    while (distance < totalDistance) {
      final currentStart = start + direction * distance;
      final currentEnd =
          start + direction * math.min(distance + dashWidth, totalDistance);
      canvas.drawLine(currentStart, currentEnd, paint);
      distance += dashWidth + dashSpace;
    }
  }
}

class _StatusInfo {
  final String label;
  final Color dotColor;
  final Color lightColor;

  const _StatusInfo({
    required this.label,
    required this.dotColor,
    required this.lightColor,
  });
}

class _HourlyPoint {
  final String label;
  final int value;

  const _HourlyPoint({required this.label, required this.value});
}

_StatusInfo _roomStatus(int peopleInside) {
  if (peopleInside >= 40) {
    return const _StatusInfo(
      label: 'Penuh',
      dotColor: Color(0xFFEF4444),
      lightColor: Color(0xFFFEE2E2),
    );
  }

  if (peopleInside >= 25) {
    return const _StatusInfo(
      label: 'Ramai',
      dotColor: Color(0xFFF59E0B),
      lightColor: Color(0xFFFFF3D6),
    );
  }

  return const _StatusInfo(
    label: 'Normal',
    dotColor: Color(0xFFF59E0B),
    lightColor: Color(0xFFFFF3D6),
  );
}

List<_HourlyPoint> _buildHourlyPoints(List<DetectionEvent> events) {
  const totalHours = 9;
  final now = DateTime.now();
  final firstHour =
      DateTime(now.year, now.month, now.day, now.hour - (totalHours - 1));
  final buckets = <DateTime, int>{};

  for (var i = 0; i < totalHours; i++) {
    final hour = DateTime(
      firstHour.year,
      firstHour.month,
      firstHour.day,
      firstHour.hour + i,
    );
    buckets[hour] = 0;
  }

  for (final event in events) {
    final detectedAt = _normalizeDetectedAt(event.detectedAt);
    final hourKey = DateTime(
      detectedAt.year,
      detectedAt.month,
      detectedAt.day,
      detectedAt.hour,
    );

    if (buckets.containsKey(hourKey)) {
      buckets[hourKey] = (buckets[hourKey] ?? 0) + 1;
    }
  }

  return buckets.entries.map((entry) {
    final hour = entry.key.hour.toString().padLeft(2, '0');
    return _HourlyPoint(label: '$hour:00', value: entry.value);
  }).toList();
}

int _niceMaxY(int value) {
  if (value <= 7) return 7;
  final step = 7;
  return ((value + step - 1) ~/ step) * step;
}

DateTime _normalizeDetectedAt(dynamic value) {
  if (value is DateTime) {
    return value.toLocal();
  }

  if (value is int) {
    final milliseconds = value < 100000000000 ? value * 1000 : value;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  }

  throw ArgumentError('Unsupported detectedAt type: ${value.runtimeType}');
}
