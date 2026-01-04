import 'dart:math';
import 'package:latlong2/latlong.dart';

class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate(this.latitude, this.longitude);

  LatLng toLatLng() => LatLng(latitude, longitude);

  static GeoCoordinate fromLatLng(LatLng latLng) =>
      GeoCoordinate(latLng.latitude, latLng.longitude);

  /// Calculate distance in kilometers using Haversine formula
  static double distanceKm(GeoCoordinate a, GeoCoordinate b) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);

    final lat1Rad = _toRadians(a.latitude);
    final lat2Rad = _toRadians(b.latitude);

    final sinDLatHalf = sin(dLat / 2);
    final sinDLonHalf = sin(dLon / 2);

    final h = sinDLatHalf * sinDLatHalf +
        cos(lat1Rad) * cos(lat2Rad) * sinDLonHalf * sinDLonHalf;

    return 2 * earthRadiusKm * asin(sqrt(h));
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinate &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoCoordinate($latitude, $longitude)';
}
