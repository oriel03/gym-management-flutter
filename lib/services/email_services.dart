import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailServices {
  static const String _backendUrl =
      'https://gym-management-flutter.vercel.app/api/send-recovery-pin';

  static Future<bool> enviarPinRecuperacion({
    required String email,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'pin': pin}),
      );

      if (response.statusCode == 200) {
        print('✅ Email enviado correctamente');
        return true;
      } else {
        print('❌ Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error de conexión: $e');
      return false;
    }
  }
}
