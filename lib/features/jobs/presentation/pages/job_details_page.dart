import 'package:flutter/material.dart';
import '../../domain/models/job.dart';
import '../../../../core/services/supabase_service.dart';

class JobDetailsPage extends StatefulWidget {
  final Job job;

  const JobDetailsPage({super.key, required this.job});

  @override
  _JobDetailsPageState createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late Job job;
  bool _hasActiveJob = false;

  @override
  void initState() {
    super.initState();
    job = widget.job;
    _checkActiveJob();
  }

  Future<void> _checkActiveJob() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final hasActive = await SupabaseService.hasActiveJob(userId);
      if (mounted) {
        setState(() {
          _hasActiveJob = hasActive;
        });
      }
    } catch (e) {
      print('Error checking active job status: $e');
    }
  }

  Future<void> _applyForJob() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to apply for jobs'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check if user has active jobs
      final hasActiveJob = await SupabaseService.hasActiveJob(userId);
      if (hasActiveJob) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please complete your current job before applying for new ones'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      final loadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Submitting application...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration:
              Duration(seconds: 30), // Long duration as we'll close it manually
          behavior: SnackBarBehavior.floating,
        ),
      );

      await SupabaseService.applyForJob(widget.job.id, userId);

      // Hide loading indicator
      loadingSnackBar.close();

      // Show success message after a short delay
      await Future.delayed(Duration(milliseconds: 100));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Color(0xFF6B5ECD),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Close the details page after a short delay
      await Future.delayed(Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      print('Error applying for job: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying for job: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.05),
        title: Text(
          job.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              'Goods Information',
              [
                _buildDetailRow('Type', job.goodsType),
                _buildDetailRow('Weight', '${job.weight} kg'),
                _buildDetailRow('Price', '₹${job.price.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              'Location Details',
              [
                _buildDetailRowWithIcon(
                  'Pickup',
                  job.pickupLocation,
                  Icons.location_on,
                ),
                _buildDetailRowWithIcon(
                  'Destination',
                  job.destination,
                  Icons.location_on,
                ),
                _buildDetailRow('Distance', '${job.distance} km'),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              'Additional Information',
              [
                _buildDetailRow('Posted', _formatDate(job.postedDate)),
                _buildDetailRow('Status', job.status.toUpperCase()),
              ],
            ),
            const SizedBox(height: 32),
            if (_hasActiveJob)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You have an active job',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please complete your current job before applying for new ones',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (job.status == 'open')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyForJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6B5ECD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply for Job',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithIcon(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
