// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seller_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SellerEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(AdvertisementModel advertisement)
        addAdvertisement,
    required TResult Function(Uint8List image) uploadImageToS3,
    required TResult Function(String adId, List<String> imageUrls)
        updateImageUrls,
    required TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)
        updatePersonalInfo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult? Function(Uint8List image)? uploadImageToS3,
    TResult? Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult? Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult Function(Uint8List image)? uploadImageToS3,
    TResult Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(_AddAdvertisement value) addAdvertisement,
    required TResult Function(_UploadImageToS3 value) uploadImageToS3,
    required TResult Function(_UpdateImageUrls value) updateImageUrls,
    required TResult Function(_UpdatePersonalInfo value) updatePersonalInfo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Started value)? started,
    TResult? Function(_AddAdvertisement value)? addAdvertisement,
    TResult? Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult? Function(_UpdateImageUrls value)? updateImageUrls,
    TResult? Function(_UpdatePersonalInfo value)? updatePersonalInfo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(_AddAdvertisement value)? addAdvertisement,
    TResult Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult Function(_UpdateImageUrls value)? updateImageUrls,
    TResult Function(_UpdatePersonalInfo value)? updatePersonalInfo,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SellerEventCopyWith<$Res> {
  factory $SellerEventCopyWith(
          SellerEvent value, $Res Function(SellerEvent) then) =
      _$SellerEventCopyWithImpl<$Res, SellerEvent>;
}

/// @nodoc
class _$SellerEventCopyWithImpl<$Res, $Val extends SellerEvent>
    implements $SellerEventCopyWith<$Res> {
  _$SellerEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SellerEvent
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
    extends _$SellerEventCopyWithImpl<$Res, _$StartedImpl>
    implements _$$StartedImplCopyWith<$Res> {
  __$$StartedImplCopyWithImpl(
      _$StartedImpl _value, $Res Function(_$StartedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$StartedImpl implements _Started {
  const _$StartedImpl();

  @override
  String toString() {
    return 'SellerEvent.started()';
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
    required TResult Function(AdvertisementModel advertisement)
        addAdvertisement,
    required TResult Function(Uint8List image) uploadImageToS3,
    required TResult Function(String adId, List<String> imageUrls)
        updateImageUrls,
    required TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)
        updatePersonalInfo,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult? Function(Uint8List image)? uploadImageToS3,
    TResult? Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult? Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
  }) {
    return started?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult Function(Uint8List image)? uploadImageToS3,
    TResult Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
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
    required TResult Function(_Started value) started,
    required TResult Function(_AddAdvertisement value) addAdvertisement,
    required TResult Function(_UploadImageToS3 value) uploadImageToS3,
    required TResult Function(_UpdateImageUrls value) updateImageUrls,
    required TResult Function(_UpdatePersonalInfo value) updatePersonalInfo,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Started value)? started,
    TResult? Function(_AddAdvertisement value)? addAdvertisement,
    TResult? Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult? Function(_UpdateImageUrls value)? updateImageUrls,
    TResult? Function(_UpdatePersonalInfo value)? updatePersonalInfo,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(_AddAdvertisement value)? addAdvertisement,
    TResult Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult Function(_UpdateImageUrls value)? updateImageUrls,
    TResult Function(_UpdatePersonalInfo value)? updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class _Started implements SellerEvent {
  const factory _Started() = _$StartedImpl;
}

/// @nodoc
abstract class _$$AddAdvertisementImplCopyWith<$Res> {
  factory _$$AddAdvertisementImplCopyWith(_$AddAdvertisementImpl value,
          $Res Function(_$AddAdvertisementImpl) then) =
      __$$AddAdvertisementImplCopyWithImpl<$Res>;
  @useResult
  $Res call({AdvertisementModel advertisement});
}

/// @nodoc
class __$$AddAdvertisementImplCopyWithImpl<$Res>
    extends _$SellerEventCopyWithImpl<$Res, _$AddAdvertisementImpl>
    implements _$$AddAdvertisementImplCopyWith<$Res> {
  __$$AddAdvertisementImplCopyWithImpl(_$AddAdvertisementImpl _value,
      $Res Function(_$AddAdvertisementImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? advertisement = null,
  }) {
    return _then(_$AddAdvertisementImpl(
      null == advertisement
          ? _value.advertisement
          : advertisement // ignore: cast_nullable_to_non_nullable
              as AdvertisementModel,
    ));
  }
}

/// @nodoc

class _$AddAdvertisementImpl implements _AddAdvertisement {
  const _$AddAdvertisementImpl(this.advertisement);

  @override
  final AdvertisementModel advertisement;

  @override
  String toString() {
    return 'SellerEvent.addAdvertisement(advertisement: $advertisement)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddAdvertisementImpl &&
            (identical(other.advertisement, advertisement) ||
                other.advertisement == advertisement));
  }

  @override
  int get hashCode => Object.hash(runtimeType, advertisement);

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddAdvertisementImplCopyWith<_$AddAdvertisementImpl> get copyWith =>
      __$$AddAdvertisementImplCopyWithImpl<_$AddAdvertisementImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(AdvertisementModel advertisement)
        addAdvertisement,
    required TResult Function(Uint8List image) uploadImageToS3,
    required TResult Function(String adId, List<String> imageUrls)
        updateImageUrls,
    required TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)
        updatePersonalInfo,
  }) {
    return addAdvertisement(advertisement);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult? Function(Uint8List image)? uploadImageToS3,
    TResult? Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult? Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
  }) {
    return addAdvertisement?.call(advertisement);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult Function(Uint8List image)? uploadImageToS3,
    TResult Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (addAdvertisement != null) {
      return addAdvertisement(advertisement);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(_AddAdvertisement value) addAdvertisement,
    required TResult Function(_UploadImageToS3 value) uploadImageToS3,
    required TResult Function(_UpdateImageUrls value) updateImageUrls,
    required TResult Function(_UpdatePersonalInfo value) updatePersonalInfo,
  }) {
    return addAdvertisement(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Started value)? started,
    TResult? Function(_AddAdvertisement value)? addAdvertisement,
    TResult? Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult? Function(_UpdateImageUrls value)? updateImageUrls,
    TResult? Function(_UpdatePersonalInfo value)? updatePersonalInfo,
  }) {
    return addAdvertisement?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(_AddAdvertisement value)? addAdvertisement,
    TResult Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult Function(_UpdateImageUrls value)? updateImageUrls,
    TResult Function(_UpdatePersonalInfo value)? updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (addAdvertisement != null) {
      return addAdvertisement(this);
    }
    return orElse();
  }
}

abstract class _AddAdvertisement implements SellerEvent {
  const factory _AddAdvertisement(final AdvertisementModel advertisement) =
      _$AddAdvertisementImpl;

  AdvertisementModel get advertisement;

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddAdvertisementImplCopyWith<_$AddAdvertisementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UploadImageToS3ImplCopyWith<$Res> {
  factory _$$UploadImageToS3ImplCopyWith(_$UploadImageToS3Impl value,
          $Res Function(_$UploadImageToS3Impl) then) =
      __$$UploadImageToS3ImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Uint8List image});
}

/// @nodoc
class __$$UploadImageToS3ImplCopyWithImpl<$Res>
    extends _$SellerEventCopyWithImpl<$Res, _$UploadImageToS3Impl>
    implements _$$UploadImageToS3ImplCopyWith<$Res> {
  __$$UploadImageToS3ImplCopyWithImpl(
      _$UploadImageToS3Impl _value, $Res Function(_$UploadImageToS3Impl) _then)
      : super(_value, _then);

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image = null,
  }) {
    return _then(_$UploadImageToS3Impl(
      null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc

class _$UploadImageToS3Impl implements _UploadImageToS3 {
  const _$UploadImageToS3Impl(this.image);

  @override
  final Uint8List image;

  @override
  String toString() {
    return 'SellerEvent.uploadImageToS3(image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UploadImageToS3Impl &&
            const DeepCollectionEquality().equals(other.image, image));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(image));

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UploadImageToS3ImplCopyWith<_$UploadImageToS3Impl> get copyWith =>
      __$$UploadImageToS3ImplCopyWithImpl<_$UploadImageToS3Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(AdvertisementModel advertisement)
        addAdvertisement,
    required TResult Function(Uint8List image) uploadImageToS3,
    required TResult Function(String adId, List<String> imageUrls)
        updateImageUrls,
    required TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)
        updatePersonalInfo,
  }) {
    return uploadImageToS3(image);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult? Function(Uint8List image)? uploadImageToS3,
    TResult? Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult? Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
  }) {
    return uploadImageToS3?.call(image);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult Function(Uint8List image)? uploadImageToS3,
    TResult Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (uploadImageToS3 != null) {
      return uploadImageToS3(image);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(_AddAdvertisement value) addAdvertisement,
    required TResult Function(_UploadImageToS3 value) uploadImageToS3,
    required TResult Function(_UpdateImageUrls value) updateImageUrls,
    required TResult Function(_UpdatePersonalInfo value) updatePersonalInfo,
  }) {
    return uploadImageToS3(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Started value)? started,
    TResult? Function(_AddAdvertisement value)? addAdvertisement,
    TResult? Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult? Function(_UpdateImageUrls value)? updateImageUrls,
    TResult? Function(_UpdatePersonalInfo value)? updatePersonalInfo,
  }) {
    return uploadImageToS3?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(_AddAdvertisement value)? addAdvertisement,
    TResult Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult Function(_UpdateImageUrls value)? updateImageUrls,
    TResult Function(_UpdatePersonalInfo value)? updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (uploadImageToS3 != null) {
      return uploadImageToS3(this);
    }
    return orElse();
  }
}

abstract class _UploadImageToS3 implements SellerEvent {
  const factory _UploadImageToS3(final Uint8List image) = _$UploadImageToS3Impl;

  Uint8List get image;

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UploadImageToS3ImplCopyWith<_$UploadImageToS3Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateImageUrlsImplCopyWith<$Res> {
  factory _$$UpdateImageUrlsImplCopyWith(_$UpdateImageUrlsImpl value,
          $Res Function(_$UpdateImageUrlsImpl) then) =
      __$$UpdateImageUrlsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String adId, List<String> imageUrls});
}

/// @nodoc
class __$$UpdateImageUrlsImplCopyWithImpl<$Res>
    extends _$SellerEventCopyWithImpl<$Res, _$UpdateImageUrlsImpl>
    implements _$$UpdateImageUrlsImplCopyWith<$Res> {
  __$$UpdateImageUrlsImplCopyWithImpl(
      _$UpdateImageUrlsImpl _value, $Res Function(_$UpdateImageUrlsImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adId = null,
    Object? imageUrls = null,
  }) {
    return _then(_$UpdateImageUrlsImpl(
      adId: null == adId
          ? _value.adId
          : adId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrls: null == imageUrls
          ? _value._imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$UpdateImageUrlsImpl implements _UpdateImageUrls {
  const _$UpdateImageUrlsImpl(
      {required this.adId, required final List<String> imageUrls})
      : _imageUrls = imageUrls;

  @override
  final String adId;
  final List<String> _imageUrls;
  @override
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  String toString() {
    return 'SellerEvent.updateImageUrls(adId: $adId, imageUrls: $imageUrls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateImageUrlsImpl &&
            (identical(other.adId, adId) || other.adId == adId) &&
            const DeepCollectionEquality()
                .equals(other._imageUrls, _imageUrls));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, adId, const DeepCollectionEquality().hash(_imageUrls));

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateImageUrlsImplCopyWith<_$UpdateImageUrlsImpl> get copyWith =>
      __$$UpdateImageUrlsImplCopyWithImpl<_$UpdateImageUrlsImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(AdvertisementModel advertisement)
        addAdvertisement,
    required TResult Function(Uint8List image) uploadImageToS3,
    required TResult Function(String adId, List<String> imageUrls)
        updateImageUrls,
    required TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)
        updatePersonalInfo,
  }) {
    return updateImageUrls(adId, imageUrls);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult? Function(Uint8List image)? uploadImageToS3,
    TResult? Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult? Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
  }) {
    return updateImageUrls?.call(adId, imageUrls);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult Function(Uint8List image)? uploadImageToS3,
    TResult Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (updateImageUrls != null) {
      return updateImageUrls(adId, imageUrls);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(_AddAdvertisement value) addAdvertisement,
    required TResult Function(_UploadImageToS3 value) uploadImageToS3,
    required TResult Function(_UpdateImageUrls value) updateImageUrls,
    required TResult Function(_UpdatePersonalInfo value) updatePersonalInfo,
  }) {
    return updateImageUrls(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Started value)? started,
    TResult? Function(_AddAdvertisement value)? addAdvertisement,
    TResult? Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult? Function(_UpdateImageUrls value)? updateImageUrls,
    TResult? Function(_UpdatePersonalInfo value)? updatePersonalInfo,
  }) {
    return updateImageUrls?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(_AddAdvertisement value)? addAdvertisement,
    TResult Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult Function(_UpdateImageUrls value)? updateImageUrls,
    TResult Function(_UpdatePersonalInfo value)? updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (updateImageUrls != null) {
      return updateImageUrls(this);
    }
    return orElse();
  }
}

abstract class _UpdateImageUrls implements SellerEvent {
  const factory _UpdateImageUrls(
      {required final String adId,
      required final List<String> imageUrls}) = _$UpdateImageUrlsImpl;

  String get adId;
  List<String> get imageUrls;

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateImageUrlsImplCopyWith<_$UpdateImageUrlsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdatePersonalInfoImplCopyWith<$Res> {
  factory _$$UpdatePersonalInfoImplCopyWith(_$UpdatePersonalInfoImpl value,
          $Res Function(_$UpdatePersonalInfoImpl) then) =
      __$$UpdatePersonalInfoImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String adId,
      String fullName,
      String phoneNumber,
      String state,
      String city,
      String district});
}

/// @nodoc
class __$$UpdatePersonalInfoImplCopyWithImpl<$Res>
    extends _$SellerEventCopyWithImpl<$Res, _$UpdatePersonalInfoImpl>
    implements _$$UpdatePersonalInfoImplCopyWith<$Res> {
  __$$UpdatePersonalInfoImplCopyWithImpl(_$UpdatePersonalInfoImpl _value,
      $Res Function(_$UpdatePersonalInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adId = null,
    Object? fullName = null,
    Object? phoneNumber = null,
    Object? state = null,
    Object? city = null,
    Object? district = null,
  }) {
    return _then(_$UpdatePersonalInfoImpl(
      adId: null == adId
          ? _value.adId
          : adId // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$UpdatePersonalInfoImpl implements _UpdatePersonalInfo {
  const _$UpdatePersonalInfoImpl(
      {required this.adId,
      required this.fullName,
      required this.phoneNumber,
      required this.state,
      required this.city,
      required this.district});

  @override
  final String adId;
  @override
  final String fullName;
  @override
  final String phoneNumber;
  @override
  final String state;
  @override
  final String city;
  @override
  final String district;

  @override
  String toString() {
    return 'SellerEvent.updatePersonalInfo(adId: $adId, fullName: $fullName, phoneNumber: $phoneNumber, state: $state, city: $city, district: $district)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdatePersonalInfoImpl &&
            (identical(other.adId, adId) || other.adId == adId) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.district, district) ||
                other.district == district));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, adId, fullName, phoneNumber, state, city, district);

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdatePersonalInfoImplCopyWith<_$UpdatePersonalInfoImpl> get copyWith =>
      __$$UpdatePersonalInfoImplCopyWithImpl<_$UpdatePersonalInfoImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(AdvertisementModel advertisement)
        addAdvertisement,
    required TResult Function(Uint8List image) uploadImageToS3,
    required TResult Function(String adId, List<String> imageUrls)
        updateImageUrls,
    required TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)
        updatePersonalInfo,
  }) {
    return updatePersonalInfo(
        adId, fullName, phoneNumber, state, city, district);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult? Function(Uint8List image)? uploadImageToS3,
    TResult? Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult? Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
  }) {
    return updatePersonalInfo?.call(
        adId, fullName, phoneNumber, state, city, district);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(AdvertisementModel advertisement)? addAdvertisement,
    TResult Function(Uint8List image)? uploadImageToS3,
    TResult Function(String adId, List<String> imageUrls)? updateImageUrls,
    TResult Function(String adId, String fullName, String phoneNumber,
            String state, String city, String district)?
        updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (updatePersonalInfo != null) {
      return updatePersonalInfo(
          adId, fullName, phoneNumber, state, city, district);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(_AddAdvertisement value) addAdvertisement,
    required TResult Function(_UploadImageToS3 value) uploadImageToS3,
    required TResult Function(_UpdateImageUrls value) updateImageUrls,
    required TResult Function(_UpdatePersonalInfo value) updatePersonalInfo,
  }) {
    return updatePersonalInfo(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Started value)? started,
    TResult? Function(_AddAdvertisement value)? addAdvertisement,
    TResult? Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult? Function(_UpdateImageUrls value)? updateImageUrls,
    TResult? Function(_UpdatePersonalInfo value)? updatePersonalInfo,
  }) {
    return updatePersonalInfo?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(_AddAdvertisement value)? addAdvertisement,
    TResult Function(_UploadImageToS3 value)? uploadImageToS3,
    TResult Function(_UpdateImageUrls value)? updateImageUrls,
    TResult Function(_UpdatePersonalInfo value)? updatePersonalInfo,
    required TResult orElse(),
  }) {
    if (updatePersonalInfo != null) {
      return updatePersonalInfo(this);
    }
    return orElse();
  }
}

abstract class _UpdatePersonalInfo implements SellerEvent {
  const factory _UpdatePersonalInfo(
      {required final String adId,
      required final String fullName,
      required final String phoneNumber,
      required final String state,
      required final String city,
      required final String district}) = _$UpdatePersonalInfoImpl;

  String get adId;
  String get fullName;
  String get phoneNumber;
  String get state;
  String get city;
  String get district;

  /// Create a copy of SellerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdatePersonalInfoImplCopyWith<_$UpdatePersonalInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SellerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(AdvertisementModel advertisement) success,
    required TResult Function(String imageUrl) successImageUpload,
    required TResult Function(String error) failure,
    required TResult Function(String message) successMessage,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(AdvertisementModel advertisement)? success,
    TResult? Function(String imageUrl)? successImageUpload,
    TResult? Function(String error)? failure,
    TResult? Function(String message)? successMessage,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(AdvertisementModel advertisement)? success,
    TResult Function(String imageUrl)? successImageUpload,
    TResult Function(String error)? failure,
    TResult Function(String message)? successMessage,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(AddAvertisementSuccess value) success,
    required TResult Function(_SuccessImageUpload value) successImageUpload,
    required TResult Function(Failure value) failure,
    required TResult Function(_SuccessMessage value) successMessage,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(AddAvertisementSuccess value)? success,
    TResult? Function(_SuccessImageUpload value)? successImageUpload,
    TResult? Function(Failure value)? failure,
    TResult? Function(_SuccessMessage value)? successMessage,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(AddAvertisementSuccess value)? success,
    TResult Function(_SuccessImageUpload value)? successImageUpload,
    TResult Function(Failure value)? failure,
    TResult Function(_SuccessMessage value)? successMessage,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SellerStateCopyWith<$Res> {
  factory $SellerStateCopyWith(
          SellerState value, $Res Function(SellerState) then) =
      _$SellerStateCopyWithImpl<$Res, SellerState>;
}

/// @nodoc
class _$SellerStateCopyWithImpl<$Res, $Val extends SellerState>
    implements $SellerStateCopyWith<$Res> {
  _$SellerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$SellerStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'SellerState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(AdvertisementModel advertisement) success,
    required TResult Function(String imageUrl) successImageUpload,
    required TResult Function(String error) failure,
    required TResult Function(String message) successMessage,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(AdvertisementModel advertisement)? success,
    TResult? Function(String imageUrl)? successImageUpload,
    TResult? Function(String error)? failure,
    TResult? Function(String message)? successMessage,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(AdvertisementModel advertisement)? success,
    TResult Function(String imageUrl)? successImageUpload,
    TResult Function(String error)? failure,
    TResult Function(String message)? successMessage,
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
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(AddAvertisementSuccess value) success,
    required TResult Function(_SuccessImageUpload value) successImageUpload,
    required TResult Function(Failure value) failure,
    required TResult Function(_SuccessMessage value) successMessage,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(AddAvertisementSuccess value)? success,
    TResult? Function(_SuccessImageUpload value)? successImageUpload,
    TResult? Function(Failure value)? failure,
    TResult? Function(_SuccessMessage value)? successMessage,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(AddAvertisementSuccess value)? success,
    TResult Function(_SuccessImageUpload value)? successImageUpload,
    TResult Function(Failure value)? failure,
    TResult Function(_SuccessMessage value)? successMessage,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements SellerState {
  const factory Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$SellerStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'SellerState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(AdvertisementModel advertisement) success,
    required TResult Function(String imageUrl) successImageUpload,
    required TResult Function(String error) failure,
    required TResult Function(String message) successMessage,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(AdvertisementModel advertisement)? success,
    TResult? Function(String imageUrl)? successImageUpload,
    TResult? Function(String error)? failure,
    TResult? Function(String message)? successMessage,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(AdvertisementModel advertisement)? success,
    TResult Function(String imageUrl)? successImageUpload,
    TResult Function(String error)? failure,
    TResult Function(String message)? successMessage,
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
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(AddAvertisementSuccess value) success,
    required TResult Function(_SuccessImageUpload value) successImageUpload,
    required TResult Function(Failure value) failure,
    required TResult Function(_SuccessMessage value) successMessage,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(AddAvertisementSuccess value)? success,
    TResult? Function(_SuccessImageUpload value)? successImageUpload,
    TResult? Function(Failure value)? failure,
    TResult? Function(_SuccessMessage value)? successMessage,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(AddAvertisementSuccess value)? success,
    TResult Function(_SuccessImageUpload value)? successImageUpload,
    TResult Function(Failure value)? failure,
    TResult Function(_SuccessMessage value)? successMessage,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class Loading implements SellerState {
  const factory Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$AddAvertisementSuccessImplCopyWith<$Res> {
  factory _$$AddAvertisementSuccessImplCopyWith(
          _$AddAvertisementSuccessImpl value,
          $Res Function(_$AddAvertisementSuccessImpl) then) =
      __$$AddAvertisementSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({AdvertisementModel advertisement});
}

/// @nodoc
class __$$AddAvertisementSuccessImplCopyWithImpl<$Res>
    extends _$SellerStateCopyWithImpl<$Res, _$AddAvertisementSuccessImpl>
    implements _$$AddAvertisementSuccessImplCopyWith<$Res> {
  __$$AddAvertisementSuccessImplCopyWithImpl(
      _$AddAvertisementSuccessImpl _value,
      $Res Function(_$AddAvertisementSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? advertisement = null,
  }) {
    return _then(_$AddAvertisementSuccessImpl(
      null == advertisement
          ? _value.advertisement
          : advertisement // ignore: cast_nullable_to_non_nullable
              as AdvertisementModel,
    ));
  }
}

/// @nodoc

class _$AddAvertisementSuccessImpl implements AddAvertisementSuccess {
  const _$AddAvertisementSuccessImpl(this.advertisement);

  @override
  final AdvertisementModel advertisement;

  @override
  String toString() {
    return 'SellerState.success(advertisement: $advertisement)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddAvertisementSuccessImpl &&
            (identical(other.advertisement, advertisement) ||
                other.advertisement == advertisement));
  }

  @override
  int get hashCode => Object.hash(runtimeType, advertisement);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddAvertisementSuccessImplCopyWith<_$AddAvertisementSuccessImpl>
      get copyWith => __$$AddAvertisementSuccessImplCopyWithImpl<
          _$AddAvertisementSuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(AdvertisementModel advertisement) success,
    required TResult Function(String imageUrl) successImageUpload,
    required TResult Function(String error) failure,
    required TResult Function(String message) successMessage,
  }) {
    return success(advertisement);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(AdvertisementModel advertisement)? success,
    TResult? Function(String imageUrl)? successImageUpload,
    TResult? Function(String error)? failure,
    TResult? Function(String message)? successMessage,
  }) {
    return success?.call(advertisement);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(AdvertisementModel advertisement)? success,
    TResult Function(String imageUrl)? successImageUpload,
    TResult Function(String error)? failure,
    TResult Function(String message)? successMessage,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(advertisement);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(AddAvertisementSuccess value) success,
    required TResult Function(_SuccessImageUpload value) successImageUpload,
    required TResult Function(Failure value) failure,
    required TResult Function(_SuccessMessage value) successMessage,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(AddAvertisementSuccess value)? success,
    TResult? Function(_SuccessImageUpload value)? successImageUpload,
    TResult? Function(Failure value)? failure,
    TResult? Function(_SuccessMessage value)? successMessage,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(AddAvertisementSuccess value)? success,
    TResult Function(_SuccessImageUpload value)? successImageUpload,
    TResult Function(Failure value)? failure,
    TResult Function(_SuccessMessage value)? successMessage,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class AddAvertisementSuccess implements SellerState {
  const factory AddAvertisementSuccess(final AdvertisementModel advertisement) =
      _$AddAvertisementSuccessImpl;

  AdvertisementModel get advertisement;

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddAvertisementSuccessImplCopyWith<_$AddAvertisementSuccessImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SuccessImageUploadImplCopyWith<$Res> {
  factory _$$SuccessImageUploadImplCopyWith(_$SuccessImageUploadImpl value,
          $Res Function(_$SuccessImageUploadImpl) then) =
      __$$SuccessImageUploadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String imageUrl});
}

/// @nodoc
class __$$SuccessImageUploadImplCopyWithImpl<$Res>
    extends _$SellerStateCopyWithImpl<$Res, _$SuccessImageUploadImpl>
    implements _$$SuccessImageUploadImplCopyWith<$Res> {
  __$$SuccessImageUploadImplCopyWithImpl(_$SuccessImageUploadImpl _value,
      $Res Function(_$SuccessImageUploadImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageUrl = null,
  }) {
    return _then(_$SuccessImageUploadImpl(
      null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SuccessImageUploadImpl implements _SuccessImageUpload {
  const _$SuccessImageUploadImpl(this.imageUrl);

  @override
  final String imageUrl;

  @override
  String toString() {
    return 'SellerState.successImageUpload(imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuccessImageUploadImpl &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @override
  int get hashCode => Object.hash(runtimeType, imageUrl);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuccessImageUploadImplCopyWith<_$SuccessImageUploadImpl> get copyWith =>
      __$$SuccessImageUploadImplCopyWithImpl<_$SuccessImageUploadImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(AdvertisementModel advertisement) success,
    required TResult Function(String imageUrl) successImageUpload,
    required TResult Function(String error) failure,
    required TResult Function(String message) successMessage,
  }) {
    return successImageUpload(imageUrl);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(AdvertisementModel advertisement)? success,
    TResult? Function(String imageUrl)? successImageUpload,
    TResult? Function(String error)? failure,
    TResult? Function(String message)? successMessage,
  }) {
    return successImageUpload?.call(imageUrl);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(AdvertisementModel advertisement)? success,
    TResult Function(String imageUrl)? successImageUpload,
    TResult Function(String error)? failure,
    TResult Function(String message)? successMessage,
    required TResult orElse(),
  }) {
    if (successImageUpload != null) {
      return successImageUpload(imageUrl);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(AddAvertisementSuccess value) success,
    required TResult Function(_SuccessImageUpload value) successImageUpload,
    required TResult Function(Failure value) failure,
    required TResult Function(_SuccessMessage value) successMessage,
  }) {
    return successImageUpload(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(AddAvertisementSuccess value)? success,
    TResult? Function(_SuccessImageUpload value)? successImageUpload,
    TResult? Function(Failure value)? failure,
    TResult? Function(_SuccessMessage value)? successMessage,
  }) {
    return successImageUpload?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(AddAvertisementSuccess value)? success,
    TResult Function(_SuccessImageUpload value)? successImageUpload,
    TResult Function(Failure value)? failure,
    TResult Function(_SuccessMessage value)? successMessage,
    required TResult orElse(),
  }) {
    if (successImageUpload != null) {
      return successImageUpload(this);
    }
    return orElse();
  }
}

abstract class _SuccessImageUpload implements SellerState {
  const factory _SuccessImageUpload(final String imageUrl) =
      _$SuccessImageUploadImpl;

  String get imageUrl;

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuccessImageUploadImplCopyWith<_$SuccessImageUploadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FailureImplCopyWith<$Res> {
  factory _$$FailureImplCopyWith(
          _$FailureImpl value, $Res Function(_$FailureImpl) then) =
      __$$FailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String error});
}

/// @nodoc
class __$$FailureImplCopyWithImpl<$Res>
    extends _$SellerStateCopyWithImpl<$Res, _$FailureImpl>
    implements _$$FailureImplCopyWith<$Res> {
  __$$FailureImplCopyWithImpl(
      _$FailureImpl _value, $Res Function(_$FailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
  }) {
    return _then(_$FailureImpl(
      null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$FailureImpl implements Failure {
  const _$FailureImpl(this.error);

  @override
  final String error;

  @override
  String toString() {
    return 'SellerState.failure(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FailureImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FailureImplCopyWith<_$FailureImpl> get copyWith =>
      __$$FailureImplCopyWithImpl<_$FailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(AdvertisementModel advertisement) success,
    required TResult Function(String imageUrl) successImageUpload,
    required TResult Function(String error) failure,
    required TResult Function(String message) successMessage,
  }) {
    return failure(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(AdvertisementModel advertisement)? success,
    TResult? Function(String imageUrl)? successImageUpload,
    TResult? Function(String error)? failure,
    TResult? Function(String message)? successMessage,
  }) {
    return failure?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(AdvertisementModel advertisement)? success,
    TResult Function(String imageUrl)? successImageUpload,
    TResult Function(String error)? failure,
    TResult Function(String message)? successMessage,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(AddAvertisementSuccess value) success,
    required TResult Function(_SuccessImageUpload value) successImageUpload,
    required TResult Function(Failure value) failure,
    required TResult Function(_SuccessMessage value) successMessage,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(AddAvertisementSuccess value)? success,
    TResult? Function(_SuccessImageUpload value)? successImageUpload,
    TResult? Function(Failure value)? failure,
    TResult? Function(_SuccessMessage value)? successMessage,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(AddAvertisementSuccess value)? success,
    TResult Function(_SuccessImageUpload value)? successImageUpload,
    TResult Function(Failure value)? failure,
    TResult Function(_SuccessMessage value)? successMessage,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class Failure implements SellerState {
  const factory Failure(final String error) = _$FailureImpl;

  String get error;

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FailureImplCopyWith<_$FailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SuccessMessageImplCopyWith<$Res> {
  factory _$$SuccessMessageImplCopyWith(_$SuccessMessageImpl value,
          $Res Function(_$SuccessMessageImpl) then) =
      __$$SuccessMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SuccessMessageImplCopyWithImpl<$Res>
    extends _$SellerStateCopyWithImpl<$Res, _$SuccessMessageImpl>
    implements _$$SuccessMessageImplCopyWith<$Res> {
  __$$SuccessMessageImplCopyWithImpl(
      _$SuccessMessageImpl _value, $Res Function(_$SuccessMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$SuccessMessageImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SuccessMessageImpl implements _SuccessMessage {
  const _$SuccessMessageImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'SellerState.successMessage(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuccessMessageImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuccessMessageImplCopyWith<_$SuccessMessageImpl> get copyWith =>
      __$$SuccessMessageImplCopyWithImpl<_$SuccessMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(AdvertisementModel advertisement) success,
    required TResult Function(String imageUrl) successImageUpload,
    required TResult Function(String error) failure,
    required TResult Function(String message) successMessage,
  }) {
    return successMessage(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(AdvertisementModel advertisement)? success,
    TResult? Function(String imageUrl)? successImageUpload,
    TResult? Function(String error)? failure,
    TResult? Function(String message)? successMessage,
  }) {
    return successMessage?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(AdvertisementModel advertisement)? success,
    TResult Function(String imageUrl)? successImageUpload,
    TResult Function(String error)? failure,
    TResult Function(String message)? successMessage,
    required TResult orElse(),
  }) {
    if (successMessage != null) {
      return successMessage(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(AddAvertisementSuccess value) success,
    required TResult Function(_SuccessImageUpload value) successImageUpload,
    required TResult Function(Failure value) failure,
    required TResult Function(_SuccessMessage value) successMessage,
  }) {
    return successMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(AddAvertisementSuccess value)? success,
    TResult? Function(_SuccessImageUpload value)? successImageUpload,
    TResult? Function(Failure value)? failure,
    TResult? Function(_SuccessMessage value)? successMessage,
  }) {
    return successMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(AddAvertisementSuccess value)? success,
    TResult Function(_SuccessImageUpload value)? successImageUpload,
    TResult Function(Failure value)? failure,
    TResult Function(_SuccessMessage value)? successMessage,
    required TResult orElse(),
  }) {
    if (successMessage != null) {
      return successMessage(this);
    }
    return orElse();
  }
}

abstract class _SuccessMessage implements SellerState {
  const factory _SuccessMessage(final String message) = _$SuccessMessageImpl;

  String get message;

  /// Create a copy of SellerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuccessMessageImplCopyWith<_$SuccessMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
