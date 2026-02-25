import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 참조 이미지 스타일: 파란 플랫 디자인 날씨 아이콘 + 애니메이션
class AnimatedWeatherIcon extends StatefulWidget {
  final String weatherIcon; // 이모지 (사용 안 함 - 직접 그림)
  final int pty;            // 강수형태 (0=없음, 1=비, 3=눈, 4=소나기)
  final int sky;            // 하늘상태 (1=맑음, 3=구름많음, 4=흐림)
  final double size;

  const AnimatedWeatherIcon({
    super.key,
    required this.weatherIcon,
    this.pty = 0,
    this.sky = 1,
    this.size = 80,
  });

  @override
  State<AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<AnimatedWeatherIcon>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;   // 태양 회전
  late AnimationController _floatCtrl;    // 구름/비 부유
  late AnimationController _dropCtrl;     // 빗방울 낙하
  late AnimationController _snowCtrl;     // 눈 표류

  late Animation<double> _floatAnim;
  late Animation<double> _dropAnim;
  late Animation<double> _snowAnim;

  @override
  void initState() {
    super.initState();

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _snowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _dropAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dropCtrl, curve: Curves.linear),
    );

    _snowAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _snowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _floatCtrl.dispose();
    _dropCtrl.dispose();
    _snowCtrl.dispose();
    super.dispose();
  }

  bool get _isSunny => widget.pty == 0 && widget.sky <= 2;
  bool get _isPartlyCloudy => widget.pty == 0 && widget.sky == 3;
  bool get _isOvercast => widget.pty == 0 && widget.sky == 4;
  bool get _isRainy => widget.pty == 1 || widget.pty == 4;
  bool get _isSnowy => widget.pty == 3;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    // ☀️ 맑음 - 파란 태양 (회전 애니메이션)
    if (_isSunny) {
      return AnimatedBuilder(
        animation: _rotateCtrl,
        builder: (_, __) => Transform.rotate(
          angle: _rotateCtrl.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(s, s),
            painter: _SunPainter(),
          ),
        ),
      );
    }

    // ⛅ 구름 조금 - 태양 + 구름 (구름 부유)
    if (_isPartlyCloudy) {
      return AnimatedBuilder(
        animation: _floatAnim,
        builder: (_, __) => SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 뒤에 작은 태양
              Positioned(
                top: s * 0.02,
                left: s * 0.1,
                child: CustomPaint(
                  size: Size(s * 0.65, s * 0.65),
                  painter: _SunPainter(color: const Color(0xFFFFD54F)),
                ),
              ),
              // 앞에 구름 (부유)
              Positioned(
                bottom: s * 0.05 + _floatAnim.value * 0.3,
                right: s * 0.02,
                child: CustomPaint(
                  size: Size(s * 0.7, s * 0.45),
                  painter: _CloudPainter(color: const Color(0xFF90CAF9)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ☁️ 흐림 - 구름 2개 겹치기 (부유)
    if (_isOvercast) {
      return AnimatedBuilder(
        animation: _floatAnim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnim.value * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: Size(s, s * 0.6),
                painter: _CloudPainter(color: const Color(0xFF90CAF9)),
              ),
            ],
          ),
        ),
      );
    }

    // 🌧️ 비 - 구름 + 낙하 빗방울
    if (_isRainy) {
      return AnimatedBuilder(
        animation: Listenable.merge([_floatAnim, _dropAnim]),
        builder: (_, __) => SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                child: Transform.translate(
                  offset: Offset(0, _floatAnim.value * 0.3),
                  child: CustomPaint(
                    size: Size(s, s * 0.5),
                    painter: _CloudPainter(color: const Color(0xFF64B5F6)),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: CustomPaint(
                  size: Size(s, s * 0.45),
                  painter: _RainPainter(progress: _dropAnim.value),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ❄️ 눈 - 구름 + 눈송이
    if (_isSnowy) {
      return AnimatedBuilder(
        animation: Listenable.merge([_floatAnim, _snowAnim]),
        builder: (_, __) => SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                child: Transform.translate(
                  offset: Offset(0, _floatAnim.value * 0.3),
                  child: CustomPaint(
                    size: Size(s, s * 0.5),
                    painter: _CloudPainter(color: const Color(0xFF90CAF9)),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: CustomPaint(
                  size: Size(s, s * 0.45),
                  painter: _SnowPainter(offset: _snowAnim.value),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 기본: 태양
    return AnimatedBuilder(
      animation: _rotateCtrl,
      builder: (_, __) => Transform.rotate(
        angle: _rotateCtrl.value * 2 * math.pi,
        child: CustomPaint(size: Size(s, s), painter: _SunPainter()),
      ),
    );
  }
}

// ───────── 태양 ─────────
class _SunPainter extends CustomPainter {
  final Color color;
  _SunPainter({this.color = const Color(0xFFFFD54F)});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    // 글로우 효과 (밝은 노란 빛)
    canvas.drawCircle(
      Offset(cx, cy), r * 0.55,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final circlePaint = Paint()..color = color..style = PaintingStyle.fill;
    final rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round;

    // 중심 원
    canvas.drawCircle(Offset(cx, cy), r * 0.38, circlePaint);
    // 중심 하이라이트
    canvas.drawCircle(Offset(cx - r * 0.08, cy - r * 0.08), r * 0.15,
      Paint()..color = Colors.white.withValues(alpha: 0.4));

    // 광선 8개 (짧고 굵은 직선)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final inner = r * 0.52;
      final outer = r * 0.75;
      canvas.drawLine(
        Offset(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
        Offset(cx + outer * math.cos(angle), cy + outer * math.sin(angle)),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.color != color;
}

// ───────── 구름 ─────────
class _CloudPainter extends CustomPainter {
  final Color color;
  _CloudPainter({this.color = const Color(0xFF90CAF9)});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()..color = color..style = PaintingStyle.fill;

    // 구름 모양 (원들 조합)
    // 오른쪽 큰 원
    canvas.drawCircle(Offset(w * 0.62, h * 0.50), h * 0.40, paint);
    // 왼쪽 중간 원
    canvas.drawCircle(Offset(w * 0.38, h * 0.58), h * 0.32, paint);
    // 중앙 위 원
    canvas.drawCircle(Offset(w * 0.52, h * 0.38), h * 0.34, paint);
    // 바닥 채우기
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.12, h * 0.55, w * 0.96, h * 0.90),
      Radius.circular(h * 0.28),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.color != color;
}

// ───────── 빗방울 ─────────
class _RainPainter extends CustomPainter {
  final double progress; // 0.0~1.0

  _RainPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    // 빗방울 3줄 (각각 위상 다르게)
    final drops = [
      {'x': 0.25, 'phase': 0.0},
      {'x': 0.50, 'phase': 0.33},
      {'x': 0.75, 'phase': 0.66},
    ];

    for (final d in drops) {
      final x = size.width * (d['x'] as double);
      final phase = ((progress + (d['phase'] as double)) % 1.0);
      final y = size.height * phase;
      final alpha = (1.0 - phase).clamp(0.0, 1.0);

      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + size.height * 0.18),
        paint..color = const Color(0xFF42A5F5).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.progress != progress;
}

// ───────── 눈송이 ─────────
class _SnowPainter extends CustomPainter {
  final double offset; // -5~5

  _SnowPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.fill;

    // 눈송이 3개
    final flakes = [
      {'x': 0.25, 'base': 0.3},
      {'x': 0.50, 'base': 0.5},
      {'x': 0.75, 'base': 0.2},
    ];

    for (final f in flakes) {
      final x = size.width * (f['x'] as double);
      final y = size.height * (f['base'] as double) + offset;
      canvas.drawCircle(Offset(x, y), size.width * 0.06, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => old.offset != offset;
}
