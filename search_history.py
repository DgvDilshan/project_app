import os
import re

history_dir = r"C:\Users\Vimuk\AppData\Roaming\Code\User\History"

matches = []

for root, dirs, files in os.walk(history_dir):
    for file in files:
        if file.endswith('.dart') or file.endswith('.json') or file == 'entries.json':
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if 'class ScanHomeScreen extends StatefulWidget' in content or 'ScanHomeScreen' in content:
                        matches.append(path)
            except Exception:
                pass

print("Found matches in:")
for m in matches:
    print(m)
