import json

transcript_path = r"C:\Users\Vimuk\.gemini\antigravity-ide\brain\0bdfa3e9-f457-4fe3-a2d6-4e83c104ad48\.system_generated\logs\transcript.jsonl"

print("Searching transcript for GatekeeperService...")
matches = 0
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        content = str(data)
        if "GatekeeperService" in content:
            matches += 1
            print(f"\n--- MATCH AT STEP {data.get('step_index')} (Type: {data.get('type')}) ---")
            print(content[:300] + "..." if len(content) > 300 else content)
            
print(f"Total matches: {matches}")
