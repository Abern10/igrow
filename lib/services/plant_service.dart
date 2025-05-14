import 'package:http/http.dart' as http;
import 'dart:convert';

class PlantService {
  static const String apiKey = 'sk-nKUW67b7f9f5bff278764';

  static Future<List<dynamic>> fetchPlantsByHardinessZone(int zone) async {
    final response = await http.get(
      Uri.parse('https://perenual.com/api/v2/species-list?key=$apiKey&hardiness=$zone'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Ensure 'data' exists before accessing it
      if (data != null && data.containsKey('data')) {
        return data['data'] ?? [];
      }
    }

    throw Exception('Failed to load plants');
  }
}
