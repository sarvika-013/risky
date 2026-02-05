import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List photos;
  final int index;
  final Function(int) onDelete;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.index,
    required this.onDelete,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final supabase = Supabase.instance.client;
  late PageController controller;

  bool showInfo = false;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget.index);
  }

  Future<void> deletePhoto(int i) async {
    final url = widget.photos[i]['image_url'];
    final name = url.split('/').last;

    await supabase.storage.from('photos').remove([name]);
    await supabase.from('photo').delete().eq('image_url', url);

    widget.onDelete(i);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0B2B30),
      body: SafeArea(
        child: PageView.builder(
          controller: controller,
          itemCount: widget.photos.length,
          itemBuilder: (_, i) {
            final p = widget.photos[i];

            final takenAt = DateTime.parse(p['taken_at']);

            return Stack(
              children: [
                /// IMAGE — SLIGHTLY TOWARDS TOP, NO STRETCH
                Positioned(
                  top: h * 0.06,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: h * 0.58, // 👈 more than half screen
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        p['image_url'],
                        fit: BoxFit.contain, // 👈 original aspect ratio
                      ),
                    ),
                  ),
                ),

                /// INFO CARD — ITS OWN SPACE (NO OVERLAP)
                if (showInfo)
                  Positioned(
                    top: h * 0.66,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${takenAt.day.toString().padLeft(2, '0')}.${takenAt.month.toString().padLeft(2, '0')}.${takenAt.year % 100}",
                              ),
                              Text(
                                "${takenAt.hour.toString().padLeft(2, '0')}:${takenAt.minute.toString().padLeft(2, '0')}",
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Location",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("Latitude: ${p['latitude']}"),
                          Text("Longitude: ${p['longitude']}"),
                        ],
                      ),
                    ),
                  ),

                /// BOTTOM NAV — FIXED
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade200,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              showInfo = !showInfo;
                            });
                          },
                          child: const Text("view info"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deletePhoto(i),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
