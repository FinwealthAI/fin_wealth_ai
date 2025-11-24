import 'package:dio/dio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fin_wealth/config/api_config.dart';

class AuthRepository {
  final Dio dio;
  final String baseUrl;

  String? _accessToken;
  String? _refreshToken;
  String? _username;
  
  final _logoutController = StreamController<void>.broadcast();
  Stream<void> get onLogout => _logoutController.stream;

  String? get username => _username;

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
        onError: (err, handler) async {
          // Nếu access hết hạn → refresh rồi retry
          if (err.response?.statusCode == 401 && _refreshToken != null) {
            try {
              final r = await dio.post('/mobile/api/token/refresh/', data: {'refresh': _refreshToken});
              _accessToken = r.data['access'] as String;
              dio.options.headers['Authorization'] = 'Bearer $_accessToken';
              // Save the new access token
              await _saveTokens();
              // Retry request cũ
              final cloned = await dio.fetch(err.requestOptions);
              return handler.resolve(cloned);
            } catch (_) {
              // Refresh fail -> coi như đăng xuất
              await logout();
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _username = prefs.getString('username');
    
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
  }

  /// Đăng nhập bằng JWT.
  /// Trả về Map để tương thích code cũ (vd. AuthBloc), gồm: {access, refresh, user:{username}}
  Future<Map<String, dynamic>> authenticate(String username, String password) async {
    // Clear any existing authentication state before attempting new login
    // This prevents stale tokens from interfering with fresh login attempts
    await logout();
    
    final response = await dio.post(
      '/mobile/api/token/',
      data: {'username': username, 'password': password},
      options: Options(headers: {'Accept': 'application/json'}),
    );

    if (response.statusCode == 200) {
      _accessToken  = response.data['access']  as String;
      _refreshToken = response.data['refresh'] as String;

      // 👉 GẮN HEADER Ở ĐÂY (bạn hỏi)
      dio.options.headers['Authorization'] = 'Bearer $_accessToken';

      // Save tokens to persistence
      await _saveTokens();

      // Lấy thông tin user từ API response
      final user = <String, dynamic>{
        'username': response.data['username'] ?? username,
        'avatar': response.data['avatar'],
      };
      
      _username = user['username'];
      await _saveTokens(); // Save again to include username

      return user; // Trả về trực tiếp user data
    }

    if (response.statusCode == 401) {
      throw Exception('Sai tài khoản hoặc mật khẩu');
    }
    throw Exception('Đăng nhập thất bại (${response.statusCode})');
  }

  /// Thử đăng nhập tự động bằng token đã lưu
  Future<Map<String, dynamic>?> tryAutoLogin() async {
    await _loadTokens();
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return {
        'username': _username ?? 'User',
        // Có thể thêm avatar nếu lưu
      };
    }
    return null;
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _username = null;
    await _saveTokens(); // Clear from storage
    dio.options.headers.remove('Authorization');
    _logoutController.add(null);
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
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
