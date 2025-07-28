import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reimbursement_request.dart';
import '../services/reimbursement_service.dart';
import '../providers/organization_provider.dart';
import '../providers/user_provider.dart';
import '../components/organization_toggle.dart';
import '../theme/app_theme.dart';

class ReimbursementGkApprovalScreen extends StatefulWidget {
  const ReimbursementGkApprovalScreen({super.key});

  @override
  State<ReimbursementGkApprovalScreen> createState() => _ReimbursementGkApprovalScreenState();
}

class _ReimbursementGkApprovalScreenState extends State<ReimbursementGkApprovalScreen> {
  final _reimbursementService = ReimbursementService();
  
  List<ReimbursementRequest> _approvedVouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovedVouchers();
  }

  Future<void> _loadApprovedVouchers() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = context.read<UserProvider>().userProfile;
      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      final organizationId = userProfile?.getOrganizationId(isAssembly) ?? '';
      
      final vouchers = await _reimbursementService.getApprovedVouchers(organizationId);
      setState(() {
        _approvedVouchers = vouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load approved vouchers: $e')),
        );
      }
    }
  }

  Future<void> _approveVoucher(ReimbursementRequest voucher) async {
    try {
      final userProfile = context.read<UserProvider>().userProfile;
      if (userProfile == null) return;

      await _reimbursementService.approveVoucher(voucher.id, userProfile.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher approved and sent to Treasurer')),
        );
        _loadApprovedVouchers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve voucher: $e')),
        );
      }
    }
  }

  Widget _buildVoucherCard(ReimbursementRequest voucher) {
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
                        'Voucher ${voucher.voucherNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        voucher.requesterName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        voucher.programName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${voucher.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Created: ${_formatDate(voucher.voucherCreatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(voucher.description),
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
                      Text(voucher.recipientType == 'self' 
                          ? 'Self' 
                          : 'Donation to ${voucher.donationEntity ?? 'Unknown'}'),
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
                      Text(voucher.deliveryMethod == 'meeting' 
                          ? 'Next Meeting' 
                          : 'Mail'),
                    ],
                  ),
                ),
              ],
            ),
            if (voucher.deliveryMethod == 'mail' && voucher.mailingAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                'Address: ${voucher.mailingAddress}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (voucher.documentUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Documents:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                spacing: 8,
                children: voucher.documentUrls.map((url) => Chip(
                  label: Text(url.split('/').last),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showVoucherDetails(voucher),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _approveVoucher(voucher),
                    child: const Text('Approve Voucher'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherDetails(ReimbursementRequest voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Voucher ${voucher.voucherNumber} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Requester', voucher.requesterName),
              _buildDetailRow('Email', voucher.requesterEmail),
              _buildDetailRow('Phone', voucher.requesterPhone),
              _buildDetailRow('Program', voucher.programName),
              _buildDetailRow('Amount', '\$${voucher.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Description', voucher.description),
              _buildDetailRow('Recipient', voucher.recipientType == 'self' 
                  ? 'Self' 
                  : 'Donation to ${voucher.donationEntity ?? 'Unknown'}'),
              _buildDetailRow('Delivery', voucher.deliveryMethod == 'meeting' 
                  ? 'Next Meeting' 
                  : 'Mail'),
              if (voucher.deliveryMethod == 'mail' && voucher.mailingAddress != null)
                _buildDetailRow('Mailing Address', voucher.mailingAddress!),
              _buildDetailRow('Created', _formatDate(voucher.voucherCreatedAt)),
              _buildDetailRow('Approved By', voucher.approvedBy ?? 'Unknown'),
              _buildDetailRow('Approved Date', _formatDate(voucher.approvedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.month}/${date.day}/${date.year}';
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
            title: const Text('Voucher Approval'),

          ),
          body: AppTheme.screenContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OrganizationToggle(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _approvedVouchers.isEmpty
                          ? const Center(
                              child: Text('No vouchers pending approval'),
                            )
                          : ListView.builder(
                              padding: AppTheme.cardPadding,
                              itemCount: _approvedVouchers.length,
                              itemBuilder: (context, index) {
                                return _buildVoucherCard(_approvedVouchers[index]);
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