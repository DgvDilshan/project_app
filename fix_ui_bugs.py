import re

# 1. Fix scan_home_screen.dart translation toggle
with open('lib/screens/scan_home_screen.dart', 'r', encoding='utf-8') as f:
    scan_content = f.read()

old_scan_build = """  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    return Scaffold("""
new_scan_build = """  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSinhalaMode,
      builder: (context, isSinhala, child) {
        return Scaffold("""

if old_scan_build in scan_content:
    scan_content = scan_content.replace(old_scan_build, new_scan_build)
    # now find the end of the Scaffold and close the ValueListenableBuilder
    # Scaffold ends with:
    #       ),
    #     );
    #   }
    # }
    scan_end = "      ),\n    );\n  }\n}"
    new_scan_end = "      ),\n    );\n      },\n    );\n  }\n}"
    scan_content = scan_content.replace(scan_end, new_scan_end)

with open('lib/screens/scan_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(scan_content)


# 2. Fix profile_tab.dart translation and empty clicks
with open('lib/screens/profile_tab.dart', 'r', encoding='utf-8') as f:
    prof_content = f.read()

old_prof_build = """  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold("""

new_prof_build = """  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: isSinhalaMode,
      builder: (context, isSinhala, child) {
        return Scaffold("""

if old_prof_build in prof_content:
    prof_content = prof_content.replace(old_prof_build, new_prof_build)
    prof_end = "      ),\n    );\n  }\n}"
    new_prof_end = "      ),\n    );\n      },\n    );\n  }\n}"
    prof_content = prof_content.replace(prof_end, new_prof_end)


# 3. Add snackbars to empty menu items in profile_tab.dart
estate_item_old = """              _ProfileMenuItem(
                icon: Icons.map_outlined,
                title: isSinhala ? 'මගේ වත්ත (අක්කර 1.5)' : 'My Estate (1.5 Acres)',
              ),"""
estate_item_new = """              _ProfileMenuItem(
                icon: Icons.map_outlined,
                title: isSinhala ? 'මගේ වත්ත (අක්කර 1.5)' : 'My Estate (1.5 Acres)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isSinhala ? 'ඉදිරියේදී බලාපොරොත්තු වන්න' : 'Coming soon!'),
                  ));
                },
              ),"""
prof_content = prof_content.replace(estate_item_old, estate_item_new)

help_item_old = """              _ProfileMenuItem(
                icon: Icons.help_outline,
                title: isSinhala ? 'උදව්' : 'Help & Support',
              ),"""
help_item_new = """              _ProfileMenuItem(
                icon: Icons.help_outline,
                title: isSinhala ? 'උදව්' : 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isSinhala ? 'අප අමතන්න: 011-2345678' : 'Contact us: 011-2345678'),
                  ));
                },
              ),"""
prof_content = prof_content.replace(help_item_old, help_item_new)

with open('lib/screens/profile_tab.dart', 'w', encoding='utf-8') as f:
    f.write(prof_content)

print("Applied UI fixes!")
