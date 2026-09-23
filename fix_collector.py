import re

# 1. Fix FAB in collector_home_screen.dart
with open('lib/screens/collector_home_screen.dart', 'r', encoding='utf-8') as f:
    collector_home = f.read()

fab_old = """      floatingActionButton: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {"""
fab_new = """      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {"""
collector_home = collector_home.replace(fab_old, fab_new)

# Add closing parenthesis for Padding at the end of FAB
fab_end_old = """          );
        },
      ),
    );"""
fab_end_new = """          );
          },
        ),
      ),
    );"""
collector_home = collector_home.replace(fab_end_old, fab_end_new)

with open('lib/screens/collector_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(collector_home)

# 2. Fix Logic in offline_weight_entry_screen.dart
with open('lib/screens/offline_weight_entry_screen.dart', 'r', encoding='utf-8') as f:
    weight_entry = f.read()

# Replace the local DB completion logic with Supabase completion logic
logic_old = """      // 2. Mark the pickup request as completed locally (if it exists)
      if (widget.requestId != null) {
        await LocalDatabaseHelper.instance.markPickupRequestCompleted(widget.requestId!);
      }"""

logic_new = """      // 2. Mark the pickup request as completed directly on Supabase
      String? reqIdToComplete = widget.requestId;
      
      if (reqIdToComplete == null) {
        try {
          final pendingReqs = await Supabase.instance.client
              .from('pickup_requests')
              .select('id')
              .eq('farmer_id', widget.farmerId)
              .eq('status', 'pending');
          if (pendingReqs.isNotEmpty) {
            reqIdToComplete = pendingReqs.first['id'] as String;
          }
        } catch (_) {}
      }

      if (reqIdToComplete != null) {
        try {
          await Supabase.instance.client
              .from('pickup_requests')
              .update({'status': 'completed'})
              .eq('id', reqIdToComplete);
        } catch (e) {
          debugPrint('Failed to update request status on Supabase: $e');
        }
      }"""

weight_entry = weight_entry.replace(logic_old, logic_new)

# Missing Supabase import in offline_weight_entry_screen.dart? Let's check.
if "import 'package:supabase_flutter/supabase_flutter.dart';" not in weight_entry:
    weight_entry = "import 'package:supabase_flutter/supabase_flutter.dart';\n" + weight_entry

with open('lib/screens/offline_weight_entry_screen.dart', 'w', encoding='utf-8') as f:
    f.write(weight_entry)

print("Applied UI and logic fixes!")
