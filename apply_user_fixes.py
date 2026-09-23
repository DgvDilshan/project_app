import re

with open('lib/screens/scan_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Restore standard NavigationBar
start_nav = "      bottomNavigationBar: SafeArea("
end_nav = "      ),\n    );\n  }\n\n  Widget _buildNavItem"
idx_start = content.find(start_nav)
if idx_start != -1:
    # find the end of _buildNavItem
    end_build_nav = "    );\n  }\n}"
    idx_end = content.find(end_build_nav, idx_start)
    if idx_end != -1:
        standard_nav = """      bottomNavigationBar: NavigationBar(
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
}"""
        content = content[:idx_start] + standard_nav + content[idx_end + len(end_build_nav):]

# 2. Fix the farmerName display
# We need to replace:
#                     Text(isSinhala ? 'ආයුබෝවන්' : 'Hello, User', style: theme.textTheme.titleMedium),
# with the proper logic that uses farmerName.
hello_user_pattern = r"Text\(isSinhala \? 'ආයුබෝවන්' : 'Hello, User', style: theme\.textTheme\.titleMedium\),"
hello_user_replacement = """Text(isSinhala ? 'ආයුබෝවන්' : 'Hello', style: theme.textTheme.titleMedium),
                    if (farmerName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(farmerName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                    ],"""
content = re.sub(hello_user_pattern, hello_user_replacement, content)

# 3. Add the Pickup Request Card
# We need to make sure pickup_request_screen.dart is imported
pickup_import = "import 'pickup_request_screen.dart';"
if pickup_import not in content:
    content = content.replace("import 'disease_info_screen.dart';", "import 'disease_info_screen.dart';\n" + pickup_import)

# Insert it after _DetectDiseaseCard
detect_disease_card = """                _DetectDiseaseCard(
                  controller: controller,
                  onTap: () => _showDetectDiseaseSheet(context),
                ),"""
collector_card = """                _DetectDiseaseCard(
                  controller: controller,
                  onTap: () => _showDetectDiseaseSheet(context),
                ),
                const SizedBox(height: 14),
                // Collector request card
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PickupRequestScreen()));
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: cs.secondaryContainer.withValues(alpha: 0.6),
                      border: Border.all(color: cs.secondaryContainer),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.local_shipping, color: cs.onSecondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSinhalaMode.value ? 'අස්වැන්න එකතු කරන්නෙකු ගෙන්වන්න' : 'Request a Collector',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isSinhalaMode.value ? 'ඔබේ තේ දළු අලෙවි කිරීමට සූදානම්ද?' : 'Ready to sell your tea leaves?',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: cs.secondary),
                      ],
                    ),
                  ),
                ),"""
content = content.replace(detect_disease_card, collector_card)

with open('lib/screens/scan_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Applied fixes!")
