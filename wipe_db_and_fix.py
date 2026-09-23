import re
import requests

# 1. Update pickup_request_screen.dart to check Supabase
with open('lib/screens/pickup_request_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_logic = """  Future<void> _checkPendingStatus() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      if (farmerId != null) {
        final hasPending = await LocalDatabaseHelper.instance.hasPendingPickupRequest(farmerId);
        setState(() {
          _hasPending = hasPending;
        });
      }
    } catch (e) {
      debugPrint("Error checking pending request: $e");
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }"""

new_logic = """  Future<void> _checkPendingStatus() async {
    try {
      final cache = await AuthService.instance.getCachedUser();
      final farmerId = cache['user_id'];
      if (farmerId != null) {
        bool pending = false;
        try {
          final res = await Supabase.instance.client
              .from('pickup_requests')
              .select('id')
              .eq('farmer_id', farmerId)
              .eq('status', 'pending');
          pending = res.isNotEmpty;
        } catch (_) {
          // Fallback to local DB if offline
          pending = await LocalDatabaseHelper.instance.hasPendingPickupRequest(farmerId);
        }
        
        setState(() {
          _hasPending = pending;
        });
      }
    } catch (e) {
      debugPrint("Error checking pending request: $e");
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }"""

content = content.replace(old_logic, new_logic)

if "import 'package:supabase_flutter/supabase_flutter.dart';" not in content:
    content = "import 'package:supabase_flutter/supabase_flutter.dart';\n" + content

with open('lib/screens/pickup_request_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 2. Bump version in local_database_helper.dart to 3 to wipe tables
with open('lib/services/local_database_helper.dart', 'r', encoding='utf-8') as f:
    local_db_content = f.read()

local_db_content = local_db_content.replace("version: 2,", "version: 3,")
local_db_content = local_db_content.replace("_initDB('tea_app_offline_v2.db')", "_initDB('tea_app_offline_v3.db')")

old_upgrade = """  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the harvests table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS harvests (
          id TEXT PRIMARY KEY,
          farmer_id TEXT NOT NULL,
          collector_id TEXT NOT NULL,
          weight_kg REAL NOT NULL,
          recorded_at TEXT NOT NULL,
          is_correction INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0
        )
      ''');
    }
  }"""

new_upgrade = """  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS harvests (
          id TEXT PRIMARY KEY,
          farmer_id TEXT NOT NULL,
          collector_id TEXT NOT NULL,
          weight_kg REAL NOT NULL,
          recorded_at TEXT NOT NULL,
          is_correction INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS pickup_requests');
      await db.execute('DROP TABLE IF EXISTS harvests');
      await _createDB(db, newVersion);
    }
  }"""
local_db_content = local_db_content.replace(old_upgrade, new_upgrade)

with open('lib/services/local_database_helper.dart', 'w', encoding='utf-8') as f:
    f.write(local_db_content)

# 3. Wipe Supabase Database
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

print("Successfully applied updates and wiped db!")
