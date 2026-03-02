import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin _localNotifPlugin = FlutterLocalNotificationsPlugin();
  bool _isNotifInitialized = false;

  Future<void> _initLocalNotif() async {
    if (_isNotifInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifPlugin.initialize(settings: initSettings);
    _isNotifInitialized = true;
  }

  Future<void> _checkAndNotifyRain(List<HourlyWeatherData> hourly, SharedPreferences prefs) async {
    if (hourly.length > 4) {
      final targetForecast = hourly[4]; // 4시간 후 (현재 시간이 index 0)
      if (targetForecast.pty > 0) { // 강수 있음
        final now = DateTime.now();
        final notifKey = '${now.month}${now.day}_${targetForecast.time}';
        final lastNotifiedTime = prefs.getString('last_rain_notified_time');
        
        if (lastNotifiedTime != notifKey) {
          await _initLocalNotif();
          const androidDetails = AndroidNotificationDetails(
            'rain_alert_channel',
            '비 예보 알림',
            channelDescription: '4시간 후 비 예보 알림',
            importance: Importance.high,
            priority: Priority.high,
          );
          const iosDetails = DarwinNotificationDetails();
          const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
          
          String rainType = '비';
          if (targetForecast.pty == 2) rainType = '비/눈';
          if (targetForecast.pty == 3) rainType = '눈';
          if (targetForecast.pty == 4) rainType = '소나기';

          await _localNotifPlugin.show(
            id: 888,
            title: '☂️ 우산 챙기세요!',
            body: '4시간 후(${targetForecast.time})에 $rainType 예보가 있습니다.',
            notificationDetails: details,
          );
          await prefs.setString('last_rain_notified_time', notifKey);
        }
      }
    }
  }

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
      final cityNameGu = prefs.getString('current_city_gu') ?? '구 선택';
      final dongName = prefs.getString('current_dong') ?? '동 선택';

      _weatherService.setGrid(nx, ny);
      final forecasts = await _weatherService.fetchForecast();
      final current = _weatherService.getCurrentWeather(forecasts);
      
      // Since we don't have sidoName stored in prefs right now easily and want to prevent a crash, rely on dongName fallback we wrote earlier, or save sidoName later. 
      // For now passing default '서울' as sidoName
      final airQuality = await _weatherService.fetchAirQuality('서울', cityNameGu, dongName);
      final yesterdayTemp = await _weatherService.fetchYesterdayTemp();
      final hourly = _weatherService.parseHourlyData(forecasts);

      // 4시간 후 비 예보 알림 체크
      await _checkAndNotifyRain(hourly, prefs);

      if (current != null) {
        final now = DateTime.now();
        final ampm = now.hour < 12 ? '오전' : '오후';
        final displayHour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
        final timeStr = '$ampm ${displayHour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        String title = '지금 $cityNameGu 날씨 - ${current.skyStatus}    $timeStr';
        String content = '🌡️ 현재 ${current.temp.toStringAsFixed(1)}°';
        
        if (yesterdayTemp != null) {
          final diff = current.temp - yesterdayTemp;
          if (diff > 0) {
            content += ' (어제보다 ${diff.toStringAsFixed(1)}° 높아요)';
          } else if (diff < 0) {
            content += ' (어제보다 ${diff.abs().toStringAsFixed(1)}° 낮아요)';
          } else {
            content += ' (어제와 같아요)';
          }
        }

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
    FlutterForegroundTask.initCommunicationPort();
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
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
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
