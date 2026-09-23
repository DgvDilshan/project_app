import re

with open('lib/screens/scan_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace the two stacked cards with the new _ActionCardsRow
old_cards_pattern = re.compile(r'_DetectDiseaseCard\([\s\S]*?const SizedBox\(height: 18\),', re.MULTILINE)
new_cards = """_ActionCardsRow(
                  controller: controller,
                  onScanTap: () => _showDetectDiseaseSheet(context),
                  onSellTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PickupRequestScreen())),
                ),
                const SizedBox(height: 18),"""
content = old_cards_pattern.sub(new_cards, content, 1)

# 2. Remove the old _DetectDiseaseCard class
old_detect_class_pattern = re.compile(r'class _DetectDiseaseCard extends StatelessWidget \{[\s\S]*?(?=class _PickOption extends StatelessWidget)', re.MULTILINE)
content = old_detect_class_pattern.sub('', content, 1)

# 3. Insert the new _ActionCardsRow and _AnimatedActionCard at the bottom of the file (before the last empty line or at the end)
new_classes = """
class _ActionCardsRow extends StatelessWidget {
  const _ActionCardsRow({
    required this.controller,
    required this.onScanTap,
    required this.onSellTap,
  });

  final Animation<double> controller;
  final VoidCallback onScanTap;
  final VoidCallback onSellTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    bool isSinhala = isSinhalaMode.value;

    final pulse = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return Row(
      children: [
        Expanded(
          child: _AnimatedActionCard(
            pulse: pulse,
            title: isSinhala ? 'රෝග හඳුනාගන්න' : 'Scan Disease',
            subtitle: isSinhala ? 'කොළයේ ඡායාරූපයක්' : 'Take a photo',
            icon: Icons.document_scanner_outlined,
            color: cs.primaryContainer,
            onColor: cs.onPrimaryContainer,
            onTap: onScanTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnimatedActionCard(
            pulse: pulse,
            title: isSinhala ? 'අස්වැන්න විකුණන්න' : 'Sell Harvest',
            subtitle: isSinhala ? 'එකතු කරන්නෙකුට' : 'Request collector',
            icon: Icons.local_shipping_outlined,
            color: cs.secondaryContainer,
            onColor: cs.onSecondaryContainer,
            onTap: onSellTap,
          ),
        ),
      ],
    );
  }
}

class _AnimatedActionCard extends StatelessWidget {
  const _AnimatedActionCard({
    required this.pulse,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final Animation<double> pulse;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        return Transform.scale(scale: pulse.value, child: child);
      },
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: onColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: onColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onColor.withValues(alpha: 0.8),
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
"""

content = content + new_classes

with open('lib/screens/scan_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Applied side-by-side card changes!")
