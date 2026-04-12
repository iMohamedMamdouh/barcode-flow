import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

class OdooClient {
  late Dio _dio;
  late CookieJar _cookieJar;

  String? baseUrl;
  String? database;
  int? uid;
  int _requestId = 0;

  bool get isAuthenticated => uid != null;

  OdooClient() {
    _cookieJar = CookieJar();
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<int> authenticate({
    required String url,
    required String db,
    required String login,
    required String password,
  }) async {
    try {
      final normalizedUrl =
          url.endsWith('/') ? url.substring(0, url.length - 1) : url;

      final response = await _dio.post(
        '$normalizedUrl${ApiConstants.authEndpoint}',
        data: {
          'jsonrpc': '2.0',
          'id': _nextId(),
          'params': {'db': db, 'login': login, 'password': password},
        },
      );

      final result = response.data;

      if (result['error'] != null) {
        final errorData = result['error'];
        throw AuthException(
          errorData['data']?['message'] ??
              errorData['message'] ??
              'فشل تسجيل الدخول',
        );
      }

      final resultData = result['result'];
      if (resultData == null ||
          resultData['uid'] == null ||
          resultData['uid'] == false) {
        throw const AuthException('بيانات الدخول غير صحيحة');
      }

      baseUrl = normalizedUrl;
      database = db;
      uid = resultData['uid'] as int;

      return uid!;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException(
          'لا يمكن الاتصال بالخادم، تحقق من العنوان',
        );
      }
      throw ServerException('خطأ في الاتصال: ${e.message}');
    } catch (e) {
      if (e is AuthException || e is NetworkException || e is ServerException) {
        rethrow;
      }
      throw ServerException('خطأ غير متوقع: $e');
    }
  }

  Future<List<dynamic>> searchRead({
    required String model,
    List<dynamic> domain = const [],
    required List<String> fields,
    int? limit,
    int? offset,
    String? order,
  }) async {
    _ensureAuthenticated();

    try {
      final kwargs = <String, dynamic>{'fields': fields};
      if (limit != null) kwargs['limit'] = limit;
      if (offset != null) kwargs['offset'] = offset;
      if (order != null) kwargs['order'] = order;

      final response = await _dio.post(
        '$baseUrl${ApiConstants.callKwEndpoint}',
        data: {
          'jsonrpc': '2.0',
          'id': _nextId(),
          'method': 'call',
          'params': {
            'model': model,
            'method': 'search_read',
            'args': [domain],
            'kwargs': kwargs,
          },
        },
      );

      final result = response.data;

      if (result['error'] != null) {
        final errorData = result['error'];
        throw ServerException(
          errorData['data']?['message'] ??
              errorData['message'] ??
              'خطأ في جلب البيانات',
        );
      }

      return (result['result'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      throw ServerException('خطأ في الاتصال: ${e.message}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('خطأ في جلب البيانات: $e');
    }
  }

  Future<List<dynamic>> read({
    required String model,
    required List<int> ids,
    required List<String> fields,
  }) async {
    _ensureAuthenticated();

    try {
      final response = await _dio.post(
        '$baseUrl${ApiConstants.callKwEndpoint}',
        data: {
          'jsonrpc': '2.0',
          'id': _nextId(),
          'method': 'call',
          'params': {
            'model': model,
            'method': 'read',
            'args': [ids],
            'kwargs': {'fields': fields},
          },
        },
      );

      final result = response.data;

      if (result['error'] != null) {
        final errorData = result['error'];
        throw ServerException(
          errorData['data']?['message'] ??
              errorData['message'] ??
              'خطأ في جلب البيانات',
        );
      }

      return (result['result'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      throw ServerException('خطأ في الاتصال: ${e.message}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('خطأ في قراءة البيانات: $e');
    }
  }

  void logout() {
    uid = null;
    baseUrl = null;
    database = null;
    _cookieJar.deleteAll();
  }

  void _ensureAuthenticated() {
    if (!isAuthenticated) {
      throw const AuthException('يجب تسجيل الدخول أولاً');
    }
  }

  int _nextId() => ++_requestId;
}
