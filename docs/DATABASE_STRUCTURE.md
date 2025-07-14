# Database Structure and API Documentation

## Database Tables

### 1. profiles
Primary table for user profiles
```sql
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL,
    full_name TEXT,
    role TEXT NOT NULL,
    is_profile_complete BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ
);
```

### 2. driver_details
Details specific to driver users
```sql
CREATE TABLE public.driver_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    license_number TEXT,
    license_expiry TIMESTAMPTZ,
    vehicle_type TEXT,
    experience_years INTEGER,
    updated_at TIMESTAMPTZ
);
```

### 3. warehouse_details
Details specific to warehouse owners
```sql
CREATE TABLE public.warehouse_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    warehouse_name TEXT,
    location TEXT,
    storage_capacity NUMERIC,
    updated_at TIMESTAMPTZ
);
```

### 4. broker_details
Details specific to brokers
```sql
CREATE TABLE public.broker_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    company_name TEXT,
    registration_number TEXT,
    years_in_business INTEGER,
    updated_at TIMESTAMPTZ
);
```

### 5. jobs
Main table for job listings
```sql
CREATE TABLE public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_owner_id UUID REFERENCES public.profiles(id),
    assigned_driver_id UUID REFERENCES public.profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    goods_type TEXT,
    weight NUMERIC,
    price NUMERIC,
    pickup_location TEXT,
    destination TEXT,
    distance NUMERIC,
    status TEXT DEFAULT 'open',
    posted_date TIMESTAMPTZ DEFAULT NOW(),
    assigned_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

### 6. job_applications
Table for tracking job applications
```sql
CREATE TABLE public.job_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES public.jobs(id),
    driver_id UUID REFERENCES public.profiles(id),
    status TEXT DEFAULT 'pending',
    updated_at TIMESTAMPTZ,
    UNIQUE(job_id, driver_id)
);
```

## API Methods Documentation

### Authentication Methods

1. `initialize()`
   - Purpose: Initializes Supabase client with environment variables
   - Parameters: None
   - Returns: Future<void>
   - Implementation:
     ```dart
     static Future<void> initialize() async {
       await dotenv.load();
       await Supabase.initialize(
         url: dotenv.env['SUPABASE_URL']!,
         anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
       );
     }
     ```

2. `signUp()`
   - Purpose: Creates new user account and profile
   - Parameters:
     - email: String
     - password: String
     - fullName: String
     - role: String
   - Returns: Future<AuthResponse>
   - Process:
     1. Creates auth user
     2. Creates profile record
     3. Creates role-specific details
   - Implementation:
     ```dart
     static Future<AuthResponse> signUp({
       required String email,
       required String password,
       required String fullName,
       required String role,
     }) async {
       // Implementation details in code
     }
     ```

3. `signIn()`
   - Purpose: Authenticates existing user
   - Parameters:
     - email: String
     - password: String
   - Returns: Future<AuthResponse>
   - Implementation:
     ```dart
     static Future<AuthResponse> signIn({
       required String email,
       required String password,
     }) async {
       return await client.auth.signInWithPassword(
         email: email,
         password: password,
       );
     }
     ```

### Profile Management Methods

1. `getUserProfile()`
   - Purpose: Fetches complete user profile with role-specific details
   - Parameters: None (uses current user)
   - Returns: Future<UserProfile?>
   - Process:
     1. Fetches basic profile
     2. Fetches role-specific details
     3. Combines data into UserProfile object
   - Implementation:
     ```dart
     static Future<UserProfile?> getUserProfile() async {
       // Implementation details in code
     }
     ```

2. `updateProfile()`
   - Purpose: Updates user profile data
   - Parameters:
     - userId: String
     - data: Map<String, dynamic>
   - Returns: Future<void>
   - Implementation:
     ```dart
     static Future<void> updateProfile(
         String userId, Map<String, dynamic> data) async {
       await client.from('profiles').update(data).eq('id', userId);
     }
     ```

### Job Management Methods

1. `postJob()`
   - Purpose: Creates new job listing
   - Parameters:
     - jobData: Map<String, dynamic>
   - Returns: Future<String> (job ID)
   - Implementation:
     ```dart
     static Future<String> postJob(Map<String, dynamic> jobData) async {
       final response =
           await client.from('jobs').insert(jobData).select().single();
       return response['id'];
     }
     ```

2. `getOpenJobs()`
   - Purpose: Fetches all open job listings
   - Parameters: None
   - Returns: Future<List<Map<String, dynamic>>>
   - Includes: Full job details with warehouse owner profile
   - Implementation:
     ```dart
     static Future<List<Map<String, dynamic>>> getOpenJobs() async {
       // Implementation details in code
     }
     ```

### Job Application Methods

1. `applyForJob()`
   - Purpose: Creates job application
   - Parameters:
     - jobId: String
     - driverId: String
   - Returns: Future<void>
   - Validations:
     - No active jobs
     - Job still open
     - No duplicate applications
   - Implementation:
     ```dart
     static Future<void> applyForJob(String jobId, String driverId) async {
       // Implementation details in code
     }
     ```

### Realtime Subscriptions

1. `subscribeToJobs()`
   - Purpose: Sets up realtime updates for job listings
   - Parameters:
     - onJobsUpdate: Function callback
   - Returns: RealtimeChannel
   - Implementation:
     ```dart
     static RealtimeChannel subscribeToJobs(
         void Function(List<Map<String, dynamic>>) onJobsUpdate) {
       // Implementation details in code
     }
     ```

## Security Policies

### Profiles Table
```sql
-- Select: Own profile or profiles interacted with through jobs
CREATE POLICY profiles_select_policy ON profiles
    FOR SELECT USING (
        id = auth.uid() OR
        id IN (
            SELECT assigned_driver_id FROM jobs WHERE warehouse_owner_id = auth.uid()
            UNION
            SELECT warehouse_owner_id FROM jobs WHERE assigned_driver_id = auth.uid()
        )
    );

-- Update: Only own profile
CREATE POLICY profiles_update_policy ON profiles
    FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Insert: Only own profile
CREATE POLICY profiles_insert_policy ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());
```

### Role-Specific Tables
```sql
-- Select: Only own details
CREATE POLICY role_details_select_policy ON {table_name}
    FOR SELECT USING (user_id = auth.uid());
```

## Data Models

### UserProfile
```dart
class UserProfile {
    String id;
    String email;
    String? fullName;
    String role;
    bool isProfileComplete;
    DateTime? updatedAt;
    Map<String, dynamic>? warehouseDetails;
    Map<String, dynamic>? driverDetails;
    Map<String, dynamic>? brokerDetails;
}
```

## Important Notes

1. Database Relationships:
   - All role-specific tables reference the profiles table
   - Jobs table references profiles table twice (warehouse_owner and assigned_driver)
   - Job applications link jobs with driver profiles

2. Security Considerations:
   - Row Level Security (RLS) enabled on all tables
   - Policies ensure users can only access their own data
   - Special policies for job-related profile access

3. Timestamps:
   - All tables include updated_at for tracking changes
   - Jobs table includes additional date fields for status tracking
   - All timestamps are in UTC

4. Status Fields:
   - Jobs: 'open', 'assigned', 'in_progress', 'completed'
   - Applications: 'pending', 'accepted', 'rejected'
   - Profiles: is_profile_complete boolean flag

5. Role Types:
   - 'driver'
   - 'warehouse_owner'
   - 'broker' 