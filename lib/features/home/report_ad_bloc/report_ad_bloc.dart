import 'package:ado_dad_user/models/report_ad_model.dart';
import 'package:ado_dad_user/repositories/report_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_ad_event.dart';
part 'report_ad_state.dart';
part 'report_ad_bloc.freezed.dart';

class ReportAdBloc extends Bloc<ReportAdEvent, ReportAdState> {
  final ReportRepository reportRepository;

  ReportAdBloc({
    required this.reportRepository,
  }) : super(const ReportAdState.initial()) {
    on<ReportAdEvent>((event, emit) async {
      await event.when(
        reportAd: (reportedUserId, reason, description, relatedAd,
            evidenceUrls) async {

          emit(const ReportAdState.reporting());
          try {
            final reportData = ReportAdModel(
              reportedUser: reportedUserId,
              reason: reason,
              description: description,
              relatedAd: relatedAd,
              evidenceUrls: evidenceUrls,
            );

            final createdReport = await reportRepository.reportAd(reportData);
            emit(ReportAdState.reported(createdReport));
          } catch (e) {
            emit(ReportAdState.error(e.toString()));
          }
        },
      );
    });
  }
}
