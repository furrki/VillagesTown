import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart' as ll;

part 'geo_coordinate.freezed.dart';
part 'geo_coordinate.g.dart';

/// Immutable geographic coordinate.
@freezed
class GeoCoordinate with _$GeoCoordinate {
  const GeoCoordinate._();

  const factory GeoCoordinate({
    required double latitude,
    required double longitude,
  }) = _GeoCoordinate;

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) =>
      _$GeoCoordinateFromJson(json);

  /// Convert to flutter_map LatLng.
  ll.LatLng toLatLng() => ll.LatLng(latitude, longitude);

  /// Create from flutter_map LatLng.
  factory GeoCoordinate.fromLatLng(ll.LatLng latLng) => GeoCoordinate(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

  /// Calculate distance to another coordinate in kilometers (Haversine formula).
  double distanceToKm(GeoCoordinate other) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(other.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Calculate travel time in turns (~100km per turn, minimum 1).
  int travelTimeTo(GeoCoordinate other) {
    final distanceKm = distanceToKm(other);
    return max(1, (distanceKm / 100.0).ceil());
  }
}
