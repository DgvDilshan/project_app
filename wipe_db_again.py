import requests

# 1. Bump version in local_database_helper.dart to 4 to wipe tables locally
with open('lib/services/local_database_helper.dart', 'r', encoding='utf-8') as f:
    local_db_content = f.read()

local_db_content = local_db_content.replace("version: 3,", "version: 4,")
local_db_content = local_db_content.replace("_initDB('tea_app_offline_v3.db')", "_initDB('tea_app_offline_v4.db')")

old_upgrade = """    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS pickup_requests');
      await db.execute('DROP TABLE IF EXISTS harvests');
      await _createDB(db, newVersion);
    }"""

new_upgrade = """    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS pickup_requests');
      await db.execute('DROP TABLE IF EXISTS harvests');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS pickup_requests');
      await db.execute('DROP TABLE IF EXISTS harvests');
      await _createDB(db, newVersion);
    }"""
local_db_content = local_db_content.replace(old_upgrade, new_upgrade)

with open('lib/services/local_database_helper.dart', 'w', encoding='utf-8') as f:
    f.write(local_db_content)

# 2. Wipe Supabase Database (harvests and pickup_requests)
supabase_url = 'https://yqaqsrlmkedinqmbapqu.supabase.co'
anon_key = 'sb_publishable_OXUq1ezIwJgJQAeARdVY1g_5W9l7FZI'

headers = {
    'apikey': anon_key,
    'Authorization': f'Bearer {anon_key}'
}

# Delete harvests
r_harvests = requests.delete(f'{supabase_url}/rest/v1/harvests', headers=headers, params={'id': 'not.is.null'})
print(f"Harvests wipe status: {r_harvests.status_code}")

# Delete pickup requests
r_pickups = requests.delete(f'{supabase_url}/rest/v1/pickup_requests', headers=headers, params={'id': 'not.is.null'})
print(f"Pickup requests wipe status: {r_pickups.status_code}")

print("Successfully wiped database!")
