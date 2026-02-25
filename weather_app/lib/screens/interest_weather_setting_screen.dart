import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../models/weather_model.dart';
import '../widgets/animated_weather_icon.dart';

class InterestWeatherSettingScreen extends StatefulWidget {
  final HourlyWeatherData? currentWeather;
  final double maxTemp;
  final double minTemp;

  const InterestWeatherSettingScreen({
    super.key,
    this.currentWeather,
    required this.maxTemp,
    required this.minTemp,
  });

  @override
  State<InterestWeatherSettingScreen> createState() => _InterestWeatherSettingScreenState();
}

class _InterestWeatherSettingScreenState extends State<InterestWeatherSettingScreen> {
  late List<String> _selectedItems;

  final List<Map<String, dynamic>> _allOptions = [
    {'id': '풍속', 'icon': Icons.air, 'color': Colors.blue},
    {'id': '자외선 지수', 'icon': Icons.wb_sunny_outlined, 'color': Colors.orange},
    {'id': '가시거리', 'icon': Icons.visibility, 'color': Colors.grey},
    {'id': '습도', 'icon': Icons.water_drop, 'color': Colors.lightBlue},
    {'id': '강수확률', 'icon': Icons.umbrella_outlined, 'color': Colors.blueAccent},
    {'id': '강수량', 'icon': Icons.water_drop_outlined, 'color': Colors.cyan},
    {'id': '체감온도', 'icon': Icons.thermostat, 'color': Colors.redAccent},
    {'id': '미세먼지', 'icon': Icons.masks_outlined, 'color': Colors.green},
    {'id': '초미세먼지', 'icon': Icons.masks, 'color': Colors.teal},
    {'id': '옷차림', 'icon': Icons.checkroom, 'color': Colors.purple},
    {'id': '일정명', 'icon': Icons.calendar_month, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    // 초기 선택 항목 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedItems = List.from(context.read<AppSettings>().interestItems);
      });
    });
    _selectedItems = []; // 빌드 에러 방지
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        if (_selectedItems.length > 1) {
          _selectedItems.remove(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('최소 1개 이상 선택해야 합니다.'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        if (_selectedItems.length < 4) {
          _selectedItems.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('최대 4개까지만 선택할 수 있습니다.'), duration: Duration(seconds: 1)),
          );
        }
      }
    });
  }

  void _saveSettings() {
    if (_selectedItems.length == 4) {
      context.read<AppSettings>().setInterestItems(_selectedItems);
      Navigator.pop(context);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('4개를 모두 선택해주세요.'), duration: Duration(seconds: 1)),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('관심날씨 설정', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_selectedItems.length == 4) {
               _saveSettings();
              }
            },
            child: Text('저장', style: TextStyle(color: _selectedItems.length == 4 ? AppTheme.primaryColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopWeatherInfo(),
            const SizedBox(height: 24),
            _buildSelectedPreview(),
            const SizedBox(height: 32),
            _buildOptionsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopWeatherInfo() {
    final current = widget.currentWeather;
    final temp = current?.temp.round() ?? 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedWeatherIcon(
          weatherIcon: current?.weatherIcon ?? '☀️',
          pty: current?.pty ?? 0,
          sky: current?.sky ?? 1,
        ),
        const SizedBox(width: 8),
        Text('$temp°', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('어제보다 2° 높아요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('최고 ${widget.maxTemp.round()}° ↑  최저 ${widget.minTemp.round()}° ↓', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        )
      ],
    );
  }

  Widget _buildSelectedPreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        if (index < _selectedItems.length) {
          final id = _selectedItems[index];
          final option = _allOptions.firstWhere((e) => e['id'] == id);
          return Expanded(child: _buildPreviewCard(option));
        } else {
          return Expanded(child: _buildEmptyPreviewCard());
        }
      }),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(option['icon'], color: option['color'], size: 28),
          const SizedBox(height: 12),
          Text(option['id'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyPreviewCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: const Column(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.grey, size: 28),
          SizedBox(height: 12),
          Text('선택', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _allOptions.length,
        itemBuilder: (context, index) {
          final option = _allOptions[index];
          final isSelected = _selectedItems.contains(option['id']);
          
          return GestureDetector(
            onTap: () => _toggleSelection(option['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(option['icon'], color: isSelected ? option['color'] : Colors.grey.shade400, size: 30),
                  const SizedBox(height: 12),
                  Text(
                    option['id'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
