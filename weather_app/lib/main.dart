import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load(); // 저장된 설정 불러오기
  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const WeatherProApp(),
    ),
  );
}

class WeatherProApp extends StatelessWidget {
  const WeatherProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
