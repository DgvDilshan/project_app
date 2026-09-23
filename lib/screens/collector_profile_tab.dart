import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';
import '../services/sync_manager.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_database_helper.dart';

class CollectorProfileTab extends StatefulWidget {
  const CollectorProfileTab({super.key});

  @override
  State<CollectorProfileTab> createState() => _CollectorProfileTabState();
}

class _CollectorProfileTabState extends State<CollectorProfileTab> {
  String _userName = 'Collector';
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
      final collectorId = cache['user_id'];
      
      final user = Supabase.instance.client.auth.currentUser;
      
      double total = 0;
      if (collectorId != null) {
        final harvests = await LocalDatabaseHelper.instance.getHarvestsByCollectorId(collectorId);
        
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
        _userName = cache['user_name'] ?? 'Collector';
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
                                child: Icon(Icons.local_shipping, color: cs.onSecondary, size: 32),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSinhala ? 'මෙම මාසයේ එකතුව' : 'Total Collected This Month',
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
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.logout, color: cs.error),
                        ),
                        title: Text(isSinhala ? 'ඉවත් වන්න' : 'Logout', style: TextStyle(color: cs.error, fontWeight: FontWeight.bold)),
                        onTap: () async {
                          await AuthService.instance.clearSession();
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
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
