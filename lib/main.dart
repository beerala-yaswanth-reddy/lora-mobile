import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/dashboard_screen.dart';

void main() {
  runApp(const IndoorTrackerApp());
}

class IndoorTrackerApp extends StatelessWidget {
  const IndoorTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return M3EMaterialApp(
      title: 'Indoor Tracker',
      data: M3EThemeData.light(seedColor: const Color(0xFF1A73E8)),
      autoTheming: true,
      dynamicColoring: false,
      drawUnderSystemBars: true,
      home: const DashboardScreen(),
    );
  }
}
