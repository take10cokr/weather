import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String apiKey = '793622d7dd6ef91e5a86118379a1797c650ee138bfe7a49a04f51ed126aa1338';
  String sidoName = '서울';

  // Original URI from weather_service.dart
  final uriOriginal = Uri.parse(
      'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
      '?serviceKey=$apiKey'
      '&returnType=json'
      '&numOfRows=100'
      '&pageNo=1'
      '&sidoName=$sidoName'
      '&ver=1.3');

  print('Original URL: $uriOriginal');
  try {
    final res1 = await http.get(uriOriginal);
    print('Original Status: ${res1.statusCode}');
  } catch(e) {
    print('Original Error: $e');
  }

  // With User-Agent
  final uriEncoded = Uri.parse(
      'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
      '?serviceKey=$apiKey'
      '&returnType=json'
      '&numOfRows=100'
      '&pageNo=1'
      '&sidoName=${Uri.encodeQueryComponent(sidoName)}'
      '&ver=1.3');

  try {
    final res2 = await http.get(uriEncoded, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    });
    print('Encoded+UA Status: ${res2.statusCode}');
    if (res2.statusCode == 200) {
      if (res2.body.length < 500) {
        print('Body: ${res2.body}');
      } else {
        print('Body start: ${res2.body.substring(0, 500)}');
      }
    }
  } catch(e) {
    print('Encoded+UA Error: $e');
  }
}
