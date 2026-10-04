import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    // 1. Get a token first
    final loginRes = await http.post(
      Uri.parse('http://127.0.0.1:5252/api/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'seller@ecoloop.com',
        'password': 'Password123!',
      }),
    );
    
    if (loginRes.statusCode != 200) {
      print('Login failed: \${loginRes.statusCode} \${loginRes.body}');
      return;
    }
    final token = jsonDecode(loginRes.body)['token'];
    
    // 2. Create listing
    var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:5252/api/MaterialListings'));
    
    final requestData = {
      "title": "Test Material",
      "category": "Other",
      "description": "Test",
      "quantity": "10",
      "unit": "Kg",
      "location": "Colombo",
      "price": "0.0",
      "priceUnit": "Kg",
      "deliveryMethod": "Self Pickup",
      "type": "0",
    };
    
    requestData.forEach((key, value) {
      request.fields[key] = value;
    });
    
    request.headers['Authorization'] = 'Bearer \$token';
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    print('Status Code: \${response.statusCode}');
    print('Response Body: \${response.body}');
  } catch (e) {
    print('Error: \$e');
  }
}
