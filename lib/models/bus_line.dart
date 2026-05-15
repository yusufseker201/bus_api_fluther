import 'bus_stop.dart';

class BusLine {
  const BusLine({
    required this.id,
    required this.name,
    required this.routeDescription,
    required this.reportsCount,
    required this.stops,
  });

  final int id;
  final String name;
  final String routeDescription;
  final int reportsCount;
  final List<BusStop> stops;

  static BusLine fromApi(Map<String, dynamic> json) {
    final stopsJson = (json['stops'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return BusLine(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? 'Hat',
      routeDescription: (json['route_description'] as String?) ?? '',
      reportsCount: (json['reports_count'] as num?)?.toInt() ?? 0,
      stops: stopsJson.map(BusStop.fromApi).toList(),
    );
  }
}

