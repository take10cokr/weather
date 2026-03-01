import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String apiKey = '793622d7dd6ef91e5a86118379a1797c650ee138bfe7a49a04f51ed126aa1338';
  String sidoName = '서울';
  String dongName = '강남구';

  final uri = Uri.parse(
      'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
      '?serviceKey=$apiKey'
      '&returnType=json'
      '&numOfRows=100'
      '&pageNo=1'
      '&sidoName=${Uri.encodeQueryComponent(sidoName)}'
      '&ver=1.3');

  print('URL: $uri');
  try {
    final response = await http.get(uri);
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      if (response.body.length < 500) {
        print('Body: ${response.body}');
      } else {
        dynamic parsed = jsonDecode(response.body);
        var items = parsed['response']['body']['items'];
        print('Items count: ${items.length}');
        var item = items.firstWhere((e) => e['stationName'] == dongName, orElse: () => null);
        print('Target item: $item');
      }
    } else {
      print('Response error.');
      print('Body: ${response.body}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
