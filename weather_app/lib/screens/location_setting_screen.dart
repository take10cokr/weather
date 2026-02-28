import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/weather_model.dart';
import '../widgets/animated_weather_icon.dart';
import '../services/app_settings.dart';

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
  List<String> _filteredLocations = [];

  final List<String> _mockLocations = [
    '서울특별시 강남구 역삼동',
    '서울특별시 강남구 삼성동',
    '서울특별시 서초구 서초동',
    '서울특별시 서초구 방배동',
    '경기도 성남시 분당구 정자동',
    '경기도 성남시 분당구 판교동',
    '경기도 수원시 영통구 영통동',
    '경기도 수원시 팔달구 인계동',
    '인천광역시 연수구 송도동',
    '인천광역시 부평구 부평동',
    '부산광역시 해운대구 우동',
    '부산광역시 수영구 광안동',
    '대구광역시 수성구 범어동',
    '광주광역시 서구 치평동',
    '대전광역시 서구 둔산동',
    '울산광역시 남구 삼산동',
    '제주특별자치도 제주시 노형동',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _filteredLocations = _mockLocations
            .where((loc) => loc.contains(query))
            .toList();
      });
    } else {
      setState(() {
        _filteredLocations = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

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
            
            // Search Results
            if (_filteredLocations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredLocations.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final loc = _filteredLocations[index];
                    final isFavorite = appSettings.favoriteLocations.contains(loc);
                    return CheckboxListTile(
                      title: Text(loc, style: const TextStyle(fontSize: 14)),
                      value: isFavorite,
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      onChanged: (bool? value) {
                        appSettings.toggleFavoriteLocation(loc);
                      },
                    );
                  },
                ),
              ),
            ],

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
            
            if (appSettings.favoriteLocations.isEmpty) ...[
              const SizedBox(height: 60),
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
            ] else ...[
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appSettings.favoriteLocations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final loc = appSettings.favoriteLocations[index];
                  // Extract dong name similar to how we show current location
                  final dongName = loc.split(' ').last;
                  return _buildFavoriteLocationCard(dongName, loc, appSettings);
                },
              ),
            ],
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

  Widget _buildFavoriteLocationCard(String dongName, String fullAddress, AppSettings appSettings) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dongName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(fullAddress, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis,),
              ],
            ),
          ),
          
          // Right: Delete button
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () {
              appSettings.toggleFavoriteLocation(fullAddress);
            },
          ),
        ],
      ),
    );
  }
}
