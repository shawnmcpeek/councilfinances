import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reimbursement_request.dart';
import '../services/reimbursement_service.dart';
import '../providers/organization_provider.dart';
import '../providers/user_provider.dart';
import '../components/organization_toggle.dart';
import '../theme/app_theme.dart';
import 'document_viewer_screen.dart';

class ReimbursementApprovalScreen extends StatefulWidget {
  const ReimbursementApprovalScreen({super.key});

  @override
  State<ReimbursementApprovalScreen> createState() => _ReimbursementApprovalScreenState();
}

class _ReimbursementApprovalScreenState extends State<ReimbursementApprovalScreen> {
  final _reimbursementService = ReimbursementService();
  final _denialReasonController = TextEditingController();
  
  List<ReimbursementRequest> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _denialReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = context.read<UserProvider>().userProfile;
      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      final organizationId = userProfile?.getOrganizationId(isAssembly) ?? '';
      
      final requests = await _reimbursementService.getPendingRequests(organizationId);
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pending requests: $e')),
        );
      }
    }
  }

  Future<void> _approveRequest(ReimbursementRequest request) async {
    try {
      final userProfile = context.read<UserProvider>().userProfile;
      if (userProfile == null) return;

      await _reimbursementService.approveRequest(request.id, userProfile.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved and voucher created')),
        );
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve request: $e')),
        );
      }
    }
  }

  Future<void> _denyRequest(ReimbursementRequest request) async {
    final userProfile = context.read<UserProvider>().userProfile;
    if (userProfile == null) return;
    final userId = userProfile.uid;
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for denying this request:'),
            const SizedBox(height: 16),
            TextField(
              controller: _denialReasonController,
              decoration: const InputDecoration(
                labelText: 'Denial Reason',
                border: OutlineInputBorder(),
                hintText: 'Enter reason for denial...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_denialReasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, _denialReasonController.text.trim());
              }
            },
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await _reimbursementService.denyRequest(request.id, userId, reason);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request denied')),
          );
          _denialReasonController.clear();
          _loadPendingRequests();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to deny request: $e')),
          );
        }
      }
    }
  }

  Widget _buildRequestCard(ReimbursementRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        request.programName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${request.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(request.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(request.recipientType == 'self' 
                          ? 'Self' 
                          : 'Donation to ${request.donationEntity ?? 'Unknown'}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(request.deliveryMethod == 'meeting' 
                          ? 'Next Meeting' 
                          : request.deliveryMethod == 'mail'
                          ? 'Mail'
                          : 'Pay Online'),
                    ],
                  ),
                ),
              ],
            ),
            if (request.deliveryMethod == 'mail' && request.mailingAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                'Address: ${request.mailingAddress}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (request.documentUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Documents:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                spacing: 8,
                children: request.documentUrls.map((url) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentViewerScreen(
                          documentUrl: url,
                          documentName: url.split('/').last,
                        ),
                      ),
                    );
                  },
                  child: Chip(
                    label: Text(url.split('/').last),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    avatar: const Icon(Icons.visibility, size: 16),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _denyRequest(request),
                    child: const Text('Deny'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _approveRequest(request),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrganizationProvider, UserProvider>(
      builder: (context, organizationProvider, userProvider, child) {
        final userProfile = userProvider.userProfile;
        
        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: Text('User profile not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pending Reimbursements'),
          ),
          body: AppTheme.screenContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OrganizationToggle(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _pendingRequests.isEmpty
                          ? const Center(
                              child: Text('No pending reimbursement requests'),
                            )
                          : ListView.builder(
                              padding: AppTheme.cardPadding,
                              itemCount: _pendingRequests.length,
                              itemBuilder: (context, index) {
                                return _buildRequestCard(_pendingRequests[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 