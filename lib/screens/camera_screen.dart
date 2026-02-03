import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'gallery_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  CameraController? controller;
  List<CameraDescription>? cams;
  int camIndex = 0;

  bool flash = false;
  bool busy = false;

  late AnimationController shutter;

  @override
  void initState() {
    super.initState();
    shutter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    init();
  }

  Future<void> init() async {
    cams = await availableCameras();
    await loadCamera();
  }

  Future<void> loadCamera() async {
    controller?.dispose();

    controller = CameraController(cams![camIndex], ResolutionPreset.high);
    await controller!.initialize();
    await controller!.setFlashMode(flash ? FlashMode.torch : FlashMode.off);

    setState(() {});
  }

  Future<void> toggleFlash() async {
    flash = !flash;
    await controller!.setFlashMode(flash ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> switchCam() async {
    camIndex = (camIndex + 1) % cams!.length;
    await loadCamera();
  }

  Future<void> capture() async {
  if (busy) return;
  busy = true;

  await shutter.forward();
  await shutter.reverse();

  final shot = await controller!.takePicture();

  final file = File(shot.path);

  // SAVE TO PHONE GALLERY
  await GallerySaver.saveImage(file.path);

  final bytes = await file.readAsBytes();

  final pos = await Geolocator.getCurrentPosition();

  final name = "${DateTime.now().millisecondsSinceEpoch}.jpg";

  // UPLOAD TO SUPABASE STORAGE
  await supabase.storage.from('photos').uploadBinary(name, bytes);

  final url = supabase.storage.from('photos').getPublicUrl(name);

  // INSERT DATABASE ROW
  await supabase.from('photo').insert({
    'user_id': supabase.auth.currentUser!.id,
    'image_url': url,
    'latitude': pos.latitude,
    'longitude': pos.longitude,
    'taken_at': DateTime.now().toIso8601String(),
    'is_public': true,
  });

  busy = false;
}


  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF06181C),
      body: Stack(children: [
        Positioned.fill(child: CameraPreview(controller!)),

        FadeTransition(
            opacity: shutter, child: Container(color: Colors.white)),

        Positioned(
            right: 20,
            top: 60,
            child: IconButton(
                onPressed: toggleFlash,
                icon: Icon(flash ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white))),

        Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(
                  icon: const Icon(Icons.grid_view, color: Colors.white),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GalleryScreen()))),

              GestureDetector(
                onTap: capture,
                child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4))),
              ),

              IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  onPressed: switchCam),
            ]))
      ]),
    );
  }

  @override
  void dispose() {
    shutter.dispose();
    controller?.dispose();
    super.dispose();
  }
}
