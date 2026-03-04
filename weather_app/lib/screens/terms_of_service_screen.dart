import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('이용약관', style: TextStyle(fontWeight: FontWeight.w700)),
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
              '이용약관 (Terms of Service)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            SizedBox(height: 16),
            Text(
              '환영합니다! 본 약관은 WeatherPro(이하 "앱")가 제공하는 날씨 및 부가 서비스의 이용과 관련하여, 회사와 이용자 간의 권리, 의무 및 책임 사항을 규정합니다.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
            ),
            SizedBox(height: 24),
            _SectionTitle(title: '제1조 (목적)'),
            _SectionContent(content: '본 약관은 회사가 운영하는 위치 기반 실시간 날씨 앱과 관련된 제반 서비스의 이용 조건, 절차 및 기타 필요한 사항을 규정함을 목적으로 합니다.'),
            SizedBox(height: 20),
            _SectionTitle(title: '제2조 (용어의 정의)'),
            _SectionContent(content: '① "서비스"란 기기 종류와 상관없이 이용자가 이용할 수 있는 앱의 모든 기능을 의미합니다.\n② "이용자"란 앱에 접속하여 본 약관에 따라 회사가 제공하는 서비스를 받는 모든 분들을 말합니다.'),
            SizedBox(height: 20),
            _SectionTitle(title: '제3조 (서비스의 제공 및 변경)'),
            _SectionContent(content: '① 앱은 기상청 등 공공기관의 신뢰할 수 있는 데이터를 바탕으로 기상 정보를 제공합니다.\n② 기상 데이터 제공 기관의 상황이나 시스템 점검에 따라 정보 제공이 일시적으로 지연되거나 중단될 수 있습니다.'),
            SizedBox(height: 20),
            _SectionTitle(title: '제4조 (회원의 의무 및 주의사항)'),
            _SectionContent(content: '이용자는 관련 법령, 본 약관 및 회사가 공지하는 주의사항을 준수해야 하며, 서비스 시스템을 해킹하거나 데이터를 무단으로 복제, 배포하는 등 업무를 방해하는 행위를 해서는 안 됩니다.'),
            SizedBox(height: 20),
            _SectionTitle(title: '제5조 (책임의 한계 및 면책)'),
            _SectionContent(content: '① 앱에서 제공하는 날씨 정보는 기상청 데이터를 가공한 것으로, 실제 기상 상황과 차이가 있을 수 있으며 이를 기반으로 한 이용자의 선택이나 사고에 대해 법적 책임을 지지 않습니다.\n② 천재지변, 파업, 공공기관의 API 통신 장애 등 불가항력적인 사유로 서비스가 중단된 경우 책임을 지지 않습니다.'),
            SizedBox(height: 20),
            _SectionTitle(title: '제6조 (약관의 개정)'),
            _SectionContent(content: '회사는 관련 법령을 위배하지 않는 범위 내에서 약관을 개정할 수 있으며, 내용이 변경될 경우 시행일자 최소 7일 전부터 앱 내 공지사항을 통해 안내합니다.'),
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
