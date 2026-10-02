import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Nhật ký hiện trường'),
          actions: [
            IconButton(
              tooltip: 'Chụp ảnh có GNSS',
              onPressed: () async {
                try {
                  await state.capturePhoto();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không chụp được ảnh: $e')));
                  }
                }
              },
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
          ],
        ),
        body: state.photos.isEmpty
            ? const Center(child: Text('Chưa có ảnh hiện trường.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: state.photos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final photo = state.photos[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          height: 96,
                          child: Image.file(
                            File(photo.filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFE8ECEA),
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(photo.takenAt.toLocal().toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(
                                  photo.latitude == null
                                      ? 'Không có GNSS'
                                      : '${photo.latitude!.toStringAsFixed(6)}, ${photo.longitude!.toStringAsFixed(6)} · ±${photo.accuracy?.toStringAsFixed(1) ?? '—'} m',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: state.capturePhoto,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Chụp ảnh'),
        ),
      ),
    );
  }
}
