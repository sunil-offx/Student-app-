import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const _baseUrlPreferenceKey = 'api_base_url';
  static const _unconfiguredBaseUrl = 'https://not-configured.invalid/api';

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;
  String? _memoryAccessToken;
  String? _memoryRefreshToken;
  String? _configuredBaseUrl;

  bool get isConfigured => _configuredBaseUrl != null;
  String? get configuredBaseUrl => _configuredBaseUrl;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _unconfiguredBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _memoryAccessToken ??
            await _storage.read(key: 'access_token');
        _memoryAccessToken = token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        if (error.response?.statusCode != 401 ||
            request.extra['authRetry'] == true ||
            request.extra['skipAuthRefresh'] == true) {
          handler.next(error);
          return;
        }

        try {
          await _refreshToken();
          request
            ..extra['authRetry'] = true
            ..headers['Authorization'] = 'Bearer $_memoryAccessToken';
          handler.resolve(await _dio.fetch(request));
        } catch (_) {
          await clearTokens();
          handler.next(error);
        }
      },
    ));
  }

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedBaseUrl = preferences.getString(_baseUrlPreferenceKey);
    final initialBaseUrl = savedBaseUrl ?? ApiConstants.defaultBaseUrl;
    if (initialBaseUrl.isNotEmpty) {
      _setBaseUrl(initialBaseUrl);
    }
  }

  Future<void> configureBaseUrl(String value) async {
    final baseUrl = _normalizeBaseUrl(value);
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Enter a valid HTTPS backend URL, such as https://your-service.onrender.com.',
      );
    }

    final response = await _dio.getUri(Uri.parse('$baseUrl/health'));
    final body = response.data;
    if (body is! Map || body['status'] != 'ok') {
      throw const FormatException(
        'The URL responded, but it is not a healthy EduPortal API server.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_baseUrlPreferenceKey, baseUrl);
    if (!saved) {
      throw StateError('Could not save the backend URL on this device.');
    }
    _setBaseUrl(baseUrl);
  }

  String _normalizeBaseUrl(String value) {
    var baseUrl = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (!baseUrl.endsWith('/api')) {
      baseUrl = '$baseUrl/api';
    }
    return baseUrl;
  }

  void _setBaseUrl(String value) {
    final baseUrl = _normalizeBaseUrl(value);
    _configuredBaseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  void _requireConfiguration() {
    if (!isConfigured) {
      throw StateError(
        'Connect the app to your deployed backend before signing in.',
      );
    }
  }

  Future<void> _refreshToken() async {
    final refreshToken =
        _memoryRefreshToken ?? await _storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token is available.');
    }

    final response = await _dio.post(
      ApiConstants.refreshToken,
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'skipAuthRefresh': true}),
    );
    final data = _asMap(response.data);
    final accessToken = data['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException(
        'The refresh response did not include an access token.',
      );
    }
    await saveTokens(
      accessToken,
      data['refresh_token'] as String? ?? refreshToken,
    );
  }

  Future<void> saveTokens(String access, String refresh) async {
    _memoryAccessToken = access;
    _memoryRefreshToken = refresh;
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    _requireConfiguration();
    final response = await _dio.get(path, queryParameters: queryParams);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    _requireConfiguration();
    final response = await _dio.post(path, data: data);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    required Map<String, dynamic> fields,
  }) async {
    _requireConfiguration();
    final response = await _dio.post(path, data: FormData.fromMap(fields));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    _requireConfiguration();
    final response = await _dio.put(path, data: data);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    _requireConfiguration();
    final response = await _dio.delete(path);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> uploadFile(
    String path,
    dynamic file, {
    Map<String, dynamic>? extraFields,
    void Function(int, int)? onProgress,
  }) async {
    _requireConfiguration();
    final filePath = file is String ? file : (file as dynamic).path as String?;
    if (filePath == null || filePath.isEmpty) {
      throw ArgumentError('The selected upload does not have a local file path.');
    }
    final multipartFile = await MultipartFile.fromFile(
      filePath,
      filename: filePath.split(RegExp(r'[/\\]')).last,
    );
    final formData = FormData.fromMap({
      'file': multipartFile,
      if (extraFields != null) ...extraFields,
    });
    final response = await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onProgress,
    );
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}
