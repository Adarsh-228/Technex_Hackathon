import 'package:geolocator/geolocator.dart';

/// In-memory store for the last known device location.
/// This lets us use the initially fetched location in other screens.
class LocationStore {
  LocationStore._internal();

  static final LocationStore instance = LocationStore._internal();

  Position? _position;
  String? _placeName;

  void setPosition(Position position, {String? placeName}) {
    _position = position;
    _placeName = placeName;
  }

  Position? get position => _position;
  String? get placeName => _placeName;

  /// Convenience: formatted string for display / text fields.
  /// Returns place name if available, otherwise coordinates.
  String? get formattedLocation {
    if (_placeName != null && _placeName!.isNotEmpty) {
      return _placeName;
    }
    if (_position == null) return null;
    return '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
  }
}


