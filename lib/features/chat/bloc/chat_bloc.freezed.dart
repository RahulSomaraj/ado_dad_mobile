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
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
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
abstract class _$$InitializeImplCopyWith<$Res> {
  factory _$$InitializeImplCopyWith(
          _$InitializeImpl value, $Res Function(_$InitializeImpl) then) =
      __$$InitializeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitializeImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$InitializeImpl>
    implements _$$InitializeImplCopyWith<$Res> {
  __$$InitializeImplCopyWithImpl(
      _$InitializeImpl _value, $Res Function(_$InitializeImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitializeImpl implements _Initialize {
  const _$InitializeImpl();

  @override
  String toString() {
    return 'ChatEvent.initialize()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitializeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return initialize();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return initialize?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initialize != null) {
      return initialize();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return initialize(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return initialize?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initialize != null) {
      return initialize(this);
    }
    return orElse();
  }
}

abstract class _Initialize implements ChatEvent {
  const factory _Initialize() = _$InitializeImpl;
}

/// @nodoc
abstract class _$$LoadChatsImplCopyWith<$Res> {
  factory _$$LoadChatsImplCopyWith(
          _$LoadChatsImpl value, $Res Function(_$LoadChatsImpl) then) =
      __$$LoadChatsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadChatsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LoadChatsImpl>
    implements _$$LoadChatsImplCopyWith<$Res> {
  __$$LoadChatsImplCopyWithImpl(
      _$LoadChatsImpl _value, $Res Function(_$LoadChatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadChatsImpl implements _LoadChats {
  const _$LoadChatsImpl();

  @override
  String toString() {
    return 'ChatEvent.loadChats()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadChatsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return loadChats();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return loadChats?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loadChats != null) {
      return loadChats();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return loadChats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return loadChats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loadChats != null) {
      return loadChats(this);
    }
    return orElse();
  }
}

abstract class _LoadChats implements ChatEvent {
  const factory _LoadChats() = _$LoadChatsImpl;
}

/// @nodoc
abstract class _$$RefreshChatsImplCopyWith<$Res> {
  factory _$$RefreshChatsImplCopyWith(
          _$RefreshChatsImpl value, $Res Function(_$RefreshChatsImpl) then) =
      __$$RefreshChatsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RefreshChatsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$RefreshChatsImpl>
    implements _$$RefreshChatsImplCopyWith<$Res> {
  __$$RefreshChatsImplCopyWithImpl(
      _$RefreshChatsImpl _value, $Res Function(_$RefreshChatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$RefreshChatsImpl implements _RefreshChats {
  const _$RefreshChatsImpl();

  @override
  String toString() {
    return 'ChatEvent.refreshChats()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RefreshChatsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return refreshChats();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return refreshChats?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (refreshChats != null) {
      return refreshChats();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return refreshChats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return refreshChats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (refreshChats != null) {
      return refreshChats(this);
    }
    return orElse();
  }
}

abstract class _RefreshChats implements ChatEvent {
  const factory _RefreshChats() = _$RefreshChatsImpl;
}

/// @nodoc
abstract class _$$ConnectImplCopyWith<$Res> {
  factory _$$ConnectImplCopyWith(
          _$ConnectImpl value, $Res Function(_$ConnectImpl) then) =
      __$$ConnectImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ConnectImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$ConnectImpl>
    implements _$$ConnectImplCopyWith<$Res> {
  __$$ConnectImplCopyWithImpl(
      _$ConnectImpl _value, $Res Function(_$ConnectImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ConnectImpl implements _Connect {
  const _$ConnectImpl();

  @override
  String toString() {
    return 'ChatEvent.connect()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ConnectImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return connect();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return connect?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (connect != null) {
      return connect();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return connect(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return connect?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (connect != null) {
      return connect(this);
    }
    return orElse();
  }
}

abstract class _Connect implements ChatEvent {
  const factory _Connect() = _$ConnectImpl;
}

/// @nodoc
abstract class _$$DisconnectImplCopyWith<$Res> {
  factory _$$DisconnectImplCopyWith(
          _$DisconnectImpl value, $Res Function(_$DisconnectImpl) then) =
      __$$DisconnectImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DisconnectImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$DisconnectImpl>
    implements _$$DisconnectImplCopyWith<$Res> {
  __$$DisconnectImplCopyWithImpl(
      _$DisconnectImpl _value, $Res Function(_$DisconnectImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DisconnectImpl implements _Disconnect {
  const _$DisconnectImpl();

  @override
  String toString() {
    return 'ChatEvent.disconnect()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$DisconnectImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return disconnect();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return disconnect?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (disconnect != null) {
      return disconnect();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return disconnect(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return disconnect?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (disconnect != null) {
      return disconnect(this);
    }
    return orElse();
  }
}

abstract class _Disconnect implements ChatEvent {
  const factory _Disconnect() = _$DisconnectImpl;
}

/// @nodoc
abstract class _$$NewMessageImplCopyWith<$Res> {
  factory _$$NewMessageImplCopyWith(
          _$NewMessageImpl value, $Res Function(_$NewMessageImpl) then) =
      __$$NewMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ChatMessage message});

  $ChatMessageCopyWith<$Res> get message;
}

/// @nodoc
class __$$NewMessageImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$NewMessageImpl>
    implements _$$NewMessageImplCopyWith<$Res> {
  __$$NewMessageImplCopyWithImpl(
      _$NewMessageImpl _value, $Res Function(_$NewMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$NewMessageImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as ChatMessage,
    ));
  }

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChatMessageCopyWith<$Res> get message {
    return $ChatMessageCopyWith<$Res>(_value.message, (value) {
      return _then(_value.copyWith(message: value));
    });
  }
}

/// @nodoc

class _$NewMessageImpl implements _NewMessage {
  const _$NewMessageImpl(this.message);

  @override
  final ChatMessage message;

  @override
  String toString() {
    return 'ChatEvent.newMessage(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewMessageImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewMessageImplCopyWith<_$NewMessageImpl> get copyWith =>
      __$$NewMessageImplCopyWithImpl<_$NewMessageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return newMessage(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return newMessage?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (newMessage != null) {
      return newMessage(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return newMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return newMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (newMessage != null) {
      return newMessage(this);
    }
    return orElse();
  }
}

abstract class _NewMessage implements ChatEvent {
  const factory _NewMessage(final ChatMessage message) = _$NewMessageImpl;

  ChatMessage get message;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewMessageImplCopyWith<_$NewMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NewChatImplCopyWith<$Res> {
  factory _$$NewChatImplCopyWith(
          _$NewChatImpl value, $Res Function(_$NewChatImpl) then) =
      __$$NewChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> chatData});
}

/// @nodoc
class __$$NewChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$NewChatImpl>
    implements _$$NewChatImplCopyWith<$Res> {
  __$$NewChatImplCopyWithImpl(
      _$NewChatImpl _value, $Res Function(_$NewChatImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatData = null,
  }) {
    return _then(_$NewChatImpl(
      null == chatData
          ? _value._chatData
          : chatData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$NewChatImpl implements _NewChat {
  const _$NewChatImpl(final Map<String, dynamic> chatData)
      : _chatData = chatData;

  final Map<String, dynamic> _chatData;
  @override
  Map<String, dynamic> get chatData {
    if (_chatData is EqualUnmodifiableMapView) return _chatData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_chatData);
  }

  @override
  String toString() {
    return 'ChatEvent.newChat(chatData: $chatData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewChatImpl &&
            const DeepCollectionEquality().equals(other._chatData, _chatData));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_chatData));

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewChatImplCopyWith<_$NewChatImpl> get copyWith =>
      __$$NewChatImplCopyWithImpl<_$NewChatImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return newChat(chatData);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return newChat?.call(chatData);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (newChat != null) {
      return newChat(chatData);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return newChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return newChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (newChat != null) {
      return newChat(this);
    }
    return orElse();
  }
}

abstract class _NewChat implements ChatEvent {
  const factory _NewChat(final Map<String, dynamic> chatData) = _$NewChatImpl;

  Map<String, dynamic> get chatData;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewChatImplCopyWith<_$NewChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CreateAdChatImplCopyWith<$Res> {
  factory _$$CreateAdChatImplCopyWith(
          _$CreateAdChatImpl value, $Res Function(_$CreateAdChatImpl) then) =
      __$$CreateAdChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String adId});
}

/// @nodoc
class __$$CreateAdChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$CreateAdChatImpl>
    implements _$$CreateAdChatImplCopyWith<$Res> {
  __$$CreateAdChatImplCopyWithImpl(
      _$CreateAdChatImpl _value, $Res Function(_$CreateAdChatImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adId = null,
  }) {
    return _then(_$CreateAdChatImpl(
      null == adId
          ? _value.adId
          : adId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$CreateAdChatImpl implements _CreateAdChat {
  const _$CreateAdChatImpl(this.adId);

  @override
  final String adId;

  @override
  String toString() {
    return 'ChatEvent.createAdChat(adId: $adId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateAdChatImpl &&
            (identical(other.adId, adId) || other.adId == adId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, adId);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateAdChatImplCopyWith<_$CreateAdChatImpl> get copyWith =>
      __$$CreateAdChatImplCopyWithImpl<_$CreateAdChatImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return createAdChat(adId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return createAdChat?.call(adId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (createAdChat != null) {
      return createAdChat(adId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return createAdChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return createAdChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (createAdChat != null) {
      return createAdChat(this);
    }
    return orElse();
  }
}

abstract class _CreateAdChat implements ChatEvent {
  const factory _CreateAdChat(final String adId) = _$CreateAdChatImpl;

  String get adId;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateAdChatImplCopyWith<_$CreateAdChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$JoinChatImplCopyWith<$Res> {
  factory _$$JoinChatImplCopyWith(
          _$JoinChatImpl value, $Res Function(_$JoinChatImpl) then) =
      __$$JoinChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$JoinChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$JoinChatImpl>
    implements _$$JoinChatImplCopyWith<$Res> {
  __$$JoinChatImplCopyWithImpl(
      _$JoinChatImpl _value, $Res Function(_$JoinChatImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$JoinChatImpl(
      null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$JoinChatImpl implements _JoinChat {
  const _$JoinChatImpl(this.chatId);

  @override
  final String chatId;

  @override
  String toString() {
    return 'ChatEvent.joinChat(chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoinChatImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JoinChatImplCopyWith<_$JoinChatImpl> get copyWith =>
      __$$JoinChatImplCopyWithImpl<_$JoinChatImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return joinChat(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return joinChat?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (joinChat != null) {
      return joinChat(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return joinChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return joinChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (joinChat != null) {
      return joinChat(this);
    }
    return orElse();
  }
}

abstract class _JoinChat implements ChatEvent {
  const factory _JoinChat(final String chatId) = _$JoinChatImpl;

  String get chatId;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JoinChatImplCopyWith<_$JoinChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SendMessageImplCopyWith<$Res> {
  factory _$$SendMessageImplCopyWith(
          _$SendMessageImpl value, $Res Function(_$SendMessageImpl) then) =
      __$$SendMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, String content});
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
    Object? chatId = null,
    Object? content = null,
  }) {
    return _then(_$SendMessageImpl(
      null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SendMessageImpl implements _SendMessage {
  const _$SendMessageImpl(this.chatId, this.content);

  @override
  final String chatId;
  @override
  final String content;

  @override
  String toString() {
    return 'ChatEvent.sendMessage(chatId: $chatId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendMessageImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, content);

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
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return sendMessage(chatId, content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return sendMessage?.call(chatId, content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(chatId, content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return sendMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return sendMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(this);
    }
    return orElse();
  }
}

abstract class _SendMessage implements ChatEvent {
  const factory _SendMessage(final String chatId, final String content) =
      _$SendMessageImpl;

  String get chatId;
  String get content;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendMessageImplCopyWith<_$SendMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MarkAsReadImplCopyWith<$Res> {
  factory _$$MarkAsReadImplCopyWith(
          _$MarkAsReadImpl value, $Res Function(_$MarkAsReadImpl) then) =
      __$$MarkAsReadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$MarkAsReadImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$MarkAsReadImpl>
    implements _$$MarkAsReadImplCopyWith<$Res> {
  __$$MarkAsReadImplCopyWithImpl(
      _$MarkAsReadImpl _value, $Res Function(_$MarkAsReadImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$MarkAsReadImpl(
      null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MarkAsReadImpl implements _MarkAsRead {
  const _$MarkAsReadImpl(this.chatId);

  @override
  final String chatId;

  @override
  String toString() {
    return 'ChatEvent.markAsRead(chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarkAsReadImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarkAsReadImplCopyWith<_$MarkAsReadImpl> get copyWith =>
      __$$MarkAsReadImplCopyWithImpl<_$MarkAsReadImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return markAsRead(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return markAsRead?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (markAsRead != null) {
      return markAsRead(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return markAsRead(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return markAsRead?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (markAsRead != null) {
      return markAsRead(this);
    }
    return orElse();
  }
}

abstract class _MarkAsRead implements ChatEvent {
  const factory _MarkAsRead(final String chatId) = _$MarkAsReadImpl;

  String get chatId;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarkAsReadImplCopyWith<_$MarkAsReadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'ChatEvent.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() loadChats,
    required TResult Function() refreshChats,
    required TResult Function() connect,
    required TResult Function() disconnect,
    required TResult Function(ChatMessage message) newMessage,
    required TResult Function(Map<String, dynamic> chatData) newChat,
    required TResult Function(String adId) createAdChat,
    required TResult Function(String chatId) joinChat,
    required TResult Function(String chatId, String content) sendMessage,
    required TResult Function(String chatId) markAsRead,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? loadChats,
    TResult? Function()? refreshChats,
    TResult? Function()? connect,
    TResult? Function()? disconnect,
    TResult? Function(ChatMessage message)? newMessage,
    TResult? Function(Map<String, dynamic> chatData)? newChat,
    TResult? Function(String adId)? createAdChat,
    TResult? Function(String chatId)? joinChat,
    TResult? Function(String chatId, String content)? sendMessage,
    TResult? Function(String chatId)? markAsRead,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? loadChats,
    TResult Function()? refreshChats,
    TResult Function()? connect,
    TResult Function()? disconnect,
    TResult Function(ChatMessage message)? newMessage,
    TResult Function(Map<String, dynamic> chatData)? newChat,
    TResult Function(String adId)? createAdChat,
    TResult Function(String chatId)? joinChat,
    TResult Function(String chatId, String content)? sendMessage,
    TResult Function(String chatId)? markAsRead,
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
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_RefreshChats value) refreshChats,
    required TResult Function(_Connect value) connect,
    required TResult Function(_Disconnect value) disconnect,
    required TResult Function(_NewMessage value) newMessage,
    required TResult Function(_NewChat value) newChat,
    required TResult Function(_CreateAdChat value) createAdChat,
    required TResult Function(_JoinChat value) joinChat,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_MarkAsRead value) markAsRead,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_RefreshChats value)? refreshChats,
    TResult? Function(_Connect value)? connect,
    TResult? Function(_Disconnect value)? disconnect,
    TResult? Function(_NewMessage value)? newMessage,
    TResult? Function(_NewChat value)? newChat,
    TResult? Function(_CreateAdChat value)? createAdChat,
    TResult? Function(_JoinChat value)? joinChat,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_MarkAsRead value)? markAsRead,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_RefreshChats value)? refreshChats,
    TResult Function(_Connect value)? connect,
    TResult Function(_Disconnect value)? disconnect,
    TResult Function(_NewMessage value)? newMessage,
    TResult Function(_NewChat value)? newChat,
    TResult Function(_CreateAdChat value)? createAdChat,
    TResult Function(_JoinChat value)? joinChat,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_MarkAsRead value)? markAsRead,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements ChatEvent {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChatState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatSummary> chats) loaded,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatSummary> chats)? loaded,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatSummary> chats)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(ChatStateError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(ChatStateError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(ChatStateError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
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
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'ChatState.initial()';
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
    required TResult Function(List<ChatSummary> chats) loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatSummary> chats)? loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatSummary> chats)? loaded,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(ChatStateError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(ChatStateError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(ChatStateError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements ChatState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'ChatState.loading()';
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
    required TResult Function(List<ChatSummary> chats) loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatSummary> chats)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatSummary> chats)? loaded,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(ChatStateError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(ChatStateError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(ChatStateError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements ChatState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
          _$LoadedImpl value, $Res Function(_$LoadedImpl) then) =
      __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<ChatSummary> chats});
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
      _$LoadedImpl _value, $Res Function(_$LoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chats = null,
  }) {
    return _then(_$LoadedImpl(
      chats: null == chats
          ? _value._chats
          : chats // ignore: cast_nullable_to_non_nullable
              as List<ChatSummary>,
    ));
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl({required final List<ChatSummary> chats}) : _chats = chats;

  final List<ChatSummary> _chats;
  @override
  List<ChatSummary> get chats {
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chats);
  }

  @override
  String toString() {
    return 'ChatState.loaded(chats: $chats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            const DeepCollectionEquality().equals(other._chats, _chats));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_chats));

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatSummary> chats) loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(chats);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatSummary> chats)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(chats);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatSummary> chats)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(chats);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(ChatStateError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(ChatStateError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(ChatStateError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements ChatState {
  const factory _Loaded({required final List<ChatSummary> chats}) =
      _$LoadedImpl;

  List<ChatSummary> get chats;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatStateErrorImplCopyWith<$Res> {
  factory _$$ChatStateErrorImplCopyWith(_$ChatStateErrorImpl value,
          $Res Function(_$ChatStateErrorImpl) then) =
      __$$ChatStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ChatStateErrorImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatStateErrorImpl>
    implements _$$ChatStateErrorImplCopyWith<$Res> {
  __$$ChatStateErrorImplCopyWithImpl(
      _$ChatStateErrorImpl _value, $Res Function(_$ChatStateErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ChatStateErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatStateErrorImpl implements ChatStateError {
  const _$ChatStateErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'ChatState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatStateErrorImplCopyWith<_$ChatStateErrorImpl> get copyWith =>
      __$$ChatStateErrorImplCopyWithImpl<_$ChatStateErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatSummary> chats) loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatSummary> chats)? loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatSummary> chats)? loaded,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(ChatStateError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(ChatStateError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(ChatStateError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class ChatStateError implements ChatState {
  const factory ChatStateError({required final String message}) =
      _$ChatStateErrorImpl;

  String get message;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatStateErrorImplCopyWith<_$ChatStateErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
