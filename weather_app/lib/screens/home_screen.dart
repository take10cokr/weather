import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../widgets/animated_weather_icon.dart';
import '../widgets/sun_moon_widgets.dart';
import 'air_quality_screen.dart';
import 'outfit_screen.dart';
import 'settings_screen.dart';

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
  bool _isLocating = true;            // GPS 찾는 중

  List<WeatherForecast> _forecasts = [];
  List<HourlyWeatherData> _hourlyData = [];
  List<DailyForecastData> _dailyData = [];
  HourlyWeatherData? _currentWeather;
  DressingIndex? _dressingIndex;
  double _maxTemp = 0;
  double _minTemp = 0;

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
      if (mounted) setState(() => _dongName = loc.dongName);
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

      setState(() {
        _forecasts = forecasts;
        _hourlyData = _service.parseHourlyData(forecasts);
        _dailyData = _service.parseDailyForecast(forecasts);
        _currentWeather = _service.getCurrentWeather(forecasts);
        _dressingIndex = dressing;
        _maxTemp = minMax['max'] ?? 0;
        _minTemp = minMax['min'] ?? 0;
        _isLoading = false;
        _errorMessage = '';
      });
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
      backgroundColor: AppTheme.backgroundColor,
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

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekDays = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    final dateStr = '${now.month}월 ${now.day}일 ${weekDays[now.weekday % 7]}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLocating ? Icons.gps_not_fixed : Icons.location_on,
                  color: AppTheme.primaryColor, size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _dongName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                if (_isLocating)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: SizedBox(width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryColor),
                    ),
                  ),
                if (!_isLocating)
                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 2),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _loadWeatherData,
          ),
        ),
      ],
    );
  }

  Widget _buildMainWeatherCard() {
    final current = _currentWeather;
    final temp = current?.temp.round() ?? 0;
    final desc = current?.weatherDesc ?? '맑음';
    final humidity = current?.reh.round() ?? 45;
    final windSpeed = current?.wsd.toStringAsFixed(1) ?? '0.0';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF258CF4), Color(0xFF1A6DD4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: Container(width: 180, height: 180, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle))),
          Positioned(right: 30, top: 30, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$temp', style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w700, height: 1)),
                            const Padding(padding: EdgeInsets.only(top: 12), child: Text('°C', style: TextStyle(color: Colors.white70, fontSize: 30))),
                          ],
                        ),
                        Text('최고 ${_maxTemp.round()}° / 최저 ${_minTemp.round()}°', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    AnimatedWeatherIcon(
                      weatherIcon: current?.weatherIcon ?? '☀️',
                      pty: current?.pty ?? 0,
                      sky: current?.sky ?? 1,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherStat(Icons.water_drop_outlined, '$humidity%', '습도'),
                    _buildWeatherStat(Icons.air, '${windSpeed}m/s', '풍속'),
                    _buildWeatherStat(Icons.thermostat, '${_maxTemp.round()}°', '최고'),
                    _buildWeatherStat(Icons.thermostat_outlined, '${_minTemp.round()}°', '최저'),
                  ],
                ),
              ],
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryColor, size: 18),
              SizedBox(width: 6),
              Text('시간별 기온 추이', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _hourlyData.isEmpty
              ? const Center(child: Text('데이터 없음', style: TextStyle(color: AppTheme.textSecondary)))
              : SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _hourlyData.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = _hourlyData[index];
                      final isNow = index == 0;
                      return Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isNow ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: isNow ? null : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(item.time, style: TextStyle(fontSize: 10, color: isNow ? Colors.white70 : AppTheme.textSecondary), textAlign: TextAlign.center),
                            Text(item.weatherIcon, style: const TextStyle(fontSize: 22)),
                            Text('${item.temp.round()}°', style: TextStyle(fontWeight: FontWeight.w700, color: isNow ? Colors.white : AppTheme.textPrimary, fontSize: 15)),
                            if (item.pop > 0)
                              Text('${item.pop}%', style: TextStyle(fontSize: 9, color: isNow ? Colors.lightBlue[100] : Colors.blue)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    final current = _currentWeather;
    final humidity = current?.reh.round() ?? 45;
    final windSpeed = current?.wsd.toStringAsFixed(1) ?? '0.0';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildDetailCard(Icons.air, '풍속', '${windSpeed}m/s', '북동풍 (NE)', const Color(0xFFE3F2FD)),
        _buildDetailCard(Icons.wb_sunny_outlined, '자외선 지수', 'UV 3', '낮음', const Color(0xFFFFF8E1)),
        _buildDetailCard(Icons.visibility, '가시거리', '20km', '선명함', const Color(0xFFE8F5E9)),
        _buildDetailCard(Icons.water_drop, '습도', '$humidity%', humidity > 70 ? '다소 높음' : '쾌적함', const Color(0xFFEDE7F6)),
      ],
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value, String sub, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: AppTheme.primaryColor)),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month, color: AppTheme.primaryColor, size: 18),
              SizedBox(width: 6),
              Text('7일간 예보', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._dailyData.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 52, child: Text(item.dayLabel, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                Text(item.weatherEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.weatherDesc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                Text('${item.maxTemp.round()}°', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.deepOrange, fontSize: 15)),
                const SizedBox(width: 4),
                Text('/ ${item.minTemp.round()}°', style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
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
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitScreen(apiAdvice: dressingAdvice)));
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
