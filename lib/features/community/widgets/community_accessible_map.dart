import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/location_model.dart';

/// Carte OpenStreetMap avec marqueurs par catégorie (même approche que [Ma3akMapWidget] / Transport).
class CommunityAccessibleMap extends StatefulWidget {
  const CommunityAccessibleMap({
    super.key,
    required this.locations,
    required this.onLocationTap,
  });

  final List<LocationModel> locations;
  final ValueChanged<LocationModel> onLocationTap;

  static const LatLng tunisCenter = LatLng(36.8065, 10.1815);

  @override
  State<CommunityAccessibleMap> createState() => _CommunityAccessibleMapState();
}

class _CommunityAccessibleMapState extends State<CommunityAccessibleMap> {
  final MapController _mapController = MapController();

  static List<LocationModel> _withValidCoords(List<LocationModel> list) {
    return list
        .where(
          (l) =>
              l.latitude.isFinite &&
              l.longitude.isFinite &&
              (l.latitude != 0 || l.longitude != 0),
        )
        .toList();
  }

  @override
  void didUpdateWidget(covariant CommunityAccessibleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fitCameraToLocations());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fitCameraToLocations());
  }

  void _fitCameraToLocations() {
    if (!mounted) return;
    final pts = _withValidCoords(widget.locations);
    if (pts.isEmpty) {
      _mapController.move(CommunityAccessibleMap.tunisCenter, 12);
      return;
    }
    if (pts.length == 1) {
      _mapController.move(
        LatLng(pts.first.latitude, pts.first.longitude),
        14,
      );
      return;
    }
    final bounds = LatLngBounds.fromPoints(
      pts.map((e) => LatLng(e.latitude, e.longitude)).toList(),
    );
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 64, 40, 100),
          maxZoom: 16,
        ),
      );
    } catch (_) {
      final c = LatLng(
        (bounds.north + bounds.south) / 2,
        (bounds.east + bounds.west) / 2,
      );
      _mapController.move(c, 13);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  (IconData, Color) _styleFor(LocationCategory c) {
    switch (c) {
      case LocationCategory.pharmacy:
        return (Icons.local_pharmacy, Colors.red.shade700);
      case LocationCategory.restaurant:
        return (Icons.restaurant, Colors.orange.shade800);
      case LocationCategory.hospital:
        return (Icons.local_hospital, Colors.red.shade900);
      case LocationCategory.school:
        return (Icons.school, Colors.blue.shade700);
      case LocationCategory.shop:
        return (Icons.shopping_bag, Colors.purple.shade700);
      case LocationCategory.publicTransport:
        return (Icons.directions_bus, Colors.green.shade800);
      case LocationCategory.park:
        return (Icons.park, Colors.green.shade900);
      case LocationCategory.other:
        return (Icons.place, const Color(0xFF1976D2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pts = _withValidCoords(widget.locations);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: CommunityAccessibleMap.tunisCenter,
          initialZoom: 12,
          minZoom: 3,
          maxZoom: 19,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'tn.ma3ak.app',
          ),
          MarkerLayer(
            markers: [
              for (final loc in pts)
                _buildMarker(loc),
            ],
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(LocationModel loc) {
    final (icon, color) = _styleFor(loc.categorie);
    return Marker(
      point: LatLng(loc.latitude, loc.longitude),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => widget.onLocationTap(loc),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
