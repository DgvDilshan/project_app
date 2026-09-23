import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../main.dart'; // for isSinhalaMode
import '../services/local_database_helper.dart';
import 'auth_gate.dart';
import 'offline_weight_entry_screen.dart';
import 'qr_scanner_screen.dart';
import 'collector_history_tab.dart';
import 'collector_profile_tab.dart';
import 'farmer_profile_for_collector_screen.dart'; // Import history tab

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  double _totalKgToday = 0.0;
  late final AnimationController _animController;

  String _collectorName = 'Collector';
  int _currentIndex = 0; // State for bottom nav


  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _images = [
    'assets/images/slider_1.jpg',
    'assets/images/slider_2.jpg',
    'assets/images/slider_3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      setState(() {
        if (_currentPage < _images.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
      });
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    _loadCollectorName();
    _fetchRequests();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadCollectorName() async {
    final cache = await AuthService.instance.getCachedUser();
    if (mounted && cache['user_name'] != null) {
      setState(() {
        _collectorName = cache['user_name'] as String;
      });
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final cache = await AuthService.instance.getCachedUser();
      final collectorId = cache['user_id'] as String?;
      final collectorRouteStr = cache['route_index'] as String?;

      final response = await _supabase
          .from('pickup_requests')
          .select('id, farmer_id, request_date, status, disease_flag, profiles(full_name, phone, route_index, plot_number)')
          .eq('status', 'pending');

      List<Map<String, dynamic>> rawRequestsList = List<Map<String, dynamic>>.from(response);
      List<Map<String, dynamic>> requestsList = [];
      
      for (var req in rawRequestsList) {
        final profile = req['profiles'] as Map<String, dynamic>?;
        final reqRouteStr = profile?['route_index']?.toString();
        // Filter out requests that do not belong to the collector's route
        if (collectorRouteStr != null && reqRouteStr == collectorRouteStr) {
          requestsList.add(req);
        } else if (collectorRouteStr == null) {
          // If collector didn't set a route, maybe show all (or none). Let's show all for safety.
          requestsList.add(req);
        }
      }

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
  }

  Widget _buildDashboard(BuildContext context, ThemeData theme, ColorScheme cs, bool isSinhala) {
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  final scale = 1.0 + (_animController.value * 0.05);
                                  return Transform.scale(scale: scale, child: child);
                                },
                                child: Image.asset(
                                  _images[index],
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.green.shade800.withOpacity(0.4),
                                  Colors.green.shade600.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.person, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => isSinhalaMode.value = !isSinhalaMode.value,
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: Text(
                                      isSinhala ? 'EN / සිං' : 'සිං / EN',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.logout, color: Colors.white),
                                      onPressed: () async {
                                        await AuthService.instance.clearSession();
                                        if (!context.mounted) return;
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (_) => const AuthGate()),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isSinhala ? 'ආයුබෝවන්,' : 'Hello,',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          Text(
                            _collectorName,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: Row(
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _pendingRequests.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 80, color: cs.primary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                isSinhala ? 'නව ඉල්ලීම් නොමැත.' : 'No pending pickup requests.',
                                style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final req = _pendingRequests[index];
                              return _PickupCard(
                                request: req,
                                onTap: () async {
                                  final profile = req['profiles'] as Map<String, dynamic>?;
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FarmerProfileForCollectorScreen(
                                        farmerId: req['farmer_id'],
                                        farmerName: profile?['full_name'] ?? 'Unknown',
                                        farmerPhone: profile?['phone'] ?? 'No phone',
                                        requestId: req['id'],
                                      ),
                                    ),
                                  );
                                  
                                  if (result == true) {
                                    _fetchRequests();
                                  }
                                },
                              );
                            },
                            childCount: _pendingRequests.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
          final scale = 1.0 + (_animController.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                );
                if (result == true) {
                  _fetchRequests(); // Refresh if a weight was saved
                }
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(isSinhala ? 'QR ස්කෑන් කරන්න' : 'Scan Farmer QR'),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: isSinhalaMode,
      builder: (context, isSinhala, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboard(context, theme, cs, isSinhala),
              const CollectorHistoryTab(),
              const CollectorProfileTab(),
            ],
          ),
          extendBody: true,
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 60, right: 60, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_filled, Icons.home_outlined, isSinhala ? 'මුල් පිටුව' : 'Home', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                  _buildNavItem(1, Icons.history, Icons.history_outlined, isSinhala ? 'ඉතිහාසය' : 'History', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                  _buildNavItem(2, Icons.person, Icons.person_outline, isSinhala ? 'ගිණුම' : 'Profile', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, int currentIndex, Function(int) onTap, ColorScheme cs) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? Colors.green.shade800 : Colors.grey.shade600),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;

  const _PickupCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    bool isSinhala = isSinhalaMode.value;

    final profile = request['profiles'] as Map<String, dynamic>?;
        final fullName = profile?['full_name'] ?? 'Unknown Farmer';
    final plotNum = profile?['plot_number'] != null ? ' (Plot: ${profile!['plot_number']})' : '';
    final farmerName = '$fullName$plotNum';
    final phone = profile?['phone'] ?? 'No phone';
    final dateStr = request['request_date']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmerName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(phone, style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${isSinhala ? 'දිනය' : 'Date'}: $dateStr', 
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(isSinhala ? 'බර යොදන්න' : 'Weigh', style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: cs.secondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
