import 'package:flutter/material.dart';
import '../main.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'ගිණුම' : 'Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              child: Icon(Icons.person, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              isSinhala ? 'සමන් කුමාර' : 'Saman Kumara',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'saman@example.com',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            
            // Total KGs summary card
            Card(
              elevation: 0,
              color: cs.secondaryContainer.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.eco, color: cs.onSecondary, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSinhala ? 'මෙම මාසයේ මුළු දළු ප්‍රමාණය' : 'Total Leaves This Month',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSecondaryContainer.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '135 Kg',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            _ProfileMenuItem(
              icon: Icons.map_outlined,
              title: isSinhala ? 'මගේ වත්ත (අක්කර 1.5)' : 'My Estate (1.5 Acres)',
            ),
            _ProfileMenuItem(
              icon: Icons.language,
              title: isSinhala ? 'භාෂාව වෙනස් කරන්න (Language)' : 'Change Language',
              onTap: () {
                isSinhalaMode.value = !isSinhalaMode.value;
              },
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              title: isSinhala ? 'උදව්' : 'Help & Support',
            ),
            _ProfileMenuItem(
              icon: Icons.logout,
              title: isSinhala ? 'ඉවත් වන්න' : 'Logout',
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isDestructive ? cs.error : cs.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap ?? () {},
    );
  }
}
