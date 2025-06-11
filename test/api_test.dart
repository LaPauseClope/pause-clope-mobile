import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  test('GET API test', () async {
    final response = await http.get(Uri.parse('http://20.188.40.98:8080/clicker/testuser'));

    expect(response.statusCode, 200);
    final body = json.decode(response.body);
    expect(body['id'], 1);
  });
}
