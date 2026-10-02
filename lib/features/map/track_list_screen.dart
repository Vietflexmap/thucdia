import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../services/measurement_service.dart';

class TrackListScreen extends StatelessWidget {
  const TrackListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final measurement = MeasurementService();
    return Scaffold(
      appBar: AppBar(title: Text('Track (${state.tracks.length})')),
      body: state.tracks.isEmpty
          ? const Center(child: Text('Chưa có track đã lưu.'))
          : ListView.separated(
              itemCount: state.tracks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final track = state.tracks[index];
                return ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: Text(track.name),
                  subtitle: Text('${track.points.length} điểm · ${measurement.formatDistance(track.totalDistanceMeters)}'),
                  trailing: IconButton(
                    tooltip: 'Export GPX',
                    onPressed: () async {
                      final path = await state.exportTrack(track);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xuất: $path')));
                      }
                    },
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                );
              },
            ),
    );
  }
}
