{{flutter_js}}
{{flutter_build_config}}

// KHÔNG truyền serviceWorkerSettings: service worker của Flutter đã bị khai tử
// (bản sinh ra chỉ tự gỡ đăng ký). Bộ nhớ đệm offline do web/sw.js đảm nhận,
// đăng ký trong index.html — xem docs/pwa.md.
_flutter.loader.load();
