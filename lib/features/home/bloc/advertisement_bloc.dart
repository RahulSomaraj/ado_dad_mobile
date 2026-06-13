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
    on<SearchByLocationEvent>(_onSearchByLocation);
    on<SearchAdsEvent>(_onSearchAds);
    on<SearchNextPageEvent>(_onSearchNextPage);
    on<FetchByUserIdEvent>(_onFetchByUserId);
  }

  int _currentPage = 1;
  bool _isFetching = false;
  bool _isSearchFetching = false;
  int _searchPage = 1;
  String? _searchQuery;
  double? _locationLatitude;
  double? _locationLongitude;

  // Location-recommendation pagination: a generous radius, sorted nearest-first
  // by the backend ($geoNear), so each page returns progressively farther ads.
  // Once that feed is exhausted, fall back to the full all-ads feed.
  static const double _locationRadiusKm = 200;
  bool _locationFallbackToAll = false;
  bool _locationQueryHasNext = false;
  int _allAdsPage = 1;

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
  List<String>? _commercialVehicleTypes;
  // Property-specific filters
  List<String>? _propertyTypes;
  int? _minBedrooms;
  int? _maxBedrooms;
  int? _minArea;
  int? _maxArea;
  bool? _isFurnished;
  bool? _hasParking;

  List<AddModel> _mergeDedupe(
      List<AddModel> current, List<AddModel> incoming) {
    final ids = current.map((a) => a.id).toSet();
    return [
      ...current,
      ...incoming.where((a) => !ids.contains(a.id)),
    ];
  }

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
    _commercialVehicleTypes = null;
    _propertyTypes = null;
    _minBedrooms = null;
    _maxBedrooms = null;
    _minArea = null;
    _maxArea = null;
    _isFurnished = null;
    _hasParking = null;
    _locationLatitude = null;
    _locationLongitude = null;
    _locationFallbackToAll = false;
    _locationQueryHasNext = false;

    try {
      final result = await repository.fetchAllAds(page: _currentPage);
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }

  Future<void> _onFetchNextPage(
      FetchNextPageEvent event, Emitter<AdvertisementState> emit) async {
    if (_isFetching) return;
    _isFetching = true;

    final currentState = state;
    if (currentState is ListingsLoaded && currentState.hasMore) {
      try {
        final bool inLocationMode =
            _locationLatitude != null && !_locationFallbackToAll;

        if (inLocationMode && _locationQueryHasNext) {
          // (a) More pages within the location radius. $geoNear sorts
          // nearest-first, so each page returns progressively farther ads.
          _currentPage += 1;
          print("📥 Location page $_currentPage @ ${_locationRadiusKm}km");
          final result = await repository.fetchAllAds(
            page: _currentPage,
            latitude: _locationLatitude,
            longitude: _locationLongitude,
            maxDistance: _locationRadiusKm,
          );
          _locationQueryHasNext = result.hasNext;
          emit(ListingsLoaded(
            listings: _mergeDedupe(currentState.listings, result.data),
            hasMore: true,
          ));
        } else if (inLocationMode) {
          // (b) Location feed exhausted → start the full all-ads fallback feed.
          _locationFallbackToAll = true;
          _allAdsPage = 1;
          print("📥 Location exhausted → all-ads fallback page $_allAdsPage");
          final result = await repository.fetchAllAds(page: _allAdsPage);
          emit(ListingsLoaded(
            listings: _mergeDedupe(currentState.listings, result.data),
            hasMore: result.hasNext,
          ));
        } else if (_locationFallbackToAll) {
          // (d) Continue the all-ads fallback feed.
          _allAdsPage += 1;
          print("📥 All-ads fallback page $_allAdsPage");
          final result = await repository.fetchAllAds(page: _allAdsPage);
          emit(ListingsLoaded(
            listings: _mergeDedupe(currentState.listings, result.data),
            hasMore: result.hasNext,
          ));
        } else {
          // (e) Normal all-ads / filtered pagination (unchanged behaviour).
          _currentPage += 1;
          print("📥 Fetching page $_currentPage");
          final result = await repository.fetchAllAds(
              page: _currentPage,
              category: _categoryId,
              latitude: _locationLatitude,
              longitude: _locationLongitude,
              commercialVehicleTypes: _commercialVehicleTypes,
              minYear: _minYear,
              maxYear: _maxYear,
              manufacturerIds: _manufacturerIds,
              modelIds: _modelIds,
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
          emit(ListingsLoaded(
            listings: [...currentState.listings, ...result.data],
            hasMore: result.hasNext,
          ));
        }
      } catch (e) {
        // Emit user-friendly message instead of raw exception
        emit(AdvertisementState.error(
            "Unable to load more recommendations. Please try again later."));
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
    _commercialVehicleTypes = null;
    _propertyTypes = null;
    _minBedrooms = null;
    _maxBedrooms = null;
    _minArea = null;
    _maxArea = null;
    _isFurnished = null;
    _hasParking = null;
    _commercialVehicleTypes = null;
    _locationLatitude = null;
    _locationLongitude = null;

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
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
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
    _commercialVehicleTypes = event.commercialVehicleTypes;
    _propertyTypes = event.propertyTypes;
    _minBedrooms = event.minBedrooms;
    _maxBedrooms = event.maxBedrooms;
    _minArea = event.minArea;
    _maxArea = event.maxArea;
    _isFurnished = event.isFurnished;
    _hasParking = event.hasParking;
    _currentPage = 1;
    _locationLatitude = null;
    _locationLongitude = null;

    try {
      final result = await repository.fetchAllAds(
          page: _currentPage,
          category: _categoryId,
          commercialVehicleTypes: _commercialVehicleTypes,
          minYear: _minYear,
          maxYear: _maxYear,
          manufacturerIds: _manufacturerIds,
          modelIds: _modelIds,
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
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
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

  Future<void> _onSearchByLocation(
      SearchByLocationEvent event, Emitter<AdvertisementState> emit) async {
    emit(const AdvertisementState.loading());
    _currentPage = 1;

    // Clear other filters when searching by location
    _categoryId = null;
    _minYear = null;
    _maxYear = null;
    _manufacturerIds = null;
    _modelIds = null;
    _fuelTypeIds = null;
    _transmissionTypeIds = null;
    _minPrice = null;
    _maxPrice = null;
    _commercialVehicleTypes = null;
    _propertyTypes = null;
    _minBedrooms = null;
    _maxBedrooms = null;
    _minArea = null;
    _maxArea = null;
    _isFurnished = null;
    _hasParking = null;
    _locationLatitude = event.latitude;
    _locationLongitude = event.longitude;
    _locationFallbackToAll = false;

    try {
      final result = await repository.fetchAllAds(
        page: _currentPage,
        latitude: event.latitude,
        longitude: event.longitude,
        maxDistance: _locationRadiusKm,
      );
      _locationQueryHasNext = result.hasNext;
      // Keep hasMore=true so scrolling can widen the radius and then fall back
      // to the full all-ads feed once nearby results are exhausted.
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: true));
    } catch (e) {
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }

  Future<void> _onSearchAds(
      SearchAdsEvent event, Emitter<AdvertisementState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    emit(const AdvertisementState.loading());
    _searchQuery = query;
    _searchPage = 1;
    _locationLatitude = null;
    _locationLongitude = null;

    try {
      print(
          '🔍 Search API: /v2/ads/list page=$_searchPage limit=20 search="$query"');
      final result = await repository.fetchAllAds(
        page: _searchPage,
        limit: 20,
        search: query,
      );
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }

  Future<void> _onSearchNextPage(
      SearchNextPageEvent event, Emitter<AdvertisementState> emit) async {
    if (_isSearchFetching) return;
    if (_searchQuery == null || _searchQuery!.isEmpty) return;

    final currentState = state;
    if (currentState is ListingsLoaded && currentState.hasMore) {
      _isSearchFetching = true;
      try {
        _searchPage += 1;
        print(
            '🔍 Search API: /v2/ads/list page=$_searchPage limit=20 search="${_searchQuery!}"');
        final result = await repository.fetchAllAds(
          page: _searchPage,
          limit: 20,
          search: _searchQuery,
        );
        final updatedList = [...currentState.listings, ...result.data];
        emit(ListingsLoaded(listings: updatedList, hasMore: result.hasNext));
      } catch (e) {
        emit(AdvertisementState.error(
            "Unable to load more recommendations. Please try again later."));
      } finally {
        _isSearchFetching = false;
      }
    }
  }

  Future<void> _onFetchByUserId(
      FetchByUserIdEvent event, Emitter<AdvertisementState> emit) async {
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
    _locationLatitude = null;
    _locationLongitude = null;

    try {
      final result = await repository.fetchAdsByUserId(
        userId: event.userId,
        page: _currentPage,
      );
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }
}
