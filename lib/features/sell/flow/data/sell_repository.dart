import 'dart:convert';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sell_category.dart';
import '../domain/sell_config.dart';
import '../domain/sell_models.dart';
import '../domain/sell_rules.dart';
import '../domain/sell_variant.dart';

/// Network side of the sell flow: config, brand/model lookups, create.
class SellRepository {
  SellRepository({Dio? dio, AddRepository? legacy})
      : _dio = dio ?? ApiService().dio,
        _legacy = legacy ?? AddRepository();

  final Dio _dio;
  final AddRepository _legacy;

  static final Map<SellCategory, SellConfig> _configMemo = {};
  static final Map<SellCategory, String> _etags = {};
  static const _prefsPrefix = 'sell_config_v1_';

  /// Last known config instantly (memory → disk → fallback). Never throws.
  static Future<SellConfig> cachedConfig(SellCategory c) async {
    final mem = _configMemo[c];
    if (mem != null) return mem;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsPrefix${c.slug}');
      if (raw != null) {
        final cfg = SellConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>, c);
        _configMemo[c] = cfg;
        return cfg;
      }
    } catch (_) {}
    return SellConfig.fallback(c);
  }

  /// Revalidates the config with ETag; keeps the cached copy on any failure.
  Future<SellConfig> refreshConfig(SellCategory c) async {
    final current = await cachedConfig(c);
    try {
      final res = await _dio.get(
        '/v2/sell/config',
        queryParameters: {'category': c.apiValue},
        options: Options(
          headers: {
            if (_etags[c] != null && !current.isFallback) 'If-None-Match': _etags[c],
          },
          validateStatus: (s) => s != null && (s == 304 || (s >= 200 && s < 300)),
        ),
      );
      if (res.statusCode == 304) return current;
      final body = res.data;
      final map = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body)
          : null;
      if (map == null) return current;
      final cfg = SellConfig.fromJson(map, c);
      _configMemo[c] = cfg;
      final etag = res.headers.value('etag');
      if (etag != null) _etags[c] = etag;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_prefsPrefix${c.slug}', jsonEncode(cfg.toJson()));
      } catch (_) {}
      return cfg;
    } catch (_) {
      return current;
    }
  }

  /// One page of brands, popular first. Empty [query] = popular list.
  Future<List<VehicleManufacturer>> searchBrands(SellConfig config, String query) async {
    final res = await _dio.get(
      '/vehicle-inventory/manufacturers',
      queryParameters: {
        'page': 1,
        'limit': 30,
        if (config.manufacturerCategory.isNotEmpty) 'category': config.manufacturerCategory,
        if (query.trim().isNotEmpty) 'search': query.trim(),
      },
    );
    final data = res.data;
    final list = data is Map ? (data['data'] as List? ?? const []) : (data as List? ?? const []);
    return list
        .whereType<Map>()
        .map((e) => VehicleManufacturer.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.id.isNotEmpty && m.displayName.isNotEmpty)
        .toList();
  }

  Future<List<VehicleModel>> models(String manufacturerId) =>
      _legacy.fetchModelsByManufacturer(manufacturerId);

  /// Active variants for a model, cheapest first.
  ///
  /// Three query parameters the app never sent, all already supported by
  /// `FilterVehicleVariantDto`:
  ///  * `limit` — `PaginationDto.limit` defaults to **10**, so a Swift with 18
  ///    trims silently returned 10 of them.
  ///  * `isActive` — the list `$match` does not exclude inactive rows, but
  ///    create-time `findVehicleVariantById` requires `isActive: true`, so a
  ///    listed-but-inactive variant came back as a 422 on Post.
  ///  * `sortBy` / `sortOrder` — the default is `createdAt DESC`, i.e. no
  ///    meaningful order at all.
  Future<List<SellVariant>> variants(String modelId) async {
    final res = await _dio.get(
      '/vehicle-inventory/variants',
      queryParameters: {
        'modelId': modelId,
        'page': 1,
        'limit': 100,
        'isActive': true,
        'sortBy': 'price',
        'sortOrder': 'ASC',
      },
    );
    final data = res.data;
    final list = data is Map ? (data['data'] as List? ?? const []) : (data as List? ?? const []);
    return list
        .whereType<Map>()
        .map((e) => SellVariant.fromJson(Map<String, dynamic>.from(e)))
        .where((v) => v.id.isNotEmpty && v.displayName.isNotEmpty)
        .toList();
  }

  static final Map<String, List<String>> _variantColorMemo = {};

  /// The manufacturer's colour names for one variant.
  ///
  /// The list endpoint projects `colors` only on servers carrying the Sep 2026
  /// change; this fills the gap from the detail endpoint, which has always
  /// returned the whole document. Never throws — no colours just means the
  /// seller sees the standard palette.
  Future<List<String>> variantColors(String variantId) async {
    if (variantId.isEmpty) return const [];
    final memo = _variantColorMemo[variantId];
    if (memo != null) return memo;
    try {
      final res = await _dio.get('/vehicle-inventory/variants/$variantId');
      final body = res.data;
      final map = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body)
          : const <String, dynamic>{};
      final colors = (map['colors'] is List)
          ? (map['colors'] as List)
              .map((e) => '$e'.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : <String>[];
      _variantColorMemo[variantId] = colors;
      return colors;
    } catch (_) {
      return const [];
    }
  }

  Future<AddModel> fetchAd(String id) => _legacy.fetchAdDetail(id);

  /// `POST /v2/ads`. Throws [CreateAdFailure].
  Future<CreatedAd> createAd(Map<String, dynamic> payload, String idempotencyKey) async {
    try {
      final res = await _dio.post(
        '/v2/ads',
        data: payload,
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
          // Server does the slow work after commit; give it room. The same
          // key is replayed on retry, so a timeout never duplicates the ad.
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final body = res.data;
      final map = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body)
          : <String, dynamic>{};
      final id = (map['id'] ?? map['_id'] ?? '').toString();
      if (id.isEmpty) throw const ServerFailure('The ad was saved but no id came back.');
      try {
        AdsCache.instance.clear();
      } catch (_) {}
      return CreatedAd(id, (map['status'] ?? 'pending').toString());
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  static CreateAdFailure mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      default:
        break;
    }
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final code = '${map['code'] ?? ''}';
    final rawMessage = map['message'];
    final message = rawMessage is List
        ? rawMessage.join(', ')
        : (rawMessage?.toString() ?? '');
    if (status == null) return const NetworkFailure();
    if (status == 401) return const AuthFailure();
    if (code == 'ACCOUNT_SUSPENDED' || (status == 403 && message.toLowerCase().contains('suspend'))) {
      return SuspendedFailure(message.isEmpty ? 'Your account can’t post ads right now.' : message);
    }
    if (code == 'IDEMPOTENCY_IN_PROGRESS') return const InProgressFailure();
    if (code == 'IDEMPOTENCY_KEY_REUSED') {
      return const ServerFailure('This ad may already be posted. Check My ads before trying again.', keyReused: true);
    }
    if (status == 429) return const RateLimitedFailure();
    if (status == 422 || (status == 400 && map['fields'] is Map && (map['fields'] as Map).isNotEmpty)) {
      final fields = <String, String>{};
      final raw = map['fields'];
      if (raw is Map) {
        raw.forEach((k, v) {
          final local = SellRules.localKeyFor('$k');
          fields.putIfAbsent(local, () => '$v');
        });
      }
      return ValidationFailure(
        fields,
        message.isEmpty ? 'Some details need fixing' : message,
      );
    }
    return ServerFailure(message.isEmpty ? 'Something went wrong on our side.' : message);
  }
}
