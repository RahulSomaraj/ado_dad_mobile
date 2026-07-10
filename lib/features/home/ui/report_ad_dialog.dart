import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/home/report_ad_bloc/report_ad_bloc.dart';

/// Report-ad bottom sheet (wireframe: docs/ado_dad_wireframes_missing_pages.html
/// → "Report ad"). Drag handle, radio reason list, min-10-char description,
/// Cancel + destructive Submit.
class ReportAdDialog extends StatefulWidget {
  final String reportedUserId;
  final String adId;

  const ReportAdDialog({
    super.key,
    required this.reportedUserId,
    required this.adId,
  });

  /// Preferred entry point: shows the sheet on both platforms.
  static Future<dynamic> show(
    BuildContext context, {
    required String reportedUserId,
    required String adId,
  }) {
    final bloc = context.read<ReportAdBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ReportAdDialog(
          reportedUserId: reportedUserId,
          adId: adId,
        ),
      ),
    );
  }

  @override
  State<ReportAdDialog> createState() => _ReportAdDialogState();
}

class _ReportAdDialogState extends State<ReportAdDialog> {
  final _descriptionController = TextEditingController();

  String _selectedReason = '';
  String? _errorText;

  static const List<String> _reasons = [
    'fake_listings',
    'spam',
    'fraud',
    'inappropriate_content',
    'price_manipulation',
    'harassment',
    'contact_abuse',
    'other',
  ];

  static const Map<String, String> _reasonLabels = {
    'fake_listings': 'Fake listing',
    'spam': 'Spam',
    'fraud': 'Fraud',
    'inappropriate_content': 'Inappropriate content',
    'price_manipulation': 'Price manipulation',
    'harassment': 'Harassment',
    'contact_abuse': 'Contact abuse',
    'other': 'Other',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_selectedReason.isEmpty) {
      setState(() => _errorText = 'Please select a reason for reporting');
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _errorText = 'Please provide a description');
      return;
    }
    if (description.length < 10) {
      setState(
          () => _errorText = 'Description must be at least 10 characters long');
      return;
    }
    setState(() => _errorText = null);

    context.read<ReportAdBloc>().add(
          ReportAdEvent.reportAd(
            reportedUserId: widget.reportedUserId,
            reason: _selectedReason,
            description: description,
            relatedAd: widget.adId,
          ),
        );
  }

  TextStyle _sectionLabelStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: GetResponsiveSize.getResponsiveFontSize(context,
            mobile: 11, tablet: 13, largeTablet: 14, desktop: 15),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.greyColor,
      );

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportAdBloc, ReportAdState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          reporting: () {},
          reported: (report) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ad reported — our team will review it.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.primaryColor,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(report);
          },
          error: (message) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to report ad: $message',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.redColor,
                duration: const Duration(seconds: 4),
              ),
            );
          },
        );
      },
      child: SafeArea(
        child: Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
              8,
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.greyColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Report this ad',
                        style: GoogleFonts.poppins(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 20,
                              largeTablet: 22,
                              desktop: 24),
                          fontWeight: FontWeight.w600,
                          color: AppColors.blackColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: AppColors.greyColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text('REASON', style: _sectionLabelStyle(context)),
                const SizedBox(height: 4),
                ..._reasons.map(
                  (reason) => RadioListTile<String>(
                    value: reason,
                    groupValue:
                        _selectedReason.isEmpty ? null : _selectedReason,
                    onChanged: (value) => setState(() {
                      _selectedReason = value ?? '';
                      _errorText = null;
                    }),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryColor,
                    title: Text(
                      _reasonLabels[reason] ?? reason,
                      style: GoogleFonts.poppins(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 13.5,
                            tablet: 16,
                            largeTablet: 18,
                            desktop: 20),
                        color: AppColors.blackColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text('DESCRIPTION', style: _sectionLabelStyle(context)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  style: GoogleFonts.poppins(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 13.5, tablet: 16, largeTablet: 18, desktop: 20),
                    color: AppColors.blackColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "Tell us what's wrong (min 10 characters)…",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: 13.5,
                          tablet: 16,
                          largeTablet: 18,
                          desktop: 20),
                      color: AppColors.greyColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide:
                          BorderSide(color: AppColors.greyColor.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                          color: AppColors.primaryColor, width: 1.5),
                    ),
                  ),
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorText!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.redColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Actions
                BlocBuilder<ReportAdBloc, ReportAdState>(
                  builder: (context, state) {
                    final isSubmitting = state.maybeWhen(
                      reporting: () => true,
                      orElse: () => false,
                    );
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color:
                                      AppColors.greyColor.withOpacity(0.6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: AppColors.blackColor,
                                fontWeight: FontWeight.w500,
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
                                        context,
                                        mobile: 13.5,
                                        tablet: 16,
                                        largeTablet: 18,
                                        desktop: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.redColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
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
                                : Text(
                                    'Submit report',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: GetResponsiveSize
                                          .getResponsiveFontSize(context,
                                              mobile: 13.5,
                                              tablet: 16,
                                              largeTablet: 18,
                                              desktop: 20),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
