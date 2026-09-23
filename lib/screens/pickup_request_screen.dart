import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../services/local_database_helper.dart';
import '../services/sync_manager.dart';

class PickupRequestScreen extends StatefulWidget {
  const PickupRequestScreen({super.key});

  @override
  State<PickupRequestScreen> createState() => _PickupRequestScreenState();
}

class _PickupRequestScreenState extends State<PickupRequestScreen> {
  bool _isLoading = false;
  bool _isChecking = true;
  bool _hasPending = false;

  @override
  void initState() {
    super.initState();
    _checkPendingStatus();
  }

  Future<void> _checkPendingStatus() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      if (farmerId != null) {
        bool pending = false;
        try {
          final res = await Supabase.instance.client
              .from('pickup_requests')
              .select('id')
              .eq('farmer_id', farmerId)
              .eq('status', 'pending');
          pending = res.isNotEmpty;
        } catch (_) {
          // Fallback to local DB if offline
          pending = await LocalDatabaseHelper.instance.hasPendingPickupRequest(farmerId);
        }
        
        setState(() {
          _hasPending = pending;
        });
      }
    } catch (e) {
      debugPrint("Error checking pending request: $e");
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      
      if (farmerId == null) throw Exception("User not logged in");

      final request = {
        'id': const Uuid().v4(),
        'farmer_id': farmerId,
        'request_date': DateTime.now().toIso8601String(),
        'status': 'pending',
        'disease_flag': null, // Can be integrated with the latest scan result
        'is_synced': 0, // 0 = not synced yet
      };

      await LocalDatabaseHelper.instance.insertPickupRequest(request);
      
      // Try to sync immediately if online
      SyncManager.instance.syncData();
      
      if (!mounted) return;
      setState(() => _hasPending = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup Request saved! It will sync when online.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Pickup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isChecking 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _hasPending ? Icons.check_circle : Icons.local_shipping, 
                  size: 80, 
                  color: _hasPending ? Colors.green : Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  _hasPending ? 'Request Already Sent!' : 'Ready to supply tea leaves?',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _hasPending 
                    ? 'You already have a pending pickup request. Please wait for the collector to visit your estate.'
                    : 'Submit a pickup request. Our collectors will be notified to visit your estate. Note that weights will be recorded by the collector at the time of pickup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _hasPending ? Colors.green.shade800 : Colors.black87,
                    fontWeight: _hasPending ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 32),
                if (!_hasPending)
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _submitRequest,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Request'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
              ],
            ),
      ),
    );
  }
}
