import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:logging/logging.dart';

class EmailServices {
  static const String _baseUrl = 'https://gym-management-flutter.vercel.app';
  static final log = Logger('EmailServices');
  static Future<bool> enviarPinRecuperacion({
    required String email,
  }) async {
    try{
    final url = Uri.parse('$_baseUrl/api/send-recovery-email');
    log.info('Solicitando recuperacion de PIN para: $email');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );
    
    if(response.statusCode == 200){
      log.info('Email de recuperacion enviado');
      return true;

    } else {
      log.warning('Respuesta inesperada: ${response.statusCode}');
      return false;
    }
  } catch(e, stackTrace) {
    log.severe('Error al enviar email de recuperacion', e, stackTrace);
    return false;
  }
 }
  }
