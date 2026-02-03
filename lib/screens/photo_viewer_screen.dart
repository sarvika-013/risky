import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List photos;
  final int index;
  final Function(int) onDelete;

  const PhotoViewerScreen(
      {super.key,
      required this.photos,
      required this.index,
      required this.onDelete});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final supabase = Supabase.instance.client;
  late PageController controller;
  bool info = false;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget.index);
  }

  Future<void> delete(int i) async {
    final url = widget.photos[i]['image_url'];
    final name = url.split('/').last;

    await supabase.storage.from('photos').remove([name]);
    await supabase.from('photo').delete().eq('image_url', url);

    widget.onDelete(i);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF06181C),
        body: PageView.builder(
            controller: controller,
            itemCount: widget.photos.length,
            itemBuilder: (_, i) {
              final p = widget.photos[i];
              return Stack(children: [
                Center(child: Image.network(p['image_url'])),

                Positioned(
                    bottom: 20,
                    left: 20,
                    child: ElevatedButton(
                        onPressed: () => setState(() => info = !info),
                        child: const Text("view info"))),

                if (info)
                  Positioned(
                      bottom: 80,
                      left: 20,
                      right: 20,
                      child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['taken_at']),
                                const SizedBox(height: 6),
                                const Text("Location"),
                                Text("Lat: ${p['latitude']}"),
                                Text("Lng: ${p['longitude']}"),
                              ]))),

                Positioned(
                    right: 20,
                    bottom: 20,
                    child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => delete(i)))
              ]);
            }));
  }
}
