import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/weather_model.dart';
import '../widgets/animated_weather_icon.dart';

class LocationSettingScreen extends StatefulWidget {
  final String dongName;
  final String fullAddress;
  final HourlyWeatherData? currentWeather;

  const LocationSettingScreen({
    super.key,
    required this.dongName,
    required this.fullAddress,
    required this.currentWeather,
  });

  @override
  State<LocationSettingScreen> createState() => _LocationSettingScreenState();
}

class _LocationSettingScreenState extends State<LocationSettingScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('지역설정', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            _buildSearchBox(),
            const SizedBox(height: 24),
            
            // Current Location Section
            Row(
              children: [
                const Icon(Icons.my_location, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                const Text('현재 위치', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            _buildCurrentLocationCard(),
            const SizedBox(height: 32),
            
            // Favorites Section
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                const Text('즐겨찾기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 60), // Add some spacing before the empty state message
            
            // Empty State
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('지역 검색 후 ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const Text('표를 눌러보세요!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: '읍/면/동으로 검색해주세요!',
          hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
          prefixIcon: Icon(Icons.search, color: Colors.black87, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    final weather = widget.currentWeather;
    final tempStr = weather != null ? '${weather.temp.round()}°' : '-°';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Location text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.dongName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(widget.fullAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          
          // Right: Weather text
          Row(
            children: [
              if (weather != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: AnimatedWeatherIcon(
                    weatherIcon: weather.weatherIcon,
                    pty: weather.pty,
                    sky: weather.sky,
                  ),
                ),
              if (weather == null)
                const Icon(Icons.wb_sunny, color: Colors.orange, size: 30),
              
              const SizedBox(width: 8),
              Text(tempStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}
