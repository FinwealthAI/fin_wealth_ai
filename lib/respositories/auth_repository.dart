import 'package:dio/dio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fin_wealth/config/api_config.dart';

class AccountExpiredException implements Exception {
  final String username;
  final String upgradeUrl; // /open-account/hsc/?u=<username>
  final String zaloGroup;
  final String zaloSupport;
  const AccountExpiredException({
    required this.username,
    required this.upgradeUrl,
    required this.zaloGroup,
    required this.zaloSupport,
  });
}

class AuthRepository {
  final Dio dio;
  late final Dio _tokenDio; // Dio instance riêng để refresh token tránh deadlock
  final String baseUrl;

  String? _accessToken;
  String? _refreshToken;
  String? _username;
  int _totalPoints = 0;
  String? _avatar;
  String? _expirationDate;
  bool _lowPointsWarning = false;
  String? _upgradeUrl;
  
  final _logoutController = StreamController<void>.broadcast();
  Stream<void> get onLogout => _logoutController.stream;

  String? get username => _username;
  int get totalPoints => _totalPoints;
  String? get avatar => _avatar;
  String? get expirationDate => _expirationDate;
  bool get lowPointsWarning => _lowPointsWarning;
  String? get upgradeUrl => _upgradeUrl;

  AuthRepository({required this.dio, String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.mobileApi {
    // Cấu hình mặc định + interceptor JWT
    dio.options = dio.options.copyWith(
      baseUrl: baseUrl,
      headers: {'Accept': 'application/json'},
      followRedirects: false,
      validateStatus: (s) => s != null && s < 500, // để 401 không throw ngay
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    );

    // Khởi tạo _tokenDio với options tương tự nhưng KHÔNG ADD INTERCEPTOR
    _tokenDio = Dio(dio.options);

    // Load tokens from persistence on initialization
    _loadTokens();

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          if (_isTokenInvalidResponse(response) && _refreshToken != null) {
            if (response.requestOptions.path.contains('/token/refresh/')) {
              return handler.next(response);
            }

            try {
              print('AuthRepository: token invalid (${response.statusCode}), refreshing...');
              final r = await _tokenDio.post('/mobile/api/token/refresh/',
                  data: {'refresh': _refreshToken});

              if (r.statusCode == 200) {
                _accessToken = r.data['access'] as String;
                dio.options.headers['Authorization'] = 'Bearer $_accessToken';
                await _saveTokens();

                final options = response.requestOptions;
                options.headers['Authorization'] = 'Bearer $_accessToken';

                final cloned = await dio.fetch(options);
                return handler.resolve(cloned);
              } else {
                print('AuthRepository: Refresh failed, logging out.');
                await logout();
              }
            } catch (e) {
              print('AuthRepository: Refresh error: $e');
              await logout();
            }
          }
          return handler.next(response);
        },
        onError: (err, handler) async {
          final resp = err.response;
          if (resp != null &&
              _isTokenInvalidResponse(resp) &&
              _refreshToken != null) {
            if (err.requestOptions.path.contains('/token/refresh/')) {
              return handler.next(err);
            }
            try {
              final r = await _tokenDio.post('/mobile/api/token/refresh/',
                  data: {'refresh': _refreshToken});
              _accessToken = r.data['access'] as String;
              dio.options.headers['Authorization'] = 'Bearer $_accessToken';
              await _saveTokens();

              final cloned = await dio.fetch(err.requestOptions);
              return handler.resolve(cloned);
            } catch (_) {
              await logout();
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  /// True if the response is a JWT-expired/invalid signal.
  /// SimpleJWT returns 401 normally, but our backend often emits 403 with
  /// `{detail: ..., code: token_not_valid}`.
  static bool _isTokenInvalidResponse(Response resp) {
    final code = resp.statusCode;
    if (code == 401) return true;
    if (code != 403) return false;
    final body = resp.data;
    if (body is Map) {
      if (body['code'] == 'token_not_valid') return true;
      final detail = body['detail']?.toString().toLowerCase() ?? '';
      if (detail.contains('token') &&
          (detail.contains('expired') || detail.contains('invalid'))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _username = prefs.getString('username');
    _totalPoints = prefs.getInt('total_points') ?? 0;
    _avatar = prefs.getString('avatar');
    _expirationDate = prefs.getString('expiration_date');
    _upgradeUrl = prefs.getString('upgrade_url');
    
    // Set authorization header if token exists
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    }
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    } else {
      await prefs.remove('access_token');
    }
    
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    } else {
      await prefs.remove('refresh_token');
    }

    if (_username != null) {
      await prefs.setString('username', _username!);
    } else {
      await prefs.remove('username');
    }

    await prefs.setInt('total_points', _totalPoints);

    if (_avatar != null) {
      await prefs.setString('avatar', _avatar!);
    } else {
      await prefs.remove('avatar');
    }

    if (_expirationDate != null) {
      await prefs.setString('expiration_date', _expirationDate!);
    } else {
      await prefs.remove('expiration_date');
    }

    if (_upgradeUrl != null) {
      await prefs.setString('upgrade_url', _upgradeUrl!);
    } else {
      await prefs.remove('upgrade_url');
    }
  }

  /// Đăng nhập bằng JWT.
  /// Trả về Map để tương thích code cũ (vd. AuthBloc), gồm: {access, refresh, user:{username}}
  Future<Map<String, dynamic>> authenticate(String username, String password) async {
    // Clear tokens trực tiếp mà không bắn logout event, tránh LogoutRequested → AuthInitial
    // sau mỗi lần đăng nhập
    _accessToken = null;
    _refreshToken = null;
    _username = null;
    await _saveTokens();
    dio.options.headers.remove('Authorization');
    
    final response = await dio.post(
      '/mobile/api/token/',
      data: {'username': username, 'password': password},
      options: Options(headers: {'Accept': 'application/json'}),
    );

    if (response.statusCode == 403 &&
        response.data is Map &&
        response.data['code'] == 'account_expired') {
      final upgradeRelative = response.data['upgrade_url'] as String? ?? '';
      final upgradeUrl = upgradeRelative.isNotEmpty
          ? '${ApiConfig.websiteUrl}$upgradeRelative'
          : ApiConfig.websiteUrl;
      throw AccountExpiredException(
        username: response.data['username'] as String? ?? username,
        upgradeUrl: upgradeUrl,
        zaloGroup: response.data['zalo_group'] as String? ?? '',
        zaloSupport: response.data['zalo_support'] as String? ?? '',
      );
    }

    if (response.statusCode == 200) {
      _accessToken  = response.data['access']  as String;
      _refreshToken = response.data['refresh'] as String;

      dio.options.headers['Authorization'] = 'Bearer $_accessToken';
      await _saveTokens();

      final upgradeRelative = response.data['upgrade_url'] as String? ?? '';
      _lowPointsWarning = response.data['low_points_warning'] == true;
      _upgradeUrl = upgradeRelative.isNotEmpty
          ? '${ApiConfig.websiteUrl}$upgradeRelative'
          : null;

      final user = <String, dynamic>{
        'username': response.data['username'] ?? username,
        'avatar': response.data['avatar'],
        'total_points': response.data['point'] ?? 0,
        'expiration_date': response.data['expiration_date']?.toString(),
        'low_points_warning': _lowPointsWarning,
        'upgrade_url': _upgradeUrl,
      };

      _username = user['username'];
      _avatar = user['avatar'];
      _totalPoints = user['total_points'] as int;
      _expirationDate = user['expiration_date'];
      await _saveTokens();

      return user;
    }

    if (response.statusCode == 401) {
      throw Exception('Sai tài khoản hoặc mật khẩu');
    }
    throw Exception('Đăng nhập thất bại (${response.statusCode})');
  }

  /// Kiểm tra nhẹ trạng thái hết hạn — dùng khi app resume từ background.
  /// Throw [AccountExpiredException] nếu tài khoản đã hết điểm.
  /// Không làm gì nếu chưa đăng nhập hoặc lỗi mạng (tránh kick user khi offline).
  Future<void> checkAccountExpiry() async {
    if (_accessToken == null || _accessToken!.isEmpty) return;
    try {
      final response = await _tokenDio.get(ApiConfig.accountStatus);
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['account_expired'] == true) {
          final upgradeRelative = data['upgrade_url'] as String? ?? '';
          throw AccountExpiredException(
            username: data['username'] as String? ?? _username ?? '',
            upgradeUrl: upgradeRelative.isNotEmpty
                ? '${ApiConfig.websiteUrl}$upgradeRelative'
                : ApiConfig.websiteUrl,
            zaloGroup: data['zalo_group'] as String? ?? '',
            zaloSupport: data['zalo_support'] as String? ?? '',
          );
        }
        // Cập nhật điểm mới nhất
        final points = data['total_points'] as int?;
        if (points != null) _totalPoints = points;
      }
    } catch (e) {
      if (e is AccountExpiredException) rethrow;
      // Lỗi mạng → im lặng, không kick user
    }
  }

  Future<void> updatePoints(int points, {String? expiration}) async {
    _totalPoints = points;
    if (expiration != null) {
      _expirationDate = expiration;
    }
    await _saveTokens();
  }

  /// Thử đăng nhập tự động bằng token đã lưu.
  /// Throw [AccountExpiredException] nếu token hợp lệ nhưng tài khoản đã hết điểm.
  /// Return null nếu không có token hoặc token hết hạn.
  Future<Map<String, dynamic>?> tryAutoLogin() async {
    await _loadTokens();
    if (_accessToken == null || _accessToken!.isEmpty) {
      return null;
    }

    // Dùng account-status/ — vừa verify token, vừa check điểm (đồng nhất với web)
    try {
      final response = await _tokenDio.get(ApiConfig.accountStatus);

      if (_isTokenInvalidResponse(response)) {
        // Token hết hạn hoặc invalid → thử refresh
        if (_refreshToken != null && _refreshToken!.isNotEmpty) {
          try {
            final r = await _tokenDio.post('/mobile/api/token/refresh/',
                data: {'refresh': _refreshToken});
            if (r.statusCode == 200) {
              _accessToken = r.data['access'] as String;
              dio.options.headers['Authorization'] = 'Bearer $_accessToken';
              await _saveTokens();
              // Gọi lại sau refresh để lấy account_expired
              return tryAutoLogin();
            }
          } catch (_) {}
        }
        await logout();
        return null;
      }

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final points = data['total_points'] as int? ?? _totalPoints;
        _totalPoints = points;
        final upgradeRelative = data['upgrade_url'] as String? ?? '';
        _upgradeUrl = upgradeRelative.isNotEmpty
            ? '${ApiConfig.websiteUrl}$upgradeRelative'
            : null;
        await _saveTokens();

        // Tài khoản hết hạn — throw để AuthBloc emit AuthAccountExpired
        if (data['account_expired'] == true) {
          throw AccountExpiredException(
            username: data['username'] as String? ?? _username ?? '',
            upgradeUrl: _upgradeUrl ?? ApiConfig.websiteUrl,
            zaloGroup: data['zalo_group'] as String? ?? '',
            zaloSupport: data['zalo_support'] as String? ?? '',
          );
        }

        return {'username': _username ?? 'User'};
      }
    } catch (e) {
      if (e is AccountExpiredException) rethrow;
      // Lỗi mạng → fallback offline-mode, giữ session
    }

    return {'username': _username ?? 'User'};
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> logout() async {
    _refreshToken = null;
    _username = null;
    _totalPoints = 0;
    _avatar = null;
    _expirationDate = null;
    await _saveTokens(); // Clear from storage
    dio.options.headers.remove('Authorization');
    _logoutController.add(null);
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await dio.post(
        ApiConfig.signup,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirm': confirmPassword,
          'role': 'investor',
        },
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('SignUp Response Status: ${response.statusCode}');
      print('SignUp Response Data: ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Save JWT tokens
        _accessToken = response.data['access'] as String;
        _refreshToken = response.data['refresh'] as String;
        
        // Set authorization header
        dio.options.headers['Authorization'] = 'Bearer $_accessToken';
        
        // Get user data
        final user = response.data['user'] as Map<String, dynamic>;
        _username = user['username'];
        _totalPoints = user['point'] ?? 0;
        _avatar = user['avatar'];
        
        // Save tokens
        await _saveTokens();
        
        return true;
      } else if (response.statusCode == 400) {
        // Validation error
        final error = response.data['error'] ?? 'Đăng ký thất bại';
        throw Exception(error);
      }
      
      return false;
    } catch (e) {
      print('SignUp Error: $e');
      rethrow;
    }
  }

  Future<String> forgotPassword(String emailOrUsername) async {
    final response = await dio.post(
      ApiConfig.forgotPassword,
      data: {'email': emailOrUsername},
      options: Options(
        contentType: Headers.jsonContentType,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (response.statusCode == 200) {
      return response.data['message'] as String;
    }
    throw Exception(response.data['error'] ?? 'Có lỗi xảy ra');
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await dio.post(
      ApiConfig.changePassword,
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode == 200) return;

    final error = response.data['error'] ?? 'Đổi mật khẩu thất bại';
    throw Exception(error);
  }

  /// Google Sign-In
  /// Nhận ID token từ Google Sign-In SDK và gọi API backend
  Future<Map<String, dynamic>> googleSignIn(String idToken, {String authEntry = 'login'}) async {
    try {
      final response = await dio.post(
        ApiConfig.googleLogin,
        data: {
          'id_token': idToken,
          'auth_entry': authEntry, // 'login' hoặc 'signup'
        },
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access'] as String;
        _refreshToken = response.data['refresh'] as String;
        
        // Set authorization header
        dio.options.headers['Authorization'] = 'Bearer $_accessToken';
        
        // Get user data
        final user = response.data['user'] as Map<String, dynamic>;
        _username = user['username'];
        _totalPoints = user['point'] ?? 0;
        _avatar = user['avatar'];
        
        // Save tokens
        await _saveTokens();
        
        return user;
      } else if (response.statusCode == 400) {
        // Email đã tồn tại hoặc lỗi validation
        throw Exception(response.data['error'] ?? 'Đăng nhập Google thất bại');
      } else if (response.statusCode == 401) {
        throw Exception('Token không hợp lệ');
      }
      
      throw Exception('Đăng nhập Google thất bại (${response.statusCode})');
    } catch (e) {
      throw Exception('Lỗi đăng nhập Google: $e');
    }
  }
}
