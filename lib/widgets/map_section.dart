import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapSection extends StatefulWidget {
  const MapSection({super.key});

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
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
  }

  Future<void> _init() async {
    await Permission.location.request();
    await _startTracking();
    _startFriendsPolling();
  }

  // -------- YOUR LOCATION --------
  Future<void> _startTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.deniedForever || p == LocationPermission.denied) return;

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

  // -------- FRIENDS --------
  void _startFriendsPolling() {
    _fetchFriends();
    _friendsTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _fetchFriends());
  }

  Future<void> _fetchFriends() async {
  try {
    // 1. Get accepted friendships
    final a = await supabase
        .from('friendship')
        .select('receiver_id')
        .eq('sender_id', myId)
        .eq('status', 'accepted');

    final b = await supabase
        .from('friendship')
        .select('sender_id')
        .eq('receiver_id', myId)
        .eq('status', 'accepted');

    final ids = <String>{
      ...a.map((e) => e['receiver_id'] as String),
      ...b.map((e) => e['sender_id'] as String),
    };

    if (ids.isEmpty) {
      setState(() => friendsLocations = []);
      return;
    }

    // 2. Fetch their locations + avatars
    final res = await supabase
        .from('user_location')
        .select('user_id, latitude, longitude')
        .inFilter('user_id', ids.toList());

    final users = await supabase
        .from('User')
        .select('user_id, avatar_url')
        .inFilter('user_id', ids.toList());

    final avatarMap = {
      for (final u in users) u['user_id']: u['avatar_url']
    };

    final merged = res.map((e) {
      return {
        ...e,
        'avatar': avatarMap[e['user_id']],
      };
    }).toList();

    debugPrint("FRIENDS FINAL: $merged");

    setState(() => friendsLocations = merged);
  } catch (e) {
    debugPrint("Friends fetch failed: $e");
  }
}


  // -------- FULLSCREEN --------
  void _openFullMap() {
    showDialog(
      context: context,
      builder: (_) => Scaffold(
        body: Stack(
          children: [
            _mapWidget(fullscreen: true),
            Positioned(
              top: 40,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _mapWidget({bool fullscreen = false}) {
    final center = currentLocation ?? const LatLng(37.7749, -122.4194);

    return FlutterMap(
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
                  backgroundImage:
                      avatarUrl != null ? AssetImage(avatarUrl!) : null,
                ),
              ),

            ...friendsLocations
                .where((e) => e['user_id'] != myId)
                .map((e) {
              final lat = e['latitude'];
              final lng = e['longitude'];
              final avatar = e['avatar'];
              if (lat == null || lng == null) return null;

              return Marker(
                point: LatLng(lat, lng),
                width: 32,
                height: 32,
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage:
                      avatar != null ? AssetImage(avatar) : null,
                ),
              );
            }).whereType<Marker>(),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _friendsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _mapWidget(),

        Positioned(
          top: 16,
          left: 16,
          right: 60,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text("Search"),
              ],
            ),
          ),
        ),

        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: _openFullMap,
            child: const Icon(Icons.fullscreen),
          ),
        ),
      ],
    );
  }
}
