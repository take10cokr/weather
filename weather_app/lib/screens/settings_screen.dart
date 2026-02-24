import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedUnit = '섭씨 (°C)';
  String _selectedLanguage = '한국어';
  String _updateInterval = '30분마다';

  @override
  Widget build(BuildContext context) {
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
              _buildSwitchTile(Icons.notifications_active, '날씨 알림', '날씨 변화 시 Push 알림', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v), const Color(0xFF1565C0)),
              _buildSwitchTile(Icons.location_on, '위치 서비스', '현재 위치 기반 날씨 조회', _locationEnabled, (v) => setState(() => _locationEnabled = v), const Color(0xFF2E7D32)),
            ]),
            const SizedBox(height: 16),
            _buildSectionTitle('표시 설정'),
            _buildSettingCard([
              _buildDropdownTile(Icons.thermostat, '온도 단위', _selectedUnit, ['섭씨 (°C)', '화씨 (°F)'], (v) => setState(() => _selectedUnit = v!)),
              _buildDropdownTile(Icons.language, '언어', _selectedLanguage, ['한국어', 'English', '日本語'], (v) => setState(() => _selectedLanguage = v!)),
              _buildDropdownTile(Icons.update, '업데이트 주기', _updateInterval, ['10분마다', '30분마다', '1시간마다'], (v) => setState(() => _updateInterval = v!)),
              _buildSwitchTile(Icons.dark_mode, '다크 모드', '어두운 테마로 변경', _darkModeEnabled, (v) => setState(() => _darkModeEnabled = v), AppTheme.textSecondary),
            ]),
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
