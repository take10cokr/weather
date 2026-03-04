import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('개인정보 처리방침', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '개인정보 처리방침',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            SizedBox(height: 16),
            Text(
              'WeatherPro(이하 "앱")는 사용자의 개인정보를 소중하게 생각하며, "개인정보 보호법" 등 관련 법규를 준수하여 안전하게 관리하고 있습니다. 본 방침은 앱이 어떤 정보를 수집하고 어떻게 이용하는지 알려드립니다.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
            ),
            SizedBox(height: 24),
            _SectionTitle(title: '1. 수집하는 개인정보 항목'),
            _SectionContent(content: '본 앱은 서비스 제공을 위해 다음 정보를 수집할 수 있습니다.\n\n• 필수항목\n- 위치 정보(GPS): 현재 위치 기반의 정확한 실시간 날씨 및 기상 특보를 제공하기 위해 파악합니다. (위/경도 좌표)\n\n• 선택항목\n- 앱 설정 정보: 화면 표시 단위, 관심 지역 설정 값 등\n- 기기 식별 정보: 푸시 알림 전송을 위한 토큰'),
            SizedBox(height: 20),
            _SectionTitle(title: '2. 개인정보의 수집 및 이용 목적'),
            _SectionContent(content: '수집한 정보를 다음의 목적을 위해만 활용합니다.\n- 현재 위치 기반 실시간 기상 데이터(온도, 강수량, 대기질 등) 제공\n- 악천후 및 기상 특보 발생 시 사용자 맞춤형 알림 전송\n- 서비스 품질 향상 및 오류 개선을 위한 통계 분석'),
            SizedBox(height: 20),
            _SectionTitle(title: '3. 개인정보의 보유 및 이용 기간'),
            _SectionContent(content: '원칙적으로 사용자가 앱을 삭제하거나 위치 정보 제공 동의를 철회할 경우 해당 정보를 지체 없이 파기합니다. 단, 관련 법령에 의해 보존할 필요가 있는 경우 해당 법령에서 정한 기간 동안 보관합니다.'),
            SizedBox(height: 20),
            _SectionTitle(title: '4. 개인정보의 제3자 제공 및 위탁'),
            _SectionContent(content: '본 앱은 사용자의 동의 없이 개인정보를 외부에 제공하지 않습니다. 단, 기상 정보를 가져오기 위해 공공기관(기상청, 환경공단 등)의 오픈 API를 호출할 때 위치 좌표값 등 필수적인 수치만 전송될 수 있으며, 특정 개인을 식별할 수 있는 형태로는 전송되지 않습니다.'),
            SizedBox(height: 20),
            _SectionTitle(title: '5. 사용자의 권리 및 행사 방법'),
            _SectionContent(content: '사용자는 기기의 "설정" 메뉴를 통해 언제든지 위치 정보 수집에 대한 동의를 철회하거나 앱 알림을 끌 수 있습니다. 동의를 철회할 경우 현재 위치 기반 자동 날씨 안내 기능이 제한될 수 있습니다.'),
            SizedBox(height: 40),
            Text(
              '공고일자: 2026년 3월 3일\n시행일자: 2026년 3월 3일',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  final String content;
  const _SectionContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
    );
  }
}
