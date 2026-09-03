import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../main.dart';
import '../localization/app_translations.dart';
import 'scan_review_screen.dart';

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

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final floatY = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    return SizedBox(
      height: 235,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.surface, cs.surfaceContainerHighest],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -10,
              top: -18,
              bottom: -18,
              child: ClipPath(
                clipper: _HeroCurveClipper(),
                child: Container(width: 230, color: cs.primaryContainer),
              ),
            ),
            Positioned(
              right: 8,
              top: 14,
              bottom: 14,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, floatY.value),
                    child: child,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SvgPicture.asset(
                    'assets/images/tea_plant_hero.svg',
                    width: 200,
                    fit: BoxFit.cover,
                    semanticsLabel: 'Tea plant illustration',
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 210,
              top: 18,
              bottom: 10, // Reduced bottom constraint to allow more space
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                      Text(isSinhala ? 'ආයුබෝවන්' : 'Hello, User', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 6),
                      Icon(Icons.spa, size: 18, color: cs.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: cs.onSurface,
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
                  const SizedBox(height: 10),
                  Text(
                    isSinhala ? 'තේ වගාවේ රෝග කල්තියා හඳුනාගෙන වගාව ආරක්ෂා කරගන්න.' : 'Detect tea plant diseases early and keep your plants healthy.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.22, 0);
    path.quadraticBezierTo(
      size.width * 0.92,
      size.height * 0.10,
      size.width,
      size.height * 0.36,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.18,
      size.height * 0.78,
      size.width * 0.22,
      0,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
      title: 'Tea Blister Blight',
      subtitle: 'Exobasidium vexans',
      asset: 'assets/images/disease_blister_blight.svg',
    ),
    _DiseaseCardData(
      title: 'Tea Brown Blight',
      subtitle: 'Colletotrichum spp.',
      asset: 'assets/images/disease_brown_blight.svg',
    ),
    _DiseaseCardData(
      title: 'Tea Red Rust',
      subtitle: 'Cephaleuros virescens',
      asset: 'assets/images/disease_red_rust.svg',
    ),
    _DiseaseCardData(
      title: 'Tea Powdery Mildew',
      subtitle: 'Erysiphe polygonii',
      asset: 'assets/images/disease_powdery_mildew.svg',
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
    required this.title,
    required this.subtitle,
    required this.asset,
  });

  final String title;
  final String subtitle;
  final String asset;
}

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({required this.data});

  final _DiseaseCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: 156,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: cs.surfaceContainerHighest,
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  data.asset,
                  fit: BoxFit.contain,
                  semanticsLabel: data.title,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
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
