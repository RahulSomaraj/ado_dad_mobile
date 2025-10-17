// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advertisement_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AdvertisementEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdvertisementEventCopyWith<$Res> {
  factory $AdvertisementEventCopyWith(
          AdvertisementEvent value, $Res Function(AdvertisementEvent) then) =
      _$AdvertisementEventCopyWithImpl<$Res, AdvertisementEvent>;
}

/// @nodoc
class _$AdvertisementEventCopyWithImpl<$Res, $Val extends AdvertisementEvent>
    implements $AdvertisementEventCopyWith<$Res> {
  _$AdvertisementEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$StartedImplCopyWith<$Res> {
  factory _$$StartedImplCopyWith(
          _$StartedImpl value, $Res Function(_$StartedImpl) then) =
      __$$StartedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$StartedImplCopyWithImpl<$Res>
    extends _$AdvertisementEventCopyWithImpl<$Res, _$StartedImpl>
    implements _$$StartedImplCopyWith<$Res> {
  __$$StartedImplCopyWithImpl(
      _$StartedImpl _value, $Res Function(_$StartedImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$StartedImpl implements Started {
  const _$StartedImpl();

  @override
  String toString() {
    return 'AdvertisementEvent.started()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$StartedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) {
    return started?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class Started implements AdvertisementEvent {
  const factory Started() = _$StartedImpl;
}

/// @nodoc
abstract class _$$FetchAllListingsEventImplCopyWith<$Res> {
  factory _$$FetchAllListingsEventImplCopyWith(
          _$FetchAllListingsEventImpl value,
          $Res Function(_$FetchAllListingsEventImpl) then) =
      __$$FetchAllListingsEventImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FetchAllListingsEventImplCopyWithImpl<$Res>
    extends _$AdvertisementEventCopyWithImpl<$Res, _$FetchAllListingsEventImpl>
    implements _$$FetchAllListingsEventImplCopyWith<$Res> {
  __$$FetchAllListingsEventImplCopyWithImpl(_$FetchAllListingsEventImpl _value,
      $Res Function(_$FetchAllListingsEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FetchAllListingsEventImpl implements FetchAllListingsEvent {
  const _$FetchAllListingsEventImpl();

  @override
  String toString() {
    return 'AdvertisementEvent.fetchAllListings()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FetchAllListingsEventImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) {
    return fetchAllListings();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) {
    return fetchAllListings?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) {
    if (fetchAllListings != null) {
      return fetchAllListings();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) {
    return fetchAllListings(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) {
    return fetchAllListings?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) {
    if (fetchAllListings != null) {
      return fetchAllListings(this);
    }
    return orElse();
  }
}

abstract class FetchAllListingsEvent implements AdvertisementEvent {
  const factory FetchAllListingsEvent() = _$FetchAllListingsEventImpl;
}

/// @nodoc
abstract class _$$FetchNextPageEventImplCopyWith<$Res> {
  factory _$$FetchNextPageEventImplCopyWith(_$FetchNextPageEventImpl value,
          $Res Function(_$FetchNextPageEventImpl) then) =
      __$$FetchNextPageEventImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FetchNextPageEventImplCopyWithImpl<$Res>
    extends _$AdvertisementEventCopyWithImpl<$Res, _$FetchNextPageEventImpl>
    implements _$$FetchNextPageEventImplCopyWith<$Res> {
  __$$FetchNextPageEventImplCopyWithImpl(_$FetchNextPageEventImpl _value,
      $Res Function(_$FetchNextPageEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FetchNextPageEventImpl implements FetchNextPageEvent {
  const _$FetchNextPageEventImpl();

  @override
  String toString() {
    return 'AdvertisementEvent.fetchNextPage()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$FetchNextPageEventImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) {
    return fetchNextPage();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) {
    return fetchNextPage?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) {
    if (fetchNextPage != null) {
      return fetchNextPage();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) {
    return fetchNextPage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) {
    return fetchNextPage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) {
    if (fetchNextPage != null) {
      return fetchNextPage(this);
    }
    return orElse();
  }
}

abstract class FetchNextPageEvent implements AdvertisementEvent {
  const factory FetchNextPageEvent() = _$FetchNextPageEventImpl;
}

/// @nodoc
abstract class _$$FetchByCategoryImplCopyWith<$Res> {
  factory _$$FetchByCategoryImplCopyWith(_$FetchByCategoryImpl value,
          $Res Function(_$FetchByCategoryImpl) then) =
      __$$FetchByCategoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String categoryId});
}

/// @nodoc
class __$$FetchByCategoryImplCopyWithImpl<$Res>
    extends _$AdvertisementEventCopyWithImpl<$Res, _$FetchByCategoryImpl>
    implements _$$FetchByCategoryImplCopyWith<$Res> {
  __$$FetchByCategoryImplCopyWithImpl(
      _$FetchByCategoryImpl _value, $Res Function(_$FetchByCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
  }) {
    return _then(_$FetchByCategoryImpl(
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$FetchByCategoryImpl implements FetchByCategory {
  const _$FetchByCategoryImpl({required this.categoryId});

  @override
  final String categoryId;

  @override
  String toString() {
    return 'AdvertisementEvent.fetchByCategory(categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FetchByCategoryImpl &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, categoryId);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FetchByCategoryImplCopyWith<_$FetchByCategoryImpl> get copyWith =>
      __$$FetchByCategoryImplCopyWithImpl<_$FetchByCategoryImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) {
    return fetchByCategory(categoryId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) {
    return fetchByCategory?.call(categoryId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) {
    if (fetchByCategory != null) {
      return fetchByCategory(categoryId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) {
    return fetchByCategory(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) {
    return fetchByCategory?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) {
    if (fetchByCategory != null) {
      return fetchByCategory(this);
    }
    return orElse();
  }
}

abstract class FetchByCategory implements AdvertisementEvent {
  const factory FetchByCategory({required final String categoryId}) =
      _$FetchByCategoryImpl;

  String get categoryId;

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FetchByCategoryImplCopyWith<_$FetchByCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApplyFiltersEventImplCopyWith<$Res> {
  factory _$$ApplyFiltersEventImplCopyWith(_$ApplyFiltersEventImpl value,
          $Res Function(_$ApplyFiltersEventImpl) then) =
      __$$ApplyFiltersEventImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String? categoryId,
      int? minYear,
      int? maxYear,
      List<String>? manufacturerIds,
      List<String>? modelIds,
      List<String>? fuelTypeIds,
      List<String>? transmissionTypeIds,
      int? minPrice,
      int? maxPrice,
      List<String>? propertyTypes,
      int? minBedrooms,
      int? maxBedrooms,
      int? minArea,
      int? maxArea,
      bool? isFurnished,
      bool? hasParking});
}

/// @nodoc
class __$$ApplyFiltersEventImplCopyWithImpl<$Res>
    extends _$AdvertisementEventCopyWithImpl<$Res, _$ApplyFiltersEventImpl>
    implements _$$ApplyFiltersEventImplCopyWith<$Res> {
  __$$ApplyFiltersEventImplCopyWithImpl(_$ApplyFiltersEventImpl _value,
      $Res Function(_$ApplyFiltersEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = freezed,
    Object? minYear = freezed,
    Object? maxYear = freezed,
    Object? manufacturerIds = freezed,
    Object? modelIds = freezed,
    Object? fuelTypeIds = freezed,
    Object? transmissionTypeIds = freezed,
    Object? minPrice = freezed,
    Object? maxPrice = freezed,
    Object? propertyTypes = freezed,
    Object? minBedrooms = freezed,
    Object? maxBedrooms = freezed,
    Object? minArea = freezed,
    Object? maxArea = freezed,
    Object? isFurnished = freezed,
    Object? hasParking = freezed,
  }) {
    return _then(_$ApplyFiltersEventImpl(
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      minYear: freezed == minYear
          ? _value.minYear
          : minYear // ignore: cast_nullable_to_non_nullable
              as int?,
      maxYear: freezed == maxYear
          ? _value.maxYear
          : maxYear // ignore: cast_nullable_to_non_nullable
              as int?,
      manufacturerIds: freezed == manufacturerIds
          ? _value._manufacturerIds
          : manufacturerIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      modelIds: freezed == modelIds
          ? _value._modelIds
          : modelIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      fuelTypeIds: freezed == fuelTypeIds
          ? _value._fuelTypeIds
          : fuelTypeIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      transmissionTypeIds: freezed == transmissionTypeIds
          ? _value._transmissionTypeIds
          : transmissionTypeIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      minPrice: freezed == minPrice
          ? _value.minPrice
          : minPrice // ignore: cast_nullable_to_non_nullable
              as int?,
      maxPrice: freezed == maxPrice
          ? _value.maxPrice
          : maxPrice // ignore: cast_nullable_to_non_nullable
              as int?,
      propertyTypes: freezed == propertyTypes
          ? _value._propertyTypes
          : propertyTypes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      minBedrooms: freezed == minBedrooms
          ? _value.minBedrooms
          : minBedrooms // ignore: cast_nullable_to_non_nullable
              as int?,
      maxBedrooms: freezed == maxBedrooms
          ? _value.maxBedrooms
          : maxBedrooms // ignore: cast_nullable_to_non_nullable
              as int?,
      minArea: freezed == minArea
          ? _value.minArea
          : minArea // ignore: cast_nullable_to_non_nullable
              as int?,
      maxArea: freezed == maxArea
          ? _value.maxArea
          : maxArea // ignore: cast_nullable_to_non_nullable
              as int?,
      isFurnished: freezed == isFurnished
          ? _value.isFurnished
          : isFurnished // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasParking: freezed == hasParking
          ? _value.hasParking
          : hasParking // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

class _$ApplyFiltersEventImpl implements ApplyFiltersEvent {
  const _$ApplyFiltersEventImpl(
      {this.categoryId,
      this.minYear,
      this.maxYear,
      final List<String>? manufacturerIds,
      final List<String>? modelIds,
      final List<String>? fuelTypeIds,
      final List<String>? transmissionTypeIds,
      this.minPrice,
      this.maxPrice,
      final List<String>? propertyTypes,
      this.minBedrooms,
      this.maxBedrooms,
      this.minArea,
      this.maxArea,
      this.isFurnished,
      this.hasParking})
      : _manufacturerIds = manufacturerIds,
        _modelIds = modelIds,
        _fuelTypeIds = fuelTypeIds,
        _transmissionTypeIds = transmissionTypeIds,
        _propertyTypes = propertyTypes;

  @override
  final String? categoryId;
  @override
  final int? minYear;
  @override
  final int? maxYear;
  final List<String>? _manufacturerIds;
  @override
  List<String>? get manufacturerIds {
    final value = _manufacturerIds;
    if (value == null) return null;
    if (_manufacturerIds is EqualUnmodifiableListView) return _manufacturerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _modelIds;
  @override
  List<String>? get modelIds {
    final value = _modelIds;
    if (value == null) return null;
    if (_modelIds is EqualUnmodifiableListView) return _modelIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _fuelTypeIds;
  @override
  List<String>? get fuelTypeIds {
    final value = _fuelTypeIds;
    if (value == null) return null;
    if (_fuelTypeIds is EqualUnmodifiableListView) return _fuelTypeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _transmissionTypeIds;
  @override
  List<String>? get transmissionTypeIds {
    final value = _transmissionTypeIds;
    if (value == null) return null;
    if (_transmissionTypeIds is EqualUnmodifiableListView)
      return _transmissionTypeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? minPrice;
  @override
  final int? maxPrice;
// Property-specific filters
  final List<String>? _propertyTypes;
// Property-specific filters
  @override
  List<String>? get propertyTypes {
    final value = _propertyTypes;
    if (value == null) return null;
    if (_propertyTypes is EqualUnmodifiableListView) return _propertyTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? minBedrooms;
  @override
  final int? maxBedrooms;
  @override
  final int? minArea;
  @override
  final int? maxArea;
  @override
  final bool? isFurnished;
  @override
  final bool? hasParking;

  @override
  String toString() {
    return 'AdvertisementEvent.applyFilters(categoryId: $categoryId, minYear: $minYear, maxYear: $maxYear, manufacturerIds: $manufacturerIds, modelIds: $modelIds, fuelTypeIds: $fuelTypeIds, transmissionTypeIds: $transmissionTypeIds, minPrice: $minPrice, maxPrice: $maxPrice, propertyTypes: $propertyTypes, minBedrooms: $minBedrooms, maxBedrooms: $maxBedrooms, minArea: $minArea, maxArea: $maxArea, isFurnished: $isFurnished, hasParking: $hasParking)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplyFiltersEventImpl &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.minYear, minYear) || other.minYear == minYear) &&
            (identical(other.maxYear, maxYear) || other.maxYear == maxYear) &&
            const DeepCollectionEquality()
                .equals(other._manufacturerIds, _manufacturerIds) &&
            const DeepCollectionEquality().equals(other._modelIds, _modelIds) &&
            const DeepCollectionEquality()
                .equals(other._fuelTypeIds, _fuelTypeIds) &&
            const DeepCollectionEquality()
                .equals(other._transmissionTypeIds, _transmissionTypeIds) &&
            (identical(other.minPrice, minPrice) ||
                other.minPrice == minPrice) &&
            (identical(other.maxPrice, maxPrice) ||
                other.maxPrice == maxPrice) &&
            const DeepCollectionEquality()
                .equals(other._propertyTypes, _propertyTypes) &&
            (identical(other.minBedrooms, minBedrooms) ||
                other.minBedrooms == minBedrooms) &&
            (identical(other.maxBedrooms, maxBedrooms) ||
                other.maxBedrooms == maxBedrooms) &&
            (identical(other.minArea, minArea) || other.minArea == minArea) &&
            (identical(other.maxArea, maxArea) || other.maxArea == maxArea) &&
            (identical(other.isFurnished, isFurnished) ||
                other.isFurnished == isFurnished) &&
            (identical(other.hasParking, hasParking) ||
                other.hasParking == hasParking));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      categoryId,
      minYear,
      maxYear,
      const DeepCollectionEquality().hash(_manufacturerIds),
      const DeepCollectionEquality().hash(_modelIds),
      const DeepCollectionEquality().hash(_fuelTypeIds),
      const DeepCollectionEquality().hash(_transmissionTypeIds),
      minPrice,
      maxPrice,
      const DeepCollectionEquality().hash(_propertyTypes),
      minBedrooms,
      maxBedrooms,
      minArea,
      maxArea,
      isFurnished,
      hasParking);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplyFiltersEventImplCopyWith<_$ApplyFiltersEventImpl> get copyWith =>
      __$$ApplyFiltersEventImplCopyWithImpl<_$ApplyFiltersEventImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) {
    return applyFilters(
        categoryId,
        minYear,
        maxYear,
        manufacturerIds,
        modelIds,
        fuelTypeIds,
        transmissionTypeIds,
        minPrice,
        maxPrice,
        propertyTypes,
        minBedrooms,
        maxBedrooms,
        minArea,
        maxArea,
        isFurnished,
        hasParking);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) {
    return applyFilters?.call(
        categoryId,
        minYear,
        maxYear,
        manufacturerIds,
        modelIds,
        fuelTypeIds,
        transmissionTypeIds,
        minPrice,
        maxPrice,
        propertyTypes,
        minBedrooms,
        maxBedrooms,
        minArea,
        maxArea,
        isFurnished,
        hasParking);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) {
    if (applyFilters != null) {
      return applyFilters(
          categoryId,
          minYear,
          maxYear,
          manufacturerIds,
          modelIds,
          fuelTypeIds,
          transmissionTypeIds,
          minPrice,
          maxPrice,
          propertyTypes,
          minBedrooms,
          maxBedrooms,
          minArea,
          maxArea,
          isFurnished,
          hasParking);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) {
    return applyFilters(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) {
    return applyFilters?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) {
    if (applyFilters != null) {
      return applyFilters(this);
    }
    return orElse();
  }
}

abstract class ApplyFiltersEvent implements AdvertisementEvent {
  const factory ApplyFiltersEvent(
      {final String? categoryId,
      final int? minYear,
      final int? maxYear,
      final List<String>? manufacturerIds,
      final List<String>? modelIds,
      final List<String>? fuelTypeIds,
      final List<String>? transmissionTypeIds,
      final int? minPrice,
      final int? maxPrice,
      final List<String>? propertyTypes,
      final int? minBedrooms,
      final int? maxBedrooms,
      final int? minArea,
      final int? maxArea,
      final bool? isFurnished,
      final bool? hasParking}) = _$ApplyFiltersEventImpl;

  String? get categoryId;
  int? get minYear;
  int? get maxYear;
  List<String>? get manufacturerIds;
  List<String>? get modelIds;
  List<String>? get fuelTypeIds;
  List<String>? get transmissionTypeIds;
  int? get minPrice;
  int? get maxPrice; // Property-specific filters
  List<String>? get propertyTypes;
  int? get minBedrooms;
  int? get maxBedrooms;
  int? get minArea;
  int? get maxArea;
  bool? get isFurnished;
  bool? get hasParking;

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplyFiltersEventImplCopyWith<_$ApplyFiltersEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateAdFavoriteStatusEventImplCopyWith<$Res> {
  factory _$$UpdateAdFavoriteStatusEventImplCopyWith(
          _$UpdateAdFavoriteStatusEventImpl value,
          $Res Function(_$UpdateAdFavoriteStatusEventImpl) then) =
      __$$UpdateAdFavoriteStatusEventImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String adId, bool isFavorited, String? favoriteId});
}

/// @nodoc
class __$$UpdateAdFavoriteStatusEventImplCopyWithImpl<$Res>
    extends _$AdvertisementEventCopyWithImpl<$Res,
        _$UpdateAdFavoriteStatusEventImpl>
    implements _$$UpdateAdFavoriteStatusEventImplCopyWith<$Res> {
  __$$UpdateAdFavoriteStatusEventImplCopyWithImpl(
      _$UpdateAdFavoriteStatusEventImpl _value,
      $Res Function(_$UpdateAdFavoriteStatusEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adId = null,
    Object? isFavorited = null,
    Object? favoriteId = freezed,
  }) {
    return _then(_$UpdateAdFavoriteStatusEventImpl(
      adId: null == adId
          ? _value.adId
          : adId // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorited: null == isFavorited
          ? _value.isFavorited
          : isFavorited // ignore: cast_nullable_to_non_nullable
              as bool,
      favoriteId: freezed == favoriteId
          ? _value.favoriteId
          : favoriteId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UpdateAdFavoriteStatusEventImpl implements UpdateAdFavoriteStatusEvent {
  const _$UpdateAdFavoriteStatusEventImpl(
      {required this.adId, required this.isFavorited, this.favoriteId});

  @override
  final String adId;
  @override
  final bool isFavorited;
  @override
  final String? favoriteId;

  @override
  String toString() {
    return 'AdvertisementEvent.updateAdFavoriteStatus(adId: $adId, isFavorited: $isFavorited, favoriteId: $favoriteId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateAdFavoriteStatusEventImpl &&
            (identical(other.adId, adId) || other.adId == adId) &&
            (identical(other.isFavorited, isFavorited) ||
                other.isFavorited == isFavorited) &&
            (identical(other.favoriteId, favoriteId) ||
                other.favoriteId == favoriteId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, adId, isFavorited, favoriteId);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateAdFavoriteStatusEventImplCopyWith<_$UpdateAdFavoriteStatusEventImpl>
      get copyWith => __$$UpdateAdFavoriteStatusEventImplCopyWithImpl<
          _$UpdateAdFavoriteStatusEventImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) {
    return updateAdFavoriteStatus(adId, isFavorited, favoriteId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) {
    return updateAdFavoriteStatus?.call(adId, isFavorited, favoriteId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) {
    if (updateAdFavoriteStatus != null) {
      return updateAdFavoriteStatus(adId, isFavorited, favoriteId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) {
    return updateAdFavoriteStatus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) {
    return updateAdFavoriteStatus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) {
    if (updateAdFavoriteStatus != null) {
      return updateAdFavoriteStatus(this);
    }
    return orElse();
  }
}

abstract class UpdateAdFavoriteStatusEvent implements AdvertisementEvent {
  const factory UpdateAdFavoriteStatusEvent(
      {required final String adId,
      required final bool isFavorited,
      final String? favoriteId}) = _$UpdateAdFavoriteStatusEventImpl;

  String get adId;
  bool get isFavorited;
  String? get favoriteId;

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateAdFavoriteStatusEventImplCopyWith<_$UpdateAdFavoriteStatusEventImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchByLocationEventImplCopyWith<$Res> {
  factory _$$SearchByLocationEventImplCopyWith(
          _$SearchByLocationEventImpl value,
          $Res Function(_$SearchByLocationEventImpl) then) =
      __$$SearchByLocationEventImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class __$$SearchByLocationEventImplCopyWithImpl<$Res>
    extends _$AdvertisementEventCopyWithImpl<$Res, _$SearchByLocationEventImpl>
    implements _$$SearchByLocationEventImplCopyWith<$Res> {
  __$$SearchByLocationEventImplCopyWithImpl(_$SearchByLocationEventImpl _value,
      $Res Function(_$SearchByLocationEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(_$SearchByLocationEventImpl(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$SearchByLocationEventImpl implements SearchByLocationEvent {
  const _$SearchByLocationEventImpl(
      {required this.latitude, required this.longitude});

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'AdvertisementEvent.searchByLocation(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchByLocationEventImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude);

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchByLocationEventImplCopyWith<_$SearchByLocationEventImpl>
      get copyWith => __$$SearchByLocationEventImplCopyWithImpl<
          _$SearchByLocationEventImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function() fetchAllListings,
    required TResult Function() fetchNextPage,
    required TResult Function(String categoryId) fetchByCategory,
    required TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)
        applyFilters,
    required TResult Function(String adId, bool isFavorited, String? favoriteId)
        updateAdFavoriteStatus,
    required TResult Function(double latitude, double longitude)
        searchByLocation,
  }) {
    return searchByLocation(latitude, longitude);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
    TResult? Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult? Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult? Function(double latitude, double longitude)? searchByLocation,
  }) {
    return searchByLocation?.call(latitude, longitude);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    TResult Function(
            String? categoryId,
            int? minYear,
            int? maxYear,
            List<String>? manufacturerIds,
            List<String>? modelIds,
            List<String>? fuelTypeIds,
            List<String>? transmissionTypeIds,
            int? minPrice,
            int? maxPrice,
            List<String>? propertyTypes,
            int? minBedrooms,
            int? maxBedrooms,
            int? minArea,
            int? maxArea,
            bool? isFurnished,
            bool? hasParking)?
        applyFilters,
    TResult Function(String adId, bool isFavorited, String? favoriteId)?
        updateAdFavoriteStatus,
    TResult Function(double latitude, double longitude)? searchByLocation,
    required TResult orElse(),
  }) {
    if (searchByLocation != null) {
      return searchByLocation(latitude, longitude);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
    required TResult Function(ApplyFiltersEvent value) applyFilters,
    required TResult Function(UpdateAdFavoriteStatusEvent value)
        updateAdFavoriteStatus,
    required TResult Function(SearchByLocationEvent value) searchByLocation,
  }) {
    return searchByLocation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
    TResult? Function(ApplyFiltersEvent value)? applyFilters,
    TResult? Function(UpdateAdFavoriteStatusEvent value)?
        updateAdFavoriteStatus,
    TResult? Function(SearchByLocationEvent value)? searchByLocation,
  }) {
    return searchByLocation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
    TResult Function(ApplyFiltersEvent value)? applyFilters,
    TResult Function(UpdateAdFavoriteStatusEvent value)? updateAdFavoriteStatus,
    TResult Function(SearchByLocationEvent value)? searchByLocation,
    required TResult orElse(),
  }) {
    if (searchByLocation != null) {
      return searchByLocation(this);
    }
    return orElse();
  }
}

abstract class SearchByLocationEvent implements AdvertisementEvent {
  const factory SearchByLocationEvent(
      {required final double latitude,
      required final double longitude}) = _$SearchByLocationEventImpl;

  double get latitude;
  double get longitude;

  /// Create a copy of AdvertisementEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchByLocationEventImplCopyWith<_$SearchByLocationEventImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AdvertisementState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<AddModel> listings, bool hasMore)
        listingsLoaded,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AdvertisementInitial value) initial,
    required TResult Function(AdvertisementLoading value) loading,
    required TResult Function(ListingsLoaded value) listingsLoaded,
    required TResult Function(AdvertisementError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AdvertisementInitial value)? initial,
    TResult? Function(AdvertisementLoading value)? loading,
    TResult? Function(ListingsLoaded value)? listingsLoaded,
    TResult? Function(AdvertisementError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AdvertisementInitial value)? initial,
    TResult Function(AdvertisementLoading value)? loading,
    TResult Function(ListingsLoaded value)? listingsLoaded,
    TResult Function(AdvertisementError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdvertisementStateCopyWith<$Res> {
  factory $AdvertisementStateCopyWith(
          AdvertisementState value, $Res Function(AdvertisementState) then) =
      _$AdvertisementStateCopyWithImpl<$Res, AdvertisementState>;
}

/// @nodoc
class _$AdvertisementStateCopyWithImpl<$Res, $Val extends AdvertisementState>
    implements $AdvertisementStateCopyWith<$Res> {
  _$AdvertisementStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AdvertisementInitialImplCopyWith<$Res> {
  factory _$$AdvertisementInitialImplCopyWith(_$AdvertisementInitialImpl value,
          $Res Function(_$AdvertisementInitialImpl) then) =
      __$$AdvertisementInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AdvertisementInitialImplCopyWithImpl<$Res>
    extends _$AdvertisementStateCopyWithImpl<$Res, _$AdvertisementInitialImpl>
    implements _$$AdvertisementInitialImplCopyWith<$Res> {
  __$$AdvertisementInitialImplCopyWithImpl(_$AdvertisementInitialImpl _value,
      $Res Function(_$AdvertisementInitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AdvertisementInitialImpl implements AdvertisementInitial {
  const _$AdvertisementInitialImpl();

  @override
  String toString() {
    return 'AdvertisementState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdvertisementInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<AddModel> listings, bool hasMore)
        listingsLoaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AdvertisementInitial value) initial,
    required TResult Function(AdvertisementLoading value) loading,
    required TResult Function(ListingsLoaded value) listingsLoaded,
    required TResult Function(AdvertisementError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AdvertisementInitial value)? initial,
    TResult? Function(AdvertisementLoading value)? loading,
    TResult? Function(ListingsLoaded value)? listingsLoaded,
    TResult? Function(AdvertisementError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AdvertisementInitial value)? initial,
    TResult Function(AdvertisementLoading value)? loading,
    TResult Function(ListingsLoaded value)? listingsLoaded,
    TResult Function(AdvertisementError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class AdvertisementInitial implements AdvertisementState {
  const factory AdvertisementInitial() = _$AdvertisementInitialImpl;
}

/// @nodoc
abstract class _$$AdvertisementLoadingImplCopyWith<$Res> {
  factory _$$AdvertisementLoadingImplCopyWith(_$AdvertisementLoadingImpl value,
          $Res Function(_$AdvertisementLoadingImpl) then) =
      __$$AdvertisementLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AdvertisementLoadingImplCopyWithImpl<$Res>
    extends _$AdvertisementStateCopyWithImpl<$Res, _$AdvertisementLoadingImpl>
    implements _$$AdvertisementLoadingImplCopyWith<$Res> {
  __$$AdvertisementLoadingImplCopyWithImpl(_$AdvertisementLoadingImpl _value,
      $Res Function(_$AdvertisementLoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AdvertisementLoadingImpl implements AdvertisementLoading {
  const _$AdvertisementLoadingImpl();

  @override
  String toString() {
    return 'AdvertisementState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdvertisementLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<AddModel> listings, bool hasMore)
        listingsLoaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AdvertisementInitial value) initial,
    required TResult Function(AdvertisementLoading value) loading,
    required TResult Function(ListingsLoaded value) listingsLoaded,
    required TResult Function(AdvertisementError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AdvertisementInitial value)? initial,
    TResult? Function(AdvertisementLoading value)? loading,
    TResult? Function(ListingsLoaded value)? listingsLoaded,
    TResult? Function(AdvertisementError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AdvertisementInitial value)? initial,
    TResult Function(AdvertisementLoading value)? loading,
    TResult Function(ListingsLoaded value)? listingsLoaded,
    TResult Function(AdvertisementError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class AdvertisementLoading implements AdvertisementState {
  const factory AdvertisementLoading() = _$AdvertisementLoadingImpl;
}

/// @nodoc
abstract class _$$ListingsLoadedImplCopyWith<$Res> {
  factory _$$ListingsLoadedImplCopyWith(_$ListingsLoadedImpl value,
          $Res Function(_$ListingsLoadedImpl) then) =
      __$$ListingsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<AddModel> listings, bool hasMore});
}

/// @nodoc
class __$$ListingsLoadedImplCopyWithImpl<$Res>
    extends _$AdvertisementStateCopyWithImpl<$Res, _$ListingsLoadedImpl>
    implements _$$ListingsLoadedImplCopyWith<$Res> {
  __$$ListingsLoadedImplCopyWithImpl(
      _$ListingsLoadedImpl _value, $Res Function(_$ListingsLoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? listings = null,
    Object? hasMore = null,
  }) {
    return _then(_$ListingsLoadedImpl(
      listings: null == listings
          ? _value._listings
          : listings // ignore: cast_nullable_to_non_nullable
              as List<AddModel>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ListingsLoadedImpl implements ListingsLoaded {
  const _$ListingsLoadedImpl(
      {required final List<AddModel> listings, required this.hasMore})
      : _listings = listings;

  final List<AddModel> _listings;
  @override
  List<AddModel> get listings {
    if (_listings is EqualUnmodifiableListView) return _listings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listings);
  }

  @override
  final bool hasMore;

  @override
  String toString() {
    return 'AdvertisementState.listingsLoaded(listings: $listings, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListingsLoadedImpl &&
            const DeepCollectionEquality().equals(other._listings, _listings) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_listings), hasMore);

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ListingsLoadedImplCopyWith<_$ListingsLoadedImpl> get copyWith =>
      __$$ListingsLoadedImplCopyWithImpl<_$ListingsLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<AddModel> listings, bool hasMore)
        listingsLoaded,
    required TResult Function(String message) error,
  }) {
    return listingsLoaded(listings, hasMore);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult? Function(String message)? error,
  }) {
    return listingsLoaded?.call(listings, hasMore);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (listingsLoaded != null) {
      return listingsLoaded(listings, hasMore);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AdvertisementInitial value) initial,
    required TResult Function(AdvertisementLoading value) loading,
    required TResult Function(ListingsLoaded value) listingsLoaded,
    required TResult Function(AdvertisementError value) error,
  }) {
    return listingsLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AdvertisementInitial value)? initial,
    TResult? Function(AdvertisementLoading value)? loading,
    TResult? Function(ListingsLoaded value)? listingsLoaded,
    TResult? Function(AdvertisementError value)? error,
  }) {
    return listingsLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AdvertisementInitial value)? initial,
    TResult Function(AdvertisementLoading value)? loading,
    TResult Function(ListingsLoaded value)? listingsLoaded,
    TResult Function(AdvertisementError value)? error,
    required TResult orElse(),
  }) {
    if (listingsLoaded != null) {
      return listingsLoaded(this);
    }
    return orElse();
  }
}

abstract class ListingsLoaded implements AdvertisementState {
  const factory ListingsLoaded(
      {required final List<AddModel> listings,
      required final bool hasMore}) = _$ListingsLoadedImpl;

  List<AddModel> get listings;
  bool get hasMore;

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ListingsLoadedImplCopyWith<_$ListingsLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AdvertisementErrorImplCopyWith<$Res> {
  factory _$$AdvertisementErrorImplCopyWith(_$AdvertisementErrorImpl value,
          $Res Function(_$AdvertisementErrorImpl) then) =
      __$$AdvertisementErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AdvertisementErrorImplCopyWithImpl<$Res>
    extends _$AdvertisementStateCopyWithImpl<$Res, _$AdvertisementErrorImpl>
    implements _$$AdvertisementErrorImplCopyWith<$Res> {
  __$$AdvertisementErrorImplCopyWithImpl(_$AdvertisementErrorImpl _value,
      $Res Function(_$AdvertisementErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$AdvertisementErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AdvertisementErrorImpl implements AdvertisementError {
  const _$AdvertisementErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AdvertisementState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdvertisementErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdvertisementErrorImplCopyWith<_$AdvertisementErrorImpl> get copyWith =>
      __$$AdvertisementErrorImplCopyWithImpl<_$AdvertisementErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<AddModel> listings, bool hasMore)
        listingsLoaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AddModel> listings, bool hasMore)? listingsLoaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AdvertisementInitial value) initial,
    required TResult Function(AdvertisementLoading value) loading,
    required TResult Function(ListingsLoaded value) listingsLoaded,
    required TResult Function(AdvertisementError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AdvertisementInitial value)? initial,
    TResult? Function(AdvertisementLoading value)? loading,
    TResult? Function(ListingsLoaded value)? listingsLoaded,
    TResult? Function(AdvertisementError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AdvertisementInitial value)? initial,
    TResult Function(AdvertisementLoading value)? loading,
    TResult Function(ListingsLoaded value)? listingsLoaded,
    TResult Function(AdvertisementError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class AdvertisementError implements AdvertisementState {
  const factory AdvertisementError(final String message) =
      _$AdvertisementErrorImpl;

  String get message;

  /// Create a copy of AdvertisementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdvertisementErrorImplCopyWith<_$AdvertisementErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
