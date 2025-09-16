import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'advertisement_event.dart';
part 'advertisement_state.dart';
part 'advertisement_bloc.freezed.dart';

class AdvertisementBloc extends Bloc<AdvertisementEvent, AdvertisementState> {
  final AddRepository repository;
  AdvertisementBloc({required this.repository})
      : super(const AdvertisementState.initial()) {
    on<FetchAllListingsEvent>(_onFetchAllListings);
    on<FetchNextPageEvent>(_onFetchNextPage);
    on<FetchByCategory>(_onFetchByCategory);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<UpdateAdFavoriteStatusEvent>(_onUpdateAdFavoriteStatus);
  }

  int _currentPage = 1;
  bool _isFetching = false;

  // Active filters remembered by the bloc
  String? _categoryId;
  int? _minYear;
  int? _maxYear;
  List<String>? _manufacturerIds;
  List<String>? _modelIds;
  List<String>? _fuelTypeIds;
  List<String>? _transmissionTypeIds;
  int? _minPrice;
  int? _maxPrice;
  // Property-specific filters
  List<String>? _propertyTypes;
  int? _minBedrooms;
  int? _maxBedrooms;
  int? _minArea;
  int? _maxArea;
  bool? _isFurnished;
  bool? _hasParking;

  Future<void> _onFetchAllListings(
      FetchAllListingsEvent event, Emitter<AdvertisementState> emit) async {
    emit(const AdvertisementState.loading());
    _currentPage = 1;

    // clear filters
    _categoryId = null;
    _minYear = null;
    _maxYear = null;
    _manufacturerIds = null;
    _modelIds = null;
    _fuelTypeIds = null;
    _transmissionTypeIds = null;
    _minPrice = null;
    _maxPrice = null;
    _propertyTypes = null;
    _minBedrooms = null;
    _maxBedrooms = null;
    _minArea = null;
    _maxArea = null;
    _isFurnished = null;
    _hasParking = null;

    try {
      final result = await repository.fetchAllAds(page: _currentPage);
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      emit(AdvertisementState.error("Failed to fetch ads: $e"));
    }
  }

  Future<void> _onFetchNextPage(
      FetchNextPageEvent event, Emitter<AdvertisementState> emit) async {
    if (_isFetching) return;
    _isFetching = true;

    final currentState = state;
    if (currentState is ListingsLoaded && currentState.hasMore) {
      try {
        _currentPage += 1;
        print("📥 Fetching page $_currentPage");
        final result = await repository.fetchAllAds(
            page: _currentPage,
            category: _categoryId,
            minYear: _minYear,
            maxYear: _maxYear,
            manufacturerId: _manufacturerIds,
            modelId: _modelIds,
            fuelTypeIds: _fuelTypeIds,
            transmissionTypeIds: _transmissionTypeIds,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            propertyTypes: _propertyTypes,
            minBedrooms: _minBedrooms,
            maxBedrooms: _maxBedrooms,
            minArea: _minArea,
            maxArea: _maxArea);
        print(
            "📦 Received ${result.data.length} ads | hasNext: ${result.hasNext}");
        final updatedList = [...currentState.listings, ...result.data];

        emit(ListingsLoaded(listings: updatedList, hasMore: result.hasNext));
      } catch (e) {
        emit(AdvertisementState.error("Failed to load more ads: $e"));
      }
    }

    _isFetching = false;
  }

  Future<void> _onFetchByCategory(
    FetchByCategory event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(const AdvertisementState.loading());

    _categoryId = event.categoryId;
    _minYear = null;
    _maxYear = null;
    _manufacturerIds = null;
    _modelIds = null;
    _fuelTypeIds = null;
    _transmissionTypeIds = null;
    _currentPage = 1;
    _minPrice = null;
    _maxPrice = null;
    _propertyTypes = null;
    _minBedrooms = null;
    _maxBedrooms = null;
    _minArea = null;
    _maxArea = null;
    _isFurnished = null;
    _hasParking = null;

    try {
      final result = await repository.fetchAllAds(
        page: _currentPage,
        category: _categoryId,
      );
      emit(AdvertisementState.listingsLoaded(
        listings: result.data,
        hasMore: result.hasNext,
      ));
    } catch (e) {
      emit(AdvertisementState.error("Failed to fetch category ads: $e"));
    }
  }

  Future<void> _onApplyFilters(
      ApplyFiltersEvent event, Emitter<AdvertisementState> emit) async {
    emit(const AdvertisementState.loading());

    // set/replace filters (category can be re-applied from page)
    _categoryId = event.categoryId ?? _categoryId;
    _minYear = event.minYear;
    _maxYear = event.maxYear;
    _manufacturerIds = event.manufacturerIds;
    _modelIds = event.modelIds;
    _fuelTypeIds = event.fuelTypeIds;
    _transmissionTypeIds = event.transmissionTypeIds;
    _minPrice = event.minPrice;
    _maxPrice = event.maxPrice;
    _propertyTypes = event.propertyTypes;
    _minBedrooms = event.minBedrooms;
    _maxBedrooms = event.maxBedrooms;
    _minArea = event.minArea;
    _maxArea = event.maxArea;
    _isFurnished = event.isFurnished;
    _hasParking = event.hasParking;
    _currentPage = 1;

    try {
      final result = await repository.fetchAllAds(
          page: _currentPage,
          category: _categoryId,
          minYear: _minYear,
          maxYear: _maxYear,
          manufacturerId: _manufacturerIds,
          modelId: _modelIds,
          fuelTypeIds: _fuelTypeIds,
          transmissionTypeIds: _transmissionTypeIds,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          propertyTypes: _propertyTypes,
          minBedrooms: _minBedrooms,
          maxBedrooms: _maxBedrooms,
          minArea: _minArea,
          maxArea: _maxArea,
          isFurnished: _isFurnished,
          hasParking: _hasParking);
      emit(AdvertisementState.listingsLoaded(
        listings: result.data,
        hasMore: result.hasNext,
      ));
    } catch (e) {
      emit(AdvertisementState.error("Failed to apply filters: $e"));
    }
  }

  Future<void> _onUpdateAdFavoriteStatus(UpdateAdFavoriteStatusEvent event,
      Emitter<AdvertisementState> emit) async {
    final currentState = state;

    if (currentState is ListingsLoaded) {
      final updatedListings = currentState.listings.map((ad) {
        if (ad.id == event.adId) {
          return ad.copyWith(
            isFavorited: event.isFavorited,
            favoriteId: event.favoriteId,
            favoritedAt:
                event.isFavorited ? DateTime.now().toIso8601String() : null,
          );
        }
        return ad;
      }).toList();

      emit(AdvertisementState.listingsLoaded(
        listings: updatedListings,
        hasMore: currentState.hasMore,
      ));
    }
  }
}
