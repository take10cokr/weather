/// 기상청 API 응답 모델들

class WeatherForecast {
  final String category;
  final String fcstDate;
  final String fcstTime;
  final String fcstValue;

  WeatherForecast({
    required this.category,
    required this.fcstDate,
    required this.fcstTime,
    required this.fcstValue,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      category: json['category'] ?? '',
      fcstDate: json['fcstDate'] ?? '',
      fcstTime: json['fcstTime'] ?? '',
      fcstValue: json['fcstValue'] ?? '',
    );
  }
}

class HourlyWeatherData {
  final String time;
  final double temp;
  final int sky;    // 1:맑음 3:구름많음 4:흐림
  final int pty;    // 0:없음 1:비 2:비눈 3:눈 4:소나기
  final int pop;    // 강수확률
  final double reh; // 습도
  final double wsd; // 풍속

  HourlyWeatherData({
    required this.time,
    required this.temp,
    required this.sky,
    required this.pty,
    required this.pop,
    required this.reh,
    required this.wsd,
  });

  String get weatherDesc {
    if (pty == 1) return '비';
    if (pty == 2) return '비/눈';
    if (pty == 3) return '눈';
    if (pty == 4) return '소나기';
    switch (sky) {
      case 1: return '맑음';
      case 3: return '구름많음';
      case 4: return '흐림';
      default: return '맑음';
    }
  }

  String get weatherIcon {
    if (pty == 1 || pty == 4) return '🌧️';
    if (pty == 2) return '🌨️';
    if (pty == 3) return '❄️';
    switch (sky) {
      case 1: return '☀️';
      case 3: return '⛅';
      case 4: return '☁️';
      default: return '☀️';
    }
  }
}

class DailyForecastData {
  final String date;
  final String dayLabel;
  final double maxTemp;
  final double minTemp;
  final int sky;
  final int pty;

  DailyForecastData({
    required this.date,
    required this.dayLabel,
    required this.maxTemp,
    required this.minTemp,
    required this.sky,
    required this.pty,
  });

  String get weatherDesc {
    if (pty == 1) return '비';
    if (pty == 2) return '비/눈';
    if (pty == 3) return '눈';
    if (pty == 4) return '소나기';
    switch (sky) {
      case 1: return '맑음';
      case 3: return '구름많음';
      case 4: return '흐림';
      default: return '맑음';
    }
  }

  String get weatherEmoji {
    if (pty == 1 || pty == 4) return '🌧️';
    if (pty == 2) return '🌨️';
    if (pty == 3) return '❄️';
    switch (sky) {
      case 1: return '☀️';
      case 3: return '⛅';
      case 4: return '☁️';
      default: return '☀️';
    }
  }
}

class DressingIndex {
  final String h3;  // 3시간 FDWR 값
  final String h6;
  final String h9;
  final String h12;

  DressingIndex({
    required this.h3,
    required this.h6,
    required this.h9,
    required this.h12,
  });

  String get outfitAdvice {
    final val = int.tryParse(h3) ?? 0;
    if (val >= 95) return '두꺼운 코트, 목도리, 기모제품 착용 추천';
    if (val >= 85) return '코트나 가죽재킷, 니트, 스카프 착용 추천';
    if (val >= 75) return '간절기 트렌치코트나 재킷, 청재킷 추천';
    if (val >= 65) return '가디건이나 간절기 재킷, 스웨터 추천';
    if (val >= 55) return '긴바지, 긴소매가 적당해요';
    if (val >= 40) return '반팔, 얇은 긴소매, 면바지 추천';
    return '민소매, 반팔, 반바지, 원피스 추천';
  }

  String get outfitEmoji {
    final val = int.tryParse(h3) ?? 0;
    if (val >= 85) return '🧥';
    if (val >= 65) return '🧶';
    if (val >= 40) return '👕';
    return '🩳';
  }
}

class AirQualityData {
  final int aqi;
  final String pm25;
  final String pm10;
  final String o3;
  final String no2;
  final String so2;
  final String co;
  final String dataTime;
  final String stationName;

  AirQualityData({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.so2,
    required this.co,
    required this.dataTime,
    required this.stationName,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    String getValue(dynamic val) {
      final s = val?.toString() ?? '-';
      return (s == '-' || s == 'null' || s.isEmpty) ? '-' : s;
    }

    return AirQualityData(
      aqi: int.tryParse(getValue(json['khaiValue'])) ?? -1,
      pm25: getValue(json['pm25Value']),
      pm10: getValue(json['pm10Value']),
      o3: getValue(json['o3Value']),
      no2: getValue(json['no2Value']),
      so2: getValue(json['so2Value']),
      co: getValue(json['coValue']),
      dataTime: json['dataTime']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? '알 수 없음',
    );
  }
}
