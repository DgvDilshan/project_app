import os

# 1. Add collector_profile_tab.dart
collector_profile_content = """import 'package:flutter/material.dart';
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
"""
with open('lib/screens/collector_profile_tab.dart', 'w', encoding='utf-8') as f:
    f.write(collector_profile_content)

# 2. Modify farmer_profile_for_collector_screen.dart
with open('lib/screens/farmer_profile_for_collector_screen.dart', 'r', encoding='utf-8') as f:
    farmer_profile_content = f.read()

old_constructor = """  const FarmerProfileForCollectorScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.requestId,
  });

  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String requestId;"""
  
new_constructor = """  const FarmerProfileForCollectorScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    this.requestId,
  });

  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String? requestId;"""
farmer_profile_content = farmer_profile_content.replace(old_constructor, new_constructor)

old_fab = """      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox("""
new_fab = """      floatingActionButton: widget.requestId == null ? null : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox("""
farmer_profile_content = farmer_profile_content.replace(old_fab, new_fab)

with open('lib/screens/farmer_profile_for_collector_screen.dart', 'w', encoding='utf-8') as f:
    f.write(farmer_profile_content)

# 3. Modify collector_history_tab.dart
with open('lib/screens/collector_history_tab.dart', 'r', encoding='utf-8') as f:
    collector_history_content = f.read()

if "import 'package:supabase_flutter/supabase_flutter.dart';" not in collector_history_content:
    collector_history_content = "import 'package:supabase_flutter/supabase_flutter.dart';\n" + collector_history_content

if "import 'farmer_profile_for_collector_screen.dart';" not in collector_history_content:
    collector_history_content = "import 'farmer_profile_for_collector_screen.dart';\n" + collector_history_content

old_load_history = """  Future<void> _loadHistory() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'];
      if (collectorId != null) {
        final data = await LocalDatabaseHelper.instance.getHarvestsByCollectorId(collectorId);
        setState(() {
          _harvests = data;
        });
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }"""
new_load_history = """  Future<void> _loadHistory() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'];
      if (collectorId != null) {
        final data = await LocalDatabaseHelper.instance.getHarvestsByCollectorId(collectorId);
        
        final farmerIds = data.map((e) => e['farmer_id'] as String).toSet().toList();
        Map<String, Map<String, dynamic>> profileMap = {};
        if (farmerIds.isNotEmpty) {
           try {
             final profiles = await Supabase.instance.client.from('profiles').select('id, full_name, phone').inFilter('id', farmerIds);
             for (var p in profiles) {
               profileMap[p['id']] = p;
             }
           } catch (_) {}
        }
        
        final List<Map<String, dynamic>> enrichedData = data.map((e) {
          final enriched = Map<String, dynamic>.from(e);
          final p = profileMap[e['farmer_id']];
          enriched['farmer_name'] = p?['full_name'] ?? 'Unknown Farmer';
          enriched['farmer_phone'] = p?['phone'] ?? 'No Phone';
          return enriched;
        }).toList();

        setState(() {
          _harvests = enrichedData;
        });
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }"""
collector_history_content = collector_history_content.replace(old_load_history, new_load_history)

old_list_tile = """                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isSynced ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                    child: Icon(
                                      isSynced ? Icons.cloud_done : Icons.cloud_upload, 
                                      color: isSynced ? Colors.green : Colors.orange
                                    ),
                                  ),
                                  title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(isSynced 
                                    ? (isSinhala ? 'සමමුහුර්ත කර ඇත' : 'Synced') 
                                    : (isSinhala ? 'සමමුහුර්ත වෙමින් පවතී' : 'Pending Sync')
                                  ),
                                  trailing: Text(
                                    '${item['weight_kg']} Kg', 
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: cs.primary, 
                                      fontWeight: FontWeight.w900
                                    ),
                                  ),
                                ),"""
new_list_tile = """                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FarmerProfileForCollectorScreen(
                                          farmerId: item['farmer_id'],
                                          farmerName: item['farmer_name'] ?? 'Unknown',
                                          farmerPhone: item['farmer_phone'] ?? 'No phone',
                                          requestId: null,
                                        ),
                                      ),
                                    );
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isSynced ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                    child: Icon(
                                      isSynced ? Icons.cloud_done : Icons.cloud_upload, 
                                      color: isSynced ? Colors.green : Colors.orange
                                    ),
                                  ),
                                  title: Text(item['farmer_name'] ?? 'Unknown Farmer', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(dateStr),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item['weight_kg']} Kg', 
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: cs.primary, 
                                          fontWeight: FontWeight.w900
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, size: 16, color: cs.primary),
                                    ],
                                  ),
                                ),"""
collector_history_content = collector_history_content.replace(old_list_tile, new_list_tile)

with open('lib/screens/collector_history_tab.dart', 'w', encoding='utf-8') as f:
    f.write(collector_history_content)

# 4. Modify collector_home_screen.dart
with open('lib/screens/collector_home_screen.dart', 'r', encoding='utf-8') as f:
    collector_home_content = f.read()

if "import 'collector_profile_tab.dart';" not in collector_home_content:
    collector_home_content = collector_home_content.replace("import 'collector_history_tab.dart';", "import 'collector_history_tab.dart';\nimport 'collector_profile_tab.dart';")

old_scaffold_body = """        return Scaffold(
          body: _currentIndex == 0 ? _buildDashboard(context, theme, cs, isSinhala) : const CollectorHistoryTab(),"""
new_scaffold_body = """        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboard(context, theme, cs, isSinhala),
              const CollectorHistoryTab(),
              const CollectorProfileTab(),
            ],
          ),"""
collector_home_content = collector_home_content.replace(old_scaffold_body, new_scaffold_body)

old_nav_items = """                children: [
                  _buildNavItem(0, Icons.home_filled, Icons.home_outlined, isSinhala ? 'මුල් පිටුව' : 'Home', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                  _buildNavItem(1, Icons.history, Icons.history_outlined, isSinhala ? 'ඉතිහාසය' : 'History', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                ],"""
new_nav_items = """                children: [
                  _buildNavItem(0, Icons.home_filled, Icons.home_outlined, isSinhala ? 'මුල් පිටුව' : 'Home', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                  _buildNavItem(1, Icons.history, Icons.history_outlined, isSinhala ? 'ඉතිහාසය' : 'History', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                  _buildNavItem(2, Icons.person, Icons.person_outline, isSinhala ? 'ගිණුම' : 'Profile', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                ],"""
collector_home_content = collector_home_content.replace(old_nav_items, new_nav_items)

with open('lib/screens/collector_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(collector_home_content)

print("Updates applied successfully!")
