import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';

class WaypointListScreen extends StatelessWidget {
  const WaypointListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Waypoint (${state.waypoints.length})'),
        actions: [
          IconButton(
            tooltip: 'Import GeoJSON/KML/GPX',
            onPressed: () async {
              try {
                final count = await state.importWaypoints();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã nhập $count waypoint.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import lỗi: $e')));
                }
              }
            },
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: 'Export GeoJSON',
            onPressed: state.waypoints.isEmpty
                ? null
                : () async {
                    final path = await state.exportWaypoints();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xuất: $path')));
                    }
                  },
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: state.waypoints.isEmpty
          ? const Center(child: Text('Chưa có waypoint.'))
          : ListView.separated(
              itemCount: state.waypoints.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final w = state.waypoints[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(w.name),
                  subtitle: Text(
                    '${w.latitude.toStringAsFixed(7)}, ${w.longitude.toStringAsFixed(7)}'
                    '${w.accuracy == null ? '' : ' · ±${w.accuracy!.toStringAsFixed(1)} m'}',
                  ),
                  trailing: Text(w.source.name),
                );
              },
            ),
    );
  }
}
