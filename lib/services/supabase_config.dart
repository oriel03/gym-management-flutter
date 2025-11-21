import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    print('URL leida: $url');

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL no está definida en .env');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    print('🔍 SUPABASE_ANON_KEY leída: ${key?.substring(0, 20)}...');

    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY no está definida en .env');
    }
    return key;
  }

  // Para desarrollo local (opcional)
  static const String localUrl = 'http://localhost:54321';
}
