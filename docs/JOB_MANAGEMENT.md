# Job Management Documentation

## Overview
The job management system handles the creation, assignment, and tracking of transportation jobs between warehouse owners and drivers, with brokers facilitating connections.

## Database Schema

### Jobs Table
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

### Job Applications Table
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

## Core Methods

### 1. postJob()
```dart
static Future<String> postJob(Map<String, dynamic> jobData) async
```
#### Purpose
Creates a new job listing.

#### Parameters
```dart
{
  'warehouse_owner_id': String,
  'title': String,
  'description': String,
  'goods_type': String,
  'weight': double,
  'price': double,
  'pickup_location': String,
  'destination': String,
  'distance': double,
}
```

#### Implementation Details
1. Validates job data
2. Sets default status to 'open'
3. Adds timestamps
4. Creates job record
5. Returns job ID

### 2. getOpenJobs()
```dart
static Future<List<Map<String, dynamic>>> getOpenJobs() async
```
#### Purpose
Fetches all available job listings.

#### Implementation Details
1. Queries jobs with status 'open'
2. Joins with warehouse owner profile
3. Orders by posted date
4. Returns formatted job list

### 3. applyForJob()
```dart
static Future<void> applyForJob(String jobId, String driverId) async
```
#### Purpose
Submits a job application.

#### Validation Checks
1. Driver has no active jobs
2. Job is still open
3. No duplicate applications

#### Implementation
```dart
// Check active jobs
final hasActive = await hasActiveJob(driverId);
if (hasActive) throw Exception('Already has active job');

// Check job status
final job = await client
    .from('jobs')
    .select('status')
    .eq('id', jobId)
    .single();
if (job['status'] != 'open') throw Exception('Job not available');

// Create application
await client.from('job_applications').insert({
  'job_id': jobId,
  'driver_id': driverId,
  'status': 'pending',
  'updated_at': DateTime.now().toUtc().toIso8601String(),
});
```

### 4. updateJobStatus()
```dart
static Future<void> updateJobStatus(String jobId, String status) async
```
#### Purpose
Updates job status and related timestamps.

#### Valid Status Values
- 'open': Initial state
- 'assigned': Driver selected
- 'in_progress': Delivery started
- 'completed': Delivery finished

#### Implementation
```dart
final now = DateTime.now().toUtc();
final data = {
  'status': status,
  'updated_at': now.toIso8601String(),
};

if (status == 'completed') {
  data['completion_date'] = now.toIso8601String();
}

await client.from('jobs').update(data).eq('id', jobId);
```

## Job Application Flow

### 1. Job Posting
```dart
// Warehouse owner creates job
final jobId = await postJob({
  'title': 'Furniture Delivery',
  'price': 1000,
  // ... other job details
});
```

### 2. Application Process
```dart
// Driver applies for job
await applyForJob(jobId, driverId);

// Warehouse owner reviews applications
final applications = await getJobApplications(jobId);

// Accept an application
await updateApplicationStatus(
  applicationId,
  'accepted',
  jobId,
  driverId: selectedDriverId
);
```

### 3. Job Progress
```dart
// Update job status as it progresses
await updateJobStatus(jobId, 'in_progress');
// ... delivery happens ...
await updateJobStatus(jobId, 'completed');
```

## Security Policies

### Jobs Table
```sql
-- Read access
CREATE POLICY "Anyone can read open jobs"
ON jobs FOR SELECT
USING (status = 'open');

CREATE POLICY "Users can read their own jobs"
ON jobs FOR SELECT
USING (
    warehouse_owner_id = auth.uid() OR
    assigned_driver_id = auth.uid()
);

-- Insert access
CREATE POLICY "Warehouse owners can create jobs"
ON jobs FOR INSERT
WITH CHECK (warehouse_owner_id = auth.uid());

-- Update access
CREATE POLICY "Job owners can update jobs"
ON jobs FOR UPDATE
USING (warehouse_owner_id = auth.uid());
```

### Job Applications Table
```sql
-- Read access
CREATE POLICY "Users can read relevant applications"
ON job_applications FOR SELECT
USING (
    driver_id = auth.uid() OR
    job_id IN (
        SELECT id FROM jobs
        WHERE warehouse_owner_id = auth.uid()
    )
);

-- Insert access
CREATE POLICY "Drivers can create applications"
ON job_applications FOR INSERT
WITH CHECK (driver_id = auth.uid());
```

## Realtime Updates

### Job Status Updates
```dart
final jobsChannel = client
    .channel('public:jobs')
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'jobs',
      ),
      (payload, [ref]) {
        // Handle job updates
      },
    )
    .subscribe();
```

### Application Updates
```dart
final applicationsChannel = client
    .channel('public:job_applications')
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'job_applications',
      ),
      (payload, [ref]) {
        // Handle application updates
      },
    )
    .subscribe();
```

## Error Handling

### Common Error Cases
1. Job Not Found
```dart
if (jobResponse == null) {
  throw Exception('Job not found: $jobId');
}
```

2. Invalid Status Transition
```dart
void validateStatusTransition(String currentStatus, String newStatus) {
  final validTransitions = {
    'open': ['assigned'],
    'assigned': ['in_progress'],
    'in_progress': ['completed'],
    'completed': [],
  };
  if (!validTransitions[currentStatus]!.contains(newStatus)) {
    throw Exception('Invalid status transition');
  }
}
```

3. Application Conflicts
```dart
try {
  await applyForJob(jobId, driverId);
} catch (e) {
  if (e.toString().contains('duplicate key')) {
    throw Exception('Already applied for this job');
  }
  rethrow;
}
```

## Best Practices

1. Job Creation
   - Validate all required fields
   - Set appropriate defaults
   - Include proper timestamps

2. Status Management
   - Use predefined status values
   - Validate status transitions
   - Update related timestamps

3. Application Handling
   - Check for conflicts
   - Validate driver availability
   - Maintain application uniqueness

4. Security
   - Enforce role-based access
   - Validate ownership
   - Protect sensitive data

## Testing Guidelines

1. Job Creation
```dart
test('should create job with valid data', () async {
  final jobId = await postJob(validJobData);
  final job = await getJob(jobId);
  expect(job.status, 'open');
});
```

2. Application Process
```dart
test('should handle job application', () async {
  await applyForJob(jobId, driverId);
  final applications = await getJobApplications(jobId);
  expect(applications.length, 1);
  expect(applications.first.status, 'pending');
});
```

3. Status Updates
```dart
test('should update job status', () async {
  await updateJobStatus(jobId, 'in_progress');
  final job = await getJob(jobId);
  expect(job.status, 'in_progress');
});
``` 