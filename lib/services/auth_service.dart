import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_helper.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache user data offline
  Future<void> _cacheUserSession(String userId, String role, String fullName, {int? routeIndex}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', role);
    await prefs.setString('user_name', fullName);
    if (routeIndex != null) {
      await prefs.setInt('route_index', routeIndex);
    } else {
      await prefs.remove('route_index');
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('route_index');
    await _supabase.auth.signOut();
  }

  Future<Map<String, String?>> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString('user_id'),
      'user_role': prefs.getString('user_role'),
      'user_name': prefs.getString('user_name'),
      'route_index': prefs.getInt('route_index')?.toString(),
    };
  }

  Future<AuthResponse> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);
    if (response.user != null) {
      // Fetch profile role from Supabase
      final profile = await _supabase.from('profiles').select().eq('id', response.user!.id).single();
      final role = profile['role'] as String;
      final name = profile['full_name'] as String? ?? 'User';
      final routeIndex = profile['route_index'] as int?;
      
      await _cacheUserSession(response.user!.id, role, name, routeIndex: routeIndex);
    }
    return response;
  }

  Future<AuthResponse> signup(String email, String password, String fullName, String phone, String role, {int? routeIndex, String? plotNumber, String? collectorId}) async {
    final response = await _supabase.auth.signUp(email: email, password: password);
    
    if (response.user != null) {
      // Create profile record
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        if (routeIndex != null) 'route_index': routeIndex,
        if (plotNumber != null) 'plot_number': plotNumber,
        if (collectorId != null) 'collector_id': collectorId,
      });

      await _cacheUserSession(response.user!.id, role, fullName, routeIndex: routeIndex);
    }
    return response;
  }
}
