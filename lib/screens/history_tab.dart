import 'package:flutter/material.dart';
import '../main.dart'; // for isSinhalaMode

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'අස්වනු ඉතිහාසය' : 'Harvest History'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Request Collection Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 48, color: cs.onPrimaryContainer),
                    const SizedBox(height: 12),
                    Text(
                      isSinhala ? 'නව අස්වැන්නක් ඇත' : 'New Harvest Ready',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSinhala 
                        ? 'දළු එකතු කරන්නාට දැනුම් දෙන්න.' 
                        : 'Notify the collector to pick up leaves.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isSinhala ? 'දැනුම්දීම යවන ලදි! (සැපයුම් දාම අනුරූපණය)' : 'Request Sent! (Supply Chain Simulation)')),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: Text(isSinhala ? 'දැනුම් දෙන්න' : 'Request Collection'),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.onPrimaryContainer,
                        foregroundColor: cs.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSinhala ? 'පසුගිය අස්වැන්න (මෙම මාසය)' : 'Past Collections (This Month)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Dummy History List
              Expanded(
                child: ListView(
                  children: [
                    _HistoryItem(date: '2026-08-25', weight: '45 Kg', collector: isSinhala ? 'කමල්' : 'Kamal'),
                    _HistoryItem(date: '2026-08-18', weight: '52 Kg', collector: isSinhala ? 'නිමල්' : 'Nimal'),
                    _HistoryItem(date: '2026-08-10', weight: '38 Kg', collector: isSinhala ? 'කමල්' : 'Kamal'),
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

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.date, required this.weight, required this.collector});
  
  final String date;
  final String weight;
  final String collector;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    bool isSinhala = isSinhalaMode.value;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.2),
          child: Icon(Icons.eco, color: cs.primary),
        ),
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${isSinhala ? 'එකතු කළේ: ' : 'Collector: '}$collector'),
        trailing: Text(
          weight, 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.primary, 
            fontWeight: FontWeight.w900
          ),
        ),
      ),
    );
  }
}
