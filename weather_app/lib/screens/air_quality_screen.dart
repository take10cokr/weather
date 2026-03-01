import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../theme/app_theme.dart';

class AirQualityScreen extends StatefulWidget {
  final String sidoName;
  final String dongName;

  const AirQualityScreen({
    super.key,
    required this.sidoName,
    required this.dongName,
  });

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
    final data = await _service.fetchAirQuality(widget.sidoName, widget.dongName);
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('대기질 상세', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 10, color: AppTheme.textSecondary),
                const SizedBox(width: 2),
                Text('${widget.sidoName} ${widget.dongName}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAqiMainCard(context),
                    const SizedBox(height: 32),
                    const Text('상세 오염 물질', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 16),
                    _buildPollutantGrid(context),
                    const SizedBox(height: 32),
                    _buildHourlyForecast(context),
                    const SizedBox(height: 32),
                    const Text('행동 권고', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 16),
                    _buildHealthAdvice(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAqiMainCard(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final int aqi = _data?.aqi ?? 0;
    
    final pm25Val = double.tryParse(_data?.pm25 ?? '0') ?? 0;
    final status = settings.getPm25Status(pm25Val);
    final color = settings.statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _AqiGaugePainter(value: aqi.toDouble(), color: color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('현재 지수', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('$aqi', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -1)),
                  Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              Positioned(
                right: 0,
                top: 10,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(Icons.cloud, size: 70, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Column(
      children: [
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50), // 좋음
                Color(0xFFFFEE58), // 보통
                Color(0xFFFFA726), // 나쁨
                Color(0xFFEF5350), // 매우나쁨
                Color(0xFF8E24AA), // 위험
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('좋음', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('보통', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('나쁨', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('매우나쁨', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('위험', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildPollutantGrid(BuildContext context) {
    final settings = context.watch<AppSettings>();

    final p25Str = _data?.pm25 ?? '-';
    final p10Str = _data?.pm10 ?? '-';
    final o3Str = _data?.o3 ?? '-';
    final no2Str = _data?.no2 ?? '-';
    final so2Str = _data?.so2 ?? '-';
    final coStr = _data?.co ?? '-';

    final p25 = double.tryParse(p25Str) ?? -1.0;
    final p10 = double.tryParse(p10Str) ?? -1.0;
    final o3v = double.tryParse(o3Str) ?? -1.0;
    final no2v = double.tryParse(no2Str) ?? -1.0;
    final so2v = double.tryParse(so2Str) ?? -1.0;
    final cov = double.tryParse(coStr) ?? -1.0;

    String getSimpleStatus(double val, double normal, double bad) {
       if (val < 0) return '-';
       if (val <= normal) return '좋음';
       if (val <= bad) return '보통';
       return '나쁨';
    }

    Color getStatusColor(String status) {
        if (status == '-') return Colors.grey;
        if (status == '좋음') return AppTheme.goodAqi;
        if (status == '보통') return const Color(0xFFFFEE58);
        if (status == '나쁨') return AppTheme.warningAqi;
        return AppTheme.dangerAqi;
    }

    final pollutants = [
      Pollutant('초미세먼지', p25Str, 'μg/m³', p25 < 0 ? '-' : settings.getPm25Status(p25), p25 < 0 ? Colors.grey : settings.statusColor(settings.getPm25Status(p25)), 'PM2.5'),
      Pollutant('미세먼지',  p10Str, 'μg/m³', p10 < 0 ? '-' : settings.getPm10Status(p10), p10 < 0 ? Colors.grey : settings.statusColor(settings.getPm10Status(p10)), 'PM10'),
      Pollutant('오존',   o3Str,   'ppm',    getSimpleStatus(o3v, 0.03, 0.09), getStatusColor(getSimpleStatus(o3v, 0.03, 0.09)), 'O3'),
      Pollutant('이산화질소',  no2Str,  'ppm',    getSimpleStatus(no2v, 0.03, 0.06), getStatusColor(getSimpleStatus(no2v, 0.03, 0.06)), 'NO2'),
      Pollutant('일산화탄소',   coStr,   'ppm',    getSimpleStatus(cov, 2.0, 9.0),   getStatusColor(getSimpleStatus(cov, 2.0, 9.0)), 'CO'),
      Pollutant('아황산가스',  so2Str,  'ppm',    getSimpleStatus(so2v, 0.02, 0.05), getStatusColor(getSimpleStatus(so2v, 0.02, 0.05)), 'SO2'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: pollutants.length,
      itemBuilder: (context, i) {
        final p = pollutants[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: p.color,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                          Text(p.subName ?? '', style: const TextStyle(fontSize: 9, color: Color(0xFFC0C8D6))),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(p.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                          const SizedBox(width: 4),
                          Text(p.unit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
                        ],
                      ),
                      Text(p.status, style: TextStyle(color: p.color, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHourlyForecast(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('시간별 대기질 예보', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
            Text('24시간 기준', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(40, '14:00'),
              _buildBar(55, '15:00'),
              _buildBar(65, '16:00'),
              _buildBar(45, '17:00'),
              _buildBar(35, '18:00'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF4A9FF5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildHealthAdvice() {
    return Column(
      children: [
        _buildAdviceCard(
          '마스크 착용 권고',
          '민감군은 실외 활동 시 일반 마스크 착용을 권장합니다.',
          Icons.masks_rounded,
          const Color(0xFFF1F8FF),
        ),
        const SizedBox(height: 12),
        _buildAdviceCard(
          '실내 환기 적정',
          '주기적인 환기는 좋으나, 도로변 등 오염원은 피하세요.',
          Icons.grid_view_rounded,
          const Color(0xFFF1F8FF),
        ),
        const SizedBox(height: 12),
        _buildAdviceCard(
          '실외 활동 가능',
          '대기 상태가 보통이므로 가벼운 운동은 무관합니다.',
          Icons.directions_run_rounded,
          const Color(0xFFF1F8FF),
        ),
      ],
    );
  }

  Widget _buildAdviceCard(String title, String desc, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AqiGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _AqiGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bgPaint = Paint()
      ..color = const Color(0xFFF0F2F5)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.14 * 0.75, 3.14 * 1.5, false, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    double sweepAngle = (value / 150) * 3.14 * 1.5;
    if (sweepAngle > 3.14 * 1.5) sweepAngle = 3.14 * 1.5;
    
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.14 * 0.75, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Pollutant {
  final String name, value, unit, status;
  final String? subName;
  final Color color;
  Pollutant(this.name, this.value, this.unit, this.status, this.color, [this.subName]);
}
