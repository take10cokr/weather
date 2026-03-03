import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_bottom_nav_bar.dart';

class OutfitScreen extends StatelessWidget {
  final String apiAdvice;
  final double currentTemp;
  const OutfitScreen({super.key, this.apiAdvice = '', this.currentTemp = 15.0});

  static const List<OutfitItem> outfits = [
    OutfitItem(temp: '15°C', icon: Icons.dry_cleaning, title: '가벼운 자켓', desc: '약간 쌀쌀할 수 있으니 가벼운 자켓이나 가디건을 걸치는 것을 추천합니다.', tags: ['자켓', '가디건', '긴팔'], color: Color(0xFF1565C0)),
    OutfitItem(temp: '10~14°C', icon: Icons.layers, title: '레이어드 스타일', desc: '아침저녁으로 기온 차가 있으니 레이어드 스타일로 입으세요.', tags: ['레이어드', '맨투맨', '청바지'], color: Color(0xFF6A1B9A)),
    OutfitItem(temp: '20°C 이상', icon: Icons.wb_sunny_outlined, title: '가벼운 여름 복장', desc: '따뜻한 날씨에 반팔이나 얇은 옷을 추천합니다.', tags: ['반팔', '반바지', '원피스'], color: Color(0xFFE65100)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('옷차림 추천', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayRecommendation(),
            const SizedBox(height: 20),
            const Text('기온별 추천 코디', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ...outfits.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOutfitCard(item),
            )),
            const SizedBox(height: 16),
            _buildTips(),
          ],
        ),
      ),
      bottomNavigationBar: SharedBottomNavBar(
        currentIndex: 2,
        dressingAdvice: apiAdvice,
        currentTemp: currentTemp,
      ),
    );
  }

  Widget _buildTodayRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF258CF4), Color(0xFF5E35B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checkroom, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('오늘의 추천 코디', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.dry_cleaning, color: Colors.white, size: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('가벼운 자켓 + 긴팔', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('현재 기온 ${currentTemp.round()}°C에 최적화된 코디입니다.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: ['자켓', '긴팔', '청바지', '운동화'].map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        apiAdvice.isNotEmpty
                            ? apiAdvice
                            : '약간 쌀쌀할 수 있으니 가벼운 자켓이나 가디건을 걸치는 것을 추천합니다.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(OutfitItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 30),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(6)),
                    child: Text(item.temp, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(item.desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: item.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: item.color.withValues(alpha: 0.2)),
                    ),
                    child: Text(tag, style: TextStyle(color: item.color, fontSize: 10, fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text('오늘의 패션 팁', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF4E342E))),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            '🌡️ 아침/저녁 기온 차가 크니 겉옷을 꼭 챙기세요',
            '🌬️ 바람이 있으니 바람막이 효과 있는 옷 추천',
            '🌤️ 낮에는 따뜻하니 탈착이 쉬운 레이어드 스타일 추천',
          ].map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(tip, style: const TextStyle(color: Color(0xFF6D4C41), fontSize: 13)),
          )),
        ],
      ),
    );
  }
}

class OutfitItem {
  final String temp, title, desc;
  final IconData icon;
  final List<String> tags;
  final Color color;
  const OutfitItem({required this.temp, required this.icon, required this.title, required this.desc, required this.tags, required this.color});
}
