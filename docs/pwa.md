# PWA — m.finwealth.vn cài được như app

`m.finwealth.vn` là bản Flutter web của dự án này (CI build rồi chép lên `/var/www/m_finwealth`; điện thoại vào `finwealth.vn` bị `MobileRedirectMiddleware` của backend chuyển sang đây). Từ 23/11/2026 bản web là **PWA**: cài lên màn hình chính, mở toàn màn hình, mở lại tức thì từ cache, cập nhật có kiểm soát.

Backend Django **không cần đổi gì**.

## Thành phần

| Tệp | Vai trò |
|---|---|
| `web/manifest.json` | Tên, màu, icon, 3 lối tắt nhấn-giữ-icon (`/?open=chat\|strategy\|market`) |
| `web/icons/*`, `web/favicon.png` | Icon PNG thật, sinh bằng `tool/make_pwa_icons.py` |
| `web/index.html` | Thẻ meta PWA/iOS · splash HTML · cầu nối `window.fwPwa` · đăng ký `sw.js` + thông báo "Đã có phiên bản mới" |
| `web/flutter_bootstrap.js` | Gọi `_flutter.loader.load()` KHÔNG kèm `serviceWorkerSettings` |
| `web/sw.js` | Service worker — là KHUÔN, CI điền bản kê tệp |
| `tool/pwa_build.py` (+ `test_pwa_build.py`) | Hậu build: kê tệp + SHA-256 vào `build/web/sw.js`, chặn deploy nếu bản build sai cấu hình |
| `lib/pwa/` | Phía Flutter: `Pwa` (cầu nối, bản trống trên native), thẻ mời cài, hướng dẫn theo trình duyệt |
| `lib/screens/v2/root_shell_v2.dart` | Lối tắt khi mở app (Chiến lược/Thị trường tự vào "Phân tích sâu"; Mr.Wealth là màn mặc định) · thẻ mời cài sau 20 giây (ở Chat: dưới thanh tiêu đề, không che ô nhập; ở "Phân tích sâu": chỉ tab Trang chủ, trên thanh tab) · mục "Cài FinWealth lên điện thoại" trong menu ba gạch và tab Khác |

⚠️ Mọi tệp trong `web/` được phát hành công khai — đừng để tài liệu/ghi chú ở đó.

## Vì sao làm thế này (đừng hoàn nguyên)

- **Icon cũ là JPEG 1024×796 (không vuông) khai là PNG** → Chrome không nhận cài đặt (chỉ tạo lối tắt). Icon mới chỉ lấy biểu tượng FW; bản `maskable` đặt biểu tượng trong vòng tròn 80% để Android cắt tròn không mất nét. `pwa_build.py` từ chối icon không phải PNG thật.
- **Service worker của Flutter đã bị khai tử**: `flutter_service_worker.js` mà Flutter 3.4x sinh ra chỉ tự gỡ đăng ký, nhưng bootstrap mặc định vẫn đăng ký nó mỗi lần mở. `web/flutter_bootstrap.js` bỏ việc đó; `pwa_build.py` báo lỗi nếu bootstrap mặc định quay lại.
- **Flutter không có hash trong tên tệp** (`main.dart.js`, `assets/…`). Trộn `main.dart.js` cũ với asset mới là vỡ app, nên mỗi bản build = MỘT cache `fw-app-<version>` và app luôn chạy trọn một phiên bản. Tệp tải về được kiểm SHA-256 với bản kê trước khi vào cache (deploy dở → lệch hash → bỏ lượt cài, lần sau thử lại). Tệp không đổi hash được chép từ cache cũ: mỗi lần deploy thường chỉ tải lại `main.dart.js` (~1,6 MB nén).
- **Bản mới không tự chiếm quyền**: tải lại giữa lúc chat cắt ngang câu trả lời. Còn ở màn chờ thì chuyển ngay; đang dùng thì hiện "Đã có phiên bản mới · Cập nhật". App đã cài ít khi bị đóng hẳn nên mỗi lần quay lại app (tối đa 30 phút/lần) có kiểm bản mới.
- **Đăng ký worker SAU khung hình đầu + 3 giây**: lúc đó `main.dart.js` đã nằm trong cache HTTP, worker kiểm lại bằng ETag (304) thay vì tải lần hai trên mạng di động.
- **Worker không chạm tới**: API (`finwealth.vn`, khác origin), POST, SSE chat, Google Sign-In. CDN chỉ cache `www.gstatic.com/flutter-canvaskit/` (gắn revision engine; dọn bản cũ khi engine đổi) và `fonts.gstatic.com/s/`.
- **Splash HTML** vẽ giống hệt `SplashScreenV2` (nền, logo 96px, chữ 36/44, vòng xoay 22px `#C084FC`) để thay trang trắng trong lúc tải mà không nháy khi Flutter vẽ khung đầu. Sửa splash Flutter thì sửa cả ở `web/index.html`.
- **`beforeinstallprompt` bị giữ lại** (`preventDefault`) để app tự mời đúng lúc; vì thế Chrome không tự hiện thanh mời — thẻ mời + mục trong menu ba gạch/tab Khác thay thế. Trình duyệt trong Zalo/Facebook/TikTok không cài được: không mời, mục cài hướng dẫn mở bằng Safari/Chrome.

## Công tắc tắt khẩn cấp

Nếu worker gây sự cố (người dùng kẹt bản cũ, cache hỏng): deploy một `sw.js` **chưa điền** bản kê (`BUILD = null`) — ví dụ tạm bỏ bước `python3 tool/pwa_build.py` trong CI. Worker đó tự kích hoạt, xoá mọi cache `fw-app-*`/`fw-cdn-*` và để mọi request đi thẳng mạng; máy đã cài nhận nó ở lần mở kế tiếp. KHÔNG xoá hẳn `sw.js` khỏi máy chủ (404 không gỡ được worker đang chạy).

## Nginx (cài tay trên server, KHÔNG có trong git)

PWA chạy được khi chưa áp phần này (worker tự bỏ qua cache HTTP), nhưng nên áp vì: (1) trình duyệt chưa có worker (lần đầu, trình duyệt nhúng) hiện có thể dùng `main.dart.js` cũ sau deploy — hiện máy chủ không gửi `Cache-Control`; (2) font icon 1,6 MB đang gửi không nén (gzip còn 0,56 MB, tiết kiệm ~1,2 MB lần tải đầu).

Đặt trong `server { }` của m.finwealth (đo 23/11/2026: các header trên chưa có):

```nginx
# Tệp không có hash trong tên: luôn hỏi lại máy chủ (không đổi → 304, rẻ).
location ~ ^/(index\.html|flutter_bootstrap\.js|flutter\.js|main\.dart\.js|sw\.js|version\.json)?$ {
    root /var/www/m_finwealth;
    add_header Cache-Control "no-cache" always;
    try_files $uri /index.html;
}
location = /manifest.json {
    root /var/www/m_finwealth;
    types { } default_type application/manifest+json;
    add_header Cache-Control "no-cache" always;
}
location ~* \.(otf|ttf)$ {
    root /var/www/m_finwealth;
    types { font/otf otf; font/ttf ttf; }
    gzip on;
    gzip_types font/otf font/ttf;
}
```

⚠️ `add_header` trong một `location` làm mất các `add_header` khai ở cấp `server` (vd HSTS) cho location đó — server đang khai gì thì chép thêm vào. `sudo nginx -t && sudo systemctl reload nginx`, rồi kiểm:

```bash
curl -sI https://m.finwealth.vn/main.dart.js | grep -i cache-control      # no-cache
curl -sI https://m.finwealth.vn/manifest.json | grep -i content-type      # application/manifest+json
curl -s -o /dev/null -w "%{size_download}\n" -H "Accept-Encoding: gzip" \
     https://m.finwealth.vn/assets/fonts/MaterialIcons-Regular.otf        # ~563000, không phải 1645184
```

## Kiểm thử

- `python3 -m unittest discover -s tool -p 'test_*.py'` (CI chạy trước `pwa_build.py`).
- Cục bộ: `flutter build web --release --dart-define=USE_LOCAL_BACKEND=false --no-tree-shake-icons && python3 tool/pwa_build.py build/web`, rồi `python3 -m http.server 8765 --directory build/web` và mở `http://localhost:8765` → DevTools › Application: Manifest (không lỗi), Service workers (`sw.js` đang chạy), Cache storage (`fw-app-<version>` 35 mục). API production chặn CORS từ localhost nên dữ liệu báo lỗi — bình thường.
- Đã kiểm 23/11/2026 bằng Chrome headless (CDP): 0 lỗi cài đặt (`Page.getInstallabilityErrors`), `beforeinstallprompt` bắn trên Android, thẻ mời (màn Chat) → hướng dẫn iPhone → ẩn 14 ngày, mục cài trong menu ba gạch, lối tắt `?open=market` mở tab Thị trường, mở lại khi máy chủ chết (khung đầu 1,2 s), deploy giả lập → thông báo cập nhật → chỉ tải lại `main.dart.js` + `sw.js`.
- Bẫy khi tự động hoá: giả lập điện thoại thì phải gửi sự kiện CHẠM (`Input.dispatchTouchEvent`), chuột bị Flutter bỏ qua; Chrome headless vẫn bắn `beforeinstallprompt` kể cả khi giả UA iPhone — bấm "Cài đặt" sẽ mở hộp cài thật (vô hình ở headless) và chặn mọi thao tác sau.
- **Còn phải thử trên máy thật**: Android Chrome (cài, mở từ icon, nhấn giữ icon → lối tắt), iPhone Safari (Thêm vào MH chính), mở link từ Zalo.

## Giới hạn đã biết

- **iPhone: app đã cài có bộ nhớ riêng với Safari** → phải đăng nhập lại một lần sau khi cài. Đăng nhập Google trong cửa sổ app đã cài trên iPhone cần thử thật (cửa sổ bật lên của Google có thể không quay về được app); đăng nhập bằng tài khoản/mật khẩu không bị ảnh hưởng.
- Flutter web tự đặt thẻ `viewport` (không có `viewport-fit=cover`) và không đọc vùng an toàn của iPhone: thanh điều hướng dưới có thể sát vạch home.
- Chưa có thông báo đẩy (web push) — iOS 16.4+ chỉ cho web push với app ĐÃ CÀI; đây là bước tiếp theo tự nhiên cho bản tin chủ động.
- Chưa đo số lượt cài/mở từ icon (backend không ghi nguồn client).
