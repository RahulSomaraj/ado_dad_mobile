import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad_detail_event.dart';
part 'ad_detail_state.dart';
part 'ad_detail_bloc.freezed.dart';

class AdDetailBloc extends Bloc<AdDetailEvent, AdDetailState> {
  final AddRepository repository;
  AdDetailBloc({required this.repository})
      : super(const AdDetailState.initial()) {
    on<AdDetailEvent>((event, emit) async {
      await event.when(
        fetch: (adId) async {
          emit(const AdDetailState.loading());
          try {
            final detail = await repository.fetchAdDetail(adId);

            // Map IDs → names
            final transmissions =
                await repository.fetchVehicleTransmissionTypes();
            final fuels = await repository.fetchVehicleFuelTypes();

            final tName = transmissions
                .firstWhere(
                  (t) => t.id == detail.transmissionId,
                  orElse: () => VehicleTransmissionType(
                    id: '',
                    displayName: '-',
                  ),
                )
                .displayName;

            final fName = fuels
                .firstWhere(
                  (f) => f.id == detail.fuelTypeId,
                  orElse: () => VehicleFuelType(
                    id: '',
                    displayName: '-',
                  ),
                )
                .displayName;

            emit(AdDetailState.loaded(
              detail.copyWith(transmission: tName, fuelType: fName),
            ));
          } catch (e) {
            emit(AdDetailState.error(e.toString()));
          }
        },
        started: () {},
      );
    });
  }
}
