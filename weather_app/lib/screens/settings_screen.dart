import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = '한국어';
  String _updateInterval = '30분마다';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.w700)),
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
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('알림 설정'),
            _buildSettingCard([
              _buildSwitchTile(
                Icons.notifications_active, 
                '날씨 알림', 
                '상단바(Foreground) 상시 알림', 
                settings.notificationsEnabled, 
                (v) async {
                  await settings.setNotificationsEnabled(v);
                  if (v) {
                    await NotificationService.start();
                  } else {
                    await NotificationService.stop();
                  }
                }, 
                const Color(0xFF1565C0)
              ),
              _buildSwitchTile(
                Icons.location_on, 
                '위치 서비스', 
                '현재 위치 기반 날씨 조회', 
                settings.locationEnabled, 
                (v) => settings.setLocationEnabled(v), 
                const Color(0xFF2E7D32)
              ),
            ]),
            const SizedBox(height: 16),
            _buildSectionTitle('표시 설정'),
            _buildSettingCard([
              _buildDropdownTile(
                Icons.thermostat,
                '온도 단위',
                settings.temperatureUnit.label,
                [TemperatureUnit.celsius.label, TemperatureUnit.fahrenheit.label],
                (v) {
                  if (v == TemperatureUnit.celsius.label) {
                    settings.setTemperatureUnit(TemperatureUnit.celsius);
                  } else {
                    settings.setTemperatureUnit(TemperatureUnit.fahrenheit);
                  }
                },
              ),
              _buildDropdownTile(Icons.language, '언어', _selectedLanguage, ['한국어', 'English', '日本語'], (v) => setState(() => _selectedLanguage = v!)),
              _buildDropdownTile(Icons.update, '업데이트 주기', _updateInterval, ['10분마다', '30분마다', '1시간마다'], (v) => setState(() => _updateInterval = v!)),
            ]),
            const SizedBox(height: 16),
            _buildSectionTitle('미세먼지 표시 기준'),
            _buildDustStandardCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('앱 정보'),
            _buildSettingCard([
              _buildNavTile(Icons.info_outline, '앱 버전', '1.0.0'),
              _buildNavTile(Icons.privacy_tip_outlined, '개인정보 처리방침', ''),
              _buildNavTile(Icons.article_outlined, '이용약관', ''),
              _buildNavTile(Icons.star_border, '앱 평점 남기기', ''),
            ]),
            const SizedBox(height: 24),
            _buildClearCacheButton(),
          ],
        ),
      ),
      bottomNavigationBar: const SharedBottomNavBar(
        currentIndex: 3,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF258CF4), Color(0xFF1A6DD4)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WeatherPro 사용자', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('📍 서울특별시 강남구', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('마지막 업데이트: 오전 10:30', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textSecondary)),
    );
  }

  Widget _buildSettingCard(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: tiles.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < tiles.length - 1)
                Divider(height: 1, indent: 52, endIndent: 16, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String sub, bool val, ValueChanged<bool> onChanged, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: Switch.adaptive(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppTheme.primaryColor : null),
        value: val,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile(IconData icon, String title, String value, List<String> items, ValueChanged<String?> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      ),
    );
  }

  Widget _buildNavTile(IconData icon, String title, String trailing) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildDustStandardCard() {
    final settings = context.watch<AppSettings>();
    final current = settings.dustStandard;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // 안내 배너
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.masks_outlined, color: Color(0xFF43A047), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '기준에 따라 대기질 등급이 달라집니다',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
          // 국내 기준
          _buildStandardOption(
            standard: DustStandard.korean,
            current: current,
            icon: '🇰🇷',
            title: '국내 기준 (환경부)',
            description: 'PM2.5  좋음 ≤15 · 보통 ≤35 · 나쁨 ≤75 μg/m³',
            settings: settings,
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
          // WHO 기준
          _buildStandardOption(
            standard: DustStandard.who,
            current: current,
            icon: '🌍',
            title: '엄격한 기준 (WHO)',
            description: 'PM2.5  좋음 ≤5 · 보통 ≤15 · 나쁨 ≤25 μg/m³',
            settings: settings,
          ),
        ],
      ),
    );
  }

  Widget _buildStandardOption({
    required DustStandard standard,
    required DustStandard current,
    required String icon,
    required String title,
    required String description,
    required AppSettings settings,
  }) {
    final isSelected = standard == current;
    return InkWell(
      onTap: () => settings.setDustStandard(standard),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  )),
                  const SizedBox(height: 3),
                  Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearCacheButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('캐시가 삭제되었습니다.'), behavior: SnackBarBehavior.floating),
          );
        },
        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
        label: const Text('캐시 삭제', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
