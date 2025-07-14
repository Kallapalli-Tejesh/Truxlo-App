# Profile Management Documentation

## Overview
The profile management system handles user profiles with role-specific details for drivers, warehouse owners, and brokers. The system uses a base profile table with role-specific extension tables.

## Core Methods

### 1. getUserProfile()
```dart
static Future<UserProfile?> getUserProfile() async
```
#### Purpose
Fetches the complete user profile including role-specific details.

#### Implementation Details
1. Gets current user ID from auth state
2. Fetches basic profile data:
   ```sql
   SELECT id, email, full_name, role, is_profile_complete, updated_at
   FROM profiles
   WHERE id = [current_user_id]
   ```
3. Based on role, fetches additional details:
   - For drivers: license, vehicle info
   - For warehouse owners: warehouse details
   - For brokers: company info
4. Combines data into UserProfile object

#### Error Handling
- Logs detailed errors with stack traces
- Returns null if profile not found
- Continues without role details if fetch fails

### 2. updateProfile()
```dart
static Future<void> updateProfile(String userId, Map<String, dynamic> data)
```
#### Purpose
Updates basic profile information.

#### Parameters
- userId: The user's UUID
- data: Map containing fields to update:
  ```dart
  {
    'full_name': String,
    'email': String,
    'is_profile_complete': bool,
    'updated_at': DateTime
  }
  ```

#### Implementation Details
1. Validates input data
2. Updates profile record
3. Triggers email update in auth.users if email changed

### 3. updateRoleDetails()
```dart
static Future<void> updateRoleDetails(String userId, String role, Map<String, dynamic> data)
```
#### Purpose
Updates role-specific information in the appropriate details table.

#### Parameters
- userId: The user's UUID
- role: User role ('driver', 'warehouse_owner', 'broker')
- data: Role-specific details to update

#### Role-Specific Data Structures

##### Driver Details
```dart
{
  'license_number': String,
  'license_expiry': DateTime,
  'vehicle_type': String,
  'experience_years': int,
  'updated_at': DateTime
}
```

##### Warehouse Details
```dart
{
  'warehouse_name': String,
  'location': String,
  'storage_capacity': double,
  'updated_at': DateTime
}
```

##### Broker Details
```dart
{
  'company_name': String,
  'registration_number': String,
  'years_in_business': int,
  'updated_at': DateTime
}
```

## Profile Completion Flow

### 1. Initial Profile Creation
```dart
// During signup
await signUp(email: email, password: password, fullName: fullName, role: role);
```
- Creates auth user
- Creates basic profile
- Sets is_profile_complete = false

### 2. Role-Specific Details
```dart
// In profile completion page
await updateRoleDetails(userId, role, roleSpecificData);
await updateProfile(userId, {'is_profile_complete': true});
```
- Collects role-specific information
- Updates appropriate details table
- Marks profile as complete

## Security Policies

### Profiles Table
```sql
-- Read access
CREATE POLICY "Users can read their own profile"
ON profiles FOR SELECT
USING (id = auth.uid());

-- Update access
CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
```

### Role-Specific Tables
```sql
-- Read access
CREATE POLICY "Users can read their own details"
ON [table_name] FOR SELECT
USING (user_id = auth.uid());

-- Update access
CREATE POLICY "Users can update their own details"
ON [table_name] FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

## Error Handling

### Common Error Cases
1. Profile Not Found
```dart
if (profileResponse == null) {
  debugPrint('No profile found for user: $userId');
  return null;
}
```

2. Role Details Missing
```dart
try {
  roleDetails = await fetchRoleDetails();
} catch (e) {
  debugPrint('Error fetching role details: $e');
  // Continue without role details
}
```

3. Invalid Role Type
```dart
if (!['driver', 'warehouse_owner', 'broker'].contains(role)) {
  throw Exception('Invalid role type: $role');
}
```

## Data Validation

### Profile Data
```dart
void validateProfileData(Map<String, dynamic> data) {
  if (data['email'] != null && !isValidEmail(data['email'])) {
    throw Exception('Invalid email format');
  }
  if (data['full_name'] != null && data['full_name'].toString().isEmpty) {
    throw Exception('Full name cannot be empty');
  }
}
```

### Role-Specific Validation
```dart
void validateRoleData(String role, Map<String, dynamic> data) {
  switch (role) {
    case 'driver':
      validateDriverData(data);
      break;
    case 'warehouse_owner':
      validateWarehouseData(data);
      break;
    case 'broker':
      validateBrokerData(data);
      break;
  }
}
```

## Best Practices

1. Profile Updates
   - Always include updated_at timestamp
   - Validate data before updates
   - Use transactions for multi-table updates

2. Role Management
   - Never change role after initial setup
   - Keep role-specific data in appropriate tables
   - Use proper foreign key constraints

3. Security
   - Always use RLS policies
   - Validate user permissions
   - Sanitize input data

4. Error Handling
   - Log all errors with context
   - Provide user-friendly error messages
   - Handle edge cases gracefully

## Testing Guidelines

1. Profile Creation
```dart
test('should create profile with role details', () async {
  final profile = await createTestProfile();
  expect(profile.isProfileComplete, false);
  expect(profile.role, 'driver');
});
```

2. Profile Updates
```dart
test('should update profile details', () async {
  await updateProfile(userId, {'full_name': 'New Name'});
  final profile = await getUserProfile();
  expect(profile?.fullName, 'New Name');
});
```

3. Role Details
```dart
test('should fetch role-specific details', () async {
  final profile = await getUserProfile();
  expect(profile?.driverDetails, isNotNull);
});
``` 