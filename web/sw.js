/*
 * FinWealth PWA — service worker.
 *
 * Tệp trong web/ là KHUÔN: sau `flutter build web`, tool/pwa_build.py điền BUILD
 * (mọi tệp của bản build + SHA-256) vào chỗ đánh dấu bên dưới. Chưa điền (flutter run,
 * bản dev) thì worker không làm gì: mọi request đi thẳng ra mạng, cache fw-app-* bị dọn.
 * Đó cũng là CÔNG TẮC TẮT KHẨN CẤP: deploy một sw.js chưa điền BUILD là mọi máy đã cài
 * quay về tải từ mạng ở lần mở kế tiếp.
 *
 * Nguyên tắc (lý do ở docs/pwa.md):
 *  - Mỗi bản build = MỘT cache `fw-app-<version>`; mở app luôn lấy trọn một phiên bản
 *    (Flutter không có hash trong tên tệp — trộn main.dart.js cũ với asset mới là vỡ app).
 *  - Tệp tải về được kiểm SHA-256 với bản build trước khi vào cache; tệp không đổi hash
 *    được chép từ cache cũ, không tải lại.
 *  - Bản mới KHÔNG tự chiếm quyền: chờ trang gửi SKIP_WAITING (index.html hỏi người dùng,
 *    hoặc tự làm khi app còn ở màn chờ).
 *  - KHÔNG chạm vào API (finwealth.vn khác origin), POST, SSE chat, Google Sign-In.
 */
'use strict';

const BUILD = /*__FW_BUILD__*/null;

const APP_PREFIX = 'fw-app-';
const CDN_CACHE = 'fw-cdn-v1';
const BUILD_KEY = '__fw_build__.json'; // bản kê của phiên bản, lưu trong chính cache của nó
const APP_CACHE = BUILD ? APP_PREFIX + BUILD.version : null;
const SCOPE = new URL(self.registration.scope);
const PARALLEL = 6;

// Tài nguyên CDN bất biến theo URL mà Flutter web tải lúc chạy.
function isCdn(url) {
  return (url.hostname === 'www.gstatic.com' && url.pathname.startsWith('/flutter-canvaskit/')) ||
    (url.hostname === 'fonts.gstatic.com' && url.pathname.startsWith('/s/'));
}

function keyFor(path) {
  return new URL(path, SCOPE).href;
}

function relPath(url) {
  let p = url.pathname;
  if (p.startsWith(SCOPE.pathname)) p = p.slice(SCOPE.pathname.length);
  if (p === '') return 'index.html';
  try {
    return decodeURIComponent(p);
  } catch (_) {
    return p;
  }
}

async function sha(buf) {
  const d = new Uint8Array(await crypto.subtle.digest('SHA-256', buf));
  let s = '';
  for (let i = 0; i < 16; i++) s += d[i].toString(16).padStart(2, '0');
  return s;
}

async function runLimited(items, limit, fn) {
  let i = 0;
  const lanes = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (i < items.length) await fn(items[i++]);
  });
  await Promise.all(lanes);
}

// Tải một tệp của bản build và kiểm đúng nội dung. 'no-cache' = hỏi lại máy chủ (ETag, rẻ);
// lệch hash thì thử 'reload' (bỏ hẳn cache HTTP) rồi mới bỏ cuộc.
async function fetchVerified(path, want) {
  for (const mode of ['no-cache', 'reload']) {
    const resp = await fetch(new Request(keyFor(path), { cache: mode, credentials: 'same-origin' }));
    if (!resp.ok) throw new Error(`[fw-sw] ${path}: HTTP ${resp.status}`);
    const buf = await resp.arrayBuffer();
    if ((await sha(buf)) === want) {
      const headers = { 'Content-Length': String(buf.byteLength) };
      const type = resp.headers.get('Content-Type');
      if (type) headers['Content-Type'] = type;
      return new Response(buf, { status: 200, statusText: 'OK', headers });
    }
  }
  // Thường là đang deploy dở (tệp mới chưa lên đủ): bỏ lượt cài, lần kiểm cập nhật sau thử lại.
  throw new Error(`[fw-sw] ${path}: nội dung không khớp bản build ${BUILD.version}`);
}

async function previousBuilds() {
  const out = [];
  for (const name of await caches.keys()) {
    if (!name.startsWith(APP_PREFIX) || name === APP_CACHE) continue;
    const cache = await caches.open(name);
    const kept = await cache.match(keyFor(BUILD_KEY));
    if (!kept) continue;
    try {
      out.push({ cache, files: (await kept.json()).files || {} });
    } catch (_) {
      // bản kê hỏng: bỏ qua cache này, tải lại từ mạng
    }
  }
  return out;
}

async function precache() {
  const cache = await caches.open(APP_CACHE);
  const prev = await previousBuilds();
  await runLimited(Object.keys(BUILD.files), PARALLEL, async (path) => {
    const key = keyFor(path);
    if (await cache.match(key)) return; // lượt cài trước của CHÍNH bản này đã kiểm và lưu
    const want = BUILD.files[path];
    for (const p of prev) {
      if (p.files[path] !== want) continue;
      const old = await p.cache.match(key);
      if (old) {
        await cache.put(key, old);
        return;
      }
    }
    await cache.put(key, await fetchVerified(path, want));
  });
  // Ghi bản kê SAU CÙNG: có bản kê nghĩa là cache đã đủ.
  await cache.put(keyFor(BUILD_KEY), new Response(JSON.stringify(BUILD), {
    headers: { 'Content-Type': 'application/json' },
  }));
}

async function dropAppCaches(keep) {
  for (const name of await caches.keys()) {
    if (name.startsWith(APP_PREFIX) && name !== keep) await caches.delete(name);
  }
}

async function pruneCdn() {
  if (!BUILD.engine) return;
  const cache = await caches.open(CDN_CACHE);
  for (const req of await cache.keys()) {
    const u = new URL(req.url);
    if (u.hostname === 'www.gstatic.com' && !u.pathname.includes(`/${BUILD.engine}/`)) {
      await cache.delete(req);
    }
  }
}

self.addEventListener('install', (event) => {
  if (!BUILD) {
    self.skipWaiting();
    return;
  }
  event.waitUntil(precache());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    if (BUILD) {
      await dropAppCaches(APP_CACHE);
      await pruneCdn();
    } else {
      await dropAppCaches(null);
      await caches.delete(CDN_CACHE);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') self.skipWaiting();
});

const OFFLINE_HTML = `<!doctype html><html lang="vi"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>FinWealth</title>
<body style="margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
background:#0D0F17;color:#E5E7EB;font:15px/1.5 system-ui,-apple-system,sans-serif;text-align:center">
<div style="padding:24px"><p style="font-size:17px;font-weight:600;margin:0 0 8px">Chưa có kết nối mạng</p>
<p style="margin:0 0 20px;color:#9CA3AF">FinWealth cần mạng để tải lần đầu.</p>
<button onclick="location.reload()" style="background:#7C3AED;color:#fff;border:0;border-radius:999px;
padding:10px 22px;font-size:15px">Thử lại</button></div></body></html>`;

async function fromApp(path, req) {
  const hit = await (await caches.open(APP_CACHE)).match(keyFor(path));
  if (hit) return hit;
  // Cache chưa đủ (đang cài, hoặc trình duyệt đã dọn bộ nhớ): đi mạng và KHÔNG ghi vào
  // cache — không chắc nội dung đó thuộc đúng phiên bản này.
  try {
    return await fetch(req);
  } catch (err) {
    if (req.mode === 'navigate') {
      return new Response(OFFLINE_HTML, { headers: { 'Content-Type': 'text/html; charset=utf-8' } });
    }
    throw err;
  }
}

async function fromCdn(req) {
  const cache = await caches.open(CDN_CACHE);
  const hit = await cache.match(req);
  if (hit) return hit;
  const resp = await fetch(req);
  if (resp.ok) cache.put(req, resp.clone()).catch(() => {});
  return resp;
}

self.addEventListener('fetch', (event) => {
  if (!BUILD) return;
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  if (url.origin === self.location.origin) {
    if (req.mode === 'navigate') {
      event.respondWith(fromApp('index.html', req));
      return;
    }
    const path = relPath(url);
    if (Object.prototype.hasOwnProperty.call(BUILD.files, path)) {
      event.respondWith(fromApp(path, req));
    }
    return; // tệp ngoài bản kê (sw.js, NOTICES, canvaskit cục bộ…) → mạng như thường
  }

  if (isCdn(url)) event.respondWith(fromCdn(req));
  // Mọi origin khác (API finwealth.vn, Google Sign-In…) không đụng tới.
});
