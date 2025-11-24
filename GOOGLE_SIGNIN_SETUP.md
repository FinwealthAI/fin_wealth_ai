# Hướng dẫn cấu hình Google Sign-In

## Bước 1: Tạo Google OAuth 2.0 Client IDs

### 1.1. Truy cập Google Cloud Console
1. Vào [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn hoặc tạo project mới
3. Vào **APIs & Services** > **Credentials**

### 1.2. Tạo OAuth 2.0 Client IDs

#### Android Client ID
1. Click **Create Credentials** > **OAuth client ID**
2. Chọn **Application type**: Android
3. Nhập **Package name**: `com.example.fin_wealth` (hoặc package name của bạn)
4. Lấy SHA-1 fingerprint:
   ```bash
   # Debug keystore
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release keystore (nếu có)
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias
   ```
5. Copy **Client ID** (dạng: `xxxxx.apps.googleusercontent.com`)

#### iOS Client ID
1. Click **Create Credentials** > **OAuth client ID**
2. Chọn **Application type**: iOS
3. Nhập **Bundle ID**: `com.example.finWealth` (check trong `ios/Runner.xcodeproj`)
4. Copy **Client ID** và **iOS URL scheme**

#### Web Client ID
1. Click **Create Credentials** > **OAuth client ID**
2. Chọn **Application type**: Web application
3. Thêm **Authorized JavaScript origins**:
   - `http://localhost`
   - `http://localhost:8080`
   - `https://finwealth.vn` (production domain)
4. Copy **Client ID**

## Bước 2: Cấu hình cho từng platform

### 2.1. Android Configuration

**File**: `android/app/build.gradle`

Thêm vào cuối file (trong `dependencies` block hoặc sau đó):
```gradle
// Google Sign-In
implementation 'com.google.android.gms:play-services-auth:20.7.0'
```

**Không cần thêm Client ID vào Android** - package sẽ tự động lấy từ Google Play Services.

### 2.2. iOS Configuration

**File**: `ios/Runner/Info.plist`

Thêm vào trong `<dict>...</dict>`:
```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- TODO: Replace with your iOS URL scheme -->
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_REVERSED</string>
        </array>
    </dict>
</array>

<key>GIDClientID</key>
<!-- TODO: Replace with your iOS Client ID -->
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

**Lưu ý**: `YOUR_IOS_CLIENT_ID_REVERSED` là Client ID đảo ngược, ví dụ:
- Client ID: `123456789-abcdef.apps.googleusercontent.com`
- Reversed: `com.googleusercontent.apps.123456789-abcdef`

### 2.3. Web Configuration

**File**: `web/index.html`

Thêm vào trong `<head>...</head>`:
```html
<!-- Google Sign-In -->
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

## Bước 3: Update GoogleSignIn initialization

**File**: `lib/screens/log_in_screen.dart` và `lib/screens/sign_up_screen.dart`

Nếu cần chỉ định Client ID cụ thể (optional), update:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Optional: Chỉ định Client ID cho iOS/Web
  // clientId: 'YOUR_IOS_OR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

## Bước 4: Test

### Test trên Web (Chrome)
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### Test trên Android
```bash
flutter run -d android
```

### Test trên iOS
```bash
flutter run -d ios
```

## Troubleshooting

### Lỗi: "PlatformException(sign_in_failed)"
- Kiểm tra SHA-1 fingerprint đã đúng chưa
- Kiểm tra package name/bundle ID đã khớp chưa
- Đợi vài phút sau khi tạo Client ID (Google cần thời gian sync)

### Lỗi: "Invalid token audience"
- Backend đang verify `aud` field trong token
- Đảm bảo `SOCIAL_AUTH_GOOGLE_OAUTH2_KEY` trong Django settings khớp với Web Client ID

### Lỗi trên iOS: "No valid client ID found"
- Kiểm tra `GIDClientID` trong `Info.plist`
- Kiểm tra URL scheme đã đảo ngược đúng chưa

## Backend Configuration

Đảm bảo Django settings có:
```python
SOCIAL_AUTH_GOOGLE_OAUTH2_KEY = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = 'YOUR_CLIENT_SECRET'
```

---

**Sau khi hoàn thành setup, Google Sign-In sẽ hoạt động trên tất cả platforms!** 🚀
