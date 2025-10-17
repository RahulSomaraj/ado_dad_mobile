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
          print('🚀 ReportAdBloc: Starting report process');
          print('🚀 ReportAdBloc: reportedUserId: $reportedUserId');
          print('🚀 ReportAdBloc: reason: $reason');
          print('🚀 ReportAdBloc: description: $description');
          print('🚀 ReportAdBloc: relatedAd: $relatedAd');
          print('🚀 ReportAdBloc: evidenceUrls: $evidenceUrls');

          emit(const ReportAdState.reporting());
          try {
            final reportData = ReportAdModel(
              reportedUser: reportedUserId,
              reason: reason,
              description: description,
              relatedAd: relatedAd,
              evidenceUrls: evidenceUrls,
            );

            print('🚀 ReportAdBloc: Calling reportRepository.reportAd()');
            final createdReport = await reportRepository.reportAd(reportData);
            print(
                '🚀 ReportAdBloc: Report created successfully: ${createdReport.id}');
            emit(ReportAdState.reported(createdReport));
          } catch (e) {
            print('🚀 ReportAdBloc: Error occurred: $e');
            print('🚀 ReportAdBloc: Error type: ${e.runtimeType}');
            emit(ReportAdState.error(e.toString()));
          }
        },
      );
    });
  }
}
