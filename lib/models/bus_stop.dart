import 'density_level.dart';

class BusStop {
  const BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.busLines,
    this.currentDensity,
  });

  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final List<String> busLines;
  final DensityLevel? currentDensity;

  static BusStop fromApi(Map<String, dynamic> json, {DensityLevel? currentDensity}) {
    return BusStop(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? 'Bilinmeyen durak',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      busLines: (json['bus_lines'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      currentDensity: currentDensity,
    );
  }
}

