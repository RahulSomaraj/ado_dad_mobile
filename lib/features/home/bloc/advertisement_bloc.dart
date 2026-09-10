import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'advertisement_event.dart';
part 'advertisement_state.dart';
part 'advertisement_bloc.freezed.dart';

/// Which kind of list the bloc is currently paginating. `fetchNextPage` uses
/// this to reuse exactly the query that produced page 1.
enum _ListMode { all, category, filters, location, search, user }

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

  /// Active list mode + the query that produced its first page.
  _ListMode _mode = _ListMode.all;
  String? _userId;

  /// Incremented for every list-producing request so that a slow, stale
  /// response (e.g. an older keystroke's search) can never overwrite a newer
  /// one.
  int _requestSeq = 0;

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

  /// Clears the nearby-feed pagination bookkeeping. Called by every list that
  /// is *not* the location feed, so its next pages cannot be served by the
  /// location branch.
  void _resetLocationPaging() {
    _locationFallbackToAll = false;
    _locationQueryHasNext = false;
    _allAdsPage = 1;
  }

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
    final seq = ++_requestSeq;
    emit(const AdvertisementState.loading());
    _mode = _ListMode.all;
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
    _searchQuery = null;
    _userId = null;
    _locationLatitude = null;
    _locationLongitude = null;
    _resetLocationPaging();

    try {
      final result = await repository.fetchAllAds(page: _currentPage);
      if (seq != _requestSeq) return;
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      if (seq != _requestSeq) return;
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
      final seq = ++_requestSeq;
      try {
        switch (_mode) {
          case _ListMode.location:
            await _fetchNextLocationPage(currentState, seq, emit);
            break;

          case _ListMode.category:
            {
              _currentPage += 1;
              final result = await repository.fetchAllAds(
                page: _currentPage,
                category: _categoryId,
              );
              if (seq != _requestSeq) return;
              emit(ListingsLoaded(
                listings: _mergeDedupe(currentState.listings, result.data),
                hasMore: result.hasNext,
              ));
            }
            break;

          case _ListMode.filters:
            {
              _currentPage += 1;
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
                hasParking: _hasParking,
              );
              if (seq != _requestSeq) return;
              emit(ListingsLoaded(
                listings: _mergeDedupe(currentState.listings, result.data),
                hasMore: result.hasNext,
              ));
            }
            break;

          case _ListMode.search:
            {
              if (_searchQuery == null || _searchQuery!.isEmpty) return;
              _searchPage += 1;
              final result = await repository.fetchAllAds(
                page: _searchPage,
                limit: 20,
                search: _searchQuery,
              );
              if (seq != _requestSeq) return;
              emit(ListingsLoaded(
                listings: _mergeDedupe(currentState.listings, result.data),
                hasMore: result.hasNext,
              ));
            }
            break;

          case _ListMode.user:
            {
              if (_userId == null) return;
              _currentPage += 1;
              final result = await repository.fetchAdsByUserId(
                userId: _userId!,
                page: _currentPage,
              );
              if (seq != _requestSeq) return;
              emit(ListingsLoaded(
                listings: _mergeDedupe(currentState.listings, result.data),
                hasMore: result.hasNext,
              ));
            }
            break;

          case _ListMode.all:
            {
              _currentPage += 1;
              final result = await repository.fetchAllAds(page: _currentPage);
              if (seq != _requestSeq) return;
              emit(ListingsLoaded(
                listings: _mergeDedupe(currentState.listings, result.data),
                hasMore: result.hasNext,
              ));
            }
            break;
        }
      } catch (e) {
        // Loading a further page failed: keep the pages we already have (an
        // error state would wipe the list) and roll the page counter back so a
        // retry re-requests the same page instead of skipping it.
        _rollBackPageCounter();
        debugPrint('❌ Failed to load next page (mode: $_mode): $e');
        if (seq == _requestSeq) emit(currentState);
      } finally {
        _isFetching = false;
      }
      return;
    }

    _isFetching = false;
  }

  /// Roll the page counter of the active mode back by one after a failed
  /// next-page request.
  void _rollBackPageCounter() {
    switch (_mode) {
      case _ListMode.search:
        if (_searchPage > 1) _searchPage -= 1;
        break;
      case _ListMode.location:
        if (_locationFallbackToAll) {
          if (_allAdsPage > 1) _allAdsPage -= 1;
        } else if (_currentPage > 1) {
          _currentPage -= 1;
        }
        break;
      default:
        if (_currentPage > 1) _currentPage -= 1;
    }
  }

  /// The original nearby-feed pagination: page through the radius first, then
  /// fall back to the full all-ads feed once nearby results are exhausted.
  Future<void> _fetchNextLocationPage(ListingsLoaded currentState, int seq,
      Emitter<AdvertisementState> emit) async {
    final bool inLocationMode =
        _locationLatitude != null && !_locationFallbackToAll;

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
      if (seq != _requestSeq) return;
      _locationQueryHasNext = result.hasNext;
      emit(ListingsLoaded(
        listings: _mergeDedupe(currentState.listings, result.data),
        hasMore: true,
      ));
    } else if (inLocationMode) {
      // (b) Location feed exhausted → start the full all-ads fallback feed.
      final result = await repository.fetchAllAds(page: 1);
      if (seq != _requestSeq) return;
      _locationFallbackToAll = true;
      _allAdsPage = 1;
      emit(ListingsLoaded(
        listings: _mergeDedupe(currentState.listings, result.data),
        hasMore: result.hasNext,
      ));
    } else {
      // (c) Continue the all-ads fallback feed.
      _allAdsPage += 1;
      final result = await repository.fetchAllAds(page: _allAdsPage);
      if (seq != _requestSeq) return;
      emit(ListingsLoaded(
        listings: _mergeDedupe(currentState.listings, result.data),
        hasMore: result.hasNext,
      ));
    }
  }

  Future<void> _onFetchByCategory(
    FetchByCategory event,
    Emitter<AdvertisementState> emit,
  ) async {
    final seq = ++_requestSeq;
    emit(const AdvertisementState.loading());

    _mode = _ListMode.category;
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
    _searchQuery = null;
    _userId = null;
    _locationLatitude = null;
    _locationLongitude = null;
    _resetLocationPaging();

    try {
      final result = await repository.fetchAllAds(
        page: _currentPage,
        category: _categoryId,
      );
      if (seq != _requestSeq) return;
      emit(AdvertisementState.listingsLoaded(
        listings: result.data,
        hasMore: result.hasNext,
      ));
    } catch (e) {
      if (seq != _requestSeq) return;
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }

  Future<void> _onApplyFilters(
      ApplyFiltersEvent event, Emitter<AdvertisementState> emit) async {
    final seq = ++_requestSeq;
    emit(const AdvertisementState.loading());

    _mode = _ListMode.filters;
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
    _searchQuery = null;
    _userId = null;
    _currentPage = 1;
    // The lat/lng here only biases the filtered query; it must not put the
    // bloc into the nearby-feed pagination mode.
    _resetLocationPaging();

    try {
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
      if (seq != _requestSeq) return;
      emit(AdvertisementState.listingsLoaded(
        listings: result.data,
        hasMore: result.hasNext,
      ));
    } catch (e) {
      if (seq != _requestSeq) return;
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
    final seq = ++_requestSeq;
    emit(const AdvertisementState.loading());
    _mode = _ListMode.location;
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
    _searchQuery = null;
    _userId = null;
    _locationLatitude = event.latitude;
    _locationLongitude = event.longitude;
    _locationFallbackToAll = false;
    _locationQueryHasNext = false;
    _allAdsPage = 1;

    try {
      final result = await repository.fetchAllAds(
        page: _currentPage,
        latitude: event.latitude,
        longitude: event.longitude,
        maxDistance: _locationRadiusKm,
      );
      if (seq != _requestSeq) return;
      _locationQueryHasNext = result.hasNext;
      // Keep hasMore=true so scrolling can widen the radius and then fall back
      // to the full all-ads feed once nearby results are exhausted.
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: true));
    } catch (e) {
      if (seq != _requestSeq) return;
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }

  Future<void> _onSearchAds(
      SearchAdsEvent event, Emitter<AdvertisementState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    final seq = ++_requestSeq;
    emit(const AdvertisementState.loading());
    _mode = _ListMode.search;
    _searchQuery = query;
    _searchPage = 1;
    _currentPage = 1;
    _userId = null;
    _locationLatitude = null;
    _locationLongitude = null;
    _resetLocationPaging();

    try {
      final result = await repository.fetchAllAds(
        page: _searchPage,
        limit: 20,
        search: query,
      );
      if (seq != _requestSeq) return;
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      if (seq != _requestSeq) return;
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
      final seq = ++_requestSeq;
      try {
        _searchPage += 1;
        final result = await repository.fetchAllAds(
          page: _searchPage,
          limit: 20,
          search: _searchQuery,
        );
        if (seq != _requestSeq) return;
        emit(ListingsLoaded(
          listings: _mergeDedupe(currentState.listings, result.data),
          hasMore: result.hasNext,
        ));
      } catch (e) {
        // Keep the already-loaded results instead of wiping them with an error
        // state, and roll the page back so a retry re-requests the same page.
        if (_searchPage > 1) _searchPage -= 1;
        debugPrint('❌ Failed to load next search page: $e');
        if (seq == _requestSeq) emit(currentState);
      } finally {
        _isSearchFetching = false;
      }
    }
  }

  Future<void> _onFetchByUserId(
      FetchByUserIdEvent event, Emitter<AdvertisementState> emit) async {
    final seq = ++_requestSeq;
    emit(const AdvertisementState.loading());
    _mode = _ListMode.user;
    _userId = event.userId;
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
    _searchQuery = null;
    _locationLatitude = null;
    _locationLongitude = null;
    _resetLocationPaging();

    try {
      final result = await repository.fetchAdsByUserId(
        userId: event.userId,
        page: _currentPage,
      );
      if (seq != _requestSeq) return;
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      if (seq != _requestSeq) return;
      // Emit user-friendly message instead of raw exception
      emit(AdvertisementState.error(
          "Unable to load recommendations. Please try again later."));
    }
  }
}
