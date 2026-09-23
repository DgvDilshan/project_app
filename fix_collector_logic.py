import re

with open('lib/screens/collector_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _totalKgToday state variable
if 'double _totalKgToday = 0.0;' not in content:
    content = content.replace('bool _isLoading = true;', 'bool _isLoading = true;\n  double _totalKgToday = 0.0;')

# 2. Replace _fetchRequests
old_fetch = """  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('pickup_requests')
          .select('id, farmer_id, request_date, status, disease_flag, profiles(full_name, phone, route_index)')
          .eq('status', 'pending');

      final List<Map<String, dynamic>> requestsList = List<Map<String, dynamic>>.from(response);

      requestsList.sort((a, b) {
        final profileA = a['profiles'] as Map<String, dynamic>?;
        final profileB = b['profiles'] as Map<String, dynamic>?;
        final indexA = profileA?['route_index'] as int? ?? 9999;
        final indexB = profileB?['route_index'] as int? ?? 9999;
        
        if (indexA == indexB) {
          final dateA = a['request_date']?.toString() ?? '';
          final dateB = b['request_date']?.toString() ?? '';
          return dateA.compareTo(dateB);
        }
        
        return indexA.compareTo(indexB);
      });

      setState(() {
        _pendingRequests = requestsList;
      });
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }"""

new_fetch = """  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'] as String?;

      final response = await _supabase
          .from('pickup_requests')
          .select('id, farmer_id, request_date, status, disease_flag, profiles(full_name, phone, route_index)')
          .eq('status', 'pending');

      List<Map<String, dynamic>> requestsList = List<Map<String, dynamic>>.from(response);

      double totalKg = 0.0;
      Set<String> farmersCollectedToday = {};
      
      if (collectorId != null) {
        final localHarvests = await LocalDatabaseHelper.instance.getHarvestsByCollectorId(collectorId);
        final todayStr = DateTime.now().toIso8601String().split('T').first;
        
        for (var h in localHarvests) {
          final recDate = h['recorded_at']?.toString() ?? '';
          if (recDate.startsWith(todayStr)) {
            totalKg += (h['weight_kg'] as num).toDouble();
            farmersCollectedToday.add(h['farmer_id'].toString());
          }
        }
      }

      List<Map<String, dynamic>> filteredRequests = [];
      for (var req in requestsList) {
        if (farmersCollectedToday.contains(req['farmer_id'].toString())) {
          try {
            _supabase.from('pickup_requests').update({'status': 'completed'}).eq('id', req['id']);
          } catch (_) {}
        } else {
          filteredRequests.add(req);
        }
      }

      requestsList = filteredRequests;

      requestsList.sort((a, b) {
        final profileA = a['profiles'] as Map<String, dynamic>?;
        final profileB = b['profiles'] as Map<String, dynamic>?;
        final indexA = profileA?['route_index'] as int? ?? 9999;
        final indexB = profileB?['route_index'] as int? ?? 9999;
        
        if (indexA == indexB) {
          final dateA = a['request_date']?.toString() ?? '';
          final dateB = b['request_date']?.toString() ?? '';
          return dateA.compareTo(dateB);
        }
        
        return indexA.compareTo(indexB);
      });

      setState(() {
        _pendingRequests = requestsList;
        _totalKgToday = totalKg;
      });
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }"""

content = content.replace(old_fetch, new_fetch)

# 3. Replace Dashboard UI
old_ui = """                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.shopping_basket, color: Colors.green.shade700),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isSinhala ? 'අද දින එකතු කිරීම්' : "Today's Pickups",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_pendingRequests.length} ${isSinhala ? 'ඉතිරියි' : 'Left'}',
                                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),"""

new_ui = """                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.pending_actions, color: Colors.orange.shade700),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isSinhala ? 'ඉතිරියි' : "Pending",
                                              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${_pendingRequests.length}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.scale, color: Colors.green.shade700),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isSinhala ? 'අද එකතුව' : "Today's Total",
                                              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${_totalKgToday.toStringAsFixed(1)} Kg',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),"""

content = content.replace(old_ui, new_ui)

with open('lib/screens/collector_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed collector app logic and UI")
