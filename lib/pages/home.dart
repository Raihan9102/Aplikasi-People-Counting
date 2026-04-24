import 'package:flutter/material.dart';

import '../models/detection_event.dart';
import '../models/live_status.dart';
import '../services/firebase_people_counter_service.dart';
import '../utils/format_helper.dart';
import 'detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard People Counting')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<LiveStatus>(
            stream: FirebasePeopleCounterService.liveStatusStream(),
            builder: (context, snapshot) {
              final live = snapshot.data ?? LiveStatus.empty();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Realtime',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last detected: ${FormatHelper.formatTimestamp(live.lastDetectedAt)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricBox(
                              title: 'Masuk',
                              value: live.orangMasuk.toString(),
                              color: Colors.green,
                              icon: Icons.login_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricBox(
                              title: 'Keluar',
                              value: live.orangKeluar.toString(),
                              color: Colors.orange,
                              icon: Icons.logout_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MetricBox(
                        title: 'Orang di Dalam',
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
          const SizedBox(height: 20),
          Text('Event Terbaru', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          StreamBuilder<List<DetectionEvent>>(
            stream: FirebasePeopleCounterService.recentEventsStream(limit: 10),
            builder: (context, snapshot) {
              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada event terbaru.'),
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
                          '${(event.confidence * 100).toStringAsFixed(0)}% • '
                          '${FormatHelper.formatRelative(event.detectedAt)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            DetailPage.routeName,
                            arguments: event,
                          );
                        },
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
