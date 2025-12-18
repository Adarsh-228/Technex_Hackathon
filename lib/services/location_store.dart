import 'package:geolocator/geolocator.dart';

/// In-memory store for the last known device location.
/// This lets us use the initially fetched location in other screens.
class LocationStore {
  LocationStore._internal();

  static final LocationStore instance = LocationStore._internal();

  Position? _position;

  void setPosition(Position position) {
    _position = position;
  }

  Position? get position => _position;

  /// Convenience: formatted string for display / text fields.
  String? get formattedLocation {
    if (_position == null) return null;
    return '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
  }
}


