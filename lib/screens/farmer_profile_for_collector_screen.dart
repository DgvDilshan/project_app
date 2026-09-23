import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../main.dart'; // for isSinhalaMode
import 'qr_scanner_screen.dart';

class FarmerProfileForCollectorScreen extends StatefulWidget {
  const FarmerProfileForCollectorScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    this.requestId,
  });

  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String? requestId;

  @override
  State<FarmerProfileForCollectorScreen> createState() => _FarmerProfileForCollectorScreenState();
}

class _FarmerProfileForCollectorScreenState extends State<FarmerProfileForCollectorScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _harvests = [];
  bool _isLoading = true;
  double _totalKg = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _supabase
          .from('harvests')
          .select()
          .eq('farmer_id', widget.farmerId)
          .order('recorded_at', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);
      
      double total = 0;
      for (var item in data) {
        total += (item['weight_kg'] as num).toDouble();
      }

      setState(() {
        _harvests = data;
        _totalKg = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching farmer history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'ගොවි පැතිකඩ' : 'Farmer Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            widget.farmerName.isNotEmpty ? widget.farmerName[0].toUpperCase() : 'F',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.farmerName,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              widget.farmerPhone,
                              style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    isSinhala ? 'මුළු දළු (Kg)' : 'Total Yield',
                                    style: theme.textTheme.titleSmall?.copyWith(color: cs.onSecondaryContainer),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _totalKg.toStringAsFixed(1),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 40, color: cs.outlineVariant),
                              Column(
                                children: [
                                  Text(
                                    isSinhala ? 'වාර්තා ගණන' : 'Total Records',
                                    style: theme.textTheme.titleSmall?.copyWith(color: cs.onSecondaryContainer),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_harvests.length}',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      isSinhala ? 'ලබාදීම් ඉතිහාසය' : 'Supply History',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                _harvests.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              isSinhala ? 'තවමත් වාර්තා නොමැත.' : 'No previous records found.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _harvests[index];
                              final dateStr = item['recorded_at']?.toString() ?? '';
                              String formattedDate = dateStr;
                              try {
                                final date = DateTime.parse(dateStr);
                                formattedDate = DateFormat('yyyy MMM dd, hh:mm a').format(date);
                              } catch (_) {}

                              return Card(
                                elevation: 0,
                                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                                    child: Icon(Icons.eco, color: cs.primary, size: 20),
                                  ),
                                  title: Text(
                                    formattedDate,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  trailing: Text(
                                    '${item['weight_kg']} Kg',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _harvests.length,
                          ),
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for FAB
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.requestId == null ? null : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => QRScannerScreen(requestId: widget.requestId)),
              );
              if (result == true) {
                // If scanned successfully, go back to dashboard so it refreshes
                if (context.mounted) Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(
              isSinhala ? 'QR ස්කෑන් කර දළු බාරගන්න' : 'Scan QR & Collect Harvest',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
        ),
      ),
    );
  }
}
