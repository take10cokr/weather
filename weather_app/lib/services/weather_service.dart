import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey =
      '793622d7dd6ef91e5a86118379a1797c650ee138bfe7a49a04f51ed126aa1338';

  // 기본 격자 좌표 (서울 강남구 역삼동)
  int _nx = 61;
  int _ny = 125;

  void setGrid(int nx, int ny) {
    _nx = nx;
    _ny = ny;
  }

  // 단기예보 base_time 목록 (내림차순)
  static const List<String> _baseTimes = [
    '2300', '2000', '1700', '1400', '1100', '0800', '0500', '0200'
  ];

  /// 현재 시각으로 베이스 날짜/시간 계산
  Map<String, String> _getBaseDateTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    // 현재 시각보다 이전인 가장 최근 base_time 찾기 (10분 딜레이 고려)
    String baseTime = '2300';
    DateTime baseDate = now;

    for (final t in _baseTimes) {
      final tHour = int.parse(t.substring(0, 2));
      final tMin = 10; // 발표 후 10분 딜레이
      if (hour > tHour || (hour == tHour && minute >= tMin)) {
        baseTime = t;
        break;
      }
    }

    // base_time이 2300인데 현재시각이 0200보다 이전이면 전날 2300으로
    if (baseTime == '2300' && hour < 2) {
      baseDate = now.subtract(const Duration(days: 1));
    }

    final dateStr =
        '${baseDate.year}${baseDate.month.toString().padLeft(2, '0')}${baseDate.day.toString().padLeft(2, '0')}';

    return {'date': dateStr, 'time': baseTime};
  }

  /// 단기예보 API 호출
  Future<List<WeatherForecast>> fetchForecast() async {
    final dt = _getBaseDateTime();
    final uri = Uri.https(
      'apis.data.go.kr',
      '/1360000/VilageFcstInfoService_2.0/getVilageFcst',
      {
        'serviceKey': _apiKey,
        'pageNo': '1',
        'numOfRows': '1500',
        'dataType': 'JSON',
        'base_date': dt['date']!,
        'base_time': dt['time']!,
        'nx': '$_nx',
        'ny': '$_ny',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final resultCode = body['response']['header']['resultCode'];
        if (resultCode != '00') return [];
        final items = body['response']['body']['items']['item'] as List;
        return items.map((e) => WeatherForecast.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  /// 시간별 날씨 데이터 파싱 (최대 48시간)
  List<HourlyWeatherData> parseHourlyData(List<WeatherForecast> forecasts) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final Map<String, Map<String, String>> grouped = {};
    for (final f in forecasts) {
      final key = f.fcstDate + f.fcstTime;
      grouped.putIfAbsent(key, () => {});
      grouped[key]![f.category] = f.fcstValue;
    }

    // 현재 시간에 가장 가까운 시간부터 정렬
    final sortedKeys = grouped.keys.toList()..sort();
    final nowKey = todayStr + now.hour.toString().padLeft(2, '0') + '00';
    
    final displayKeys = sortedKeys.where((k) => k.compareTo(nowKey) >= 0).toList();

    return displayKeys.take(48).map((key) {
      final data = grouped[key]!;
      final fDate = key.substring(0, 8);
      final fTime = key.substring(8);
      final hour = int.parse(fTime.substring(0, 2));
      
      final isNowSlot = fDate == todayStr && hour == now.hour;
      final ampm = hour < 12 ? '오전' : '오후';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      String label = isNowSlot ? '지금' : '$ampm ${displayHour}시';
      
      // 내일이나 모레인 경우 라벨에 표시
      if (fDate != todayStr) {
        final d = DateTime(
          int.parse(fDate.substring(0, 4)),
          int.parse(fDate.substring(4, 6)),
          int.parse(fDate.substring(6, 8)),
        );
        final today = DateTime(now.year, now.month, now.day);
        final diff = d.difference(today).inDays;
        
        if (diff == 1) label = '내일 $label';
        else if (diff == 2) label = '모레 $label';
      }

      return HourlyWeatherData(
        time: label,
        temp: double.tryParse(data['TMP'] ?? '') ?? 0,
        sky: int.tryParse(data['SKY'] ?? '1') ?? 1,
        pty: int.tryParse(data['PTY'] ?? '0') ?? 0,
        pop: int.tryParse(data['POP'] ?? '0') ?? 0,
        reh: double.tryParse(data['REH'] ?? '0') ?? 0,
        wsd: double.tryParse(data['WSD'] ?? '0') ?? 0,
      );
    }).toList();
  }

  /// 오늘 현재 기온 가져오기
  HourlyWeatherData? getCurrentWeather(List<WeatherForecast> forecasts) {
    final hourly = parseHourlyData(forecasts);
    return hourly.isNotEmpty ? hourly.first : null;
  }

  /// 오늘 최고/최저 기온
  Map<String, double> getTodayMinMax(List<WeatherForecast> forecasts) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final tmxList = forecasts.where((f) => f.fcstDate == todayStr && f.category == 'TMX').map((f) => double.tryParse(f.fcstValue) ?? 0).toList();
    final tmnList = forecasts.where((f) => f.fcstDate == todayStr && f.category == 'TMN').map((f) => double.tryParse(f.fcstValue) ?? 0).toList();
    final tmpList = forecasts.where((f) => f.fcstDate == todayStr && f.category == 'TMP').map((f) => double.tryParse(f.fcstValue) ?? 0).toList();

    double maxTemp = tmxList.isNotEmpty ? tmxList.reduce((a, b) => a > b ? a : b) : (tmpList.isNotEmpty ? tmpList.reduce((a, b) => a > b ? a : b) : 0);
    double minTemp = tmnList.isNotEmpty ? tmnList.reduce((a, b) => a < b ? a : b) : (tmpList.isNotEmpty ? tmpList.reduce((a, b) => a < b ? a : b) : 0);

    return {'max': maxTemp, 'min': minTemp};
  }

  /// 주간 예보 파싱 (7일치)
  List<DailyForecastData> parseDailyForecast(List<WeatherForecast> forecasts) {
    final now = DateTime.now();
    final Map<String, Map<String, dynamic>> dailyMap = {};

    for (final f in forecasts) {
      dailyMap.putIfAbsent(f.fcstDate, () => {'tmps': <double>[], 'skys': <int>[], 'ptys': <int>[]});
      if (f.category == 'TMP') {
        (dailyMap[f.fcstDate]!['tmps'] as List<double>).add(double.tryParse(f.fcstValue) ?? 0);
      }
      if (f.category == 'TMX') {
        dailyMap[f.fcstDate]!['tmx'] = double.tryParse(f.fcstValue) ?? 0;
      }
      if (f.category == 'TMN') {
        dailyMap[f.fcstDate]!['tmn'] = double.tryParse(f.fcstValue) ?? 0;
      }
      if (f.category == 'SKY') {
        (dailyMap[f.fcstDate]!['skys'] as List<int>).add(int.tryParse(f.fcstValue) ?? 1);
      }
      if (f.category == 'PTY') {
        (dailyMap[f.fcstDate]!['ptys'] as List<int>).add(int.tryParse(f.fcstValue) ?? 0);
      }
    }

    final dayLabels = ['오늘', '내일', '모레'];
    final weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    final sortedDates = dailyMap.keys.toList()..sort();

    return sortedDates.take(7).toList().asMap().entries.map((entry) {
      final idx = entry.key;
      final date = entry.value;
      final data = dailyMap[date]!;

      final tmps = data['tmps'] as List<double>;
      final skys = data['skys'] as List<int>;
      final ptys = data['ptys'] as List<int>;

      double maxT = data['tmx'] as double? ?? (tmps.isNotEmpty ? tmps.reduce((a, b) => a > b ? a : b) : 0);
      double minT = data['tmn'] as double? ?? (tmps.isNotEmpty ? tmps.reduce((a, b) => a < b ? a : b) : 0);

      // 대표 날씨 (가장 많이 나온 값)
      int sky = skys.isNotEmpty ? _mode(skys) : 1;
      int pty = ptys.isNotEmpty ? _mode(ptys) : 0;

      // 날짜 → 요일 계산
      String label;
      if (idx < dayLabels.length) {
        label = dayLabels[idx];
      } else {
        final d = DateTime(
          int.parse(date.substring(0, 4)),
          int.parse(date.substring(4, 6)),
          int.parse(date.substring(6, 8)),
        );
        label = weekDays[d.weekday % 7];
      }

      return DailyForecastData(
        date: date,
        dayLabel: label,
        maxTemp: maxT,
        minTemp: minT,
        sky: sky,
        pty: pty,
      );
    }).toList();
  }

  int _mode(List<int> list) {
    final freq = <int, int>{};
    for (final v in list) freq[v] = (freq[v] ?? 0) + 1;
    return freq.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// 생활기상지수 - 옷차림 지수 API
  Future<DressingIndex?> fetchDressingIndex() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      'https://apis.data.go.kr/1360000/LivingWthrIdxServiceV4/getLivingWthrIdxV4DressingIdex'
      '?serviceKey=$_apiKey'
      '&pageNo=1'
      '&numOfRows=10'
      '&dataType=JSON'
      '&areaNo=1168000000' // 서울 강남구 행정코드
      '&time=${dateStr}06', // YYYYMMDDH
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final item = body['response']['body']['items']['item'];
        if (item != null) {
          final data = item is List ? item.first : item;
          return DressingIndex(
            h3: data['h3']?.toString() ?? '65',
            h6: data['h6']?.toString() ?? '65',
            h9: data['h9']?.toString() ?? '65',
            h12: data['h12']?.toString() ?? '65',
          );
        }
      }
    } catch (e) {
      // 에러 시 null 반환
    }
    return null;
  }

  /// 어제 동시간대 기온 조회
  Future<double?> fetchYesterdayTemp() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final dayBefore = now.subtract(const Duration(days: 2));
    
    final yesterdayStr = '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';
    final dayBeforeStr = '${dayBefore.year}${dayBefore.month.toString().padLeft(2, '0')}${dayBefore.day.toString().padLeft(2, '0')}';

    final uri = Uri.https(
      'apis.data.go.kr',
      '/1360000/VilageFcstInfoService_2.0/getVilageFcst',
      {
        'serviceKey': _apiKey,
        'pageNo': '1',
        'numOfRows': '1000',
        'dataType': 'JSON',
        'base_date': dayBeforeStr,
        'base_time': '2300',
        'nx': '$_nx',
        'ny': '$_ny',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final resultCode = body['response']['header']['resultCode'];
        if (resultCode != '00') return null;
        
        final items = body['response']['body']['items']['item'] as List;
        final targetHour = '${now.hour.toString().padLeft(2, '0')}00';
        
        for (var item in items) {
          if (item['fcstDate'] == yesterdayStr && item['fcstTime'] == targetHour && item['category'] == 'TMP') {
            return double.tryParse(item['fcstValue']);
          }
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// 습도 가져오기 (현재 시간대)
  double getCurrentHumidity(List<WeatherForecast> forecasts) {
    final current = getCurrentWeather(forecasts);
    return current?.reh ?? 45;
  }

  /// 풍속 가져오기
  double getCurrentWindSpeed(List<WeatherForecast> forecasts) {
    final current = getCurrentWeather(forecasts);
    return current?.wsd ?? 2.5;
  }

  /// 에어코리아 대기질 실시간 정보 가져오기 (시도별 실시간 측정 데이터)
  Future<AirQualityData?> fetchAirQuality(String city) async {
    // API 주소: 한국환경공단_에어코리아_대기오염정보
    final uri = Uri.parse(
        'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
        '?serviceKey=$_apiKey'
        '&returnType=json'
        '&numOfRows=100'
        '&pageNo=1'
        '&sidoName=서울'
        '&ver=1.3');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final items = body['response']['body']['items'] as List;
        
        // 해당 시군구(stationName) 데이터 찾기
        final item = items.firstWhere(
            (e) => e['stationName'] == city, 
            orElse: () => items.first);

        if (item != null) {
          return AirQualityData.fromJson(item);
        }
      }
    } catch (e) {
      // 에러 시 null
    }
    return null;
  }
}
