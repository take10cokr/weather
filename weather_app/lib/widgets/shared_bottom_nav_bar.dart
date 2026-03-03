import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/air_quality_screen.dart';
import '../screens/outfit_screen.dart';
import '../screens/settings_screen.dart';
import '../models/weather_model.dart';

class SharedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String sidoName;
  final String cityName;
  final String dongName;
  final AirQualityData? airQuality;
  final String dressingAdvice;
  final double currentTemp;

  const SharedBottomNavBar({
    super.key,
    required this.currentIndex,
    this.sidoName = '',
    this.cityName = '',
    this.dongName = '',
    this.airQuality,
    this.dressingAdvice = '',
    this.currentTemp = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;

          switch (index) {
            case 0:
              // 홈 화면으로 이동 (모든 스택 비우기)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => AirQualityScreen(
                    sidoName: sidoName,
                    cityName: cityName,
                    dongName: dongName,
                    initialData: airQuality,
                  ),
                  transitionDuration: Duration.zero,
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => OutfitScreen(
                    apiAdvice: dressingAdvice,
                    currentTemp: currentTemp,
                  ),
                  transitionDuration: Duration.zero,
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SettingsScreen(),
                  transitionDuration: Duration.zero,
                ),
              );
              break;
          }
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
