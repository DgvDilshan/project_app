import re

with open("lib/screens/collector_home_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# We need to replace _buildDashboard and _CollectorHeroSection.
# Also need to add variables for the slider.
# Actually, since _CollectorHomeScreenState is huge, I will replace the whole _buildDashboard function.

# Let's extract the start of _buildDashboard to the end of _CollectorHeroSection.
# Wait, let's just replace _buildDashboard entirely, and _CollectorHeroSection entirely.

new_dashboard = """
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

  Future<void> _fetchRequests() async {
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
                                  Colors.green.shade800.withOpacity(0.85),
                                  Colors.green.shade600.withOpacity(0.95),
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
                                        isSinhala ? 'අද දින එකතු කිරීම්' : 'Today\'s Pickups',
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
      floatingActionButton: AnimatedBuilder(
"""

start_str = "  @override\n  void initState() {"
end_str = "      floatingActionButton: AnimatedBuilder("

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + new_dashboard + "\n      floatingActionButton: AnimatedBuilder(" + content[end_idx + len("      floatingActionButton: AnimatedBuilder("):]
    
    # We also need to remove _CollectorHeroSection
    hero_start = "class _CollectorHeroSection extends StatelessWidget {"
    hero_end = "class _PickupCard extends StatelessWidget {"
    
    h_start_idx = content.find(hero_start)
    h_end_idx = content.find(hero_end)
    
    if h_start_idx != -1 and h_end_idx != -1:
        content = content[:h_start_idx] + content[h_end_idx:]
    
    with open("lib/screens/collector_home_screen.dart", "w", encoding="utf-8") as f:
        f.write(content)
    print("Successfully replaced collector_home_screen")
else:
    print("Could not find start or end bounds for collector_home_screen")
