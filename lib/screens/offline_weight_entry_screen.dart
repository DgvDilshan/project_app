import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_database_helper.dart';
import '../services/sync_manager.dart';

import '../services/auth_service.dart';

class OfflineWeightEntryScreen extends StatefulWidget {
  final String? requestId;
  final String farmerId;
  final String farmerName;

  const OfflineWeightEntryScreen({
    super.key,
    this.requestId,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  State<OfflineWeightEntryScreen> createState() => _OfflineWeightEntryScreenState();
}

class _OfflineWeightEntryScreenState extends State<OfflineWeightEntryScreen> {
  final _weightController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitWeight() async {
    final weightStr = _weightController.text.trim();
    if (weightStr.isEmpty) return;

    final weight = double.tryParse(weightStr);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'];
      
      if (collectorId == null) throw Exception('Collector not logged in');

      // 1. Create Immutable Harvest Record
      final harvestId = const Uuid().v4();
      final harvestRecord = {
        'id': harvestId,
        'farmer_id': widget.farmerId,
        'collector_id': collectorId,
        'weight_kg': weight,
        'recorded_at': DateTime.now().toIso8601String(),
        'is_correction': 0, // 0 = false
        'is_synced': 0, // 0 = false
      };

      await LocalDatabaseHelper.instance.insertHarvest(harvestRecord);

      // 2. Mark the pickup request as completed directly on Supabase
      String? reqIdToComplete = widget.requestId;
      
      if (reqIdToComplete == null) {
        try {
          final pendingReqs = await Supabase.instance.client
              .from('pickup_requests')
              .select('id')
              .eq('farmer_id', widget.farmerId)
              .eq('status', 'pending');
          if (pendingReqs.isNotEmpty) {
            reqIdToComplete = pendingReqs.first['id'] as String;
          }
        } catch (_) {}
      }

      if (reqIdToComplete != null) {
        try {
          await Supabase.instance.client
              .from('pickup_requests')
              .update({'status': 'completed'})
              .eq('id', reqIdToComplete);
        } catch (e) {
          debugPrint('Failed to update request status on Supabase: $e');
        }
      }
      
      // Attempt to sync immediately
      SyncManager.instance.syncData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight recorded offline successfully!')),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving record: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Weight')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.scale, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Farmer: ${widget.farmerName}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the total weight of tea leaves collected. This record is immutable.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight (Kg)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.eco_outlined),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
                    onPressed: _submitWeight,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Record (Offline)'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
