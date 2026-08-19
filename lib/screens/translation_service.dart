import 'dart:convert';
import 'package:http/http.dart' as http;
// For languageCodes map

class TranslationService {
  static Future<String> translate(String text, String targetLang) async {
    final url = Uri.parse('https://libretranslate.com/translate');
    final Map<String, String> languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Marathi': 'mr',
    'Bengali': 'bn',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Urdu': 'ur',
  };  
  final response = await http.post(url, body: {
      'q': text,
      'source': 'en',
      'target': languageCodes[targetLang] ?? 'en',
      'format': 'text',
    });

  
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['translatedText'];
    } else {
      return text; // fallback to original text
    }
  }
}