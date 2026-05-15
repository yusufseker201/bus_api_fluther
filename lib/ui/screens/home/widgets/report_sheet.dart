import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../models/bus_line.dart';
import '../../../../models/density_level.dart';
import '../../../../services/api_service.dart';
import '../../../../state/app_state.dart';
import '../../../../state/session_state.dart';
import '../../auth/login_screen.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, this.prefillLine, this.prefillStopId});

  final BusLine? prefillLine;
  final int? prefillStopId;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  int? _lineId;
  int? _stopId;
  DensityLevel _level = DensityLevel.yellow;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lineId = widget.prefillLine?.id;
    _stopId = widget.prefillStopId;
  }

  Future<Position> _currentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw StateError('Konum izni gerekli.');
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw StateError('Konum servisi kapalı.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final api = context.read<ApiService>();
      final appState = context.read<AppState>();

      final lineId = _lineId;
      final stopId = _stopId;
      if (lineId == null) throw StateError('Hat seçin.');
      if (stopId == null) throw StateError('Durak seçin.');

      final pos = await _currentPosition();
      await api.submitReport(
        busLineId: lineId,
        busStopId: stopId,
        densityLevel: _level,
        userLat: pos.latitude,
        userLon: pos.longitude,
      );
      await appState.refreshAll();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lines = app.lines;
    final session = context.watch<SessionState>();

    final selectedLine = lines.where((l) => l.id == _lineId).cast<BusLine?>().firstOrNull;
    final stops = selectedLine?.stops ?? app.stops;
    final stopItems = stops.where((s) => s.latitude != null && s.longitude != null).toList();

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
            Text('Yoğunluk raporu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (!session.isLoggedIn) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Rapor göndermek için giriş yapmalısın.')),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Text('Giriş'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownMenu<int>(
              initialSelection: _lineId,
              enabled: !_submitting,
              expandedInsets: EdgeInsets.zero,
              label: const Text('Hat'),
              dropdownMenuEntries: [
                for (final line in lines)
                  DropdownMenuEntry(value: line.id, label: line.name),
              ],
              onSelected: (value) => setState(() {
                _lineId = value;
                _stopId = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownMenu<int>(
              initialSelection: _stopId,
              enabled: !_submitting,
              expandedInsets: EdgeInsets.zero,
              label: const Text('Durak'),
              dropdownMenuEntries: [
                for (final stop in stopItems)
                  DropdownMenuEntry(value: stop.id, label: stop.name),
              ],
              onSelected: (value) => setState(() => _stopId = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in DensityLevel.values)
                  ChoiceChip(
                    label: Text(level.labelTr),
                    selected: _level == level,
                    onSelected: _submitting ? null : (_) => setState(() => _level = level),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_submitting || !session.isLoggedIn) ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Gönderiliyor…' : 'Raporu gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

