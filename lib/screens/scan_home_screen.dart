import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../main.dart';
import '../localization/app_translations.dart';
import 'scan_review_screen.dart';
import 'disease_info_screen.dart';

class ScanHomeScreen extends StatefulWidget {
  const ScanHomeScreen({super.key});

  @override
  State<ScanHomeScreen> createState() => _ScanHomeScreenState();
}

class _ScanHomeScreenState extends State<ScanHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _HomeTab(controller: _controller),
          _PlaceholderTab(title: isSinhala ? 'ඉතිහාසය' : 'History'),
          _PlaceholderTab(title: isSinhala ? 'උපදෙස්' : 'Tips'),
          _PlaceholderTab(title: isSinhala ? 'ගිණුම' : 'Profile'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: isSinhala ? 'මුල් පිටුව' : 'Home'),
          NavigationDestination(icon: const Icon(Icons.history), label: isSinhala ? 'ඉතිහාසය' : 'History'),
          NavigationDestination(icon: const Icon(Icons.spa_outlined), label: isSinhala ? 'උපදෙස්' : 'Tips'),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: isSinhala ? 'ගිණුම' : 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.controller});

  final Animation<double> controller;

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

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surface,
                    cs.primaryContainer.withValues(alpha: 0.32),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Menu',
                      onPressed: () {},
                      icon: const Icon(Icons.menu),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        isSinhalaMode.value = !isSinhalaMode.value;
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        isSinhala ? 'EN / සිං' : 'සිං / EN',
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(isSinhala ? 'ආයුබෝවන්' : 'Hello, User', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Icon(Icons.spa, color: cs.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                _HeroSection(controller: controller),
                const SizedBox(height: 14),
                _DetectDiseaseCard(
                  controller: controller,
                  onTap: () => _showDetectDiseaseSheet(context),
                ),
                const SizedBox(height: 18),
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
                _BottomBanner(controller: controller),
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
        ],
      ),
    );
  }
}

class _HeroSection extends StatefulWidget {
  const _HeroSection({required this.controller});
  final Animation<double> controller;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
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

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // 1. Image Slider Background
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Auto-slide only
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, child) {
                       // Very subtle zoom effect
                       final scale = 1.0 + (widget.controller.value * 0.05);
                       return Transform.scale(
                         scale: scale,
                         child: child,
                       );
                    },
                    child: Image.asset(
                      _images[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            // 2. Gradient Overlay for Text Readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            // 3. Text Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isSinhala ? 'ආයුබෝවන්' : 'Hello, User', 
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.spa, size: 18, color: cs.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: isSinhala ? 'තේ රෝග\n' : 'Tea Disease\n'),
                        TextSpan(
                          text: isSinhala ? 'හඳුනාගැනීම' : 'Detection',
                          style: TextStyle(color: cs.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSinhala ? 'තේ වගාවේ රෝග කල්තියා හඳුනාගෙන වගාව ආරක්ෂා කරගන්න.' : 'Detect tea plant diseases early and keep your plants healthy.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // 4. Dots Indicator
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentPage == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? cs.primary : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectDiseaseCard extends StatelessWidget {
  const _DetectDiseaseCard({required this.controller, required this.onTap});

  final Animation<double> controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final arrowPulse = Tween<double>(
      begin: 0.98,
      end: 1.05,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primaryContainer, cs.primary.withValues(alpha: 0.85)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: cs.surface.withValues(alpha: 0.85),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: cs.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.get('proceed_button', isSinhalaMode.value).replaceAll('Disease', '').trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSinhalaMode.value 
                        ? 'රෝග හඳුනාගැනීම සඳහා තේ කොළයක ඡායාරූපයක් ලබා දෙන්න.'
                        : 'Upload or capture a photo\nof tea leaf to detect disease.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Transform.scale(scale: arrowPulse.value, child: child);
                },
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surface.withValues(alpha: 0.85),
                  ),
                  child: Icon(Icons.chevron_right, color: cs.primary, size: 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickOption extends StatelessWidget {
  const _PickOption({required this.source});

  final ScanSource source;

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final label = source == ScanSource.camera
        ? AppTranslations.get('take_photo', isSinhala)
        : AppTranslations.get('pick_gallery', isSinhala);
    final icon = source == ScanSource.camera
        ? Icons.camera_alt_outlined
        : Icons.photo_outlined;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(source),
    );
  }
}

class _CommonDiseasesRow extends StatelessWidget {
  const _CommonDiseasesRow();

  static const _items = <_DiseaseCardData>[
    _DiseaseCardData(
      titleEn: 'Tea Blister Blight',
      titleSi: 'බ්ලිස්ටර් බ්ලයිට්',
      subtitle: 'Exobasidium vexans',
      asset: 'assets/images/real_blister_blight.jpg',
      symptomsEn: [
        'Small translucent spots on young leaves.',
        'White blister-like swellings on the underside of leaves.',
        'Curling and distortion of tender shoots.',
      ],
      symptomsSi: [
        'ළපටි කොළ වල කුඩා පාරභාසක ලප ඇතිවීම.',
        'කොළ යටි පැත්තේ සුදු පැහැති බිබිලි මතු වීම.',
        'ළපටි දළු හැකිලී විකෘති වීම.',
      ],
      recommendationsEn: [
        'Isolate the affected section immediately.',
        'Apply copper-based fungicides.',
        'Remove heavily infected shoots and leaves.',
        'Ensure timely plucking to reduce spread.',
      ],
      recommendationsSi: [
        'රෝගී කොටස් වහාම වෙන් කරන්න.',
        'කොපර් අඩංගු දිලීර නාශකයක් යොදන්න.',
        'දරුණු ලෙස රෝගී වූ දළු සහ කොළ කඩා ඉවත් කරන්න.',
        'රෝගය පැතිරීම අවම කිරීමට නියමිත කාලයට දළු නෙළන්න.',
      ],
    ),
    _DiseaseCardData(
      titleEn: 'Tea Brown Blight',
      titleSi: 'බ්‍රවුන් බ්ලයිට්',
      subtitle: 'Colletotrichum spp.',
      asset: 'assets/images/real_brown_blight.jpg',
      symptomsEn: [
        'Yellow-brown spots on older leaves.',
        'Spots develop into large brown patches with concentric rings.',
        'Leaves eventually dry up and fall off.',
      ],
      symptomsSi: [
        'පැරණි කොළවල කහ-දුඹුරු ලප ඇතිවීම.',
        'ලප විශාල වී වෘත්තාකාර දුඹුරු පැල්ලම් බවට පත්වීම.',
        'අවසානයේ කොළ වියළී හැලී යාම.',
      ],
      recommendationsEn: [
        'Reduce shade if it is too dense.',
        'Collect and dispose of fallen infected leaves.',
        'Improve airflow by light pruning.',
      ],
      recommendationsSi: [
        'සෙවණ වැඩි නම් එය අඩු කරන්න.',
        'බිමට වැටී ඇති රෝගී කොළ එකතු කර විනාශ කරන්න.',
        'සුළු කප්පාදුවක් මගින් වාතාශ්‍රය වැඩි කරන්න.',
      ],
    ),
    _DiseaseCardData(
      titleEn: 'Tea Red Rust',
      titleSi: 'රෙඩ් රස්ට්',
      subtitle: 'Cephaleuros virescens',
      asset: 'assets/images/real_red_rust.jpg',
      symptomsEn: [
        'Orange-red or rusty raised spots on the upper leaf surface.',
        'Spots may merge to form larger rusty patches.',
        'Usually indicates poor plant vigor and nutritional stress.',
      ],
      symptomsSi: [
        'කොළ මතුපිට තැඹිලි-රතු පැහැති රළු ලප ඇතිවීම.',
        'මෙම ලප එකතු වී විශාල රතු පැල්ලම් සෑදීම.',
        'බොහෝවිට ශාකයේ පෝෂණ ඌනතාවයක් පෙන්නුම් කරයි.',
      ],
      recommendationsEn: [
        'Check for nutritional stress and apply proper fertilizers.',
        'Ensure adequate drainage and avoid waterlogging.',
        'Prune affected branches if the infection is severe.',
      ],
      recommendationsSi: [
        'පෝෂණ ඌනතා පරීක්ෂා කර නිසි පොහොර යොදන්න.',
        'ජලය හොඳින් බැසයාමට සලස්වා ජලය රැඳීම වළක්වන්න.',
        'රෝගය දරුණු නම් රෝගී අතු කපා ඉවත් කරන්න.',
      ],
    ),
    _DiseaseCardData(
      titleEn: 'Tea Powdery Mildew',
      titleSi: 'පවුඩරි මිල්ඩියු',
      subtitle: 'Erysiphe polygonii',
      asset: 'assets/images/real_powdery_mildew.jpg',
      symptomsEn: [
        'White, powdery fungal growth mostly on young leaves.',
        'Infected leaves become curled and distorted.',
        'Premature leaf drop in severe cases.',
      ],
      symptomsSi: [
        'ළපටි කොළ සහ දළු මත සුදු පැහැති පිටි වැනි දිලීර වර්ධනය වීම.',
        'රෝගී වූ කොළ හැකිලී විකෘති වීම.',
        'දරුණු තත්ත්වයකදී කොළ නොමේරී හැලී යාම.',
      ],
      recommendationsEn: [
        'Apply sulfur-based fungicides.',
        'Improve air circulation in the field.',
        'Avoid high humidity and damp conditions.',
      ],
      recommendationsSi: [
        'සල්ෆර් අඩංගු දිලීර නාශක යොදන්න.',
        'වගාවේ වාතය හොඳින් ගමන් කිරීමට සලස්වන්න.',
        'අධික ආර්ද්‍රතාවය සහ තෙත් පරිසරය වළක්වාගන්න.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _DiseaseCard(data: _items[index]),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemCount: _items.length,
      ),
    );
  }
}

class _DiseaseCardData {
  const _DiseaseCardData({
    required this.titleEn,
    required this.titleSi,
    required this.subtitle,
    required this.asset,
    required this.symptomsEn,
    required this.symptomsSi,
    required this.recommendationsEn,
    required this.recommendationsSi,
  });

  final String titleEn;
  final String titleSi;
  final String subtitle;
  final String asset;
  final List<String> symptomsEn;
  final List<String> symptomsSi;
  final List<String> recommendationsEn;
  final List<String> recommendationsSi;
}

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({required this.data});

  final _DiseaseCardData data;

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: 156,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiseaseInfoScreen(
                  title: isSinhala ? data.titleSi : data.titleEn,
                  subtitle: data.subtitle,
                  assetPath: data.asset,
                  symptoms: isSinhala ? data.symptomsSi : data.symptomsEn,
                  recommendations: isSinhala ? data.recommendationsSi : data.recommendationsEn,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: cs.surfaceContainerHighest,
                  padding: data.asset.endsWith('.svg') ? const EdgeInsets.all(12) : EdgeInsets.zero,
                  child: data.asset.endsWith('.svg') 
                    ? SvgPicture.asset(
                        data.asset,
                        fit: BoxFit.contain,
                        semanticsLabel: isSinhala ? data.titleSi : data.titleEn,
                      )
                    : Image.asset(
                        data.asset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSinhala ? data.titleSi : data.titleEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBanner extends StatelessWidget {
  const _BottomBanner({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final floatX = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: cs.primaryContainer.withValues(alpha: 0.55),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surface.withValues(alpha: 0.9),
            ),
            child: Icon(Icons.shield_outlined, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSinhalaMode.value ? 'නිරෝගී වගාවක්, වඩා හොඳ අනාගතයක්' : 'Healthy Plant, Better Future',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSinhalaMode.value 
                    ? 'නිතිපතා පරීක්ෂා කිරීමෙන් සහ කල්තියා හඳුනාගැනීමෙන් හොඳ අස්වැන්නක් ලබාගත හැක.'
                    : 'Regular monitoring and early detection helps in better yield and quality.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(floatX.value, 0),
                child: child,
              );
            },
            child: SizedBox(
              height: 56,
              width: 56,
              child: SvgPicture.asset('assets/images/tea_leaf.svg'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title will appear here.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
