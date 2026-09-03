import 'package:flutter/material.dart';
import '../main.dart'; // for isSinhalaMode

class DiseaseInfoScreen extends StatelessWidget {
  const DiseaseInfoScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.symptoms,
    required this.recommendations,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final List<String> symptoms;
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(assetPath, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          cs.surface.withValues(alpha: 0.8),
                          cs.surface,
                        ],
                        stops: const [0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    subtitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isSinhala ? 'රෝග ලක්ෂණ' : 'Symptoms',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...symptoms.map((s) => _buildBulletPoint(context, s)),
                  const SizedBox(height: 24),
                  Text(
                    isSinhala ? 'පාලනය කිරීමේ නිර්දේශ' : 'Control Measures',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...recommendations.asMap().entries.map((e) => _buildNumberedTile(context, e.key, e.value)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedTile(BuildContext context, int index, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.primaryContainer.withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: cs.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.4,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
