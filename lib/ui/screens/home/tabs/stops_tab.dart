import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/app_state.dart';
import '../widgets/density_badge.dart';
import '../widgets/report_sheet.dart';

class StopsTab extends StatelessWidget {
  const StopsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final stops = app.stops;

    if (app.isLoading && stops.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (app.error != null && stops.isEmpty) {
      return _StopsInfoState(
        title: 'Durak verileri alinamadi',
        message: app.error!,
        actionLabel: 'Tekrar dene',
        onAction: () => context.read<AppState>().refreshAll(),
      );
    }

    if (!app.isLoading && stops.isEmpty) {
      return _StopsInfoState(
        title: 'Durak verisi yok',
        message: 'Sunucudan henuz gosterilecek bir durak kaydi gelmedi.',
        actionLabel: 'Yenile',
        onAction: () => context.read<AppState>().refreshAll(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().refreshAll(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: stops.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final stop = stops[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name.trim().isEmpty ? 'Bilinmeyen durak' : stop.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stop.busLines.isEmpty
                              ? 'Hat yok'
                              : 'Hatlar: ${stop.busLines.take(4).join(', ')}${stop.busLines.length > 4 ? '…' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (stop.currentDensity != null) DensityBadge(level: stop.currentDensity!),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Rapor gönder',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => ReportSheet(prefillStopId: stop.id),
                    ),
                    icon: const Icon(Icons.add_chart),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StopsInfoState extends StatelessWidget {
  const _StopsInfoState({
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
