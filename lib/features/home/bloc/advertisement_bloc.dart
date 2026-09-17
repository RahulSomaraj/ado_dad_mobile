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
    _live.add(this);
  }

  /// Every open instance. Home's lives for the process (it is provided in
  /// `main.dart`); the category and search instances are route-scoped and drop
  /// out of here when their route is popped.
  static final Set<AdvertisementBloc> _live = <AdvertisementBloc>{};

  /// Drops the accumulated listings and every remembered filter/cursor in all
  /// live feeds. Called on logout: the state used to be retained for the whole
  /// process, so the next user saw the previous one's feed and filters.
  static void resetAll() {
    for (final bloc in _live.toList()) {
      bloc._resetForLogout();
    }
    AddRepository.invalidateAdsCache();
  }

  void _resetForLogout() {
    if (isClosed) return;
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
    _currentPage = 1;
    _allAdsPage = 1;
    _searchPage = 1;
    _searchQuery = null;
    _isFetching = false;
    _isSearchFetching = false;
    _locationFallbackToAll = false;
    _locationQueryHasNext = false;
    _locationLatitude = null;
    _locationLongitude = null;
    _filterMode = false;
    _userRadiusKm = null;
    _filterMaxDistance = null;
    // Deliberately outside an event handler: this runs on logout for every live
    // feed, and the state classes are freezed (adding an event needs codegen).
    // Safe because isClosed was checked above.
    // ignore: invalid_use_of_visible_for_testing_member
    emit(const AdvertisementState.initial());
  }

  @override
  Future<void> close() {
    _live.remove(this);
    return super.close();
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

  /// A "near you" page this thin is not a feed — it is a dead end. Below this
  /// many nearby results the bloc widens to the full all-ads feed instead of
  /// leaving the user staring at one or two stray listings. This covers real
  /// users outside the covered districts as well as an emulator whose default
  /// fix is Mountain View.
  static const int _minNearbyResults = 5;

  /// Radius used once the nearby feed is exhausted or too thin. 5000 km is the
  /// server's hard maximum (it rejects anything larger with a 400), and from
  /// anywhere in India it reaches the entire catalogue.
  ///
  /// Widening rather than dropping the coordinates matters: the backend only
  /// computes each ad's `distance` via `$geoNear`, so a fallback that queried
  /// without a location returned the right ads with every distance null, and
  /// the "x km away" line silently disappeared from every card.
  static const double _wideRadiusKm = 5000;
  bool _locationFallbackToAll = false;
  bool _locationQueryHasNext = false;
  int _allAdsPage = 1;

  /// True while this bloc serves a category/filter list (applyFilters or
  /// fetchByCategory). Paging then always repeats the same filtered query.
  /// Before this flag, page 2 of a category list fell into the location
  /// recommendation branches, which carry no category, so scrolling a Cars
  /// list pulled in bikes and property (audit 4.3).
  bool _filterMode = false;

  /// Radius the user picked in a filter sheet (km). Null = Anywhere, which
  /// keeps the automatic widening below. Set before dispatching applyFilters.
  double? _userRadiusKm;

  /// The maxDistance page 1 of the current filtered list actually used, so
  /// later pages ask the same question.
  double? _filterMaxDistance;

  double? get searchRadiusKm => _userRadiusKm;

  void setSearchRadius(double? km) => _userRadiusKm = km;

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

  /// The feed used once the nearby radius is exhausted or came back too thin.
  ///
  /// Keeps the user's coordinates so every ad still carries a `distance`,
  /// widening to [_wideRadiusKm] instead of dropping the location. Falls back to
  /// a location-less query only when coordinates are unknown, or when even the
  /// wide radius finds almost nothing — a user farther from the inventory than
  /// the server's maximum radius allows. Those results genuinely cannot carry a
  /// distance, which is correct: there is no meaningful one to show.
  Future<PaginatedAdsResponse> _fetchWideFeed(int page) async {
    if (_locationLatitude == null || _locationLongitude == null) {
      return repository.fetchAllAds(page: page);
    }

    final wide = await repository.fetchAllAds(
      page: page,
      latitude: _locationLatitude,
      longitude: _locationLongitude,
      maxDistance: _wideRadiusKm,
    );
    if (wide.data.length >= _minNearbyResults || page > 1) return wide;

    return repository.fetchAllAds(page: page);
  }

  /// One page of the filter screen's feed, carrying every remembered filter.
  /// [maxDistance] applies only when coordinates are in play; pass
  /// `withLocation: false` to drop them — which also drops each ad's distance.
  Future<PaginatedAdsResponse> _fetchFilteredPage(
    int page, {
    bool withLocation = true,
    double? maxDistance,
  }) {
    return repository.fetchAllAds(
      page: page,
      category: _categoryId,
      latitude: withLocation ? _locationLatitude : null,
      longitude: withLocation ? _locationLongitude : null,
      maxDistance: withLocation ? maxDistance : null,
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
      hasParking: _hasParking,
    );
  }

  List<AddModel> _mergeDedupe(List<AddModel> current, List<AddModel> incoming) {
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
    _filterMode = false;
    _filterMaxDistance = null;

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
        final bool inLocationMode = !_filterMode &&
            _locationLatitude != null &&
            !_locationFallbackToAll;

        if (inLocationMode && _locationQueryHasNext) {
          // (a) More pages within the location radius. $geoNear sorts
          // nearest-first, so each page returns progressively farther ads.
          _currentPage += 1;
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
          final result = await _fetchWideFeed(_allAdsPage);
          emit(ListingsLoaded(
            listings: _mergeDedupe(currentState.listings, result.data),
            hasMore: result.hasNext,
          ));
        } else if (!_filterMode && _locationFallbackToAll) {
          // (d) Continue the all-ads fallback feed.
          _allAdsPage += 1;
          final result = await _fetchWideFeed(_allAdsPage);
          emit(ListingsLoaded(
            listings: _mergeDedupe(currentState.listings, result.data),
            hasMore: result.hasNext,
          ));
        } else {
          // (e) Filtered / category / plain all-ads pagination: the same query
          // as page 1, every filter included (isFurnished/hasParking and the
          // radius used to be dropped from page 2 onward).
          _currentPage += 1;
          final result = await _fetchFilteredPage(_currentPage,
              maxDistance: _filterMaxDistance);
          emit(ListingsLoaded(
            listings: _mergeDedupe(currentState.listings, result.data),
            hasMore: result.hasNext,
          ));
        }
      } catch (_) {
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
    _filterMode = true;
    _filterMaxDistance = null;
    _locationFallbackToAll = false;

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
    } catch (_) {
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
    _locationLatitude = event.latitude;
    _locationLongitude = event.longitude;
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
    _filterMode = true;
    _locationFallbackToAll = false;
    final radius = _locationLatitude != null ? _userRadiusKm : null;
    _filterMaxDistance = radius;

    try {
      if (radius != null) {
        // The user chose a radius: honour it exactly. An empty result is shown
        // as "nothing within N km" with widen options, never silently widened.
        final result = await _fetchFilteredPage(_currentPage, maxDistance: radius);
        emit(AdvertisementState.listingsLoaded(
          listings: result.data,
          hasMore: result.hasNext,
        ));
        return;
      }
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
          maxArea: _maxArea,
          isFurnished: _isFurnished,
          hasParking: _hasParking);

      if (result.data.length < _minNearbyResults && _locationLatitude != null) {
        // Coordinates narrow a category/filter query and must never be the
        // reason a screen comes back empty. Widen to the server's maximum
        // radius first: dropping them outright also drops each ad's `distance`,
        // which is what made the "x km away" line vanish from these screens.
        var wide =
            await _fetchFilteredPage(_currentPage, maxDistance: _wideRadiusKm);
        _filterMaxDistance = _wideRadiusKm;

        if (wide.data.length < _minNearbyResults) {
          // Still thin at 5000 km, so the location really is the constraint.
          // Only now give up the coordinates — and with them the distances,
          // which at this range would not be meaningful anyway.
          _locationLatitude = null;
          _locationLongitude = null;
          _filterMaxDistance = null;
          wide = await _fetchFilteredPage(_currentPage, withLocation: false);
        }

        emit(AdvertisementState.listingsLoaded(
          listings: wide.data,
          hasMore: wide.hasNext,
        ));
        return;
      }

      emit(AdvertisementState.listingsLoaded(
        listings: result.data,
        hasMore: result.hasNext,
      ));
    } catch (_) {
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
    _filterMode = false;
    _filterMaxDistance = null;

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

      if (result.data.length < _minNearbyResults) {
        // Too little within the radius. This happens for real users outside the
        // covered regions, and on an emulator whose default fix is Mountain
        // View — either way the location filter must never be allowed to
        // produce an empty home. Fall straight through to the full feed.
        _locationFallbackToAll = true;
        _locationQueryHasNext = false;
        _allAdsPage = 1;
        final all = await _fetchWideFeed(_allAdsPage);
        final merged = _mergeDedupe(result.data, all.data);
        // Keep the nearby ones first, then the rest of the feed behind them.
        emit(AdvertisementState.listingsLoaded(
            listings: merged, hasMore: all.hasNext));
        return;
      }

      _locationQueryHasNext = result.hasNext;
      // Keep hasMore=true so scrolling can widen the radius and then fall back
      // to the full all-ads feed once nearby results are exhausted.
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: true));
    } catch (_) {
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
      final result = await repository.fetchAllAds(
        page: _searchPage,
        limit: 20,
        search: query,
      );
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (_) {
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
        final result = await repository.fetchAllAds(
          page: _searchPage,
          limit: 20,
          search: _searchQuery,
        );
        final updatedList = [...currentState.listings, ...result.data];
        emit(ListingsLoaded(listings: updatedList, hasMore: result.hasNext));
      } catch (_) {
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
    _filterMode = false;
    _filterMaxDistance = null;

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
    } catch (_) {
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }
}
