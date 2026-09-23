import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // New Fields for Route & Factory
  final _factoryCodeController = TextEditingController();
  final _supplierNumberController = TextEditingController();
  
  String _selectedRole = 'farmer';
  bool _isLoading = false;
  
  bool _linkFactory = false; // Checkbox for optional factory linkage
  String? _selectedRoute;
  
  // Mock routes for demo purposes (Since we are using Factory Code)
  final List<String> _demoRoutes = [
    'Line 1 (North)',
    'Line 2 (South)',
    'Line 3 (East)',
    'Line 4 (West)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _factoryCodeController.dispose();
    _supplierNumberController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all basic fields')));
      return;
    }

    // Validation for Collector
    if (_selectedRole == 'collector') {
      if (_factoryCodeController.text.isEmpty || _selectedRoute == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collectors must provide Factory Code and Route')));
        return;
      }
    }

    // Validation for Farmer if they chose to link
    if (_selectedRole == 'farmer' && _linkFactory) {
      if (_factoryCodeController.text.isEmpty || _selectedRoute == null || _supplierNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete Factory linking details')));
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final factoryCode = (_selectedRole == 'collector' || _linkFactory) ? _factoryCodeController.text.trim() : null;
      final routeName = (_selectedRole == 'collector' || _linkFactory) ? _selectedRoute : null;
      final supplierNumber = (_selectedRole == 'farmer' && _linkFactory) ? _supplierNumberController.text.trim() : null;

      await AuthService.instance.signup(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _selectedRole,
        factoryCode: factoryCode,
        routeName: routeName,
        supplierNumber: supplierNumber,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/slider_1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.eco_outlined, color: Colors.white, size: 24),
                                Text('AGRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(_nameController, 'Full Name (සම්පූර්ණ නම)', false),
                          const SizedBox(height: 12),
                          _buildTextField(_phoneController, 'Phone Number (දුරකථන අංකය)', false, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildTextField(_emailController, 'Email (විද්‍යුත් තැපෑල)', false, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _buildTextField(_passwordController, 'Password (මුරපදය)', true),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Role (ගිණුම් වර්ගය)',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'farmer', child: Text('Farmer (ගොවියා)')),
                              DropdownMenuItem(value: 'collector', child: Text('Collector (දළු එකතු කරන්නා)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() {
                                _selectedRole = val;
                                // Collectors must always link to a factory route
                                if (val == 'collector') _linkFactory = true;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Factory Linking Section
                          if (_selectedRole == 'farmer')
                            CheckboxListTile(
                              title: const Text('Link to Tea Factory (Optional)', style: TextStyle(color: Colors.white, fontSize: 14)),
                              subtitle: const Text('Required for Pickup Requests', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              value: _linkFactory,
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              onChanged: (val) {
                                setState(() => _linkFactory = val ?? false);
                              },
                            ),

                          if (_linkFactory || _selectedRole == 'collector') ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    _factoryCodeController, 
                                    'Factory Code (උදා: ROS-123)', 
                                    false
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _selectedRoute,
                                    dropdownColor: Colors.black87,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Collection Route (දළු මාර්ගය)',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _demoRoutes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedRoute = val);
                                    },
                                  ),
                                  if (_selectedRole == 'farmer') ...[
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      _supplierNumberController, 
                                      'Supplier Number (සැපයුම්කරු අංකය)', 
                                      false,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          _isLoading 
                            ? const CircularProgressIndicator(color: Colors.green)
                            : ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool obscure, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
