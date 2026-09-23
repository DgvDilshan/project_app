import 'package:flutter/material.dart';
import '../main.dart'; // for isSinhalaMode
import '../services/local_database_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_manager.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
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
      final farmerId = cache['user_id'];
      if (farmerId != null) {
        final data = await LocalDatabaseHelper.instance.getHarvestsByFarmerId(farmerId);
        setState(() {
          _harvests = data;
        });
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'අස්වනු ඉතිහාසය (Passbook)' : 'Digital Passbook'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSinhala ? 'ඔබගේ ලබාදීම් වාර්තාව' : 'Your Supply Records',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    try {
                      await SyncManager.instance.syncData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sync completed!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync Error: $e')),
                        );
                      }
                    }
                    await _loadHistory();
                  },
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _harvests.isEmpty
                      ? ListView( // Use ListView so RefreshIndicator works
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Text(isSinhala ? 'තවමත් වාර්තා නොමැත.' : 'No records yet.'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _harvests.length,
                          itemBuilder: (context, index) {
                            final item = _harvests[index];
                            // Simple date formatting
                            final dateStr = item['recorded_at'].toString().split('T').first;
                            return _HistoryItem(
                              date: dateStr,
                              weight: '${item['weight_kg']} Kg',
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

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.date, required this.weight});
  
  final String date;
  final String weight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.2),
          child: Icon(Icons.eco, color: cs.primary),
        ),
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Tea Leaves'),
        trailing: Text(
          weight, 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.primary, 
            fontWeight: FontWeight.w900
          ),
        ),
      ),
    );
  }
}
