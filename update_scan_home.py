import re

with open("lib/screens/scan_home_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

new_code = """class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.controller, required this.farmerName});

  final Animation<double> controller;
  final String farmerName;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showDetectDiseaseSheet(BuildContext context) async {
    final choice = await showModalBottomSheet<ScanSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _PickOption(source: ScanSource.camera),
              _PickOption(source: ScanSource.gallery),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ScanReviewScreen(source: choice)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    bool isSinhala = isSinhalaMode.value;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: CustomScrollView(
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
                    height: 380,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: widget.controller,
                              builder: (context, child) {
                                final scale = 1.0 + (widget.controller.value * 0.05);
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
                                Colors.green.shade700.withOpacity(0.85),
                                Colors.green.shade500.withOpacity(0.9),
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
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_none, color: Colors.white),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isSinhala ? 'ආයුබෝවන්,' : 'Hello,',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          widget.farmerName,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showDetectDiseaseSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.document_scanner, color: Colors.orange.shade700),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isSinhala ? 'රෝග හඳුනාගැනීම' : 'Detect Disease',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PickupRequestScreen()));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.local_shipping, color: Colors.blue.shade700),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isSinhala ? 'දළු ලබාදීම' : 'Request Pickup',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isSinhala ? 'සුලබ තේ රෝග' : 'Common Tea Diseases', 
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        label: Text(isSinhala ? 'සියල්ල බලන්න' : 'View All'),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _CommonDiseasesRow(),
                  const SizedBox(height: 18),
                  _BottomBanner(controller: widget.controller),
                  const SizedBox(height: 12),
                  Text(
                    isSinhala 
                      ? 'සටහන: මෙම යෙදුම තීරණ ගැනීමට සහාය වීම සඳහා පමණි, එය සහතිකයක් නොවේ. බරපතල රෝග ලක්ෂණ ඇත්නම්, සුදුසුකම් ලත් කෘෂි නිලධාරියෙකු අමතන්න.'
                      : 'Note: This app is for decision support, not a guarantee. If severe symptoms appear, contact a qualified field officer.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
"""

start_str = "class _HomeTab extends StatelessWidget {"
end_str = "class _DetectDiseaseCard extends StatelessWidget {"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + new_code + "\n" + content[end_idx:]
    with open("lib/screens/scan_home_screen.dart", "w", encoding="utf-8") as f:
        f.write(new_content)
    print("Replaced scan_home_screen successfully")
else:
    print("Could not find start or end index")
