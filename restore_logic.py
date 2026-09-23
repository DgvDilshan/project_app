import re

with open('lib/screens/scan_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
imports_to_add = """import '../services/local_database_helper.dart';
import 'history_tab.dart';
import 'tips_tab.dart';
import 'profile_tab.dart';
"""
if 'history_tab.dart' not in content:
    content = content.replace("import 'disease_info_screen.dart';", "import 'disease_info_screen.dart';\n" + imports_to_add)

# 2. Add _farmerName and _loadFarmerName to _ScanHomeScreenState
state_vars = """  int _tabIndex = 0;
  String _farmerName = '';

  Future<void> _loadFarmerName() async {
    final db = LocalDatabaseHelper.instance;
    final user = await db.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _farmerName = user['name'] ?? '';
      });
    }
  }"""
content = re.sub(r'int _tabIndex = 0;', state_vars, content)

# 3. Call _loadFarmerName in initState
init_state_update = """  @override
  void initState() {
    super.initState();
    _loadFarmerName();"""
content = content.replace("  @override\n  void initState() {\n    super.initState();", init_state_update)

# 4. Replace _PlaceholderTabs with real tabs
tabs_replacement = """          _HomeTab(controller: _controller, farmerName: _farmerName),
          HistoryTab(),
          TipsTab(),
          ProfileTab(),"""
content = re.sub(
    r'_HomeTab\(controller: _controller\),\s*_PlaceholderTab.*?\),\s*_PlaceholderTab.*?\),\s*_PlaceholderTab.*?\),',
    tabs_replacement,
    content,
    flags=re.DOTALL
)

# 5. Update _HomeTab constructor
hometab_update = """class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.controller, this.farmerName = ''});

  final Animation<double> controller;
  final String farmerName;"""
content = content.replace("class _HomeTab extends StatelessWidget {\n  const _HomeTab({required this.controller});\n\n  final Animation<double> controller;", hometab_update)

# 6. Use farmerName in UI
old_ui = """                    Row(
                  children: [
                    Text(isSinhala ? 'ආයුබෝවන්' : 'Hello, User', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Icon(Icons.spa, color: cs.primary, size: 20),
                  ],
                ),"""
new_ui = """                    Row(
                  children: [
                    Text(isSinhala ? 'ආයුබෝවන්' : 'Hello', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Icon(Icons.spa, color: cs.primary, size: 20),
                  ],
                ),
                if (farmerName.isNotEmpty) ...[
                  Text(
                    farmerName,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ],"""
content = content.replace(old_ui, new_ui)

# 7. Also remove the PlaceholderTab class at the end of the file since it's unused now
placeholder_class = r"class _PlaceholderTab extends StatelessWidget \{.*?\}"
content = re.sub(placeholder_class, "", content, flags=re.DOTALL)

with open('lib/screens/scan_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Restored logic!")
