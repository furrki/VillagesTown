import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'polygon_editor_state.dart';

class PolygonEditorScreen extends StatefulWidget {
  final List<LatLng>? initialPoints;
  final LatLng? center;
  final String? title;
  final void Function(List<LatLng> points)? onSave;

  const PolygonEditorScreen({
    super.key,
    this.initialPoints,
    this.center,
    this.title,
    this.onSave,
  });

  @override
  State<PolygonEditorScreen> createState() => _PolygonEditorScreenState();
}

class _PolygonEditorScreenState extends State<PolygonEditorScreen> {
  final _state = PolygonEditorState();
  final _mapController = MapController();
  int? _draggingIndex;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null) {
      _state.vertices = List.from(widget.initialPoints!);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter {
    if (widget.center != null) return widget.center!;
    if (_state.vertices.isNotEmpty) {
      final lats = _state.vertices.map((p) => p.latitude);
      final lngs = _state.vertices.map((p) => p.longitude);
      return LatLng(
        (lats.reduce((a, b) => a + b)) / lats.length,
        (lngs.reduce((a, b) => a + b)) / lngs.length,
      );
    }
    return const LatLng(38.0, 35.0); // Default center (Turkey area)
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_state.isAddMode) {
      setState(() => _state.addVertex(point));
    } else {
      setState(() => _state.selectVertex(null));
    }
  }

  void _onVertexTap(int index) {
    setState(() => _state.selectVertex(index));
  }

  void _onVertexDragStart(int index) {
    _draggingIndex = index;
    setState(() => _state.selectVertex(index));
  }

  void _onVertexDragUpdate(int index, LatLng newPoint) {
    if (_draggingIndex == index) {
      setState(() => _state.updateVertex(index, newPoint));
    }
  }

  void _onVertexDragEnd() {
    _draggingIndex = null;
  }

  void _onVertexSecondaryTap(int index) {
    setState(() => _state.removeVertex(index));
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        setState(() => _state.removeSelected());
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _state.selectVertex(null));
      }
    }
  }

  Future<void> _loadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      setState(() {
        if (!_state.fromJson(content)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid JSON format')),
          );
        }
      });
    }
  }

  Future<void> _saveFile() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Polygon',
      fileName: 'polygon.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path != null) {
      final file = File(path.endsWith('.json') ? path : '$path.json');
      await file.writeAsString(_state.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${file.path}')),
        );
      }
    }
  }

  void _applyToApp() {
    if (widget.onSave != null && _state.vertices.length >= 3) {
      widget.onSave!(_state.vertices);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applied to app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Polygon Editor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Load',
              onPressed: _loadFile,
            ),
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: 'Export to file',
              onPressed: _state.vertices.isEmpty ? null : _saveFile,
            ),
            if (widget.onSave != null)
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Apply to app',
                onPressed: _state.vertices.length >= 3 ? _applyToApp : null,
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear',
              onPressed: _state.vertices.isEmpty
                  ? null
                  : () => setState(() => _state.clear()),
            ),
            const VerticalDivider(),
            ToggleButtons(
              isSelected: [_state.isAddMode, !_state.isAddMode],
              onPressed: (i) => setState(() => _state.isAddMode = i == 0),
              children: const [
                Tooltip(message: 'Add mode', child: Icon(Icons.add_location)),
                Tooltip(message: 'Select mode', child: Icon(Icons.pan_tool)),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 5,
                  onTap: _onMapTap,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.polygon_editor',
                  ),
                  if (_state.vertices.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _state.vertices,
                          color: Colors.blue.withValues(alpha: 0.3),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (_state.vertices.length >= 2 && _state.vertices.length < 3)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _state.vertices,
                          color: Colors.blue,
                          strokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: _buildVertexMarkers(),
                  ),
                ],
              ),
            ),
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildVertexMarkers() {
    return List.generate(_state.vertices.length, (i) {
      final isSelected = _state.selectedIndex == i;
      return Marker(
        point: _state.vertices[i],
        width: 24,
        height: 24,
        child: GestureDetector(
          onTap: () => _onVertexTap(i),
          onSecondaryTap: () => _onVertexSecondaryTap(i),
          onPanStart: (_) => _onVertexDragStart(i),
          onPanUpdate: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final point = _mapController.camera.pointToLatLng(
              math.Point(localPos.dx, localPos.dy - kToolbarHeight),
            );
            _onVertexDragUpdate(i, point);
          },
          onPanEnd: (_) => _onVertexDragEnd(),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStatusBar() {
    final selected = _state.selectedIndex != null
        ? _state.vertices[_state.selectedIndex!]
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          Text('Vertices: ${_state.vertices.length}'),
          const SizedBox(width: 24),
          if (selected != null)
            Text(
              'Selected #${_state.selectedIndex! + 1}: '
              '${selected.latitude.toStringAsFixed(6)}, '
              '${selected.longitude.toStringAsFixed(6)}',
            )
          else
            const Text('No vertex selected'),
          const Spacer(),
          Text(_state.isAddMode ? 'Click map to add points' : 'Drag to move points'),
        ],
      ),
    );
  }
}
