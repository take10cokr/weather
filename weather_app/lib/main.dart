import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'theme/app_theme.dart';

import 'package:permission_handler/permission_handler.dart';
import 'services/notification_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 알림 서비스 초기화
  NotificationService.init();
  
  // 권한 요청
  await [
    Permission.location,
    Permission.notification,
  ].request();

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
      home: const WithForegroundTask(
        child: HomeScreen(),
      ),
    );
  }
}
