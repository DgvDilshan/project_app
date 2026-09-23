import json

transcript_path = r"C:\Users\Vimuk\.gemini\antigravity-ide\brain\0bdfa3e9-f457-4fe3-a2d6-4e83c104ad48\.system_generated\logs\transcript.jsonl"

file_chunks = {}

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            # Find TOOL_RESPONSE events
            if data.get("type") == "TOOL_RESPONSE" and "content" in data:
                # The content is usually a JSON string for tool response
                resp = data["content"]
                if "scan_home_screen.dart" in resp and "The following code has been modified to include a line number" in resp:
                    # Parse out the actual text
                    # It looks like:
                    # Created At: ...
                    # Completed At: ...
                    # File Path: ...
                    # Total Lines: ...
                    # Total Bytes: ...
                    # Showing lines X to Y
                    # The following code ...
                    # 1: import ...
                    
                    lines = resp.split("\n")
                    is_code = False
                    for l in lines:
                        if l.startswith("The following code has been modified") or l.startswith("The above content"):
                            continue
                        
                        # Check if line starts with "<number>: "
                        import re
                        match = re.match(r"^(\d+): (.*)", l)
                        if match:
                            line_num = int(match.group(1))
                            line_text = match.group(2)
                            file_chunks[line_num] = line_text
        except Exception as e:
            pass

print(f"Extracted {len(file_chunks)} lines from transcript.")
if len(file_chunks) > 0:
    max_line = max(file_chunks.keys())
    with open("recovered_scan_home_screen.dart", "w", encoding="utf-8") as out:
        for i in range(1, max_line + 1):
            if i in file_chunks:
                out.write(file_chunks[i] + "\n")
            else:
                out.write(f"// MISSING LINE {i}\n")
    print("Wrote to recovered_scan_home_screen.dart")
