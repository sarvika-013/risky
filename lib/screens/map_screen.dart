import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  LatLng? currentLocation;
  double _zoom = 13;

  StreamSubscription<Position>? _positionStream;
  String? avatarUrl;

  static const mapboxToken =
      'pk.eyJ1IjoiZmx1dHRlci1sb2ciLCJhIjoiY21peXNucHF4MGp2aDNoczY0b2hvcjRhMCJ9.fZ-6OD0ZqO4twwvBLOdSgA';

  String get tileUrl =>
      'https://api.mapbox.com/styles/v1/flutter-log/cmkrqwd1p001f01r69enga5ly/tiles/256/{z}/{x}/{y}?access_token=$mapboxToken';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Permission.location.request();
    await _startTracking();
  }

  Future<void> _startTracking() async {
    final supabase = Supabase.instance.client;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final me = await supabase
        .from('User')
        .select('avatar_url, show_location')
        .eq('user_id', supabase.auth.currentUser!.id)
        .maybeSingle();

    avatarUrl = me?['avatar_url'];

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    await _update(pos);

    _positionStream = Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen(_update);
  }

  Future<void> _update(Position p) async {
  final ll = LatLng(p.latitude, p.longitude);

  setState(() => currentLocation = ll);

  _mapController.move(ll, _zoom);

  final supabase = Supabase.instance.client;

  final res = await supabase.from('user_location').upsert(
    {
      'user_id': supabase.auth.currentUser!.id,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    },
    onConflict: 'user_id', // <<< IMPORTANT
  );

  debugPrint("LOCATION UPSERT RESULT: $res");
}


  void _zoomIn() {
    _zoom = (_zoom + 1).clamp(3, 18);
    if (currentLocation != null) _mapController.move(currentLocation!, _zoom);
  }

  void _zoomOut() {
    _zoom = (_zoom - 1).clamp(3, 18);
    if (currentLocation != null) _mapController.move(currentLocation!, _zoom);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = currentLocation ?? const LatLng(37.7749, -122.4194);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: _zoom),
            children: [
              TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'geo.app'),
              if (currentLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: currentLocation!,
                    width: 40,
                    height: 40,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: avatarUrl != null
                          ? (avatarUrl!.startsWith('http')
                              ? NetworkImage(avatarUrl!)
                              : AssetImage(avatarUrl!) as ImageProvider)
                          : null,
                      child:
                          avatarUrl == null ? const Icon(Icons.person) : null,
                    ),
                  ),
                ]),
            ],
          ),

          Positioned(
            right: 16,
            top: 100,
            child: Column(children: [
              FloatingActionButton(
                  mini: true, onPressed: _zoomIn, child: const Icon(Icons.add)),
              const SizedBox(height: 8),
              FloatingActionButton(
                  mini: true, onPressed: _zoomOut, child: const Icon(Icons.remove)),
            ]),
          ),
        ],
      ),
    );
  }
}
