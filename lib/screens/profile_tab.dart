import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';
import 'digital_id_screen.dart';
import 'help_support_screen.dart';
import '../widgets/update_profile_dialog.dart';
import '../services/sync_manager.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_database_helper.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _userName = 'Farmer';
  String _userEmail = '';
  String _routeName = '';
  String _supplierNumber = '';
  double _totalMonthlyKg = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      
      final user = Supabase.instance.client.auth.currentUser;
      
      double total = 0;
      if (farmerId != null) {
        final harvests = await LocalDatabaseHelper.instance.getHarvestsByFarmerId(farmerId);
        
        final now = DateTime.now();
        for (var harvest in harvests) {
          final recordedAtStr = harvest['recorded_at'] as String?;
          if (recordedAtStr != null) {
            final recordedDate = DateTime.parse(recordedAtStr);
            if (recordedDate.year == now.year && recordedDate.month == now.month) {
              total += (harvest['weight_kg'] as num).toDouble();
            }
          }
        }
      }

      
      String rName = cache['route_name'] ?? '';
      String sNumber = cache['supplier_number'] ?? '';
      if (farmerId != null) {
          try {
              final profile = await Supabase.instance.client.from('profiles').select('route_name, supplier_number').eq('id', farmerId).single();
              rName = profile['route_name']?.toString() ?? 'No Route';
              sNumber = profile['supplier_number']?.toString() ?? 'No Supplier No';
              // Update cache with latest
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('route_name', rName);
              await prefs.setString('supplier_number', sNumber);
          } catch (_) {
              // Fallback to cache if offline (already set above)
          }
      }
      
      setState(() {
        _userName = cache['user_name'] ?? 'Farmer';
        _userEmail = user?.email ?? 'Unknown Email';
        _routeName = rName;
        _supplierNumber = sNumber;
        _totalMonthlyKg = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: isSinhalaMode,
      builder: (context, isSinhala, child) {
        return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'ගිණුම' : 'Profile'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              await SyncManager.instance.syncData();
              await _loadProfileData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _userName == 'Farmer' && _userEmail == 'Unknown Email' // Simple Guest check
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.no_accounts, size: 80, color: Colors.grey),
                      const SizedBox(height: 24),
                      Text(
                        isSinhalaMode.value ? 'අමුත්තෙකුගේ ගිණුම' : 'Guest Account',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSinhalaMode.value 
                          ? 'ඔබ දැනට ලියාපදිංචි වී නොමැත. ඔබේ පැතිකඩ සහ දළු විස්තර බැලීමට කරුණාකර ලියාපදිංචි වන්න.' 
                          : 'You are using a guest account. Please sign up to view your profile and harvest records.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthGate()),
                            (route) => false,
                          );
                        },
                        child: Text(isSinhalaMode.value ? 'ලියාපදිංචි වන්න / ඇතුල් වන්න' : 'Sign Up / Log In'),
                      ),
                    ],
                  )
                : Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    child: Icon(Icons.person, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  if (_supplierNumber.isNotEmpty && _supplierNumber != 'No Supplier No')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        isSinhala ? 'සැපයුම්කරු අංකය: $_supplierNumber  |  මාර්ගය: $_routeName' : 'Supplier No: $_supplierNumber  |  Route: $_routeName',
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 32),
                  
                  // Total KGs summary card
                  Card(
                    elevation: 0,
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.eco, color: cs.onSecondary, size: 32),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSinhala ? 'මෙම මාසයේ මුළු දළු ප්‍රමාණය' : 'Total Leaves This Month',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onSecondaryContainer.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_totalMonthlyKg.toStringAsFixed(1)} Kg',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final cache = await AuthService.instance.getCachedUser();
                    if (!context.mounted) return;
                    final result = await showDialog(
                      context: context,
                      builder: (_) => UpdateProfileDialog(
                        currentFactoryCode: cache['factory_code'],
                        currentRoute: cache['route_name'],
                        currentSupplierNo: cache['supplier_number'],
                        isFarmer: true,
                      ),
                    );
                    if (result == true) {
                      _loadProfileData(); // reload
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(isSinhala ? 'ගිණුමේ විස්තර යාවත්කාලීන කරන්න' : 'Update Profile Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _ProfileMenuItem(
                icon: Icons.qr_code_2,
                title: isSinhala ? 'මගේ ඩිජිටල් හැඳුනුම්පත (QR)' : 'My Digital ID (QR)',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DigitalIdScreen()),
                  );
                },
              ),

              _ProfileMenuItem(
                icon: Icons.language,
                title: isSinhala ? 'භාෂාව වෙනස් කරන්න (Language)' : 'Change Language',
                onTap: () {
                  isSinhalaMode.value = !isSinhalaMode.value;
                },
              ),
              _ProfileMenuItem(
                icon: Icons.help_outline,
                title: isSinhala ? 'උදව් සහ සහාය' : 'Help & Support',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  );
                },
              ),
              _ProfileMenuItem(
                icon: Icons.logout,
                title: isSinhala ? 'ඉවත් වන්න' : 'Logout',
                isDestructive: true,
                onTap: () async {
                  await AuthService.instance.clearSession();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isDestructive ? cs.error : cs.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap ?? () {},
    );
  }
}
