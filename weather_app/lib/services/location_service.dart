import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double lat;
  final double lon;
  final int nx;   // KMA 격자 X
  final int ny;   // KMA 격자 Y
  final String dongName;    // 역삼동
  final String fullAddress; // 서울특별시 강남구 역삼동

  LocationResult({
    required this.lat,
    required this.lon,
    required this.nx,
    required this.ny,
    required this.dongName,
    required this.fullAddress,
  });
}

class LocationService {
  /// 위치 권한 확인 및 요청
  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// 현재 위치 가져오기 (GPS)
  Future<LocationResult?> getCurrentLocation() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) return _defaultLocation(); // 기본값: 강남 역삼동

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lon = position.longitude;

      // KMA 격자 변환
      final grid = latLonToGrid(lat, lon);
      final nx = grid['nx']!;
      final ny = grid['ny']!;

      // 역지오코딩으로 주소 가져오기
      String dongName = '현재위치';
      String fullAddress = '';

      try {
        final placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // subLocality = 동(洞), locality = 시/구
          dongName = p.subLocality?.isNotEmpty == true
              ? p.subLocality!
              : (p.locality ?? '현재위치');
          final parts = [
            p.administrativeArea,
            p.subAdministrativeArea,
            p.subLocality,
          ].where((s) => s != null && s.isNotEmpty).toList();
          fullAddress = parts.join(' ');
        }
      } catch (_) {
        dongName = '현재위치';
      }

      return LocationResult(
        lat: lat,
        lon: lon,
        nx: nx,
        ny: ny,
        dongName: dongName,
        fullAddress: fullAddress,
      );
    } catch (e) {
      return _defaultLocation();
    }
  }

  /// 기본 위치 (강남구 역삼동)
  LocationResult _defaultLocation() {
    return LocationResult(
      lat: 37.5007,
      lon: 127.0368,
      nx: 61,
      ny: 125,
      dongName: '역삼동',
      fullAddress: '서울특별시 강남구 역삼동',
    );
  }

  /// 위도/경도 → KMA 기상청 격자 좌표 변환 (LCC 투영 공식)
  static Map<String, int> latLonToGrid(double lat, double lon) {
    const double RE = 6371.00877;   // 지구 반경 (km)
    const double GRID = 5.0;         // 격자 간격 (km)
    const double SLAT1 = 30.0;       // 투영 위도 1 (degree)
    const double SLAT2 = 60.0;       // 투영 위도 2 (degree)
    const double OLON = 126.0;       // 기준점 경도 (degree)
    const double OLAT = 38.0;        // 기준점 위도 (degree)
    const double XO = 43.0;          // 기준점 X 격자
    const double YO = 136.0;         // 기준점 Y 격자

    const double DEGRAD = math.pi / 180.0;

    final re = RE / GRID;
    final slat1 = SLAT1 * DEGRAD;
    final slat2 = SLAT2 * DEGRAD;
    final olon = OLON * DEGRAD;
    final olat = OLAT * DEGRAD;

    double sn = math.tan(math.pi * 0.25 + slat2 * 0.5) /
        math.tan(math.pi * 0.25 + slat1 * 0.5);
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(sn);

    double sf = math.pow(math.tan(math.pi * 0.25 + slat1 * 0.5), sn) *
        math.cos(slat1) / sn;

    double ro = re * sf /
        math.pow(math.tan(math.pi * 0.25 + olat * 0.5), sn);

    final ra = re * sf /
        math.pow(math.tan(math.pi * 0.25 + lat * DEGRAD * 0.5), sn);

    double theta = lon * DEGRAD - olon;
    if (theta > math.pi) theta -= 2.0 * math.pi;
    if (theta < -math.pi) theta += 2.0 * math.pi;
    theta *= sn;

    final x = (ra * math.sin(theta) + XO + 0.5).floor();
    final y = (ro - ra * math.cos(theta) + YO + 0.5).floor();

    return {'nx': x, 'ny': y};
  }
}
