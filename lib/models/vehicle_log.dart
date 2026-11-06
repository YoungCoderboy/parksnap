import 'package:uuid/uuid.dart';

/// Represents a single vehicle log entry in the parking system.
class VehicleLog {
  final String id;
  final String licensePlate;
  final String vehicleType; // Car, Bike, Truck, Other
  final DateTime entryTimestamp;
  final DateTime? exitTimestamp;
  final String flatOrVisitorInfo;
  final String status; // 'Inside', 'Exited'
  final String imagePath;
  final double confidence;

  static const _uuid = Uuid();

  VehicleLog({
    String? id,
    required this.licensePlate,
    required this.vehicleType,
    required this.entryTimestamp,
    this.exitTimestamp,
    this.flatOrVisitorInfo = '',
    this.status = 'Inside',
    this.imagePath = '',
    this.confidence = 0.0,
  }) : id = id ?? _uuid.v4();

  /// Duration the vehicle has been inside (null if already exited).
  Duration? get timeInside {
    final end = exitTimestamp ?? DateTime.now();
    return status == 'Inside' ? end.difference(entryTimestamp) : null;
  }

  /// Human-readable duration string, e.g. "2h 15m"
  String get timeInsideString {
    final d = status == 'Inside'
        ? DateTime.now().difference(entryTimestamp)
        : (exitTimestamp != null
            ? exitTimestamp!.difference(entryTimestamp)
            : Duration.zero);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  VehicleLog copyWith({
    String? id,
    String? licensePlate,
    String? vehicleType,
    DateTime? entryTimestamp,
    DateTime? exitTimestamp,
    String? flatOrVisitorInfo,
    String? status,
    String? imagePath,
    double? confidence,
  }) {
    return VehicleLog(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      entryTimestamp: entryTimestamp ?? this.entryTimestamp,
      exitTimestamp: exitTimestamp ?? this.exitTimestamp,
      flatOrVisitorInfo: flatOrVisitorInfo ?? this.flatOrVisitorInfo,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'license_plate': licensePlate,
      'vehicle_type': vehicleType,
      'entry_timestamp': entryTimestamp.toIso8601String(),
      'exit_timestamp': exitTimestamp?.toIso8601String(),
      'flat_or_visitor_info': flatOrVisitorInfo,
      'status': status,
      'image_path': imagePath,
      'confidence': confidence,
    };
  }

  factory VehicleLog.fromMap(Map<String, dynamic> map) {
    return VehicleLog(
      id: map['id'] as String,
      licensePlate: map['license_plate'] as String,
      vehicleType: map['vehicle_type'] as String,
      entryTimestamp: DateTime.parse(map['entry_timestamp'] as String),
      exitTimestamp: map['exit_timestamp'] != null
          ? DateTime.parse(map['exit_timestamp'] as String)
          : null,
      flatOrVisitorInfo: (map['flat_or_visitor_info'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'Inside',
      imagePath: (map['image_path'] as String?) ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() =>
      'VehicleLog(id: $id, plate: $licensePlate, status: $status)';
}
