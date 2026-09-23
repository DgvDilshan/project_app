import re

with open('lib/screens/scan_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_action_card = """                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onColor.withValues(alpha: 0.8),
                  ),
                ),"""

new_action_card = """                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onColor.withValues(alpha: 0.8),
                  ),
                ),"""

content = content.replace(old_action_card, new_action_card)

with open('lib/screens/scan_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed Action Card text overflow")
