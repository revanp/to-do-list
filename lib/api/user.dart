import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String url = 'https://65e1e6e8a8583365b31795ff.mockapi.io/api/v1/users';

  login(apiURL) async {
    var fullUrl = Uri.parse(url + apiURL);
    return await http.get(
      fullUrl,
    );
  }
}
