import os

with open('lib/screens/signup_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add plot number controller
content = content.replace(
    "final _routeIndexController = TextEditingController();",
    "final _routeIndexController = TextEditingController();\n  final _plotNumberController = TextEditingController();"
)

# 2. Update validation logic
old_validation = """    if (_routeIndexController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Plot/Route Number')));
      return;
    }"""
new_validation = """    if (_routeIndexController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Route Number')));
      return;
    }
    if (_selectedRole == 'farmer' && _plotNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Plot Number')));
      return;
    }"""
content = content.replace(old_validation, new_validation)

# 3. Update sign up arguments (append plot to name for farmer)
old_signup = """      await AuthService.instance.signup(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _selectedRole,
        routeIndex: routeIndex,
      );"""
new_signup = """      String finalName = _nameController.text.trim();
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
content = content.replace(old_signup, new_signup)

# 4. Update the text fields section
old_fields = """                          const SizedBox(height: 12),
                          _buildTextField(
                            _routeIndexController, 
                            'Plot Number / Route Index (අංකය)', 
                            false, 
                            keyboardType: TextInputType.number,
                          ),"""
new_fields = """                          if (_selectedRole == 'farmer') ...[
                            const SizedBox(height: 12),
                            _buildTextField(
                              _plotNumberController, 
                              'Plot Number (ඉඩමේ අංකය)', 
                              false,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildTextField(
                            _routeIndexController, 
                            'Route Number (කලාප අංකය - උදා: 1)', 
                            false, 
                            keyboardType: TextInputType.number,
                          ),"""
content = content.replace(old_fields, new_fields)

with open('lib/screens/signup_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Signup updated successfully!")
