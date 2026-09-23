import os

# 1. Update auth_service.dart
with open('lib/services/auth_service.dart', 'r', encoding='utf-8') as f:
    auth_content = f.read()

old_signup_sig = "Future<AuthResponse> signup(String email, String password, String fullName, String phone, String role, {int? routeIndex}) async {"
new_signup_sig = "Future<AuthResponse> signup(String email, String password, String fullName, String phone, String role, {int? routeIndex, String? plotNumber}) async {"
auth_content = auth_content.replace(old_signup_sig, new_signup_sig)

old_insert = """        'role': role,
        if (routeIndex != null) 'route_index': routeIndex,
      });"""
new_insert = """        'role': role,
        if (routeIndex != null) 'route_index': routeIndex,
        if (plotNumber != null) 'plot_number': plotNumber,
      });"""
auth_content = auth_content.replace(old_insert, new_insert)

with open('lib/services/auth_service.dart', 'w', encoding='utf-8') as f:
    f.write(auth_content)

# 2. Update signup_screen.dart
with open('lib/screens/signup_screen.dart', 'r', encoding='utf-8') as f:
    signup_content = f.read()

old_signup_logic = """      String finalName = _nameController.text.trim();
      if (_selectedRole == 'farmer') {
        finalName = "$finalName (Plot: ${_plotNumberController.text.trim()})";
      }

      await AuthService.instance.signup(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        finalName,
        _phoneController.text.trim(),
        _selectedRole,
        routeIndex: routeIndex,
      );"""

new_signup_logic = """      final plotNumber = _selectedRole == 'farmer' ? _plotNumberController.text.trim() : null;

      await AuthService.instance.signup(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _selectedRole,
        routeIndex: routeIndex,
        plotNumber: plotNumber,
      );"""
signup_content = signup_content.replace(old_signup_logic, new_signup_logic)

with open('lib/screens/signup_screen.dart', 'w', encoding='utf-8') as f:
    f.write(signup_content)

# 3. Update collector_home_screen.dart
with open('lib/screens/collector_home_screen.dart', 'r', encoding='utf-8') as f:
    collector_home_content = f.read()

old_select = ".select('id, farmer_id, request_date, status, disease_flag, profiles(full_name, phone, route_index)')"
new_select = ".select('id, farmer_id, request_date, status, disease_flag, profiles(full_name, phone, route_index, plot_number)')"
collector_home_content = collector_home_content.replace(old_select, new_select)

old_farmer_name = "final farmerName = profile?['full_name'] ?? 'Unknown Farmer';"
new_farmer_name = """    final fullName = profile?['full_name'] ?? 'Unknown Farmer';
    final plotNum = profile?['plot_number'] != null ? ' (Plot: ${profile!['plot_number']})' : '';
    final farmerName = '$fullName$plotNum';"""
collector_home_content = collector_home_content.replace(old_farmer_name, new_farmer_name)

with open('lib/screens/collector_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(collector_home_content)

# 4. Update collector_history_tab.dart
with open('lib/screens/collector_history_tab.dart', 'r', encoding='utf-8') as f:
    history_content = f.read()

old_profile_select = ".select('id, full_name, phone')"
new_profile_select = ".select('id, full_name, phone, plot_number')"
history_content = history_content.replace(old_profile_select, new_profile_select)

old_history_enrich = """          enriched['farmer_name'] = p?['full_name'] ?? 'Unknown Farmer';
          enriched['farmer_phone'] = p?['phone'] ?? 'No Phone';"""
new_history_enrich = """          final plotNum = p?['plot_number'] != null ? ' (Plot: ${p!['plot_number']})' : '';
          enriched['farmer_name'] = '${p?['full_name'] ?? 'Unknown Farmer'}$plotNum';
          enriched['farmer_phone'] = p?['phone'] ?? 'No Phone';"""
history_content = history_content.replace(old_history_enrich, new_history_enrich)

with open('lib/screens/collector_history_tab.dart', 'w', encoding='utf-8') as f:
    f.write(history_content)

print("Updates applied successfully!")
