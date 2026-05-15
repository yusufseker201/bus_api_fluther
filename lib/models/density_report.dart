import 'density_level.dart';

class DensityReport {
  const DensityReport({
    required this.id,
    required this.busLineId,
    required this.busStopId,
    required this.densityLevel,
    required this.reportedAt,
    required this.isActive,
    required this.busLineName,
    required this.busStopName,
    required this.userUsername,
  });

  final int id;
  final int busLineId;
  final int busStopId;
  final DensityLevel densityLevel;
  final DateTime reportedAt;
  final bool isActive;
  final String busLineName;
  final String busStopName;
  final String userUsername;

  static DensityReport fromApi(Map<String, dynamic> json) {
    return DensityReport(
      id: (json['id'] as num).toInt(),
      busLineId: (json['bus_line'] as num).toInt(),
      busStopId: (json['bus_stop'] as num).toInt(),
      densityLevel: DensityLevel.fromApi(json['density_level'] as String?),
      reportedAt: DateTime.tryParse(json['reported_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isActive: (json['is_active'] as bool?) ?? true,
      busLineName: (json['bus_line_name'] as String?) ?? '',
      busStopName: (json['bus_stop_name'] as String?) ?? '',
      userUsername: (json['user_username'] as String?) ?? '',
    );
  }
}

