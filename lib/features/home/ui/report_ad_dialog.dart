import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/home/report_ad_bloc/report_ad_bloc.dart';

class ReportAdDialog extends StatefulWidget {
  final String reportedUserId;
  final String adId;

  const ReportAdDialog({
    super.key,
    required this.reportedUserId,
    required this.adId,
  });

  @override
  State<ReportAdDialog> createState() => _ReportAdDialogState();
}

class _ReportAdDialogState extends State<ReportAdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedReason = '';

  final List<String> _reasons = [
    'spam',
    'inappropriate_content',
    'fraud',
    'harassment',
    'fake_listings',
    'price_manipulation',
    'contact_abuse',
    'other',
  ];

  final Map<String, String> _reasonLabels = {
    'spam': 'Spam',
    'inappropriate_content': 'Inappropriate Content',
    'fraud': 'Fraud',
    'harassment': 'Harassment',
    'fake_listings': 'Fake Listings',
    'price_manipulation': 'Price Manipulation',
    'contact_abuse': 'Contact Abuse',
    'other': 'Other',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for reporting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use bloc to submit the report
    context.read<ReportAdBloc>().add(
          ReportAdEvent.reportAd(
            reportedUserId: widget.reportedUserId,
            reason: _selectedReason,
            description: _descriptionController.text.trim(),
            relatedAd: widget.adId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportAdBloc, ReportAdState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          reporting: () {},
          reported: (report) {
            // Show success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ad reported successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Close dialog after showing success message
            Navigator.of(context).pop(report);
          },
          error: (message) {
            print('🚨 ReportAdDialog: Error received: $message');
            // Close dialog first so snackbar is visible
            Navigator.of(context).pop();
            // Show error snackbar after dialog is closed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to report ad: $message'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          },
        );
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.report_problem,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Report Ad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Reason Selection
                const Text(
                  'Reason for reporting:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Reason dropdown
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedReason.isEmpty ? null : _selectedReason,
                      hint: const Text('Select a reason'),
                      isExpanded: true,
                      items: _reasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(_reasonLabels[reason] ?? reason),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedReason = newValue ?? '';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Please provide additional details about why you are reporting this ad...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<ReportAdBloc, ReportAdState>(
                        builder: (context, state) {
                          final isSubmitting = state.maybeWhen(
                            reporting: () => true,
                            orElse: () => false,
                          );
                          return OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<ReportAdBloc, ReportAdState>(
                        builder: (context, state) {
                          final isSubmitting = state.maybeWhen(
                            reporting: () => true,
                            orElse: () => false,
                          );
                          return ElevatedButton(
                            onPressed: isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Submit Report',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
