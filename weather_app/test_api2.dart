import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String apiKey = '793622d7dd6ef91e5a86118379a1797c650ee138bfe7a49a04f51ed126aa1338';
  final dt = {'date': '20231010', 'time': '0500'}; // using a static old date for test
  final uri = Uri.https(
    'apis.data.go.kr',
    '/1360000/VilageFcstInfoService_2.0/getVilageFcst',
    {
      'serviceKey': apiKey,
      'pageNo': '1',
      'numOfRows': '10',
      'dataType': 'JSON',
      'base_date': dt['date']!,
      'base_time': dt['time']!,
      'nx': '61',
      'ny': '125',
    },
  );

  print('URL: $uri');
  try {
    final response = await http.get(uri);
    print('Status: ${response.statusCode}');
    if (response.body.length < 500) {
      print('Body: ${response.body}');
    } else {
      print('Body start: ${response.body.substring(0, 500)}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
