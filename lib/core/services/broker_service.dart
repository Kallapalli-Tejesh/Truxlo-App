import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class BrokerService {
  static final _client = Supabase.instance.client;

  // Add a driver to broker's network
  static Future<void> addDriver({
    required String brokerId,
    required String driverPhone,
  }) async {
    try {
      // First, find the driver by phone number
      final driverProfile = await _client
          .from('profiles')
          .select()
          .eq('phone', driverPhone)
          .eq('role', 'driver')
          .single();

      if (driverProfile == null) {
        throw Exception('Driver not found');
      }

      // Check if relationship already exists
      final existingRelation = await _client
          .from('broker_drivers')
          .select()
          .eq('broker_id', brokerId)
          .eq('driver_id', driverProfile['id'])
          .maybeSingle();

      if (existingRelation != null) {
        if (existingRelation['status'] == 'active') {
          throw Exception('Driver is already in your network');
        } else if (existingRelation['status'] == 'pending') {
          throw Exception('Invitation already sent to this driver');
        }
      }

      // Create new relationship
      await _client.from('broker_drivers').insert({
        'broker_id': brokerId,
        'driver_id': driverProfile['id'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all drivers in broker's network
  static Future<List<Map<String, dynamic>>> getDrivers(String brokerId) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            driver:driver_id (
              id,
              full_name,
              phone,
              address,
              city,
              state
            )
          ''').eq('broker_id', brokerId).eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get pending driver invitations
  static Future<List<Map<String, dynamic>>> getPendingInvitations(
    String brokerId,
  ) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            driver:driver_id (
              id,
              full_name,
              phone,
              address,
              city,
              state
            )
          ''').eq('broker_id', brokerId).eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Accept or reject broker invitation (for drivers)
  static Future<void> respondToInvitation({
    required String driverId,
    required String brokerId,
    required bool accept,
  }) async {
    try {
      await _client
          .from('broker_drivers')
          .update({
            'status': accept ? 'active' : 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('broker_id', brokerId)
          .eq('driver_id', driverId);
    } catch (e) {
      rethrow;
    }
  }

  // Remove driver from network
  static Future<void> removeDriver({
    required String brokerId,
    required String driverId,
  }) async {
    try {
      await _client
          .from('broker_drivers')
          .update({
            'status': 'removed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('broker_id', brokerId)
          .eq('driver_id', driverId);
    } catch (e) {
      rethrow;
    }
  }

  // Get broker invitations for a driver
  static Future<List<Map<String, dynamic>>> getDriverInvitations(
    String driverId,
  ) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            broker:broker_id (
              id,
              full_name,
              phone,
              company_name:broker_details(company_name)
            )
          ''').eq('driver_id', driverId).eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all brokers for a driver
  static Future<List<Map<String, dynamic>>> getDriverBrokers(
    String driverId,
  ) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            broker:broker_id (
              id,
              full_name,
              phone,
              company_name:broker_details(company_name)
            )
          ''').eq('driver_id', driverId).eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }
}
