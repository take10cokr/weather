import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// 일출/일몰 호(Arc) 카드
class SunriseSunsetCard extends StatefulWidget {
  final String sunriseTime; // "07:12"
  final String sunsetTime;  // "17:44"

  const SunriseSunsetCard({
    super.key,
    required this.sunriseTime,
    required this.sunsetTime,
  });

  @override
  State<SunriseSunsetCard> createState() => _SunriseSunsetCardState();
}

class _SunriseSunsetCardState extends State<SunriseSunsetCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnim;

  double _getSunProgress() {
    final now = DateTime.now();
    final sunriseParts = widget.sunriseTime.split(':');
    final sunsetParts = widget.sunsetTime.split(':');
    final sunrise = DateTime(now.year, now.month, now.day,
        int.parse(sunriseParts[0]), int.parse(sunriseParts[1]));
    final sunset = DateTime(now.year, now.month, now.day,
        int.parse(sunsetParts[0]), int.parse(sunsetParts[1]));
    if (now.isBefore(sunrise)) return 0.0;
    if (now.isAfter(sunset)) return 1.0;
    final total = sunset.difference(sunrise).inMinutes;
    final elapsed = now.difference(sunrise).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.animateTo(_getSunProgress());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    if (hour == 0) return '오전 12:$minute AM';
    if (hour < 12) return '오전 $hour:$minute AM';
    if (hour == 12) return '오후 12:$minute PM';
    return '오후 ${hour - 12}:$minute PM';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_twilight, color: Color(0xFFFFAB40), size: 20),
              SizedBox(width: 8),
              Text('일출 / 일몰', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: 140,
                    width: constraints.maxWidth,
                    child: CustomPaint(
                      painter: SunArcPainter(progress: _progressAnim.value),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeInfo(Icons.wb_sunny, '일출', _formatTime(widget.sunriseTime), const Color(0xFFFF8F00)),
              _buildTimeInfo(Icons.nightlight_round, '일몰', _formatTime(widget.sunsetTime), const Color(0xFF5C6BC0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text(time, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class SunArcPainter extends CustomPainter {
  final double progress;
  SunArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ 캔버스 범위 밖으로 그리지 않도록 클리핑
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cx = size.width / 2;
    const sunMargin = 20.0; // 태양 아이콘 + 글로우 여유 공간
    final cy = size.height - 6; // 바닥에서 약간 위로

    // ✅ 타원 반지름 계산 (완만한 곡선을 위해 rx > ry)
    final rx = (size.width - sunMargin * 2) / 2;
    final ry = (cy - sunMargin) * 0.7; // 높이의 70%만 사용하여 완만하게 처리
    final arcRect = Rect.fromLTRB(cx - rx, cy - ry, cx + rx, cy + ry);

    // ✅ 점선 호 배경 (타원형)
    final bgPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    _drawDashedEllipticalArc(canvas, arcRect, bgPaint);

    // 지평선
    canvas.drawLine(
      Offset(cx - rx - 8, cy),
      Offset(cx + rx + 8, cy),
      Paint()..color = Colors.grey.shade300..strokeWidth = 1.0,
    );

    // 태양 위치 계산 (시간 흐름에 맞춰 X축 선형 이동 후 타원 Y 좌표 계산)
    final sunX = (cx - rx) + (rx * 2) * progress;
    final nx = (sunX - cx) / rx;
    final val = 1.0 - (nx * nx);
    final sunY = cy - ry * math.sqrt(math.max(0.0, val));

    // 태양 글로우 효과
    canvas.drawCircle(
      Offset(sunX, sunY),
      20,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 태양 아이콘 그리기
    final textPainter = TextPainter(
      text: TextSpan(
        text: '☀️',
        style: TextStyle(
          fontSize: 24,
          shadows: [
            Shadow(
              blurRadius: 10,
              color: const Color(0xFFFFAB40).withValues(alpha: 0.8),
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(sunX - textPainter.width / 2, sunY - textPainter.height / 2),
    );

    // 일출 점 (왼쪽)
    _drawEndDot(canvas, cx - rx, cy, const Color(0xFFFFB300));
    // 일몰 점 (오른쪽)
    _drawEndDot(canvas, cx + rx, cy, const Color(0xFF7986CB));
  }

  void _drawEndDot(Canvas canvas, double x, double y, Color color) {
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
    canvas.drawCircle(Offset(x, y), 5,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  /// ✅ 타원형 점선 호 그리기
  void _drawDashedEllipticalArc(Canvas canvas, Rect rect, Paint paint) {
    const int n = 36;                             // 점선 개수
    const double totalAngle = math.pi;            // 180도
    const double dashRatio = 0.6;
    const double segAngle = totalAngle / n;
    const double dashAngle = segAngle * dashRatio;

    for (int i = 0; i < n; i++) {
      final startAngle = math.pi + i * segAngle;
      canvas.drawArc(rect, startAngle, dashAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(SunArcPainter old) => old.progress != progress;
}


/// 달 위상 카드
class MoonPhaseCard extends StatelessWidget {
  final String phaseName; // "상현달"
  final String moonrise;  // "오후 12:44"
  final String moonset;   // "오전 02:18"
  final double phaseValue; // 0.0~1.0

  const MoonPhaseCard({
    super.key,
    required this.phaseName,
    required this.moonrise,
    required this.moonset,
    required this.phaseValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nightlight, color: Color(0xFF90A4AE), size: 20),
              SizedBox(width: 8),
              Text('달 위상', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CustomPaint(
                size: const Size(72, 72),
                painter: MoonPhasePainter(phase: phaseValue),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(phaseName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 14),
                    _buildMoonTime(Icons.arrow_upward_rounded, '월출', moonrise, const Color(0xFFFFB300)),
                    const SizedBox(height: 8),
                    _buildMoonTime(Icons.arrow_downward_rounded, '월몰', moonset, const Color(0xFF90A4AE)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoonTime(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text('$label  ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(time, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
      ],
    );
  }
}

class MoonPhasePainter extends CustomPainter {
  final double phase; // 0.0~1.0

  MoonPhasePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 달 밝은 면 (전체 원)
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFECEFF1));

    // 위상 그림자 마스크
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final shadowPaint = Paint()
      ..color = const Color(0xFF546E7A).withValues(alpha: 0.9);

    // phase: 0=삭(어두움), 0.25=상현(오른쪽 밝음), 0.5=보름(밝음), 0.75=하현(왼쪽 밝음)
    if (phase < 0.5) {
      // 오른쪽이 점점 밝아짐
      final xOffset = radius - (phase / 0.5) * 2 * radius;
      final shadowPath = Path()
        ..addArc(Rect.fromCircle(center: center, radius: radius), math.pi / 2, math.pi);
      if (xOffset > 0) {
        shadowPath.addOval(Rect.fromCenter(center: center, width: xOffset * 2, height: radius * 2));
      }
      canvas.drawPath(shadowPath, shadowPaint);
      if (xOffset < 0) {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: xOffset.abs() * 2, height: radius * 2),
          Paint()..color = const Color(0xFFECEFF1),
        );
      }
    } else {
      // 왼쪽이 점점 밝아짐 (하현)
      final xOffset = ((phase - 0.5) / 0.5) * 2 * radius - radius;
      final shadowPath = Path()
        ..addArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi);
      canvas.drawPath(shadowPath, shadowPaint);
      if (xOffset > 0) {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: xOffset * 2, height: radius * 2),
          shadowPaint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: xOffset.abs() * 2, height: radius * 2),
          Paint()..color = const Color(0xFFECEFF1),
        );
      }
    }

    canvas.restore();

    // 크레이터
    _drawCrater(canvas, center + const Offset(-10, -8), 4);
    _drawCrater(canvas, center + const Offset(8, 6), 6);
    _drawCrater(canvas, center + const Offset(-4, 12), 3);

    // 테두리
    canvas.drawCircle(center, radius,
        Paint()..color = Colors.blueGrey.shade200..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawCrater(Canvas canvas, Offset pos, double r) {
    canvas.drawCircle(pos, r, Paint()..color = Colors.blueGrey.shade100);
    canvas.drawCircle(pos, r, Paint()..color = Colors.blueGrey.shade200..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(MoonPhasePainter old) => old.phase != phase;
}
