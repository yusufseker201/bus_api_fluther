import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/density_report.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._api);

  ApiService _api;
  Timer? _pollTimer;

  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? error;

  List<BusLine> lines = const [];
  List<BusStop> stops = const [];
  List<DensityReport> reports = const [];

  void updateApi(ApiService api) {
    _api = api;
  }

  Future<void> loadInitialData() async {
    if (hasLoadedOnce || isLoading) return;
    await refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final fetchedReports = await _api.fetchReports();
      final fetchedLines = await _api.fetchBusLines();
      final fetchedStops = await _api.fetchBusStops(reports: fetchedReports);
      reports = fetchedReports;
      lines = fetchedLines;
      stops = fetchedStops;
      hasLoadedOnce = true;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      if (isLoading) return;
      refreshAll();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
