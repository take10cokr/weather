import 'package:http/http.dart' as http;

void main() async {
  String apiKey = '793622d7dd6ef91e5a86118379a1797c650ee138bfe7a49a04f51ed126aa1338';
  String sidoName = '서울';

  final uri = Uri.parse(
      'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
      '?serviceKey=$apiKey'
      '&returnType=json'
      '&numOfRows=100'
      '&pageNo=1'
      '&sidoName=$sidoName'
      '&ver=1.3');

  print('URL: $uri');
  try {
    final res = await http.get(uri);
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      if (res.body.length < 500) print(res.body);
      else print(res.body.substring(0, 500));
    } else {
      print('Body: ${res.body}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
