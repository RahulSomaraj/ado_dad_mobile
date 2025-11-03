import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/home/report_ad_bloc/report_ad_bloc.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

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
    final isIOS = !kIsWeb && Platform.isIOS;

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
      child: isIOS
          ? _buildCupertinoDialog(context)
          : _buildMaterialDialog(context),
    );
  }

  Widget _buildMaterialDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(context,
              mobile: 16, tablet: 18, largeTablet: 20, desktop: 22),
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: GetResponsiveSize.getResponsiveSize(context,
              mobile: 400, tablet: 500, largeTablet: 600, desktop: 700),
        ),
        padding: EdgeInsets.all(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
        ),
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
                    size: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 24, tablet: 30, largeTablet: 36, desktop: 42),
                  ),
                  SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 12,
                          tablet: 14,
                          largeTablet: 16,
                          desktop: 18)),
                  Text(
                    'Report Ad',
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: 20, tablet: 26, largeTablet: 30, desktop: 34),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 20, tablet: 24, largeTablet: 28, desktop: 32)),

              // Reason Selection
              Text(
                'Reason for reporting:',
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 12, tablet: 14, largeTablet: 16, desktop: 18)),

              // Reason dropdown
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                  vertical: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 4, tablet: 8, largeTablet: 12, desktop: 16),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(context,
                        mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason.isEmpty ? null : _selectedReason,
                    hint: Text(
                      'Select a reason',
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 18,
                            largeTablet: 22,
                            desktop: 26),
                        color: Colors.black,
                      ),
                    ),
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                      color: Colors.black,
                    ),
                    iconSize: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
                    items: _reasons.map((String reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(
                          _reasonLabels[reason] ?? reason,
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                largeTablet: 22,
                                desktop: 26),
                            color: Colors.black,
                          ),
                        ),
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
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 20, tablet: 24, largeTablet: 28, desktop: 32)),

              // Description
              Text(
                'Description:',
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 12, tablet: 14, largeTablet: 16, desktop: 18)),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                ),
                decoration: InputDecoration(
                  hintText:
                      'Please provide additional details about why you are reporting this ad...',
                  hintStyle: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                    vertical: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(context,
                          mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(context,
                          mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(context,
                          mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                    ),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 2, tablet: 2.5, largeTablet: 3, desktop: 3.5),
                    ),
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
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 24, tablet: 28, largeTablet: 32, desktop: 36)),

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
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 1,
                                  tablet: 1.5,
                                  largeTablet: 2,
                                  desktop: 2.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GetResponsiveSize.getResponsiveBorderRadius(
                                    context,
                                    mobile: 8,
                                    tablet: 10,
                                    largeTablet: 12,
                                    desktop: 14),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  GetResponsiveSize.getResponsivePadding(
                                      context,
                                      mobile: 16,
                                      tablet: 20,
                                      largeTablet: 24,
                                      desktop: 28),
                              vertical: GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 18,
                                  largeTablet: 22,
                                  desktop: 26),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 12,
                          tablet: 16,
                          largeTablet: 20,
                          desktop: 24)),
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
                              borderRadius: BorderRadius.circular(
                                GetResponsiveSize.getResponsiveBorderRadius(
                                    context,
                                    mobile: 8,
                                    tablet: 10,
                                    largeTablet: 12,
                                    desktop: 14),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  GetResponsiveSize.getResponsivePadding(
                                      context,
                                      mobile: 16,
                                      tablet: 20,
                                      largeTablet: 24,
                                      desktop: 28),
                              vertical: GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24),
                            ),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  height: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 20,
                                      tablet: 26,
                                      largeTablet: 30,
                                      desktop: 34),
                                  width: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 20,
                                      tablet: 26,
                                      largeTablet: 30,
                                      desktop: 34),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Submit Report',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize:
                                        GetResponsiveSize.getResponsiveFontSize(
                                            context,
                                            mobile: 14,
                                            tablet: 18,
                                            largeTablet: 22,
                                            desktop: 26),
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
    );
  }

  Widget _buildCupertinoDialog(BuildContext context) {
    final ValueNotifier<String?> errorTextNotifier =
        ValueNotifier<String?>(null);

    return StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return BlocBuilder<ReportAdBloc, ReportAdState>(
          builder: (context, state) {
            final isSubmitting = state.maybeWhen(
              reporting: () => true,
              orElse: () => false,
            );

            return ValueListenableBuilder<String?>(
              valueListenable: errorTextNotifier,
              builder: (context, errorText, _) {
                return CupertinoAlertDialog(
                  title: Text(
                    'Report Ad',
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 18,
                        tablet: 22,
                        largeTablet: 26,
                        desktop: 30,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Container(
                    padding: EdgeInsets.only(
                      top: GetResponsiveSize.getResponsivePadding(
                        context,
                        mobile: 16,
                        tablet: 20,
                        largeTablet: 24,
                        desktop: 28,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Reason Selection
                        Text(
                          'Reason for reporting:',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              largeTablet: 18,
                              desktop: 20,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 8,
                            tablet: 12,
                            largeTablet: 16,
                            desktop: 20,
                          ),
                        ),
                        // Reason dropdown with Cupertino style
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _showCupertinoReasonPicker(
                              dialogContext,
                              () => setDialogState(() {}),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 12,
                                tablet: 16,
                                largeTablet: 20,
                                desktop: 24,
                              ),
                              vertical: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 10,
                                tablet: 14,
                                largeTablet: 18,
                                desktop: 22,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedReason.isEmpty
                                      ? 'Select a reason'
                                      : (_reasonLabels[_selectedReason] ??
                                          _selectedReason),
                                  style: TextStyle(
                                    fontSize:
                                        GetResponsiveSize.getResponsiveFontSize(
                                      context,
                                      mobile: 16,
                                      tablet: 18,
                                      largeTablet: 20,
                                      desktop: 22,
                                    ),
                                    color: _selectedReason.isEmpty
                                        ? CupertinoColors.placeholderText
                                        : CupertinoColors.label,
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_down,
                                  size: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 16,
                                    tablet: 20,
                                    largeTablet: 24,
                                    desktop: 28,
                                  ),
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 12,
                            tablet: 16,
                            largeTablet: 20,
                            desktop: 24,
                          ),
                        ),
                        // Description
                        Text(
                          'Description:',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              largeTablet: 18,
                              desktop: 20,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 8,
                            tablet: 12,
                            largeTablet: 16,
                            desktop: 20,
                          ),
                        ),
                        CupertinoTextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          placeholder:
                              'Please provide additional details about why you are reporting this ad...',
                          padding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 12,
                              tablet: 16,
                              largeTablet: 20,
                              desktop: 24,
                            ),
                            vertical: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 10,
                              tablet: 14,
                              largeTablet: 18,
                              desktop: 22,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              largeTablet: 20,
                              desktop: 22,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (_) {
                            if (errorTextNotifier.value != null) {
                              errorTextNotifier.value = null;
                            }
                          },
                        ),
                        if (errorText != null)
                          Padding(
                            padding: EdgeInsets.only(
                              top: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 8,
                                tablet: 10,
                                largeTablet: 12,
                                desktop: 14,
                              ),
                            ),
                            child: Text(
                              errorText,
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 14,
                                  largeTablet: 16,
                                  desktop: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: false,
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: CupertinoColors.systemBlue,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            largeTablet: 20,
                            desktop: 22,
                          ),
                        ),
                      ),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: false,
                      isDestructiveAction: true,
                      onPressed: isSubmitting
                          ? null
                          : () {
                              // Manual validation
                              if (_selectedReason.isEmpty) {
                                errorTextNotifier.value =
                                    'Please select a reason for reporting';
                                return;
                              }

                              final description =
                                  _descriptionController.text.trim();
                              if (description.isEmpty) {
                                errorTextNotifier.value =
                                    'Please provide a description';
                                return;
                              }

                              if (description.length < 10) {
                                errorTextNotifier.value =
                                    'Description must be at least 10 characters long';
                                return;
                              }

                              // Clear error and submit
                              errorTextNotifier.value = null;

                              // Submit the report
                              context.read<ReportAdBloc>().add(
                                    ReportAdEvent.reportAd(
                                      reportedUserId: widget.reportedUserId,
                                      reason: _selectedReason,
                                      description: description,
                                      relatedAd: widget.adId,
                                    ),
                                  );
                            },
                      child: isSubmitting
                          ? CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  largeTablet: 20,
                                  desktop: 22,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCupertinoReasonPicker(
      BuildContext context, VoidCallback onStateChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Select Reason',
          style: TextStyle(
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: _reasons.map((reason) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedReason = reason;
              });
              onStateChanged();
              Navigator.of(context).pop();
            },
            child: Text(
              _reasonLabels[reason] ?? reason,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
              ),
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
            ),
          ),
        ),
      ),
    );
  }
}
