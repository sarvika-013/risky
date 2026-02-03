import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo_viewer_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final supabase = Supabase.instance.client;
  List photos = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final res = await supabase
        .from('photo')
        .select()
        .order('taken_at', ascending: false);

    setState(() => photos = res);
  }

  void remove(int i) {
    setState(() => photos.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Gallery")),
        body: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: photos.length,
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PhotoViewerScreen(
                                photos: photos,
                                index: i,
                                onDelete: remove,
                              )));
                },
                child: Image.network(photos[i]['image_url'], fit: BoxFit.cover),
              );
            }));
  }
}
