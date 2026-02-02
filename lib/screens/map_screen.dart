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
  final supabase = Supabase.instance.client;

  LatLng? currentLocation;
  double _zoom = 13;

  StreamSubscription<Position>? _positionStream;
  Timer? _friendsTimer;

  String? avatarUrl;
  List<Map<String, dynamic>> friendsLocations = [];

  String get myId => supabase.auth.currentUser!.id;

  static const mapboxToken =
      'pk.eyJ1IjoiZmx1dHRlci1sb2ciLCJhIjoiY21reTlldGphMDNqdTNkcjBub3E1Ym5hdCJ9.lJOm6O5jAdmnLlyvLZ7afg';

  String get tileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}?access_token=$mapboxToken';

  @override
  void initState() {
    super.initState();
    _init();
    _startFriendsPolling();
  }

  Future<void> _init() async {
    await Permission.location.request();
    await _startTracking();
  }

  Future<void> _startTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever ||
        p == LocationPermission.denied) return;

    final me = await supabase
        .from('User')
        .select('avatar_url')
        .eq('user_id', myId)
        .maybeSingle();

    avatarUrl = me?['avatar_url'];

    final pos = await Geolocator.getCurrentPosition();
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

    await supabase.from('user_location').upsert({
      'user_id': myId,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  void _startFriendsPolling() {
    _fetchFriendsLocations();
    _friendsTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _fetchFriendsLocations());
  }

  Future<void> _fetchFriendsLocations() async {
    final res = await supabase.from('user_location').select('''
      user_id,
      latitude,
      longitude,
      User!user_location_user_id_fkey(avatar_url)
    ''');

    debugPrint("FRIENDS RAW: $res");

    if (mounted) {
      setState(() {
        friendsLocations = List<Map<String, dynamic>>.from(res);
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _friendsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = currentLocation ?? const LatLng(37.7749, -122.4194);

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: center, initialZoom: _zoom),
        children: [
          TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'geo.app'),

          MarkerLayer(
            markers: [
              if (currentLocation != null)
                Marker(
                  point: currentLocation!,
                  width: 40,
                  height: 40,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: avatarUrl != null
                        ? AssetImage(avatarUrl!)
                        : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),

              ...friendsLocations
                  .where((e) => e['user_id'] != myId)
                  .map((e) {
                final lat = e['latitude'];
                final lng = e['longitude'];
                final avatar = e['User']?['avatar_url'];
                if (lat == null || lng == null) return null;

                return Marker(
                  point: LatLng(lat, lng),
                  width: 36,
                  height: 36,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        avatar != null ? AssetImage(avatar) : null,
                    child:
                        avatar == null ? const Icon(Icons.person, size: 12) : null,
                  ),
                );
              }).whereType<Marker>(),
            ],
          ),
        ],
      ),
    );
  }
}
