import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/bus_line.dart';
import '../../../../models/density_level.dart';
import '../../../../state/app_state.dart';
import '../widgets/density_badge.dart';
import '../widgets/report_sheet.dart';

class LinesTab extends StatelessWidget {
  const LinesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lines = app.lines;

    if (app.isLoading && lines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (app.error != null && lines.isEmpty) {
      return _LinesInfoState(
        title: 'Hat verileri alinamadi',
        message: app.error!,
        actionLabel: 'Tekrar dene',
        onAction: () => context.read<AppState>().refreshAll(),
      );
    }

    if (!app.isLoading && lines.isEmpty) {
      return _LinesInfoState(
        title: 'Hat verisi yok',
        message: 'Sunucudan henuz gosterilecek bir hat kaydi gelmedi.',
        actionLabel: 'Yenile',
        onAction: () => context.read<AppState>().refreshAll(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().refreshAll(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: lines.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final line = lines[index];
          final matching = app.reports.where((r) => r.busLineId == line.id);
          final latest = matching.isEmpty ? null : matching.first;

          return _LineCard(
            line: line,
            latestStopName: latest?.busStopName,
            latestDensity: latest?.densityLevel,
            onReport: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => ReportSheet(prefillLine: line),
            ),
          );
        },
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.line,
    required this.onReport,
    this.latestStopName,
    this.latestDensity,
  });

  final BusLine line;
  final String? latestStopName;
  final DensityLevel? latestDensity;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final density = latestDensity;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.name.trim().isEmpty ? 'Isimsiz hat' : line.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (density != null) DensityBadge(level: density),
              ],
            ),
            if (line.routeDescription.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(line.routeDescription),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    latestStopName == null || latestStopName!.trim().isEmpty
                        ? 'Son rapor yok'
                        : 'Son durak: $latestStopName',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.add_chart),
                  label: const Text('Raporla'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinesInfoState extends StatelessWidget {
  const _LinesInfoState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
