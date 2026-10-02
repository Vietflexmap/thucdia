import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _centralMeridian;

  @override
  void initState() {
    super.initState();
    _centralMeridian = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = context.read<AppState>().centralMeridian.toStringAsFixed(5);
    if (_centralMeridian.text.isEmpty) _centralMeridian.text = value;
  }

  @override
  void dispose() {
    _centralMeridian.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thực địa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('GNSS', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngưỡng độ chính xác: ≤ ${state.gpsAccuracyThreshold.toStringAsFixed(0)} m'),
                  Slider(
                    value: state.gpsAccuracyThreshold,
                    min: 3,
                    max: 50,
                    divisions: 47,
                    label: '${state.gpsAccuracyThreshold.toStringAsFixed(0)} m',
                    onChanged: state.setGpsAccuracyThreshold,
                  ),
                  const Text('Điểm track có accuracy kém hơn ngưỡng này sẽ không được ghi.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('VN-2000', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _centralMeridian,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Kinh tuyến trục (độ)'),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () async {
                        final value = double.tryParse(_centralMeridian.text.replaceAll(',', '.'));
                        if (value == null) return;
                        await state.setCentralMeridian(value);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu kinh tuyến trục.')));
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Dữ liệu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Waypoint'),
                  trailing: Text('${state.waypoints.length}'),
                ),
                ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: const Text('Track'),
                  trailing: Text('${state.tracks.length}'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text('Ảnh hiện trường'),
                  trailing: Text('${state.photos.length}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Vietflex Thực địa v0.1 · clean-room field GIS · offline-first core'),
            ),
          ),
        ],
      ),
    );
  }
}
