import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/job_provider.dart';

class OptimizedJobCard extends ConsumerWidget {
  final Job job;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onStatusUpdate;

  const OptimizedJobCard({
    Key? key,
    required this.job,
    this.onTap,
    this.onApply,
    this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildLocationRow(),
              const SizedBox(height: 8),
              _buildPriceAndWeightRow(),
              const SizedBox(height: 16),
              _buildActionRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      job.title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${job.pickupLocation} → ${job.destinationLocation}',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndWeightRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.currency_rupee, color: Colors.green, size: 14),
              Text(
                job.price.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.scale, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Text(
          '${job.weight}kg',
          style: const TextStyle(color: Colors.grey),
        ),
        const Spacer(),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(job.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        job.status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        if (job.description.isNotEmpty)
          Expanded(
            child: Text(
              job.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const Spacer(),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildActionButton() {
    switch (job.status) {
      case 'open':
        return ElevatedButton(
          onPressed: onApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        );
      case 'assigned':
        return ElevatedButton(
          onPressed: onStatusUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Start'),
        );
      case 'in_transit':
        return ElevatedButton(
          onPressed: onStatusUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Complete'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'in_transit':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class OptimizedJobListView extends ConsumerWidget {
  final List<Job> jobs;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(String)? onJobApply;
  final Function(String, String)? onStatusUpdate;

  const OptimizedJobListView({
    Key? key,
    required this.jobs,
    this.isLoading = false,
    this.onLoadMore,
    this.onJobApply,
    this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: jobs.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == jobs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final job = jobs[index];
        
        // Trigger load more when near the end
        if (index == jobs.length - 3 && onLoadMore != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLoadMore!();
          });
        }

        return OptimizedJobCard(
          key: ValueKey(job.id),
          job: job,
          onApply: onJobApply != null ? () => onJobApply!(job.id) : null,
          onStatusUpdate: onStatusUpdate != null 
            ? () => onStatusUpdate!(job.id, _getNextStatus(job.status))
            : null,
        );
      },
    );
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'assigned':
        return 'in_transit';
      case 'in_transit':
        return 'completed';
      default:
        return currentStatus;
    }
  }
} 