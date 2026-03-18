import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/commercial_vehicle_type_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad_edit_event.dart';
part 'ad_edit_state.dart';
part 'ad_edit_bloc.freezed.dart';

class AdEditBloc extends Bloc<AdEditEvent, AdEditState> {
  final AddRepository repo;
  AdEditBloc({required this.repo}) : super(const AdEditState.idle()) {
    on<AdEditEvent>((event, emit) async {
      await event.when(
        loadCommercialVehicleTypes: () async {
          emit(const AdEditState.commercialVehicleTypesLoading());
          try {
            final items = await repo.fetchCommercialVehicleTypes();
            emit(AdEditState.commercialVehicleTypesLoaded(items));
          } catch (e) {
            emit(AdEditState.commercialVehicleTypesFailure(e.toString()));
          }
        },
        submit: (adId, category, payload) async {
          emit(const AdEditState.saving());
          try {
            // 1) call update API
            await repo.updateAd(adId, category: category, data: payload);

            // 2) re-fetch the updated record, so UI gets fresh data
            final updated = await repo.fetchAdDetail(adId);

            // Print updated ad data to console
            // print('✅ Ad updated successfully!');
            // print('📦 Updated Ad Data:');
            // print('   ID: ${updated.id}');
            // print('   Title: ${updated.title}');
            // print('   Category: ${updated.category}');
            // print('   Price: ${updated.price}');
            // print('   Location: ${updated.location}');
            // print('   Video Link: ${updated.link}');
            // print('   Images: ${updated.images.length} images');
            print('   Full Ad JSON: ${updated.toJson()}');

            emit(AdEditState.success(updated));
          } catch (e) {
            emit(AdEditState.failure(e.toString()));
          }
        },
        started: () {},
      );
    });
  }
}
