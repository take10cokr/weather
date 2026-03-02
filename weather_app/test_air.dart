import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '793622d7dd6ef91e5a86118379a1797c650ee138bfe7a49a04f51ed126aa1338';
  final uri = Uri.https(
    'apis.data.go.kr',
    '/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty',
    {
      'serviceKey': apiKey,
      'returnType': 'json',
      'numOfRows': '100',
      'pageNo': '1',
      'sidoName': '서울',
      'ver': '1.3',
    },
  );

  final response = await http.get(uri);
  print('Status code: ${response.statusCode}');
  print('Response body: ${response.body}');
  
  if (response.statusCode == 200 && response.body.trim().startsWith('{')) {
    final body = jsonDecode(response.body);
    final items = body['response']['body']['items'] as List;
    
    for (var i = 0; i < (items.length < 5 ? items.length : 5); i++) {
      print(items[i]['stationName']);
      print(items[i]);
    }
  } else {
    print('Failed to parse response or bad status code.');
  }
}
