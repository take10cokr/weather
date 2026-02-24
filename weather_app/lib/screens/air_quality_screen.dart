import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AirQualityScreen extends StatelessWidget {
  const AirQualityScreen({super.key});

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAqiMainCard(),
            const SizedBox(height: 16),
            _buildPollutantGrid(),
            const SizedBox(height: 16),
            _buildHealthAdvice(),
            const SizedBox(height: 16),
            _buildHourlyAqi(),
          ],
        ),
      ),
    );
  }

  Widget _buildAqiMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.goodAqi.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.air, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          const Text('대기질 지수 (AQI)', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('24', style: TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w800, height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('좋음 (Good)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const Text(
            '현재 대기 질이 매우 좋습니다.\n마음껏 야외 활동을 즐기세요!',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('50', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('100', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('150', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('200', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('300+', style: TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final indicatorLeft = (24 / 300) * constraints.maxWidth - 8;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(colors: [
                            Color(0xFF4CAF50), Color(0xFFFFEB3B),
                            Color(0xFFFF9800), Color(0xFFF44336),
                            Color(0xFF9C27B0), Color(0xFF7B1FA2),
                          ]),
                        ),
                      ),
                      Positioned(
                        left: indicatorLeft,
                        top: -3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantGrid() {
    final pollutants = [
      Pollutant('PM2.5', '8', 'μg/m³', '좋음', AppTheme.goodAqi),
      Pollutant('PM10', '22', 'μg/m³', '좋음', AppTheme.goodAqi),
      Pollutant('O₃', '45', 'μg/m³', '보통', AppTheme.warningAqi),
      Pollutant('NO₂', '12', 'μg/m³', '좋음', AppTheme.goodAqi),
      Pollutant('SO₂', '3', 'μg/m³', '좋음', AppTheme.goodAqi),
      Pollutant('CO', '0.4', 'mg/m³', '좋음', AppTheme.goodAqi),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: pollutants.length,
      itemBuilder: (context, i) {
        final p = pollutants[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(p.value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: p.color)),
              Text(p.unit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          _buildAdviceItem(Icons.directions_run, '야외 활동', '오늘은 야외 활동에 최적입니다!', AppTheme.goodAqi),
          _buildAdviceItem(Icons.masks, '마스크', '마스크 착용이 필요 없는 날입니다.', AppTheme.goodAqi),
          _buildAdviceItem(Icons.window, '환기', '창문을 열고 환기시키기 좋은 날씨입니다.', AppTheme.primaryColor),
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

  Widget _buildHourlyAqi() {
    final data = [
      {'time': '오전 6시', 'aqi': 20},
      {'time': '오전 9시', 'aqi': 24},
      {'time': '오후 12시', 'aqi': 35},
      {'time': '오후 3시', 'aqi': 30},
      {'time': '오후 6시', 'aqi': 22},
      {'time': '오후 9시', 'aqi': 18},
    ];

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
          const Text('시간별 AQI 추이', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final aqi = d['aqi'] as int;
              final height = (aqi / 50) * 80 + 20.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$aqi', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.goodAqi)),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppTheme.goodAqi.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goodAqi.withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d['time'] as String, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                ],
              );
            }).toList(),
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
