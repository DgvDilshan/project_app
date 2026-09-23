import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';
import 'digital_id_screen.dart';
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

      setState(() {
        _userName = cache['user_name'] ?? 'Farmer';
        _userEmail = user?.email ?? 'Unknown Email';
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
              child: Column(
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
                icon: Icons.map_outlined,
                title: isSinhala ? 'මගේ වත්ත (අක්කර 1.5)' : 'My Estate (1.5 Acres)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isSinhala ? 'ඉදිරියේදී බලාපොරොත්තු වන්න' : 'Coming soon!'),
                  ));
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
                title: isSinhala ? 'උදව්' : 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isSinhala ? 'අප අමතන්න: 011-2345678' : 'Contact us: 011-2345678'),
                  ));
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
