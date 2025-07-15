import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/protected_user_profile.dart';
import '../models/protected_job.dart';
import 'encryption_service.dart';

class EncryptionMigrationService {
  /// Migrate existing user profiles to encrypted format
  static Future<void> migrateUserProfiles() async {
    try {
      print('Starting user profile migration...');
      // First check if encrypted columns exist
      final columnCheck = await Supabase.instance.client
          .rpc('check_column_exists', params: {
            'table_name': 'profiles',
            'column_name': 'encrypted_name'
          });
      if (columnCheck == false) {
        print('Encrypted columns do not exist. Please run schema update first.');
        return;
      }
      // Fetch all profiles that haven't been encrypted yet
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, name, phone, email, role, created_at, updated_at')
          .filter('encrypted_name', 'is', null);
      print('Found ${response.length} profiles to migrate');
      for (final profileData in response) {
        try {
          final protectedProfile = ProtectedUserProfile.fromExisting(profileData);
          await Supabase.instance.client
              .from('profiles')
              .update({
                'encrypted_name': protectedProfile.toDatabase()['encrypted_name'],
                'encrypted_phone': protectedProfile.toDatabase()['encrypted_phone'],
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', profileData['id']);
          print('Migrated profile: ${profileData['id']}');
        } catch (e) {
          print('Error migrating profile ${profileData['id']}: $e');
        }
      }
      print('User profile migration completed');
    } catch (e) {
      print('Migration error: $e');
      print('Make sure to run the database schema update first!');
    }
  }

  /// Migrate existing jobs to encrypted format
  static Future<void> migrateJobs() async {
    try {
      print('Starting job migration...');
      // Fetch all jobs that haven't been encrypted yet
      final response = await Supabase.instance.client
          .from('jobs')
          .select('id, title, description, pickup_location, destination_location, price, weight, status, warehouse_owner_id, assigned_driver_id, created_at, updated_at')
          .filter('encrypted_pickup_location', 'is', null);
      print('Found ${response.length} jobs to migrate');
      for (final jobData in response) {
        try {
          final protectedJob = ProtectedJob.fromExisting(jobData);
          await Supabase.instance.client
              .from('jobs')
              .update({
                'encrypted_pickup_location': protectedJob.toDatabase()['encrypted_pickup_location'],
                'encrypted_destination_location': protectedJob.toDatabase()['encrypted_destination_location'],
                'encrypted_price': protectedJob.toDatabase()['encrypted_price'],
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', jobData['id']);
          print('Migrated job: ${jobData['id']}');
        } catch (e) {
          print('Error migrating job ${jobData['id']}: $e');
        }
      }
      print('Job migration completed');
    } catch (e) {
      print('Migration error: $e');
      print('Make sure to run the database schema update first!');
    }
  }
} 