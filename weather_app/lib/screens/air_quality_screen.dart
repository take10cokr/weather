import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../theme/app_theme.dart';

class AirQualityScreen extends StatefulWidget {
  const AirQualityScreen({super.key});

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  final WeatherService _service = WeatherService();
  AirQualityData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    // 현재는 '강남구' 기준, 실제로는 LocationService의 동이름 등을 활용 가능
    final data = await _service.fetchAirQuality('강남구');
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('대기질 상세', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAqiMainCard(context),
                    const SizedBox(height: 16),
                    _buildPollutantGrid(context),
                    const SizedBox(height: 16),
                    _buildHealthAdvice(),
                    const SizedBox(height: 16),
                    // 시간별 추이는 공공 API에서 제공하는 형태에 따라 추가 구현 가능 (현재는 생략)
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAqiMainCard(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final double mainAqi = _data?.aqi.toDouble() ?? 0;
    
    // PM2.5 수치로 등급 판단 (AQI 지수가 없는 경우 대비)
    final pm25Val = double.tryParse(_data?.pm25 ?? '0') ?? 0;
    final status = settings.getPm25Status(pm25Val);
    final color = settings.statusColor(status);
    
    // 등급별 안내 문구
    String advice = '현재 대기 질이 매우 좋습니다.\n마음껏 야외 활동을 즐기세요!';
    if (status == '보통') advice = '현재 대기 질이 무난합니다.\n야외 활동 시 참고하세요.';
    if (status == '나쁨') advice = '대기 질이 좋지 않습니다.\n장시간 야외 활동을 자제하세요.';
    if (status == '매우 나쁨') advice = '대기 질이 매우 나쁩니다!\n외출을 가급적 삼가주세요.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.air, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          const Text('통합 대기환경 지수 (KHAI)', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${_data?.aqi ?? "-"}', style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w800, height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          Text(
            advice,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (_data?.dataTime != null) ...[
             const SizedBox(height: 12),
             Text('측정시간: ${_data!.dataTime}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ]
        ],
      ),
    );
  }

  Widget _buildPollutantGrid(BuildContext context) {
    if (_data == null) return const SizedBox();
    
    final settings = context.watch<AppSettings>();

    // 숫자로 변환
    final p25 = double.tryParse(_data!.pm25) ?? 0;
    final p10 = double.tryParse(_data!.pm10) ?? 0;
    final o3v = double.tryParse(_data!.o3) ?? 0;
    final no2v = double.tryParse(_data!.no2) ?? 0;
    final so2v = double.tryParse(_data!.so2) ?? 0;
    final cov = double.tryParse(_data!.co) ?? 0;

    // 등급 계산
    final pm25Status = settings.getPm25Status(p25);
    final pm10Status = settings.getPm10Status(p10);
    
    // 오존 등은 일단 보통으로 고정하거나 로직 추가 가능
    String getSimpleStatus(double val, double normal, double bad) {
       if (val <= normal) return '좋음';
       if (val <= bad) return '보통';
       return '나쁨';
    }

    final pollutants = [
      Pollutant('PM2.5', _data!.pm25, 'μg/m³', pm25Status, settings.statusColor(pm25Status)),
      Pollutant('PM10',  _data!.pm10, 'μg/m³', pm10Status, settings.statusColor(pm10Status)),
      Pollutant('O₃',   _data!.o3,   'ppm',    getSimpleStatus(o3v, 0.03, 0.09), AppTheme.warningAqi),
      Pollutant('NO₂',  _data!.no2,  'ppm',    getSimpleStatus(no2v, 0.03, 0.06), AppTheme.goodAqi),
      Pollutant('SO₂',  _data!.so2,  'ppm',    getSimpleStatus(so2v, 0.02, 0.05), AppTheme.goodAqi),
      Pollutant('CO',   _data!.co,   'ppm',    getSimpleStatus(cov, 2.0, 9.0),   AppTheme.goodAqi),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: pollutants.length,
      itemBuilder: (context, i) {
        final p = pollutants[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              FittedBox(fit: BoxFit.scaleDown, child: Text(p.value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: p.color))),
              Text(p.unit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(p.status, style: TextStyle(color: p.color, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthAdvice() {
    final pm25Val = double.tryParse(_data?.pm25 ?? '0') ?? 0;
    final isBad = pm25Val > 35; // 단순 예시

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
              Icon(Icons.health_and_safety, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('건강 조언', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildAdviceItem(Icons.directions_run, '야외 활동', isBad ? '실외 활동을 줄이고 실내에서 활동하세요.' : '오늘은 야외 활동에 최적입니다!', isBad ? Colors.orange : AppTheme.goodAqi),
          _buildAdviceItem(Icons.masks, '마스크', isBad ? '보건용 마스크를 반드시 착용하세요.' : '마스크 착용이 필요 없는 날입니다.', isBad ? Colors.orange : AppTheme.goodAqi),
          _buildAdviceItem(Icons.window, '환기', isBad ? '대기 질이 좋지 않으니 환기를 자제하세요.' : '창문을 열고 환기시키기 좋은 날씨입니다.', isBad ? Colors.redAccent : AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildAdviceItem(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Pollutant {
  final String name, value, unit, status;
  final Color color;
  Pollutant(this.name, this.value, this.unit, this.status, this.color);
}
