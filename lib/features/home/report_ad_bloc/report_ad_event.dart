part of 'report_ad_bloc.dart';

@freezed
class ReportAdEvent with _$ReportAdEvent {
  const factory ReportAdEvent.reportAd({
    required String reportedUserId,
    required String reason,
    required String description,
    required String relatedAd,
    List<String>? evidenceUrls,
  }) = _ReportAd;
}
