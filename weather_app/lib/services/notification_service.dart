import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_service.dart';
import '../models/weather_model.dart';

// 백그라운드에서 실행될 콜백 함수 (반드시 top-level이어야 함)
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  final WeatherService _weatherService = WeatherService();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 시작 시 한 번 업데이트
    _updateNotification();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // 주기적으로 업데이트
    _updateNotification();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // 서비스 종료 시 처리
  }

  Future<void> _updateNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nx = prefs.getInt('nx') ?? 61;
      final ny = prefs.getInt('ny') ?? 125;
      final cityName = prefs.getString('current_city') ?? '서울';

      _weatherService.setGrid(nx, ny);
      final forecasts = await _weatherService.fetchForecast();
      final current = _weatherService.getCurrentWeather(forecasts);
      final airQuality = await _weatherService.fetchAirQuality(cityName);

      if (current != null) {
        String title = '지금 $cityName 날씨는 ${current.skyStatus}';
        String content = '🌡️ 현재 ${current.temp.toStringAsFixed(1)}°';
        
        if (airQuality != null) {
          content += ' | 😶 미세먼지 ${airQuality.pm10GradeKor}';
        }

        FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: content,
        );
      }
    } catch (e) {
      // ignore
    }
  }
}

class NotificationService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'weather_notification_channel',
        channelName: 'Weather App Notification',
        channelDescription: 'Shows real-time weather in status bar',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(3600000), // 1시간마다
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: '날씨 정보 불러오는 중...',
      notificationText: '잠시만 기다려 주세요.',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

extension on HourlyWeatherData {
  String get skyStatus {
    if (pty > 0) {
      switch (pty) {
        case 1: return '비 🌧️';
        case 2: return '비/눈 🌨️';
        case 3: return '눈 ❄️';
        case 4: return '소나기 🌦️';
        default: return '강수';
      }
    }
    switch (sky) {
      case 1: return '맑음 ☀️';
      case 3: return '구름많음 ⛅';
      case 4: return '흐림 ☁️';
      default: return '맑음';
    }
  }
}

extension on AirQualityData {
  String get pm10GradeKor {
    final val = double.tryParse(pm10) ?? 0;
    if (val <= 30) return '좋음 😊';
    if (val <= 80) return '보통 🙂';
    if (val <= 150) return '나쁨 😷';
    return '매우나쁨 🚨';
  }
}
