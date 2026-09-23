import os

# 1. auth_service.dart
with open('lib/services/auth_service.dart', 'r', encoding='utf-8') as f:
    auth_content = f.read()

auth_content = auth_content.replace(
    "Future<void> _cacheUserSession(String userId, String role, String fullName) async {",
    "Future<void> _cacheUserSession(String userId, String role, String fullName, {int? routeIndex}) async {"
)

auth_content = auth_content.replace(
    "await prefs.setString('user_name', fullName);",
    "await prefs.setString('user_name', fullName);\n    if (routeIndex != null) {\n      await prefs.setInt('route_index', routeIndex);\n    } else {\n      await prefs.remove('route_index');\n    }"
)

auth_content = auth_content.replace(
    "await prefs.remove('user_name');",
    "await prefs.remove('user_name');\n    await prefs.remove('route_index');"
)

auth_content = auth_content.replace(
    """    return {
      'user_id': prefs.getString('user_id'),
      'user_role': prefs.getString('user_role'),
      'user_name': prefs.getString('user_name'),
    };""",
    """    return {
      'user_id': prefs.getString('user_id'),
      'user_role': prefs.getString('user_role'),
      'user_name': prefs.getString('user_name'),
      'route_index': prefs.getInt('route_index')?.toString(),
    };"""
)

auth_content = auth_content.replace(
    """      final name = profile['full_name'] as String? ?? 'User';
      
      await _cacheUserSession(response.user!.id, role, name);""",
    """      final name = profile['full_name'] as String? ?? 'User';
      final routeIndex = profile['route_index'] as int?;
      
      await _cacheUserSession(response.user!.id, role, name, routeIndex: routeIndex);"""
)

auth_content = auth_content.replace(
    "await _cacheUserSession(response.user!.id, role, fullName);",
    "await _cacheUserSession(response.user!.id, role, fullName, routeIndex: routeIndex);"
)

with open('lib/services/auth_service.dart', 'w', encoding='utf-8') as f:
    f.write(auth_content)

# 2. signup_screen.dart
with open('lib/screens/signup_screen.dart', 'r', encoding='utf-8') as f:
    signup_content = f.read()

signup_content = signup_content.replace("Text('FARM', style:", "Text('AGRO', style:")

signup_content = signup_content.replace(
    """    if (_selectedRole == 'farmer' && _routeIndexController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Plot Number')));
      return;
    }""",
    """    if (_routeIndexController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Plot/Route Number')));
      return;
    }"""
)

signup_content = signup_content.replace(
    "final routeIndex = _selectedRole == 'farmer' ? int.tryParse(_routeIndexController.text.trim()) ?? 0 : null;",
    "final routeIndex = int.tryParse(_routeIndexController.text.trim()) ?? 0;"
)

old_field = """                          if (_selectedRole == 'farmer') ...[
                            const SizedBox(height: 12),
                            _buildTextField(
                              _routeIndexController, 
                              'Plot Number / Route Index (අංකය)', 
                              false, 
                              keyboardType: TextInputType.number,
                            ),
                          ],"""
new_field = """                          const SizedBox(height: 12),
                          _buildTextField(
                            _routeIndexController, 
                            'Plot Number / Route Index (අංකය)', 
                            false, 
                            keyboardType: TextInputType.number,
                          ),"""
signup_content = signup_content.replace(old_field, new_field)

with open('lib/screens/signup_screen.dart', 'w', encoding='utf-8') as f:
    f.write(signup_content)

# 3. collector_home_screen.dart
with open('lib/screens/collector_home_screen.dart', 'r', encoding='utf-8') as f:
    collector_content = f.read()

old_fetch = """      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'] as String?;

      final response = await _supabase
          .from('pickup_requests')
          .select('id, farmer_id, request_date, status, disease_flag, profiles(full_name, phone, route_index)')
          .eq('status', 'pending');

      List<Map<String, dynamic>> requestsList = List<Map<String, dynamic>>.from(response);"""

new_fetch = """      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'] as String?;
      final collectorRouteStr = cache['route_index'] as String?;

      final response = await _supabase
          .from('pickup_requests')
          .select('id, farmer_id, request_date, status, disease_flag, profiles(full_name, phone, route_index)')
          .eq('status', 'pending');

      List<Map<String, dynamic>> rawRequestsList = List<Map<String, dynamic>>.from(response);
      List<Map<String, dynamic>> requestsList = [];
      
      for (var req in rawRequestsList) {
        final profile = req['profiles'] as Map<String, dynamic>?;
        final reqRouteStr = profile?['route_index']?.toString();
        // Filter out requests that do not belong to the collector's route
        if (collectorRouteStr != null && reqRouteStr == collectorRouteStr) {
          requestsList.add(req);
        } else if (collectorRouteStr == null) {
          // If collector didn't set a route, maybe show all (or none). Let's show all for safety.
          requestsList.add(req);
        }
      }"""

collector_content = collector_content.replace(old_fetch, new_fetch)

with open('lib/screens/collector_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(collector_content)

print("Updates applied successfully!")
