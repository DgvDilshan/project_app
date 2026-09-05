import 'package:flutter/material.dart';
import '../main.dart';

class TipsTab extends StatelessWidget {
  const TipsTab({super.key});

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    
    final tips = isSinhala ? [
      {'title': 'දළු නෙළීමේ නිවැරදි ක්‍රමය', 'desc': 'සෑම විටම "දළු දෙකයි රන් කෙන්දයි" පමණක් නෙළාගන්න. මේ මගින් තේ දළුවල ඉහළ ගුණාත්මකභාවයක් සහ හොඳ මිලක් ලබා ගත හැක.', 'icon': Icons.pan_tool},
      {'title': 'පොහොර යෙදීම', 'desc': 'පස පරීක්ෂා කර සුදුසු පොහොර වර්ගය පමණක් නියමිත ප්‍රමාණයෙන් යොදන්න. වැසි දිනවල පොහොර යෙදීමෙන් වළකින්න.', 'icon': Icons.grass},
      {'title': 'වල් මර්දනය', 'desc': 'තේ පඳුරු අවට වල් පැළ ඉවත් කර පිරිසිදුව තබාගන්න. වල් නාශක භාවිතය අවම කර අතින් වල් නෙළීමට උත්සාහ කරන්න.', 'icon': Icons.cleaning_services},
      {'title': 'රෝග පාලනය', 'desc': 'රෝගී කොළ දුටු වහාම මේ යෙදුම හරහා පරීක්ෂා කර, අදාළ දිලීර නාශක හෝ ප්‍රතිකර්ම වහාම යොදන්න.', 'icon': Icons.health_and_safety},
    ] : [
      {'title': 'Proper Plucking Method', 'desc': 'Always pluck "two leaves and a bud". This ensures high quality and better market price.', 'icon': Icons.pan_tool},
      {'title': 'Fertilizer Application', 'desc': 'Test soil and apply only recommended fertilizer quantities. Avoid applying during heavy rain.', 'icon': Icons.grass},
      {'title': 'Weed Management', 'desc': 'Keep the area around bushes clean. Minimize herbicide use and prefer manual weeding.', 'icon': Icons.cleaning_services},
      {'title': 'Disease Control', 'desc': 'Check suspicious leaves using this app immediately and apply appropriate fungicides as recommended.', 'icon': Icons.health_and_safety},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'කෘෂි උපදෙස්' : 'Agricultural Tips'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tip = tips[index];
          return _TipCard(
            title: tip['title'] as String,
            desc: tip['desc'] as String,
            icon: tip['icon'] as IconData,
          );
        },
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.title, required this.desc, required this.icon});

  final String title;
  final String desc;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
