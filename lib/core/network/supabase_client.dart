import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager instance = SupabaseManager._();
  SupabaseManager._();

  Future<void> initialize() async {
    try {
      const envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

      final String url = envUrl.isNotEmpty ? envUrl : (dotenv.env['SUPABASE_URL'] ?? '');
      final String anonKey = envAnonKey.isNotEmpty ? envAnonKey : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('Supabase Init Error: $e');
    }
  }
}
