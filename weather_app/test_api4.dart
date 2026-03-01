import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String apiKey = '793622d7dd6ef91e5a86118379a1797c650ee138bfe7a49a04f51ed126aa1338';
  String sidoName = '서울';

  // Try over HTTP
  final uriHttp = Uri.parse(
      'http://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
      '?serviceKey=$apiKey'
      '&returnType=json'
      '&numOfRows=10'
      '&pageNo=1'
      '&sidoName=${Uri.encodeQueryComponent(sidoName)}'
      '&ver=1.3');

  try {
    final res = await http.get(uriHttp, headers: {
      'Accept': '*/*, application/json'
    });
    print('HTTP Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      if (res.body.length < 500) print(res.body);
      else print(res.body.substring(0, 500));
    } else {
      print('Body: ${res.body}');
    }
  } catch(e) {
    print('HTTP Error: $e');
  }
}
