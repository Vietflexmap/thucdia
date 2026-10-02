import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/app_state.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();
  runApp(VietflexThucDia(appState: appState));
}

class VietflexThucDia extends StatelessWidget {
  const VietflexThucDia({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vietflex Thực địa',
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
