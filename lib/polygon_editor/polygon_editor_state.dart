import 'dart:convert';
import 'package:latlong2/latlong.dart';

class PolygonEditorState {
  List<LatLng> vertices = [];
  int? selectedIndex;
  bool isAddMode = true;

  void addVertex(LatLng point) {
    vertices.add(point);
    selectedIndex = vertices.length - 1;
  }

  void insertVertex(int index, LatLng point) {
    vertices.insert(index, point);
    selectedIndex = index;
  }

  void updateVertex(int index, LatLng point) {
    if (index >= 0 && index < vertices.length) {
      vertices[index] = point;
    }
  }

  void removeVertex(int index) {
    if (index >= 0 && index < vertices.length) {
      vertices.removeAt(index);
      if (selectedIndex == index) {
        selectedIndex = vertices.isNotEmpty ? (index > 0 ? index - 1 : 0) : null;
      } else if (selectedIndex != null && selectedIndex! > index) {
        selectedIndex = selectedIndex! - 1;
      }
    }
  }

  void removeSelected() {
    if (selectedIndex != null) {
      removeVertex(selectedIndex!);
    }
  }

  void clear() {
    vertices.clear();
    selectedIndex = null;
  }

  void selectVertex(int? index) {
    selectedIndex = index;
  }

  String toJson() {
    final coords = vertices.map((v) => [v.longitude, v.latitude]).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'type': 'Polygon',
      'coordinates': coords,
    });
  }

  bool fromJson(String jsonStr) {
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final coords = data['coordinates'] as List;
      vertices = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
      selectedIndex = null;
      return true;
    } catch (e) {
      return false;
    }
  }
}
