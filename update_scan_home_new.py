import re

with open("lib/screens/scan_home_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

new_build = """  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    bool isSinhala = isSinhalaMode.value;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Soft green background
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Top Bar: Menu, Lang, Notifications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black87),
                          onPressed: () {},
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => isSinhalaMode.value = !isSinhalaMode.value,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green.shade200,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(
                                isSinhala ? 'EN / සිං' : 'සිං / EN',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: Colors.black87),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Greeting Text
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          isSinhala ? 'ආයුබෝවන්' : 'Hello',
                          style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.spa, color: Colors.green.shade800, size: 24),
                      ],
                    ),
                    if (widget.farmerName.isNotEmpty) ...[
                      Text(
                        widget.farmerName,
                        style: const TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 20),
                    
                    // The Image Slider Card (Hero Section)
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
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
                            // Dark gradient at the bottom for text readability
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            // Text inside the slider
                            Positioned(
                              bottom: 24,
                              left: 20,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSinhala ? 'තේ රෝග' : 'Tea Disease',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    isSinhala ? 'හඳුනාගැනීම' : 'Detection',
                                    style: TextStyle(color: Colors.green.shade300, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isSinhala 
                                      ? 'තේ වගාවේ රෝග කල්තියා හඳුනාගෙන වගාව ආරක්ෂා කරගන්න.' 
                                      : 'Identify diseases early and protect your tea plantation.',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // Page Indicator dots
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_images.length, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    height: 6,
                                    width: _currentPage == index ? 24 : 6,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index ? Colors.green.shade400 : Colors.white54,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Detect Disease Action Card (Matching user mockup)
                    GestureDetector(
                      onTap: () => _showDetectDiseaseSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5D6A7), // Soft vibrant green
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.camera_alt_outlined, color: Colors.green.shade800, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSinhala ? 'රෝගය හඳුනාගන්න' : 'Detect Disease',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isSinhala 
                                      ? 'රෝග හඳුනාගැනීම සඳහා තේ කොළයක ඡායාරූපයක් ලබා දෙන්න.' 
                                      : 'Provide a photo of a tea leaf for disease detection.',
                                    style: TextStyle(color: Colors.black87.withOpacity(0.7), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_right, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Request Pickup Action Card
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PickupRequestScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8E6C9), // Slightly lighter green
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.local_shipping_outlined, color: Colors.green.shade800, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSinhala ? 'දළු ලබාදීම' : 'Request Pickup',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isSinhala 
                                      ? 'ඔබගේ තේ දළු ලබාදීම සඳහා එකතු කරන්නෙකු ගෙන්වා ගන්න.' 
                                      : 'Request a collector to pick up your harvest.',
                                    style: TextStyle(color: Colors.black87.withOpacity(0.7), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_right, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                            color: Colors.black87
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        label: Text(isSinhala ? 'සියල්ල බලන්න' : 'View All', style: TextStyle(color: Colors.green.shade800)),
                        icon: Icon(Icons.chevron_right, color: Colors.green.shade800),
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
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}"""

start_str = "  @override\n  Widget build(BuildContext context) {"
end_str = "class _CommonDiseasesRow extends StatelessWidget {"

s_idx = content.find(start_str)
e_idx = content.find(end_str)

if s_idx != -1 and e_idx != -1:
    new_content = content[:s_idx] + new_build + "\n\n" + content[e_idx:]
    with open("lib/screens/scan_home_screen.dart", "w", encoding="utf-8") as f:
        f.write(new_content)
    print("Replaced build method successfully")
else:
    print("Could not find start or end bounds")
