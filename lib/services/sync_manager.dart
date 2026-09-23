import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database_helper.dart';
import 'auth_service.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  SyncManager._init();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void startListening() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // If we have any form of connection (Mobile, WiFi, Ethernet, etc.)
      if (!results.contains(ConnectivityResult.none)) {
        syncData();
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final supabase = Supabase.instance.client;
      final localDb = LocalDatabaseHelper.instance;

      // 1. Sync Pickup Requests
      final unsyncedRequests = await localDb.getUnsyncedPickupRequests();
      for (var request in unsyncedRequests) {
        try {
          final requestPayload = Map<String, dynamic>.from(request)..remove('is_synced');
          // Try to upsert so it updates the status if it already exists
          await supabase.from('pickup_requests').upsert(requestPayload);
          await localDb.markPickupRequestSynced(request['id']);
          print('Successfully synced pickup request: ${request['id']}');
        } catch (e) {
          // If the error is a duplicate key, we should still mark it as synced
          if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
             await localDb.markPickupRequestSynced(request['id']);
          }
          print('Failed to sync pickup request ${request['id']}: $e');
        }
      }

      // 2. Sync Harvests (Weights) [PUSH]
      final unsyncedHarvests = await localDb.getUnsyncedHarvests();
      for (var harvest in unsyncedHarvests) {
        try {
          final harvestPayload = Map<String, dynamic>.from(harvest)..remove('is_synced');
          // SQLite stores boolean as 1/0, Supabase expects true/false. Convert it.
          harvestPayload['is_correction'] = harvestPayload['is_correction'] == 1;
          
          await supabase.from('harvests').insert(harvestPayload);
          await localDb.markHarvestSynced(harvest['id']);
          print('Successfully synced harvest: ${harvest['id']}');
        } catch (e) {
          if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
             await localDb.markHarvestSynced(harvest['id']);
          }
          print('Failed to sync harvest ${harvest['id']}: $e');
        }
      }

      // 3. Pull Harvests (For Farmer's Passbook)
      try {
        final cache = await AuthService.instance.getCachedUser();
        final userId = cache['user_id'];
        final role = cache['user_role'];

        if (userId != null && role == 'farmer') {
          // Fetch all harvests for this farmer from Supabase
          final remoteHarvests = await supabase
              .from('harvests')
              .select()
              .eq('farmer_id', userId);

          // Save them to local DB (as synced)
          for (var remoteRecord in remoteHarvests) {
            final localRecord = {
              'id': remoteRecord['id'],
              'farmer_id': remoteRecord['farmer_id'],
              'collector_id': remoteRecord['collector_id'],
              'weight_kg': double.tryParse(remoteRecord['weight_kg'].toString()) ?? 0.0,
              'recorded_at': remoteRecord['recorded_at'],
              'is_correction': (remoteRecord['is_correction'] == true) ? 1 : 0,
              'is_synced': 1,
            };
            
            // Insert or replace in local DB
            await localDb.insertHarvest(localRecord);
          }
          print('Successfully pulled harvests for farmer');
        }
      } catch (e) {
        print('Failed to pull harvests: $e');
        rethrow;
      }
    } catch (e) {
      print('Critical error during sync: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }
}
