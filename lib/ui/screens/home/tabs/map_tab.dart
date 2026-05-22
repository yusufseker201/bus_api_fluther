import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../models/bus_line.dart';
import '../../../../models/bus_stop.dart';
import '../../../../models/density_level.dart';
import '../../../../models/density_report.dart';
import '../../../../state/app_state.dart';
import '../widgets/density_badge.dart';
import '../widgets/report_sheet.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  static const _center = LatLng(37.5753, 36.9228);
  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgentPackageName = 'com.kahramanmaras.bus_density_mobile';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final stops = app.stops.where((s) => s.latitude != null && s.longitude != null).toList();

    if (kIsWeb) {
      return RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshAll(),
        child: _WebMapExperience(
          stops: stops,
          lines: app.lines,
          reports: app.reports,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = math.max(420.0, constraints.maxHeight + 1);

        return RefreshIndicator(
          onRefresh: () => context.read<AppState>().refreshAll(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: minHeight,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: _center,
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _osmTileUrl,
                      userAgentPackageName: _userAgentPackageName,
                    ),
                    MarkerLayer(
                      markers: [
                        for (final stop in stops)
                          Marker(
                            point: LatLng(stop.latitude!, stop.longitude!),
                            width: 46,
                            height: 46,
                            child: GestureDetector(
                              onTap: () => _openStopSheet(
                                context,
                                stop: stop,
                                lines: app.lines,
                                reports: app.reports,
                              ),
                              child: _StopMarker(level: stop.currentDensity),
                            ),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WebMapExperience extends StatelessWidget {
  const _WebMapExperience({
    required this.stops,
    required this.lines,
    required this.reports,
  });

  final List<BusStop> stops;
  final List<BusLine> lines;
  final List<DensityReport> reports;

  @override
  Widget build(BuildContext context) {
    final previewStops = stops.take(6).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFFF8FAFC),
            Color(0xFFFFF7ED),
          ],
        ),
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _MapHeroCard(
            stops: stops,
            lines: lines,
            reports: reports,
          ),
          const SizedBox(height: 18),
          Text(
            'Hızlı erişim durakları',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (previewStops.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Haritada gösterecek konumlu durak bulunamadı.'),
              ),
            )
          else
            for (final stop in previewStops)
              Card(
                child: ListTile(
                  leading: _StopMarker(level: stop.currentDensity),
                  title: Text(stop.name),
                  subtitle: Text(
                    stop.busLines.isEmpty
                        ? 'Bu durakta otobüs bilgisi yok'
                        : 'Otobüsler: ${stop.busLines.take(3).join(', ')}${stop.busLines.length > 3 ? '…' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openStopSheet(
                    context,
                    stop: stop,
                    lines: lines,
                    reports: reports,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _MapHeroCard extends StatelessWidget {
  const _MapHeroCard({
    required this.stops,
    required this.lines,
    required this.reports,
  });

  final List<BusStop> stops;
  final List<BusLine> lines;
  final List<DensityReport> reports;

  @override
  Widget build(BuildContext context) {
    final stats = _MapStats.fromStops(stops);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.travel_explore, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kahramanmaraş durak haritası',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duraklara dokun, içinden geçen otobüsleri gör ve anında şikayet bildir.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(label: 'Konumlu durak', value: '${stops.length}'),
              _StatChip(label: 'Aktif hat', value: '${lines.length}'),
              _StatChip(label: 'Canlı bildirim', value: '${reports.length}'),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final mapHeight = math.max(320.0, constraints.maxWidth * 0.65);
              return SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFB9E6FF),
                              Color(0xFFE4F4FF),
                              Color(0xFFFDF1DD),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CustomPaint(
                          painter: _KahramanmarasBackdropPainter(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: _MapLegend(stats: stats),
                    ),
                    for (final stop in stops)
                      _PositionedStopMarker(
                        stop: stop,
                        stats: stats,
                        onTap: () => _openStopSheet(
                          context,
                          stop: stop,
                          lines: lines,
                          reports: reports,
                        ),
                      ),
                    Positioned(
                      right: 18,
                      bottom: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Merkez odak'),
                            SizedBox(height: 4),
                            Text('Kahramanmaraş'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PositionedStopMarker extends StatelessWidget {
  const _PositionedStopMarker({
    required this.stop,
    required this.stats,
    required this.onTap,
  });

  final BusStop stop;
  final _MapStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dx = stats.normalizeLongitude(stop.longitude);
    final dy = stats.normalizeLatitude(stop.latitude);

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = 26 + dx * (constraints.maxWidth - 70);
          final top = 34 + dy * (constraints.maxHeight - 90);

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTap: onTap,
                  child: Column(
                    children: [
                      _StopMarker(level: stop.currentDensity),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 78),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 12,
                                offset: Offset(0, 6),
                                color: Color(0x22000000),
                              ),
                            ],
                          ),
                          child: Text(
                            stop.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.stats});

  final _MapStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durak yoğunluğu',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const _LegendRow(color: Color(0xFF2563EB), label: 'Bildirim bekliyor'),
          const _LegendRow(color: Color(0xFF0F7A3D), label: 'Boş'),
          const _LegendRow(color: Color(0xFFB08900), label: 'Orta'),
          const _LegendRow(color: Color(0xFFB00020), label: 'Kalabalık'),
          const _LegendRow(color: Color(0xFF111827), label: 'Dolu'),
          const SizedBox(height: 8),
          Text(
            'Harita alanı: ${stats.cityLabel}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label),
        ],
      ),
    );
  }
}

class _KahramanmarasBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = const Color(0x80FFFFFF);
    final border = Paint()
      ..color = const Color(0x553B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final road = Paint()
      ..color = const Color(0xAA2B6EA6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final districtFill = Paint()..color = const Color(0x33FFFFFF);

    final shape = ui.Path()
      ..moveTo(size.width * 0.10, size.height * 0.16)
      ..lineTo(size.width * 0.31, size.height * 0.08)
      ..lineTo(size.width * 0.52, size.height * 0.11)
      ..lineTo(size.width * 0.80, size.height * 0.18)
      ..lineTo(size.width * 0.90, size.height * 0.34)
      ..lineTo(size.width * 0.85, size.height * 0.58)
      ..lineTo(size.width * 0.76, size.height * 0.76)
      ..lineTo(size.width * 0.57, size.height * 0.88)
      ..lineTo(size.width * 0.30, size.height * 0.82)
      ..lineTo(size.width * 0.12, size.height * 0.66)
      ..close();

    canvas.drawPath(shape, land);
    canvas.drawPath(shape, border);

    final districtA = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.22,
      size.width * 0.26,
      size.height * 0.18,
    );
    final districtB = Rect.fromLTWH(
      size.width * 0.50,
      size.height * 0.26,
      size.width * 0.22,
      size.height * 0.16,
    );
    final districtC = Rect.fromLTWH(
      size.width * 0.34,
      size.height * 0.54,
      size.width * 0.28,
      size.height * 0.18,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(districtA, const Radius.circular(18)),
      districtFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(districtB, const Radius.circular(18)),
      districtFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(districtC, const Radius.circular(18)),
      districtFill,
    );

    final roadOne = ui.Path()
      ..moveTo(size.width * 0.12, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.34,
        size.width * 0.58,
        size.height * 0.29,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.24,
        size.width * 0.88,
        size.height * 0.18,
      );
    canvas.drawPath(roadOne, road);

    final roadTwo = ui.Path()
      ..moveTo(size.width * 0.18, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.62,
        size.width * 0.68,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.66,
        size.width * 0.90,
        size.height * 0.58,
      );
    canvas.drawPath(roadTwo, road);

    final roadThree = ui.Path()
      ..moveTo(size.width * 0.34, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.42,
        size.width * 0.34,
        size.height * 0.74,
      );
    canvas.drawPath(roadThree, road..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StopDetailsSheet extends StatelessWidget {
  const _StopDetailsSheet({
    required this.stop,
    required this.lines,
    required this.reports,
  });

  final BusStop stop;
  final List<BusLine> lines;
  final List<DensityReport> reports;

  @override
  Widget build(BuildContext context) {
    final matchingLines = _matchingLines(lines, stop);
    final recentReports = reports.where((report) => report.busStopId == stop.id).take(4).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _StopMarker(level: stop.currentDensity),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duraktan gecen otobus ve hat bilgileri',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (stop.currentDensity != null) DensityBadge(level: stop.currentDensity!),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Otobüsler / hatlar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (matchingLines.isEmpty && stop.busLines.isEmpty)
              const Text('Bu durak için otobüs bilgisi bulunamadı.')
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final line in matchingLines)
                    ActionChip(
                      avatar: const Icon(Icons.directions_bus, size: 18),
                      label: Text(line.name),
                      onPressed: () => _openReportSheet(
                        context,
                        prefillLine: line,
                        prefillStopId: stop.id,
                      ),
                    ),
                  for (final lineName in stop.busLines)
                    if (!_containsLine(matchingLines, lineName))
                      Chip(
                        avatar: const Icon(Icons.alt_route, size: 18),
                        label: Text(lineName),
                      ),
                ],
              ),
            const SizedBox(height: 18),
            Text(
              'Son bildirimler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (recentReports.isEmpty)
              const Text('Bu durak için henüz kullanıcı bildirimi yok.')
            else
              for (final report in recentReports)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    title: Text(report.busLineName.isEmpty ? 'Hat bildirimi' : report.busLineName),
                    subtitle: Text(
                      '${report.userUsername.isEmpty ? 'Anonim' : report.userUsername} • ${_formatReportTime(report.reportedAt)}',
                    ),
                    trailing: DensityBadge(level: report.densityLevel),
                  ),
                ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _openReportSheet(context, prefillStopId: stop.id),
              icon: const Icon(Icons.campaign),
              label: const Text('Bu durak için şikayet / yoğunluk bildir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapStats {
  const _MapStats({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.cityLabel,
  });

  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final String cityLabel;

  factory _MapStats.fromStops(List<BusStop> stops) {
    if (stops.isEmpty) {
      return const _MapStats(
        minLat: 37.45,
        maxLat: 37.68,
        minLon: 36.76,
        maxLon: 37.10,
        cityLabel: 'Kahramanmaraş merkez',
      );
    }

    final lats = stops.map((stop) => stop.latitude!).toList();
    final lons = stops.map((stop) => stop.longitude!).toList();

    return _MapStats(
      minLat: lats.reduce(math.min),
      maxLat: lats.reduce(math.max),
      minLon: lons.reduce(math.min),
      maxLon: lons.reduce(math.max),
      cityLabel: 'Kahramanmaraş',
    );
  }

  double normalizeLatitude(double? latitude) {
    if (latitude == null || maxLat == minLat) return 0.5;
    final normalized = (latitude - minLat) / (maxLat - minLat);
    return (1 - normalized).clamp(0.06, 0.92);
  }

  double normalizeLongitude(double? longitude) {
    if (longitude == null || maxLon == minLon) return 0.5;
    final normalized = (longitude - minLon) / (maxLon - minLon);
    return normalized.clamp(0.06, 0.94);
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({this.level});

  final DensityLevel? level;

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (level) {
      DensityLevel.green => (const Color(0xFF0F7A3D), const Color(0xFFE6F7EE)),
      DensityLevel.yellow => (const Color(0xFFB08900), const Color(0xFFFFF7DF)),
      DensityLevel.red => (const Color(0xFFB00020), const Color(0xFFFFE7E7)),
      DensityLevel.black => (const Color(0xFF111827), const Color(0xFFCBD5E1)),
      null => (const Color(0xFF2563EB), const Color(0xFFE0F2FE)),
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 3),
        boxShadow: const [
          BoxShadow(blurRadius: 10, color: Color(0x33000000), offset: Offset(0, 4)),
        ],
      ),
      child: const Icon(Icons.directions_bus, color: Colors.white, size: 18),
    );
  }
}

void _openStopSheet(
  BuildContext context, {
  required BusStop stop,
  required List<BusLine> lines,
  required List<DensityReport> reports,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _StopDetailsSheet(
      stop: stop,
      lines: lines,
      reports: reports,
    ),
  );
}

void _openReportSheet(
  BuildContext context, {
  BusLine? prefillLine,
  int? prefillStopId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReportSheet(
      prefillLine: prefillLine,
      prefillStopId: prefillStopId,
    ),
  );
}

List<BusLine> _matchingLines(List<BusLine> lines, BusStop stop) {
  final rawNames = stop.busLines.map(_normalizeText).toSet();
  return lines.where((line) {
    final lineName = _normalizeText(line.name);
    if (rawNames.contains(lineName)) return true;
    return rawNames.any(
      (raw) => raw.isNotEmpty && (lineName.contains(raw) || raw.contains(lineName)),
    );
  }).toList();
}

bool _containsLine(List<BusLine> lines, String lineName) {
  final normalized = _normalizeText(lineName);
  return lines.any((line) => _normalizeText(line.name) == normalized);
}

String _normalizeText(String value) {
  return value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

String _formatReportTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) return 'Az once';
  if (diff.inHours < 1) return '${diff.inMinutes} dk once';
  if (diff.inDays < 1) return '${diff.inHours} sa once';
  return '${diff.inDays} gun once';
}
