import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../widgets/animated_weather_icon.dart';
import '../widgets/sun_moon_widgets.dart';
import 'air_quality_screen.dart';
import 'outfit_screen.dart';
import 'settings_screen.dart';
import 'interest_weather_setting_screen.dart';
import 'location_setting_screen.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final WeatherService _service = WeatherService();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  String _errorMessage = '';
  String _dongName = '역삼동';        // 표시할 동 이름
  String _fullAddress = '서울특별시 강남구 역삼동'; // 전체 주소
  bool _isLocating = true;            // GPS 찾는 중

  List<WeatherForecast> _forecasts = [];
  List<HourlyWeatherData> _hourlyData = [];
  List<DailyForecastData> _dailyData = [];
  HourlyWeatherData? _currentWeather;
  AirQualityData? _airQuality;
  DressingIndex? _dressingIndex;
  double _maxTemp = 0;
  double _minTemp = 0;
  double? _yesterdayTemp; // 어제 기온 저장용

  @override
  void initState() {
    super.initState();
    _initLocationAndWeather();
  }

  Future<void> _initLocationAndWeather() async {
    // GPS 위치 먼저
    final loc = await _locationService.getCurrentLocation();
    if (loc != null) {
      _service.setGrid(loc.nx, loc.ny);
      
      // 위치 정보 저장 (알림 서비스 공유용)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('nx', loc.nx);
      await prefs.setInt('ny', loc.ny);
      await prefs.setString('current_city', loc.dongName);

      if (mounted) setState(() {
        _dongName = loc.dongName;
        _fullAddress = loc.fullAddress;
      });
    }
    setState(() => _isLocating = false);
    await _loadWeatherData();
  }


  Future<void> _loadWeatherData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    try {
      final forecasts = await _service.fetchForecast();
      final dressing = await _service.fetchDressingIndex();
      final minMax = _service.getTodayMinMax(forecasts);
      final airQuality = await _service.fetchAirQuality(_dongName);
      final yesterdayTemp = await _service.fetchYesterdayTemp();

      setState(() {
        _forecasts = forecasts;
        _hourlyData = _service.parseHourlyData(forecasts);
        _dailyData = _service.parseDailyForecast(forecasts);
        _currentWeather = _service.getCurrentWeather(forecasts);
        _dressingIndex = dressing;
        _airQuality = airQuality;
        _maxTemp = minMax['max'] ?? 0;
        _minTemp = minMax['min'] ?? 0;
        _yesterdayTemp = yesterdayTemp;
        _isLoading = false;
        _errorMessage = '';
      });
      
      NotificationService.start();
    } catch (e) {
      setState(() {
        _errorMessage = '날씨 정보를 불러올 수 없습니다.';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경을 흰색으로 변경
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView()
            : RefreshIndicator(
                onRefresh: () => _loadWeatherData(isRefresh: true),
                color: AppTheme.primaryColor,
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                displacement: 20,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        if (_errorMessage.isNotEmpty)
                          _buildErrorBanner()
                        else ...[
                          _buildMainWeatherCard(),
                          const SizedBox(height: 16),
                          _buildAirQualityCard(),
                          const SizedBox(height: 16),
                          if (_dressingIndex != null) _buildDressingCard(),
                          const SizedBox(height: 16),
                          _buildHourlyForecast(),
                          const SizedBox(height: 16),
                          _buildWeatherDetails(),
                          const SizedBox(height: 16),
                          _buildWeeklyForecast(),
                          const SizedBox(height: 16),
                          _buildSunriseSunset(),
                          const SizedBox(height: 16),
                          _buildMoonPhase(),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          const Text('기상청에서 날씨를 불러오는 중...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('잠시만 기다려 주세요 ☁️', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent))),
          TextButton(onPressed: _loadWeatherData, child: const Text('재시도')),
        ],
      ),
    );
  }

  Future<void> _setLocationFromAddress(String fullAddress) async {
    setState(() => _isLocating = true);
    try {
      final locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final grid = LocationService.latLonToGrid(loc.latitude, loc.longitude);
        final nx = grid['nx']!;
        final ny = grid['ny']!;
        
        String dongName = fullAddress.split(' ').last;

        _service.setGrid(nx, ny);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('nx', nx);
        await prefs.setInt('ny', ny);
        await prefs.setString('current_city', dongName);

        if (mounted) {
          setState(() {
            _dongName = dongName;
            _fullAddress = fullAddress;
          });
          await _loadWeatherData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 찾을 수 없습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekDays = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    final dateStr = '${now.month}월 ${now.day}일 ${weekDays[now.weekday % 7]}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String displayName = _dongName;
    final String addressToSplit = _fullAddress.trim().isEmpty ? _dongName : _fullAddress;
    final parts = addressToSplit.split(' ').where((s) => s.trim().isNotEmpty).toList();
    
    if (parts.length >= 2) {
      displayName = '${parts[parts.length - 2]} ${parts[parts.length - 1]}';
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // 왼쪽 햄버거 메뉴
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.textPrimary, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ),
        // 중앙 지역명 및 날짜
        Column(
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
        // 오른쪽 위치 추가 아이콘
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: AppTheme.textPrimary, size: 26),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationSettingScreen(
              dongName: _dongName,
              fullAddress: _fullAddress,
              currentWeather: _currentWeather,
            ))),
          ),
        ),
      ],
    );
  }

  Widget _buildMainWeatherCard() {
    final current = _currentWeather;
    final temp = current?.temp.round() ?? 0;
    final desc = current?.weatherDesc ?? '맑음';
    final humidity = current?.reh.round() ?? 0;
    final windSpeed = current?.wsd.toStringAsFixed(1) ?? '0.0';

    String diffText = '';
    if (_yesterdayTemp != null && current != null) {
      final diff = current.temp - _yesterdayTemp!;
      if (diff.abs() < 0.5) {
        diffText = '어제와 기온이 비슷해요';
      } else if (diff > 0) {
        diffText = '어제보다 ${diff.abs().toStringAsFixed(1).replaceAll('.0', '')}° 높아요';
      } else {
        diffText = '어제보다 ${diff.abs().toStringAsFixed(1).replaceAll('.0', '')}° 낮아요';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 원 포인트
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        desc,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$temp',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 76,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -3),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 14, left: 2),
                            child: Text(
                              '°C',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 날씨 아이콘
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 10),
                    child: Hero(
                      tag: 'weather_icon',
                      child: AnimatedWeatherIcon(
                        weatherIcon: current?.weatherIcon ?? '☀️',
                        pty: current?.pty ?? 0,
                        sky: current?.sky ?? 1,
                        size: 90,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (diffText.isNotEmpty)
                Text(
                  diffText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 8),
              Text(
                '최고 ${_maxTemp.round()}° / 최저 ${_minTemp.round()}°',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherStat(Icons.water_drop_outlined, '$humidity%', '습도'),
                  _buildWeatherStat(Icons.air, '${windSpeed}m/s', '풍속'),
                  _buildWeatherStat(Icons.thermostat_outlined, '${_maxTemp.round()}°', '최고'),
                  _buildWeatherStat(Icons.thermostat_outlined, '${_minTemp.round()}°', '최저'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildAirQualityCard() {
    if (_airQuality == null) return const SizedBox();
    
    final pm25Value = double.tryParse(_airQuality!.pm25) ?? 0;
    final status = context.read<AppSettings>().getPm25Status(pm25Value);
    final color = context.read<AppSettings>().statusColor(status);
    final aqi = _airQuality!.aqi;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FF), // 이미지와 유사한 연한 파란색 배경
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1F0FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Icon(Icons.energy_savings_leaf_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('미세먼지 상태', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  status == '좋음' ? '현재 대기 질이 매우 좋습니다.' : (status == '보통' ? '현재 대기 질이 보통입니다.' : '대기 질이 좋지 않습니다.'),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
              Text('AQI $aqi', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDressingCard() {
    final dressing = _dressingIndex!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5E35B1), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF5E35B1).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text(dressing.outfitEmoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘의 옷차림 추천', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(dressing.outfitAdvice, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('옷차림 지수 ${dressing.h3}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    // 표시할 데이터 (최대 48시간)
    final displayData = _hourlyData.length > 48 ? _hourlyData.sublist(0, 48) : _hourlyData;

    // 시간 포맷 변환 - 이미 '오전 10시', '지금' 등으로 포맷되어 있음
    String formatTimeLabel(String time) {
      if (time == '지금') return '지금';
      // "오전 10시" → "오전\n10시" 로 줄바꿈 처리
      if (time.contains(' ')) {
        return time.replaceFirst(' ', '\n');
      }
      return time;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 타이틀 + 오늘 (24H) 탭
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule, color: AppTheme.primaryColor, size: 18),
                  SizedBox(width: 6),
                  Text('시간별 기온 추이', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('48H 예보', style: TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 곡선 차트 + 온도/시간 라벨 통합
          displayData.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('데이터 없음', style: TextStyle(color: AppTheme.textSecondary)),
                ))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    height: 180, // 아이콘 영역 확보를 위해 높이 증가
                    width: math.max(
                        MediaQuery.of(context).size.width - 32,
                        displayData.length * 55.0),
                    child: CustomPaint(
                      painter: _HourlyChartPainter(
                        data: displayData,
                        formatTimeLabel: formatTimeLabel,
                        dayMaxTemp: _maxTemp,
                        dayMinTemp: _minTemp,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        final items = settings.interestItems;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard_customize, color: AppTheme.primaryColor, size: 18),
                    SizedBox(width: 6),
                    Text('관심날씨 설정', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => InterestWeatherSettingScreen(
                        currentWeather: _currentWeather,
                        maxTemp: _maxTemp,
                        minTemp: _minTemp,
                      )
                    ));
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text('설정 >', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: items.map((id) => _buildDynamicDetailCard(id)).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDynamicDetailCard(String id) {
    final current = _currentWeather;
    
    switch (id) {
      case '풍속':
        final wsd = current?.wsd.toStringAsFixed(1) ?? '0.0';
        return _buildDetailCard(Icons.air, '풍속', '${wsd}m/s', '북동풍 (NE)', Colors.blue, const Color(0xFFE3F2FD));
      case '자외선 지수':
        return _buildDetailCard(Icons.wb_sunny_outlined, '자외선 지수', 'UV 3', '낮음', Colors.orange, const Color(0xFFFFF8E1));
      case '가시거리':
        return _buildDetailCard(Icons.visibility, '가시거리', '20km', '선명함', Colors.grey, const Color(0xFFF5F5F5));
      case '습도':
        final humidity = current?.reh.round() ?? 45;
        return _buildDetailCard(Icons.water_drop, '습도', '$humidity%', humidity > 70 ? '다소 높음' : '쾌적함', Colors.lightBlue, const Color(0xFFE1F5FE));
      case '강수확률':
        final pop = current?.pop ?? 0;
        return _buildDetailCard(Icons.umbrella_outlined, '강수확률', '$pop%', pop > 40 ? '우산 챙기세요' : '맑음', Colors.blueAccent, const Color(0xFFE8EAF6));
      case '강수량':
        return _buildDetailCard(Icons.water_drop_outlined, '강수량', '0mm', '비 안옴', Colors.cyan, const Color(0xFFE0F7FA));
      case '체감온도':
        final temp = current?.temp.round() ?? 0;
        return _buildDetailCard(Icons.thermostat, '체감온도', '$temp°', '비슷함', Colors.redAccent, const Color(0xFFFFEBEE));
      case '미세먼지':
        final pm10 = _airQuality?.pm10 ?? '30';
        return _buildDetailCard(Icons.masks_outlined, '미세먼지', pm10, context.read<AppSettings>().getPm10Status(double.tryParse(pm10) ?? 0), Colors.green, const Color(0xFFE8F5E9));
      case '초미세먼지':
        final pm25 = _airQuality?.pm25 ?? '15';
        return _buildDetailCard(Icons.masks, '초미세먼지', pm25, context.read<AppSettings>().getPm25Status(double.tryParse(pm25) ?? 0), Colors.teal, const Color(0xFFE0F2F1));
      case '옷차림':
        final h3 = _dressingIndex?.h3 ?? '65';
        return _buildDetailCard(Icons.checkroom, '옷차림', h3, '지수', Colors.purple, const Color(0xFFF3E5F5));
      case '일정명':
        return _buildDetailCard(Icons.calendar_month, '일정명', 'D-10', '다가오는 일정', Colors.indigo, const Color(0xFFE8EAF6));
      default:
        return _buildDetailCard(Icons.info_outline, id, '-', '-', Colors.grey, const Color(0xFFF5F5F5));
    }
  }

  Widget _buildDetailCard(IconData icon, String title, String value, String sub, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 18),
                  SizedBox(width: 8),
                  Text('5일간 일기예보', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                ],
              ),
              Icon(Icons.bar_chart_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ..._dailyData.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(width: 50, child: Text(item.dayLabel, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
                const SizedBox(width: 4),
                Text(item.weatherEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                // 온도 진행바 (이미지 스타일)
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.center,
                      widthFactor: 0.6, // 예시용 고정 비율 (실제로는 기온 데이터로 계산 가능)
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF2196F3)]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${item.maxTemp.round()}°', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('${item.minTemp.round()}°', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSunriseSunset() {
    return const SunriseSunsetCard(
      sunriseTime: '07:12',
      sunsetTime: '18:14',
    );
  }

  Widget _buildMoonPhase() {
    return const MoonPhaseCard(
      phaseName: '상현달',
      moonrise: '오후 12:44',
      moonset: '오전 02:18',
      phaseValue: 0.25,
    );
  }

  Widget _buildSunItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Color(0xFF795548), fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          final dressingAdvice = _dressingIndex?.outfitAdvice ?? '';
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const AirQualityScreen()));
          if (index == 2) {
            final currentTemp = _currentWeather?.temp ?? 15.0;
            Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitScreen(apiAdvice: dressingAdvice, currentTemp: currentTemp)));
          }
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.air_rounded), label: '대기질'),
          BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: '옷차림'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '설정'),
        ],
      ),
    );
  }
}

/// 시간별 기온 추이 곡선 차트 페인터
class _HourlyChartPainter extends CustomPainter {
  final List<HourlyWeatherData> data;
  final String Function(String) formatTimeLabel;
  final double dayMaxTemp;
  final double dayMinTemp;

  _HourlyChartPainter({
    required this.data,
    required this.formatTimeLabel,
    required this.dayMaxTemp,
    required this.dayMinTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double topPadding = 28;   // 온도 라벨 영역
    const double bottomPadding = 56; // 시간 라벨 + 아이콘 영역 확보 (36 -> 56)
    const double sidePadding = 24;

    final chartTop = topPadding;
    final chartBottom = size.height - bottomPadding;
    final chartHeight = chartBottom - chartTop;
    final chartWidth = size.width - sidePadding * 2;

    // 최대/최소 온도 계산 (현재 차트 데이터 중)
    final temps = data.map((e) => e.temp).toList();
    final localMaxTemp = temps.reduce((a, b) => a > b ? a : b);
    final localMinTemp = temps.reduce((a, b) => a < b ? a : b);
    
    // 차트의 전체 Y축 산정 시, 앱 전체의 일일 최고/최저(dayMaxTemp/dayMinTemp)를 기준으로 여백을 포함하여 높이를 제어합니다.
    // 만약 데이터 중 범위를 벗어나는 값이 있으면 그 값을 우선 적용합니다.
    final chartMaxTemp = math.max(dayMaxTemp, localMaxTemp);
    final chartMinTemp = math.min(dayMinTemp, localMinTemp);

    final tempRange = (chartMaxTemp - chartMinTemp).abs();
    final effectiveRange = tempRange < 1 ? 1.0 : tempRange;

    // 각 데이터 포인트 좌표 계산
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = sidePadding + (chartWidth / (data.length - 1)) * i;
      final normalizedTemp = (data[i].temp - chartMinTemp) / effectiveRange;
      final y = chartBottom - normalizedTemp * chartHeight;
      points.add(Offset(x, y));
    }

    // 부드러운 곡선 경로 생성 (Catmull-Rom → Cubic Bezier)
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // 그래디언트 채우기 경로
    final fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, chartBottom);
    fillPath.lineTo(points.first.dx, chartBottom);
    fillPath.close();

    // 그래디언트 채우기
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4A9FF5).withValues(alpha: 0.3),
          const Color(0xFF4A9FF5).withValues(alpha: 0.05),
          const Color(0xFF4A9FF5).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, chartTop, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // 곡선 선 그리기
    final linePaint = Paint()
      ..color = const Color(0xFF4A9FF5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // 각 포인트에 도트 + 온도 라벨 + 시간 라벨
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // 도트 (외곽 파랑 + 내부 흰색)
      canvas.drawCircle(point, 3.5, Paint()..color = const Color(0xFF4A9FF5));
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);

      // 온도 라벨 (포인트 위)
      final tempText = TextPainter(
        text: TextSpan(
          text: '${data[i].temp.round()}°',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tempText.layout();
      tempText.paint(canvas, Offset(point.dx - tempText.width / 2, point.dy - tempText.height - 8));

      // 시간 라벨 (차트 하단)
      final timeLabel = formatTimeLabel(data[i].time);
      final timeLines = timeLabel.split('\n');
      double yOffset = chartBottom + 4;
      for (final line in timeLines) {
        final timeText = TextPainter(
          text: TextSpan(
            text: line,
            style: const TextStyle(color: Color(0xFF999999), fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        timeText.layout();
        timeText.paint(canvas, Offset(point.dx - timeText.width / 2, yOffset));
        yOffset += 12;
      }

      // 날씨 아이콘 (시간 라벨 아래)
      final iconText = TextPainter(
        text: TextSpan(
          text: data[i].weatherIcon,
          style: const TextStyle(fontSize: 15),
        ),
        textDirection: TextDirection.ltr,
      );
      iconText.layout();
      iconText.paint(canvas, Offset(point.dx - iconText.width / 2, yOffset + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
