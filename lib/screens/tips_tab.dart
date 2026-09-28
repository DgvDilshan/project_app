import 'package:flutter/material.dart';
import '../main.dart';

class TipsTab extends StatefulWidget {
  const TipsTab({super.key});

  @override
  State<TipsTab> createState() => _TipsTabState();
}

class _TipsTabState extends State<TipsTab> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    
    final tips = isSinhala ? [
      {'title': 'දළු නෙළීමේ නිවැරදි ක්‍රමය', 'desc': 'සෑම විටම "දළු දෙකයි රන් කෙන්දයි" පමණක් නෙළාගන්න. මින් ඉහළ ගුණාත්මකභාවයක් සහ හොඳ මිලක් ලැබේ.', 'icon': Icons.eco},
      {'title': 'කාබනික පොහොර භාවිතය', 'desc': 'කොම්පෝස්ට් සහ ගොම වැනි ස්වභාවික පොහොර භාවිතයෙන් පසේ සරු බව වැඩි කර, නිරෝගී පඳුරු ලබා ගත හැක.', 'icon': Icons.compost},
      {'title': 'පඳුරු කප්පාදු කිරීම', 'desc': 'නිසි කලට පඳුරු කප්පාදු කිරීමෙන් නව දළු වර්ධනය වේගවත් වන අතර ඵලදාව ඉහළ යයි.', 'icon': Icons.content_cut},
      {'title': 'පිරිසිදුකම පවත්වා ගැනීම', 'desc': 'තේ පඳුරු අවට වල් පැළ ඉවත් කර පිරිසිදුව තබාගන්න. මින් රෝග බෝවීම අවම වේ.', 'icon': Icons.cleaning_services},
    ] : [
      {'title': 'Proper Plucking', 'desc': 'Always pluck "two leaves and a bud". This ensures high quality and better market prices.', 'icon': Icons.eco},
      {'title': 'Organic Fertilizer', 'desc': 'Use compost and natural fertilizers to improve soil fertility and get healthier tea bushes.', 'icon': Icons.compost},
      {'title': 'Bush Pruning', 'desc': 'Timely pruning accelerates the growth of new shoots and increases overall yield.', 'icon': Icons.content_cut},
      {'title': 'Clean Environment', 'desc': 'Keep the area around bushes free from weeds to minimize the spread of diseases.', 'icon': Icons.cleaning_services},
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: isSinhalaMode,
      builder: (context, isSinhalaModeVal, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(isSinhala ? 'කෘෂි උපදෙස්' : 'Agricultural Tips'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
          
              final slideAnim = Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animController,
                  curve: Interval(
                    index * 0.15,
                    (index * 0.15) + 0.4 > 1.0 ? 1.0 : (index * 0.15) + 0.4,
                    curve: Curves.easeOutBack,
                  ),
                ),
              );
          
              final fadeAnim = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: _animController,
                  curve: Interval(
                    index * 0.15,
                    (index * 0.15) + 0.4 > 1.0 ? 1.0 : (index * 0.15) + 0.4,
                    curve: Curves.easeIn,
                  ),
                ),
              );

              return FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _TipCard(
                      title: tip['title'] as String,
                      desc: tip['desc'] as String,
                      icon: tip['icon'] as IconData,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.green.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
