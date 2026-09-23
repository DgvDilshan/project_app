import re

# Update scan_home_screen.dart
with open("lib/screens/scan_home_screen.dart", "r", encoding="utf-8") as f:
    scan_content = f.read()

scan_nav = """          extendBody: true,
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_filled, Icons.home_outlined, isSinhala ? 'මුල් පිටුව' : 'Home', _tabIndex, (i) => setState(() => _tabIndex = i), cs),
                  _buildNavItem(1, Icons.history, Icons.history_outlined, isSinhala ? 'ඉතිහාසය' : 'History', _tabIndex, (i) => setState(() => _tabIndex = i), cs),
                  _buildNavItem(2, Icons.spa, Icons.spa_outlined, isSinhala ? 'උපදෙස්' : 'Tips', _tabIndex, (i) => setState(() => _tabIndex = i), cs),
                  _buildNavItem(3, Icons.person, Icons.person_outline, isSinhala ? 'ගිණුම' : 'Profile', _tabIndex, (i) => setState(() => _tabIndex = i), cs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, int currentIndex, Function(int) onTap, ColorScheme cs) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? Colors.green.shade800 : Colors.grey.shade600),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }
}"""

# Find the start of bottomNavigationBar and replace
scan_start = "          bottomNavigationBar: NavigationBar("
scan_end = "        );\n      },\n    );\n  }\n}"

s_idx = scan_content.find(scan_start)
e_idx = scan_content.find(scan_end)
if s_idx != -1 and e_idx != -1:
    new_scan = scan_content[:s_idx] + scan_nav + scan_content[e_idx + len(scan_end):]
    with open("lib/screens/scan_home_screen.dart", "w", encoding="utf-8") as f:
        f.write(new_scan)
    print("Updated scan_home_screen.dart nav bar")


# Update collector_home_screen.dart
with open("lib/screens/collector_home_screen.dart", "r", encoding="utf-8") as f:
    col_content = f.read()

col_nav = """          extendBody: true,
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 60, right: 60, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_filled, Icons.home_outlined, isSinhala ? 'මුල් පිටුව' : 'Home', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                  _buildNavItem(1, Icons.history, Icons.history_outlined, isSinhala ? 'ඉතිහාසය' : 'History', _currentIndex, (i) => setState(() => _currentIndex = i), cs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, int currentIndex, Function(int) onTap, ColorScheme cs) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? Colors.green.shade800 : Colors.grey.shade600),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }
}"""

col_start = "          bottomNavigationBar: NavigationBar("
col_end = "        );\n      },\n    );\n  }\n}"

cs_idx = col_content.find(col_start)
ce_idx = col_content.find(col_end)
if cs_idx != -1 and ce_idx != -1:
    new_col = col_content[:cs_idx] + col_nav + col_content[ce_idx + len(col_end):]
    with open("lib/screens/collector_home_screen.dart", "w", encoding="utf-8") as f:
        f.write(new_col)
    print("Updated collector_home_screen.dart nav bar")
