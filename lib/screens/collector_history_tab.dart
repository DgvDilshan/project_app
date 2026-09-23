import 'farmer_profile_for_collector_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/local_database_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_manager.dart';

class CollectorHistoryTab extends StatefulWidget {
  const CollectorHistoryTab({super.key});

  @override
  State<CollectorHistoryTab> createState() => _CollectorHistoryTabState();
}

class _CollectorHistoryTabState extends State<CollectorHistoryTab> {
  List<Map<String, dynamic>> _harvests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'];
      if (collectorId != null) {
        final data = await LocalDatabaseHelper.instance.getHarvestsByCollectorId(collectorId);
        
        final farmerIds = data.map((e) => e['farmer_id'] as String).toSet().toList();
        Map<String, Map<String, dynamic>> profileMap = {};
        if (farmerIds.isNotEmpty) {
           try {
             final profiles = await Supabase.instance.client.from('profiles').select('id, full_name, phone, plot_number').inFilter('id', farmerIds);
             for (var p in profiles) {
               profileMap[p['id']] = p;
             }
           } catch (_) {}
        }
        
        final List<Map<String, dynamic>> enrichedData = data.map((e) {
          final enriched = Map<String, dynamic>.from(e);
          final p = profileMap[e['farmer_id']];
          final plotNum = p?['plot_number'] != null ? ' (Plot: ${p!['plot_number']})' : '';
          enriched['farmer_name'] = '${p?['full_name'] ?? 'Unknown Farmer'}$plotNum';
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
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'එකතු කිරීමේ ඉතිහාසය' : 'Collection History'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSinhala ? 'ඔබගේ එකතු කිරීමේ වාර්තාව' : 'Your Collection Records',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await SyncManager.instance.syncData();
                    await _loadHistory();
                  },
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _harvests.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.history, size: 80, color: cs.primary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(isSinhala ? 'තවමත් වාර්තා නොමැත.' : 'No records yet.'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _harvests.length,
                          itemBuilder: (context, index) {
                            final item = _harvests[index];
                            final dateStr = item['recorded_at'].toString().split('T').first;
                            final isSynced = item['is_synced'] == 1;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
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
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
