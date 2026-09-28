import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/custom_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../services/local_database_helper.dart';
import '../services/sync_manager.dart';
import 'auth_gate.dart';

class PickupRequestScreen extends StatefulWidget {
  const PickupRequestScreen({super.key});

  @override
  State<PickupRequestScreen> createState() => _PickupRequestScreenState();
}

class _PickupRequestScreenState extends State<PickupRequestScreen> {
  bool _isLoading = false;
  bool _isChecking = true;
  bool _hasPending = false;
  bool _isLinkedToFactory = false;

  final _factoryCodeController = TextEditingController();
  final _supplierNumberController = TextEditingController();
  String? _selectedRoute;
  
  final List<String> _demoRoutes = [
    'Line 1 (North)',
    'Line 2 (South)',
    'Line 3 (East)',
    'Line 4 (West)',
  ];

  @override
  void initState() {
    super.initState();
    _checkPendingStatus();
  }

  Future<void> _checkPendingStatus() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      if (farmerId == null) {
          _isLinkedToFactory = false;
      }
      if (farmerId != null) {
        
        // 1. Check if linked to factory
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('factory_code, route_name, supplier_number')
            .eq('id', farmerId)
            .single();
            
        final hasFactory = profileRes['factory_code'] != null && profileRes['factory_code'].toString().isNotEmpty;
        final hasRoute = profileRes['route_name'] != null && profileRes['route_name'].toString().isNotEmpty;
        
        if (hasFactory && hasRoute) {
          _isLinkedToFactory = true;
        } else {
          _isLinkedToFactory = false;
        }

        // 2. Check for pending requests
        bool pending = false;
        try {
          final res = await Supabase.instance.client
              .from('pickup_requests')
              .select('id')
              .eq('farmer_id', farmerId)
              .eq('status', 'pending');
          pending = res.isNotEmpty;
        } catch (_) {
          pending = await LocalDatabaseHelper.instance.hasPendingPickupRequest(farmerId);
        }
        
        if (mounted) {
          setState(() {
            _hasPending = pending;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking pending status: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      
      if (farmerId == null) throw Exception("User not logged in");

      // We don't save the route in pickup_requests yet, we just rely on profiles.
      // But we can fetch route_name to be sure.
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('route_name')
          .eq('id', farmerId)
          .single();
          
      final routeName = profileRes['route_name'];

      final request = {
        'id': const Uuid().v4(),
        'farmer_id': farmerId,
        'request_date': DateTime.now().toIso8601String(),
        'status': 'pending',
        'disease_flag': null, 
        'is_synced': 0, 
      };

      await LocalDatabaseHelper.instance.insertPickupRequest(request);
      
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

  Future<void> _linkFactory() async {
    if (_factoryCodeController.text.isEmpty || _selectedRoute == null || _supplierNumberController.text.isEmpty) {
      CustomSnackBar.showError(context, 'Please fill all fields');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      if (farmerId == null) return;
      
      await Supabase.instance.client.from('profiles').update({
        'factory_code': _factoryCodeController.text.trim(),
        'route_name': _selectedRoute,
        'supplier_number': _supplierNumberController.text.trim(),
      }).eq('id', farmerId);
      
      setState(() {
        _isLinkedToFactory = true;
      });
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Factory Linked Successfully!');
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLinkFactoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Link to a Factory'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('You must link to a tea factory to request pickups.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _factoryCodeController,
                      decoration: const InputDecoration(labelText: 'Factory Code (e.g., ROS-123)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRoute,
                      decoration: const InputDecoration(labelText: 'Collection Route', border: OutlineInputBorder()),
                      items: _demoRoutes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setDialogState(() => _selectedRoute = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _supplierNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Supplier Number (e.g., 1200)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Call the method in the parent state
                    _linkFactory();
                  },
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Link Factory'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    return Scaffold(
      appBar: AppBar(title: Text(isSinhala ? 'දලු ලබාගැනීමේ ඉල්ලීම' : 'Request Pickup')),
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isChecking 
          ? const Center(child: CircularProgressIndicator())
          : !_isLinkedToFactory
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_off, size: 80, color: Colors.orange),
                  const SizedBox(height: 24),
                  Text(
                    isSinhala ? 'කර්මාන්තශාලාවකට සම්බන්ධ කර නොමැත' : 'Not Linked to a Factory',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSinhala ? 'දලු ලබාගැනීමක් ඉල්ලීමට, ඔබගේ ගිණුම කර්මාන්තශාලා අංකයක් හරහා සම්බන්ධ කර තිබිය යුතුය.' : 'To request a harvest pickup, you must have an account linked to a Tea Factory using a Factory Code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<Map<String, String?>>(
                    future: AuthService.instance.getCachedUser(),
                    builder: (context, snapshot) {
                      final isGuest = snapshot.data?['user_id'] == null;
                      if (isGuest) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthGate()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: Text(isSinhala ? 'ලියාපදිංචි වන්න / ලොග් වන්න' : 'Sign Up / Log In Now'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          ),
                        );
                      }
                      return ElevatedButton.icon(
                        onPressed: _showLinkFactoryDialog,
                        icon: const Icon(Icons.link),
                        label: Text(isSinhala ? 'කර්මාන්තශාලාව සම්බන්ධ කරන්න' : 'Link Factory Now'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        ),
                      );
                    },
                  ),
                ],
              )
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
      ),
    );
  }
}
