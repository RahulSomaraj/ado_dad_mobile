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
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function()? fetchAllListings,
    TResult? Function()? fetchNextPage,
    TResult? Function(String categoryId)? fetchByCategory,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function()? fetchAllListings,
    TResult Function()? fetchNextPage,
    TResult Function(String categoryId)? fetchByCategory,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
    required TResult Function(FetchAllListingsEvent value) fetchAllListings,
    required TResult Function(FetchNextPageEvent value) fetchNextPage,
    required TResult Function(FetchByCategory value) fetchByCategory,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Started value)? started,
    TResult? Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult? Function(FetchNextPageEvent value)? fetchNextPage,
    TResult? Function(FetchByCategory value)? fetchByCategory,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    TResult Function(FetchAllListingsEvent value)? fetchAllListings,
    TResult Function(FetchNextPageEvent value)? fetchNextPage,
    TResult Function(FetchByCategory value)? fetchByCategory,
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
