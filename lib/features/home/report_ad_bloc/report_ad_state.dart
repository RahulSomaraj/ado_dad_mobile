part of 'report_ad_bloc.dart';

@freezed
class ReportAdState with _$ReportAdState {
  const factory ReportAdState.initial() = _Initial;
  const factory ReportAdState.reporting() = _Reporting;
  const factory ReportAdState.reported(ReportAdModel report) = _Reported;
  const factory ReportAdState.error(String message) = _Error;
}
