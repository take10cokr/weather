import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 미세먼지 표시 기준
enum DustStandard {
  korean, // 국내 기준 (환경부)
  who,    // 엄격한 기준 (WHO 권고)
}

extension DustStandardExt on DustStandard {
  String get label {
    switch (this) {
      case DustStandard.korean:
        return '국내 기준 (환경부)';
      case DustStandard.who:
        return '엄격한 기준 (WHO)';
    }
  }

  String get description {
    switch (this) {
      case DustStandard.korean:
        return 'PM2.5 좋음 ≤15 / 보통 ≤35 / 나쁨 ≤75';
      case DustStandard.who:
        return 'PM2.5 좋음 ≤5 / 보통 ≤15 / 나쁨 ≤25';
    }
  }
}

class AppSettings extends ChangeNotifier {
  static const _keyDustStandard = 'dust_standard';
  static const _keyInterestItems = 'interest_items';

  DustStandard _dustStandard = DustStandard.korean;
  List<String> _interestItems = ['풍속', '자외선 지수', '가시거리', '습도']; // 기본 4개

  DustStandard get dustStandard => _dustStandard;
  List<String> get interestItems => _interestItems;

  /// SharedPreferences에서 설정 불러오기
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyDustStandard);
    if (saved == 'who') {
      _dustStandard = DustStandard.who;
    } else {
      _dustStandard = DustStandard.korean;
    }
    
    final savedItems = prefs.getStringList(_keyInterestItems);
    if (savedItems != null && savedItems.length == 4) {
      _interestItems = savedItems;
    }
    
    notifyListeners();
  }

  /// 미세먼지 기준 변경 & 저장
  Future<void> setDustStandard(DustStandard standard) async {
    _dustStandard = standard;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDustStandard, standard.name);
  }

  /// 관심날씨 4개 저장
  Future<void> setInterestItems(List<String> items) async {
    if (items.length != 4) return;
    _interestItems = items;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyInterestItems, items);
  }

  // ── 기준별 PM2.5 임계값 ──────────────────────────────
  /// PM2.5 등급 반환 (값: μg/m³)
  String getPm25Status(double value) {
    if (_dustStandard == DustStandard.who) {
      if (value <= 5)  return '좋음';
      if (value <= 15) return '보통';
      if (value <= 25) return '나쁨';
      return '매우 나쁨';
    } else {
      if (value <= 15) return '좋음';
      if (value <= 35) return '보통';
      if (value <= 75) return '나쁨';
      return '매우 나쁨';
    }
  }

  /// PM10 등급 반환 (값: μg/m³)
  String getPm10Status(double value) {
    if (_dustStandard == DustStandard.who) {
      if (value <= 15) return '좋음';
      if (value <= 45) return '보통';
      if (value <= 75) return '나쁨';
      return '매우 나쁨';
    } else {
      if (value <= 30) return '좋음';
      if (value <= 80) return '보통';
      if (value <= 150) return '나쁨';
      return '매우 나쁨';
    }
  }

  /// 등급에 따른 색상
  Color statusColor(String status) {
    switch (status) {
      case '좋음':      return const Color(0xFF43A047);
      case '보통':      return const Color(0xFFFFA726);
      case '나쁨':      return const Color(0xFFEF5350);
      case '매우 나쁨': return const Color(0xFF8E24AA);
      default:          return const Color(0xFF43A047);
    }
  }
}
