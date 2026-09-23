import re

with open('lib/screens/scan_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix _loadFarmerName in _HeroSectionState
bad_hero_init = """  @override
  void initState() {
    super.initState();
    _loadFarmerName();"""
good_hero_init = """  @override
  void initState() {
    super.initState();"""
# Only replace the SECOND occurrence (the one in _HeroSectionState)
parts = content.split(bad_hero_init)
if len(parts) >= 3:
    content = parts[0] + bad_hero_init + parts[1] + good_hero_init + bad_hero_init.join(parts[2:])

# 2. Fix the missing AuthService and getCurrentUser call
auth_import = "import '../services/auth_service.dart';"
if auth_import not in content:
    content = content.replace("import '../services/local_database_helper.dart';", "import '../services/local_database_helper.dart';\n" + auth_import)

old_load_farmer = """  Future<void> _loadFarmerName() async {
    final db = LocalDatabaseHelper.instance;
    final user = await db.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _farmerName = user['name'] ?? '';
      });
    }
  }"""
new_load_farmer = """  Future<void> _loadFarmerName() async {
    final user = await AuthService.instance.getCachedUser();
    if (mounted) {
      setState(() {
        _farmerName = user['user_name'] ?? '';
      });
    }
  }"""
content = content.replace(old_load_farmer, new_load_farmer)

# 3. Remove the broken remainder of _PlaceholderTab
lines = content.split("\n")
# find the line that has ");" at line 857 in previous run, but we just look for class _BottomBannerState ending
# The last clean class is _BottomBannerState.
# Let's find "class _PlaceholderTab" and remove it entirely. But wait, we already removed the start of it!
# Let's just find the last class ending.
# _BottomBannerState ends with:
#               child: SvgPicture.asset('assets/images/tea_leaf.svg'),
#             ),
#           ),
#         ],
#       ),
#     );
#   }
# }
banner_end = "      ),\n    );\n  }\n}"
banner_idx = content.rfind(banner_end)
if banner_idx != -1:
    content = content[:banner_idx + len(banner_end)] + "\n"

with open('lib/screens/scan_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed compile issues")
