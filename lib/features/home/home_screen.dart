import 'package:flutter/material.dart';

import '../coordinates/coordinates_screen.dart';
import '../map/map_screen.dart';
import '../media/media_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  static const pages = <Widget>[
    MapScreen(),
    CoordinatesScreen(),
    MediaScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Bản đồ'),
          NavigationDestination(icon: Icon(Icons.gps_fixed), label: 'Tọa độ'),
          NavigationDestination(icon: Icon(Icons.photo_camera_outlined), label: 'Hiện trường'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
