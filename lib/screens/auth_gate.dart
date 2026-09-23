import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'scan_home_screen.dart';
import 'login_screen.dart';
import 'collector_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1. Check local cache (Fast, supports offline)
    final cache = await AuthService.instance.getCachedUser();
    
    if (cache['user_id'] != null && cache['user_role'] != null) {
      setState(() {
        _userRole = cache['user_role'];
        _isLoading = false;
      });
    } else {
      // Not logged in
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole == 'farmer') {
      return const ScanHomeScreen();
    } else if (_userRole == 'collector') {
      return const CollectorHomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
