import json
import re

transcript_path = r"C:\Users\Vimuk\.gemini\antigravity-ide\brain\0bdfa3e9-f457-4fe3-a2d6-4e83c104ad48\.system_generated\logs\transcript.jsonl"

outputs = []

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        if 'scan_home_screen.dart' in line:
            try:
                data = json.loads(line)
                if data.get("type") == "TOOL_RESPONSE":
                    outputs.append(data)
            except Exception:
                pass

with open("scratch_extract.json", "w", encoding="utf-8") as out:
    json.dump(outputs, out, indent=2)

print(f"Dumped {len(outputs)} tool responses to scratch_extract.json")
