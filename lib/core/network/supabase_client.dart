import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager instance = SupabaseManager._();
  SupabaseManager._();

  static const String defaultUrl = 'https://htzcephotiafugeyfflq.supabase.co';
  static const String defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0emNlcGhvdGlhZnVnZXlmZmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NjIxOTgsImV4cCI6MjA5OTQzODE5OH0.HjNmn8Ovbv2PYUxfKdEfGyfd3iv4RItqOUASUWbI_-s';

  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: defaultUrl,
        anonKey: defaultAnonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('Supabase Init Error: $e');
    }
  }
}
