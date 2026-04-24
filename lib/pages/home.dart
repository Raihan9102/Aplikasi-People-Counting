import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/detection_event.dart';
import '../models/live_status.dart';
import '../services/firebase_people_counter_service.dart';
import '../utils/format_helper.dart';
import 'package:easy_localization/easy_localization.dart'; // Import localization

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  static const String flaskBaseUrl = "http://10.186.223.150:5000/captures/";

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reset_dialog_title'.tr()),
        content: Text('reset_dialog_content'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              await FirebasePeopleCounterService.resetDailyCount();
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('reset_success_msg'.tr())),
              );
            },
            child: Text('reset'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCaptureCard(DetectionEvent? latestEvent) {
    return _LiveCaptureCard(
      latestEvent: latestEvent,
      flaskBaseUrl: flaskBaseUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetConfirmation(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<List<DetectionEvent>>(
            stream: FirebasePeopleCounterService.recentEventsStream(limit: 1),
            builder: (context, snapshot) {
              final latestEvent =
                  (snapshot.data != null && snapshot.data!.isNotEmpty)
                      ? snapshot.data!.first
                      : null;
              return _buildLiveCaptureCard(latestEvent);
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<LiveStatus>(
            stream: FirebasePeopleCounterService.liveStatusStream(),
            builder: (context, snapshot) {
              final live = snapshot.data ?? LiveStatus.empty();

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'real_time_Status'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            onPressed: () => _showResetConfirmation(context),
                            icon: const Icon(Icons.restore_rounded,
                                color: Colors.blueAccent),
                            tooltip: 'daily_reset'.tr(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${'last_detected'.tr()}: ${FormatHelper.formatTimestamp(live.lastDetectedAt)}"
                            .tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricBox(
                              title: 'total_in'.tr(),
                              value: live.orangMasuk.toString(),
                              color: Colors.green,
                              icon: Icons.login_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricBox(
                              title: 'total_out'.tr(),
                              value: live.orangKeluar.toString(),
                              color: Colors.orange,
                              icon: Icons.logout_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MetricBox(
                        title: 'the_people_inside'.tr(),
                        value: live.orangDidalam.toString(),
                        color: Colors.blue,
                        icon: Icons.groups_rounded,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              );
            },
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
            'the_last_5_events'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<DetectionEvent>>(
            stream: FirebasePeopleCounterService.recentEventsStream(limit: 5),
            builder: (context, snapshot) {
              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('no_events_yet.'.tr()),
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

class _LiveCaptureCard extends StatefulWidget {
  final DetectionEvent? latestEvent;
  final String flaskBaseUrl;

  const _LiveCaptureCard({
    required this.latestEvent,
    required this.flaskBaseUrl,
  });

  @override
  State<_LiveCaptureCard> createState() => _LiveCaptureCardState();
}

class _LiveCaptureCardState extends State<_LiveCaptureCard> {
  // Unique bust key per render attempt — prevents Flutter's image cache
  // from serving a stale/404 copy of the same filename.
  int _cacheBust = DateTime.now().millisecondsSinceEpoch;
  bool _hasError = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  void didUpdateWidget(_LiveCaptureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New event from Firebase → reset error state and try fresh
    if (oldWidget.latestEvent?.imageName != widget.latestEvent?.imageName) {
      _retryTimer?.cancel();
      setState(() {
        _cacheBust = DateTime.now().millisecondsSinceEpoch;
        _hasError = false;
        _retryCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (!mounted) return;
      setState(() {
        _retryCount++;
        _cacheBust = DateTime.now().millisecondsSinceEpoch;
        _hasError = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageName = widget.latestEvent?.imageName;
    final hasImage = imageName != null && imageName.trim().isNotEmpty;

    // Always bust cache with a fresh millisecond timestamp so Flask serves
    // the latest file, not a browser/Flutter cached 404 response.
    final imageUrl =
        hasImage ? "${widget.flaskBaseUrl}$imageName?v=$_cacheBust" : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 240,
        color: Colors.black87,
        child: !hasImage
            ? Center()
            : _hasError
                ? _buildErrorPlaceholder()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl!,
                        // ValueKey forces Flutter to rebuild the widget and
                        // issue a new HTTP request on each retry/new event.
                        key: ValueKey('$imageName-$_cacheBust'),
                        fit: BoxFit.cover,
                        headers: const {
                          'Cache-Control': 'no-cache, no-store',
                          'Pragma': 'no-cache',
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Schedule a retry instead of showing a hard error
                          // immediately — the file may still be writing to disk.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            if (_retryCount < _maxRetries) {
                              _scheduleRetry();
                            } else {
                              setState(() => _hasError = true);
                            }
                          });
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          color: Colors.black54,
                          child: Text(
                            "${'LIVE_CAPTURE'.tr()}: ${widget.latestEvent!.typeLabel.toUpperCase()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined,
              color: Colors.white54, size: 40),
          const SizedBox(height: 8),
          Text(
            "text_for_camera".tr(),
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _cacheBust = DateTime.now().millisecondsSinceEpoch;
                _hasError = false;
                _retryCount = 0;
              });
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                Text("try_again".tr(), style: TextStyle(color: Colors.white)),
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
            'room_status'.tr(),
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
                  ],
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
            'recent_activity'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'hourly_people_count'.tr(),
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

class _MetricBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _MetricBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
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
  if (peopleInside >= 20) {
    return _StatusInfo(
      label: 'crowded'.tr(),
      dotColor: Color(0xFFEF4444),
      lightColor: Color(0xFFFEE2E2),
    );
  }

  if (peopleInside >= 10) {
    return _StatusInfo(
      label: 'warning'.tr(),
      dotColor: Color(0xFFF59E0B),
      lightColor: Color(0xFFFFF3D6),
    );
  }

  if (peopleInside == 0) {
    return _StatusInfo(
      label: 'empty'.tr(),
      dotColor: Color.fromARGB(255, 174, 183, 184),
      lightColor: Color(0xFFFFF3D6),
    );
  }

  return _StatusInfo(
    label: 'normal'.tr(),
    dotColor: Color.fromARGB(255, 83, 240, 16),
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

  throw ArgumentError(
      "${'unsupported_detectedat_type'.tr()}: ${value.runtimeType}");
}
