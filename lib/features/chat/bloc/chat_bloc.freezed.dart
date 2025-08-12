// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() fetchChatList,
    required TResult Function(List<Map<String, dynamic>> chats) updateChatList,
    required TResult Function(String username, String message) sendMessage,
    required TResult Function(String username, String message) receiveMessage,
    required TResult Function(String username) markChatAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? fetchChatList,
    TResult? Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult? Function(String username, String message)? sendMessage,
    TResult? Function(String username, String message)? receiveMessage,
    TResult? Function(String username)? markChatAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? fetchChatList,
    TResult Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult Function(String username, String message)? sendMessage,
    TResult Function(String username, String message)? receiveMessage,
    TResult Function(String username)? markChatAsRead,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FetchChatList value) fetchChatList,
    required TResult Function(UpdateChatList value) updateChatList,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(ReceiveMessage value) receiveMessage,
    required TResult Function(MarkChatAsRead value) markChatAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FetchChatList value)? fetchChatList,
    TResult? Function(UpdateChatList value)? updateChatList,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(ReceiveMessage value)? receiveMessage,
    TResult? Function(MarkChatAsRead value)? markChatAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FetchChatList value)? fetchChatList,
    TResult Function(UpdateChatList value)? updateChatList,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(ReceiveMessage value)? receiveMessage,
    TResult Function(MarkChatAsRead value)? markChatAsRead,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatEventCopyWith<$Res> {
  factory $ChatEventCopyWith(ChatEvent value, $Res Function(ChatEvent) then) =
      _$ChatEventCopyWithImpl<$Res, ChatEvent>;
}

/// @nodoc
class _$ChatEventCopyWithImpl<$Res, $Val extends ChatEvent>
    implements $ChatEventCopyWith<$Res> {
  _$ChatEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$FetchChatListImplCopyWith<$Res> {
  factory _$$FetchChatListImplCopyWith(
          _$FetchChatListImpl value, $Res Function(_$FetchChatListImpl) then) =
      __$$FetchChatListImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FetchChatListImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$FetchChatListImpl>
    implements _$$FetchChatListImplCopyWith<$Res> {
  __$$FetchChatListImplCopyWithImpl(
      _$FetchChatListImpl _value, $Res Function(_$FetchChatListImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FetchChatListImpl implements FetchChatList {
  const _$FetchChatListImpl();

  @override
  String toString() {
    return 'ChatEvent.fetchChatList()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$FetchChatListImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() fetchChatList,
    required TResult Function(List<Map<String, dynamic>> chats) updateChatList,
    required TResult Function(String username, String message) sendMessage,
    required TResult Function(String username, String message) receiveMessage,
    required TResult Function(String username) markChatAsRead,
  }) {
    return fetchChatList();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? fetchChatList,
    TResult? Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult? Function(String username, String message)? sendMessage,
    TResult? Function(String username, String message)? receiveMessage,
    TResult? Function(String username)? markChatAsRead,
  }) {
    return fetchChatList?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? fetchChatList,
    TResult Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult Function(String username, String message)? sendMessage,
    TResult Function(String username, String message)? receiveMessage,
    TResult Function(String username)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (fetchChatList != null) {
      return fetchChatList();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FetchChatList value) fetchChatList,
    required TResult Function(UpdateChatList value) updateChatList,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(ReceiveMessage value) receiveMessage,
    required TResult Function(MarkChatAsRead value) markChatAsRead,
  }) {
    return fetchChatList(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FetchChatList value)? fetchChatList,
    TResult? Function(UpdateChatList value)? updateChatList,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(ReceiveMessage value)? receiveMessage,
    TResult? Function(MarkChatAsRead value)? markChatAsRead,
  }) {
    return fetchChatList?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FetchChatList value)? fetchChatList,
    TResult Function(UpdateChatList value)? updateChatList,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(ReceiveMessage value)? receiveMessage,
    TResult Function(MarkChatAsRead value)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (fetchChatList != null) {
      return fetchChatList(this);
    }
    return orElse();
  }
}

abstract class FetchChatList implements ChatEvent {
  const factory FetchChatList() = _$FetchChatListImpl;
}

/// @nodoc
abstract class _$$UpdateChatListImplCopyWith<$Res> {
  factory _$$UpdateChatListImplCopyWith(_$UpdateChatListImpl value,
          $Res Function(_$UpdateChatListImpl) then) =
      __$$UpdateChatListImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Map<String, dynamic>> chats});
}

/// @nodoc
class __$$UpdateChatListImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$UpdateChatListImpl>
    implements _$$UpdateChatListImplCopyWith<$Res> {
  __$$UpdateChatListImplCopyWithImpl(
      _$UpdateChatListImpl _value, $Res Function(_$UpdateChatListImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chats = null,
  }) {
    return _then(_$UpdateChatListImpl(
      null == chats
          ? _value._chats
          : chats // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc

class _$UpdateChatListImpl implements UpdateChatList {
  const _$UpdateChatListImpl(final List<Map<String, dynamic>> chats)
      : _chats = chats;

  final List<Map<String, dynamic>> _chats;
  @override
  List<Map<String, dynamic>> get chats {
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chats);
  }

  @override
  String toString() {
    return 'ChatEvent.updateChatList(chats: $chats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateChatListImpl &&
            const DeepCollectionEquality().equals(other._chats, _chats));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_chats));

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateChatListImplCopyWith<_$UpdateChatListImpl> get copyWith =>
      __$$UpdateChatListImplCopyWithImpl<_$UpdateChatListImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() fetchChatList,
    required TResult Function(List<Map<String, dynamic>> chats) updateChatList,
    required TResult Function(String username, String message) sendMessage,
    required TResult Function(String username, String message) receiveMessage,
    required TResult Function(String username) markChatAsRead,
  }) {
    return updateChatList(chats);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? fetchChatList,
    TResult? Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult? Function(String username, String message)? sendMessage,
    TResult? Function(String username, String message)? receiveMessage,
    TResult? Function(String username)? markChatAsRead,
  }) {
    return updateChatList?.call(chats);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? fetchChatList,
    TResult Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult Function(String username, String message)? sendMessage,
    TResult Function(String username, String message)? receiveMessage,
    TResult Function(String username)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (updateChatList != null) {
      return updateChatList(chats);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FetchChatList value) fetchChatList,
    required TResult Function(UpdateChatList value) updateChatList,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(ReceiveMessage value) receiveMessage,
    required TResult Function(MarkChatAsRead value) markChatAsRead,
  }) {
    return updateChatList(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FetchChatList value)? fetchChatList,
    TResult? Function(UpdateChatList value)? updateChatList,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(ReceiveMessage value)? receiveMessage,
    TResult? Function(MarkChatAsRead value)? markChatAsRead,
  }) {
    return updateChatList?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FetchChatList value)? fetchChatList,
    TResult Function(UpdateChatList value)? updateChatList,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(ReceiveMessage value)? receiveMessage,
    TResult Function(MarkChatAsRead value)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (updateChatList != null) {
      return updateChatList(this);
    }
    return orElse();
  }
}

abstract class UpdateChatList implements ChatEvent {
  const factory UpdateChatList(final List<Map<String, dynamic>> chats) =
      _$UpdateChatListImpl;

  List<Map<String, dynamic>> get chats;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateChatListImplCopyWith<_$UpdateChatListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SendMessageImplCopyWith<$Res> {
  factory _$$SendMessageImplCopyWith(
          _$SendMessageImpl value, $Res Function(_$SendMessageImpl) then) =
      __$$SendMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String username, String message});
}

/// @nodoc
class __$$SendMessageImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SendMessageImpl>
    implements _$$SendMessageImplCopyWith<$Res> {
  __$$SendMessageImplCopyWithImpl(
      _$SendMessageImpl _value, $Res Function(_$SendMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? message = null,
  }) {
    return _then(_$SendMessageImpl(
      null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SendMessageImpl implements SendMessage {
  const _$SendMessageImpl(this.username, this.message);

  @override
  final String username;
  @override
  final String message;

  @override
  String toString() {
    return 'ChatEvent.sendMessage(username: $username, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendMessageImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, username, message);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SendMessageImplCopyWith<_$SendMessageImpl> get copyWith =>
      __$$SendMessageImplCopyWithImpl<_$SendMessageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() fetchChatList,
    required TResult Function(List<Map<String, dynamic>> chats) updateChatList,
    required TResult Function(String username, String message) sendMessage,
    required TResult Function(String username, String message) receiveMessage,
    required TResult Function(String username) markChatAsRead,
  }) {
    return sendMessage(username, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? fetchChatList,
    TResult? Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult? Function(String username, String message)? sendMessage,
    TResult? Function(String username, String message)? receiveMessage,
    TResult? Function(String username)? markChatAsRead,
  }) {
    return sendMessage?.call(username, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? fetchChatList,
    TResult Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult Function(String username, String message)? sendMessage,
    TResult Function(String username, String message)? receiveMessage,
    TResult Function(String username)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(username, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FetchChatList value) fetchChatList,
    required TResult Function(UpdateChatList value) updateChatList,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(ReceiveMessage value) receiveMessage,
    required TResult Function(MarkChatAsRead value) markChatAsRead,
  }) {
    return sendMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FetchChatList value)? fetchChatList,
    TResult? Function(UpdateChatList value)? updateChatList,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(ReceiveMessage value)? receiveMessage,
    TResult? Function(MarkChatAsRead value)? markChatAsRead,
  }) {
    return sendMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FetchChatList value)? fetchChatList,
    TResult Function(UpdateChatList value)? updateChatList,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(ReceiveMessage value)? receiveMessage,
    TResult Function(MarkChatAsRead value)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(this);
    }
    return orElse();
  }
}

abstract class SendMessage implements ChatEvent {
  const factory SendMessage(final String username, final String message) =
      _$SendMessageImpl;

  String get username;
  String get message;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendMessageImplCopyWith<_$SendMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ReceiveMessageImplCopyWith<$Res> {
  factory _$$ReceiveMessageImplCopyWith(_$ReceiveMessageImpl value,
          $Res Function(_$ReceiveMessageImpl) then) =
      __$$ReceiveMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String username, String message});
}

/// @nodoc
class __$$ReceiveMessageImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$ReceiveMessageImpl>
    implements _$$ReceiveMessageImplCopyWith<$Res> {
  __$$ReceiveMessageImplCopyWithImpl(
      _$ReceiveMessageImpl _value, $Res Function(_$ReceiveMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? message = null,
  }) {
    return _then(_$ReceiveMessageImpl(
      null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ReceiveMessageImpl implements ReceiveMessage {
  const _$ReceiveMessageImpl(this.username, this.message);

  @override
  final String username;
  @override
  final String message;

  @override
  String toString() {
    return 'ChatEvent.receiveMessage(username: $username, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceiveMessageImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, username, message);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceiveMessageImplCopyWith<_$ReceiveMessageImpl> get copyWith =>
      __$$ReceiveMessageImplCopyWithImpl<_$ReceiveMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() fetchChatList,
    required TResult Function(List<Map<String, dynamic>> chats) updateChatList,
    required TResult Function(String username, String message) sendMessage,
    required TResult Function(String username, String message) receiveMessage,
    required TResult Function(String username) markChatAsRead,
  }) {
    return receiveMessage(username, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? fetchChatList,
    TResult? Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult? Function(String username, String message)? sendMessage,
    TResult? Function(String username, String message)? receiveMessage,
    TResult? Function(String username)? markChatAsRead,
  }) {
    return receiveMessage?.call(username, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? fetchChatList,
    TResult Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult Function(String username, String message)? sendMessage,
    TResult Function(String username, String message)? receiveMessage,
    TResult Function(String username)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (receiveMessage != null) {
      return receiveMessage(username, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FetchChatList value) fetchChatList,
    required TResult Function(UpdateChatList value) updateChatList,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(ReceiveMessage value) receiveMessage,
    required TResult Function(MarkChatAsRead value) markChatAsRead,
  }) {
    return receiveMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FetchChatList value)? fetchChatList,
    TResult? Function(UpdateChatList value)? updateChatList,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(ReceiveMessage value)? receiveMessage,
    TResult? Function(MarkChatAsRead value)? markChatAsRead,
  }) {
    return receiveMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FetchChatList value)? fetchChatList,
    TResult Function(UpdateChatList value)? updateChatList,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(ReceiveMessage value)? receiveMessage,
    TResult Function(MarkChatAsRead value)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (receiveMessage != null) {
      return receiveMessage(this);
    }
    return orElse();
  }
}

abstract class ReceiveMessage implements ChatEvent {
  const factory ReceiveMessage(final String username, final String message) =
      _$ReceiveMessageImpl;

  String get username;
  String get message;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceiveMessageImplCopyWith<_$ReceiveMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MarkChatAsReadImplCopyWith<$Res> {
  factory _$$MarkChatAsReadImplCopyWith(_$MarkChatAsReadImpl value,
          $Res Function(_$MarkChatAsReadImpl) then) =
      __$$MarkChatAsReadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String username});
}

/// @nodoc
class __$$MarkChatAsReadImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$MarkChatAsReadImpl>
    implements _$$MarkChatAsReadImplCopyWith<$Res> {
  __$$MarkChatAsReadImplCopyWithImpl(
      _$MarkChatAsReadImpl _value, $Res Function(_$MarkChatAsReadImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
  }) {
    return _then(_$MarkChatAsReadImpl(
      null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MarkChatAsReadImpl implements MarkChatAsRead {
  const _$MarkChatAsReadImpl(this.username);

  @override
  final String username;

  @override
  String toString() {
    return 'ChatEvent.markChatAsRead(username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarkChatAsReadImpl &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @override
  int get hashCode => Object.hash(runtimeType, username);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarkChatAsReadImplCopyWith<_$MarkChatAsReadImpl> get copyWith =>
      __$$MarkChatAsReadImplCopyWithImpl<_$MarkChatAsReadImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() fetchChatList,
    required TResult Function(List<Map<String, dynamic>> chats) updateChatList,
    required TResult Function(String username, String message) sendMessage,
    required TResult Function(String username, String message) receiveMessage,
    required TResult Function(String username) markChatAsRead,
  }) {
    return markChatAsRead(username);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? fetchChatList,
    TResult? Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult? Function(String username, String message)? sendMessage,
    TResult? Function(String username, String message)? receiveMessage,
    TResult? Function(String username)? markChatAsRead,
  }) {
    return markChatAsRead?.call(username);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? fetchChatList,
    TResult Function(List<Map<String, dynamic>> chats)? updateChatList,
    TResult Function(String username, String message)? sendMessage,
    TResult Function(String username, String message)? receiveMessage,
    TResult Function(String username)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (markChatAsRead != null) {
      return markChatAsRead(username);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FetchChatList value) fetchChatList,
    required TResult Function(UpdateChatList value) updateChatList,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(ReceiveMessage value) receiveMessage,
    required TResult Function(MarkChatAsRead value) markChatAsRead,
  }) {
    return markChatAsRead(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FetchChatList value)? fetchChatList,
    TResult? Function(UpdateChatList value)? updateChatList,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(ReceiveMessage value)? receiveMessage,
    TResult? Function(MarkChatAsRead value)? markChatAsRead,
  }) {
    return markChatAsRead?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FetchChatList value)? fetchChatList,
    TResult Function(UpdateChatList value)? updateChatList,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(ReceiveMessage value)? receiveMessage,
    TResult Function(MarkChatAsRead value)? markChatAsRead,
    required TResult orElse(),
  }) {
    if (markChatAsRead != null) {
      return markChatAsRead(this);
    }
    return orElse();
  }
}

abstract class MarkChatAsRead implements ChatEvent {
  const factory MarkChatAsRead(final String username) = _$MarkChatAsReadImpl;

  String get username;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarkChatAsReadImplCopyWith<_$MarkChatAsReadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChatState {
  List<Map<String, dynamic>> get chats =>
      throw _privateConstructorUsedError; // Chat list
  List<Map<String, String>> get messages => throw _privateConstructorUsedError;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatStateCopyWith<ChatState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
  @useResult
  $Res call(
      {List<Map<String, dynamic>> chats, List<Map<String, String>> messages});
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res, $Val extends ChatState>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chats = null,
    Object? messages = null,
  }) {
    return _then(_value.copyWith(
      chats: null == chats
          ? _value.chats
          : chats // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatBlocStateImplCopyWith<$Res>
    implements $ChatStateCopyWith<$Res> {
  factory _$$ChatBlocStateImplCopyWith(
          _$ChatBlocStateImpl value, $Res Function(_$ChatBlocStateImpl) then) =
      __$$ChatBlocStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Map<String, dynamic>> chats, List<Map<String, String>> messages});
}

/// @nodoc
class __$$ChatBlocStateImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatBlocStateImpl>
    implements _$$ChatBlocStateImplCopyWith<$Res> {
  __$$ChatBlocStateImplCopyWithImpl(
      _$ChatBlocStateImpl _value, $Res Function(_$ChatBlocStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chats = null,
    Object? messages = null,
  }) {
    return _then(_$ChatBlocStateImpl(
      chats: null == chats
          ? _value._chats
          : chats // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
    ));
  }
}

/// @nodoc

class _$ChatBlocStateImpl implements ChatBlocState {
  const _$ChatBlocStateImpl(
      {final List<Map<String, dynamic>> chats = const [],
      final List<Map<String, String>> messages = const []})
      : _chats = chats,
        _messages = messages;

  final List<Map<String, dynamic>> _chats;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get chats {
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chats);
  }

// Chat list
  final List<Map<String, String>> _messages;
// Chat list
  @override
  @JsonKey()
  List<Map<String, String>> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'ChatState(chats: $chats, messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatBlocStateImpl &&
            const DeepCollectionEquality().equals(other._chats, _chats) &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_chats),
      const DeepCollectionEquality().hash(_messages));

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatBlocStateImplCopyWith<_$ChatBlocStateImpl> get copyWith =>
      __$$ChatBlocStateImplCopyWithImpl<_$ChatBlocStateImpl>(this, _$identity);
}

abstract class ChatBlocState implements ChatState {
  const factory ChatBlocState(
      {final List<Map<String, dynamic>> chats,
      final List<Map<String, String>> messages}) = _$ChatBlocStateImpl;

  @override
  List<Map<String, dynamic>> get chats; // Chat list
  @override
  List<Map<String, String>> get messages;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatBlocStateImplCopyWith<_$ChatBlocStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
