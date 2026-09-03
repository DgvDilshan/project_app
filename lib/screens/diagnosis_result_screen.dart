import 'package:flutter/material.dart';

import '../models/diagnosis_result.dart';
import '../models/picked_image.dart';
import '../main.dart';
import '../localization/app_translations.dart';

class DiagnosisResultScreen extends StatelessWidget {
  const DiagnosisResultScreen({
    super.key,
    required this.pickedImage,
    required this.result,
  });

  final PickedImage pickedImage;
  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confidencePercent = (result.confidence.clamp(0, 1) * 100).round();
    final isBlisterBlight = result.disease == TeaLeafDisease.blisterBlight;

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
                  Image.memory(pickedImage.bytes, fit: BoxFit.cover),
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
                AppTranslations.get('result_title', isSinhala),
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
                  _buildMainResultCard(context, confidencePercent, isBlisterBlight),
                  const SizedBox(height: 24),
                  if (isBlisterBlight) _buildBlisterBlightAlert(context),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.get('recommendations', isSinhala),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...result.suggestions.map((s) => _buildSuggestionTile(context, s)),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.restart_alt),
                    label: Text(AppTranslations.get('back_home', isSinhala)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainResultCard(BuildContext context, int confidencePercent, bool isBlisterBlight) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final cardColor = isBlisterBlight ? Colors.red.shade50 : cs.primaryContainer;
    final textColor = isBlisterBlight ? Colors.red.shade900 : cs.onPrimaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.disease.label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
              _StatusBadge(disease: result.disease),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(context, AppTranslations.get('confidence', isSinhalaMode.value), '$confidencePercent%', textColor),
              ),
              Container(width: 1, height: 40, color: textColor.withValues(alpha: 0.2)),
              Expanded(
                child: _buildStatColumn(context, AppTranslations.get('severity', isSinhalaMode.value), result.severity.label, textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBlisterBlightAlert(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSinhala ? 'අත්‍යවශ්‍ය ක්‍රියාමාර්ගයක් අවශ්‍යයි' : 'CRITICAL ACTION REQUIRED',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSinhala ? 'බ්ලිස්ටර් බ්ලයිට් වේගයෙන් පැතිරේ. වහාම දිලීර නාශකයක් යොදන්න.' : 'Blister Blight spreads rapidly. Immediate fungicidal application is recommended.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, String suggestion) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              suggestion,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.4,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.disease});

  final TeaLeafDisease disease;

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);

    final (label, icon, color) = switch (disease) {
      TeaLeafDisease.healthy => (isSinhala ? 'නිරෝගීයි' : 'OK', Icons.verified_outlined, Colors.green),
      TeaLeafDisease.unknown => (isSinhala ? 'පරීක්ෂා කරන්න' : 'Check', Icons.help_outline, Colors.orange),
      _ => (isSinhala ? 'අවදානමක්' : 'Alert', Icons.warning_amber_outlined, Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
