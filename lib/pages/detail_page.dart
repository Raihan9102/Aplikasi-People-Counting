import 'package:flutter/material.dart';

import '../models/detection_event.dart';
import '../utils/format_helper.dart';

class DetailPage extends StatelessWidget {
  static const routeName = '/detail-page';

  //final DetectionEvent event;

  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)!.settings.arguments as DetectionEvent;
    final color = event.isMasuk ? Colors.green : Colors.orange;
    final icon = event.isMasuk ? Icons.login_rounded : Icons.logout_rounded;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track ID: ${event.trackId}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _InfoRow(label: 'Jenis Event', value: event.typeLabel),
                  _InfoRow(
                    label: 'Confidence',
                    value: '${(event.confidence * 100).toStringAsFixed(0)}%',
                  ),
                  _InfoRow(
                    label: 'Waktu Deteksi',
                    value: FormatHelper.formatTimestamp(event.detectedAt),
                  ),
                  _InfoRow(
                    label: 'Unix Timestamp',
                    value: event.detectedAt.toString(),
                  ),
                  _InfoRow(label: 'Event ID', value: event.id),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                event.isMasuk
                    ? 'Objek terdeteksi melintasi garis ke arah masuk.'
                    : 'Objek terdeteksi melintasi garis ke arah keluar.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
