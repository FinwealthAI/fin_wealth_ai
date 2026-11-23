#!/usr/bin/env python3
"""Bước hậu build PWA cho m.finwealth.vn (xem docs/pwa.md).

Chạy NGAY SAU `flutter build web` (CI làm ở .github/workflows/deploy.yml):

    python3 tool/pwa_build.py build/web

Việc làm: kê mọi tệp của bản build kèm SHA-256 rồi điền vào chỗ đánh dấu trong
build/web/sw.js. Bản kê đổi khi và chỉ khi nội dung build đổi ⇒ trình duyệt thấy
sw.js khác byte ⇒ cài bản mới, chỉ tải lại tệp đổi hash.

Hỏng bất kỳ kiểm tra nào thì thoát mã ≠ 0 để CI dừng trước khi deploy: một sw.js
sai có thể giữ người dùng ở bản cũ, nên thà không deploy.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

MARKER = '/*__FW_BUILD__*/null'

# Không đưa vào bản kê ⇒ worker không cache, request đi thẳng mạng.
EXCLUDE_DIRS = (
    'canvaskit/',  # CanvasKit nạp từ gstatic theo engineRevision; bản cục bộ (~25 MB) không dùng tới
)
EXCLUDE_FILES = {
    'sw.js',                      # chính worker — trình duyệt tự tải
    'flutter_service_worker.js',  # worker đã khai tử của Flutter, không còn được đăng ký
    'version.json',               # app không đọc
    'assets/NOTICES',             # ~1 MB, chỉ màn giấy phép đọc
    '.last_build_id',
}
EXCLUDE_SUFFIXES = ('.map', '.symbols')

REQUIRED = ('index.html', 'flutter_bootstrap.js', 'flutter.js', 'main.dart.js', 'manifest.json')


class BuildError(Exception):
    pass


def file_hash(path: Path) -> str:
    # 32 ký tự hex đầu của SHA-256 — sw.js tính đúng như vậy bằng crypto.subtle.
    return hashlib.sha256(path.read_bytes()).hexdigest()[:32]


def is_cached(rel: str) -> bool:
    if rel in EXCLUDE_FILES or rel.endswith(EXCLUDE_SUFFIXES):
        return False
    if rel.startswith(EXCLUDE_DIRS):
        return False
    return not any(part.startswith('.') for part in rel.split('/'))


def collect(build_dir: Path) -> dict:
    files = {}
    for p in sorted(build_dir.rglob('*')):
        if not p.is_file():
            continue
        rel = p.relative_to(build_dir).as_posix()
        if is_cached(rel):
            files[rel] = file_hash(p)
    return files


def check_build(build_dir: Path, files: dict) -> str:
    """Kiểm bản build đúng cấu hình PWA; trả về engineRevision (để dọn CanvasKit cũ)."""
    missing = [f for f in REQUIRED if f not in files]
    if missing:
        raise BuildError(f'thiếu tệp trong bản build: {", ".join(missing)}')

    index = (build_dir / 'index.html').read_text(encoding='utf-8')
    if '$FLUTTER_BASE_HREF' in index:
        raise BuildError('index.html còn $FLUTTER_BASE_HREF — không phải bản build của flutter build web')
    if "register('sw.js'" not in index:
        raise BuildError('index.html không đăng ký sw.js')

    bootstrap = (build_dir / 'flutter_bootstrap.js').read_text(encoding='utf-8')
    # Chỉ xét ĐỐI SỐ của lời gọi load(): mã loader flutter.js nhúng ở đầu tệp có sẵn chữ
    # "serviceWorkerSettings" (tên tham số) nên tìm chuỗi trần là báo động giả.
    calls = re.findall(r'_flutter\.loader\.load\(([^;]*)\)', bootstrap)
    if not calls:
        raise BuildError('flutter_bootstrap.js không gọi _flutter.loader.load()')
    if any('serviceWorker' in args for args in calls):
        # Flutter dùng bootstrap mặc định (không thấy web/flutter_bootstrap.js) ⇒ đăng ký
        # flutter_service_worker.js tự gỡ, giành scope với sw.js.
        raise BuildError('flutter_bootstrap.js vẫn đăng ký service worker của Flutter')
    if '"useLocalCanvasKit":true' in bootstrap:
        raise BuildError('bản build dùng CanvasKit cục bộ nhưng canvaskit/ không được cache — sửa EXCLUDE_DIRS')
    m = re.search(r'"engineRevision":"([0-9a-f]{40})"', bootstrap)
    if not m:
        raise BuildError('không đọc được engineRevision trong flutter_bootstrap.js')

    manifest = json.loads((build_dir / 'manifest.json').read_text(encoding='utf-8'))
    for key in ('name', 'short_name', 'start_url', 'display', 'icons'):
        if not manifest.get(key):
            raise BuildError(f'manifest.json thiếu "{key}"')
    for icon in manifest['icons']:
        if icon['src'] not in files:
            raise BuildError(f'manifest.json trỏ tới icon không có trong bản build: {icon["src"]}')
        if icon.get('type') != 'image/png' or not (build_dir / icon['src']).read_bytes().startswith(b'\x89PNG'):
            raise BuildError(f'icon {icon["src"]} phải là PNG thật (Chrome không nhận JPEG)')
    return m.group(1)


def build_manifest(build_dir: Path) -> dict:
    files = collect(build_dir)
    engine = check_build(build_dir, files)
    digest = hashlib.sha256('\n'.join(f'{k}:{v}' for k, v in files.items()).encode()).hexdigest()
    return {'version': digest[:12], 'engine': engine, 'files': files}


def inject(build_dir: Path) -> dict:
    sw_path = build_dir / 'sw.js'
    if not sw_path.is_file():
        raise BuildError('không có sw.js trong bản build (web/sw.js bị xoá?)')
    sw = sw_path.read_text(encoding='utf-8')
    if sw.count(MARKER) != 1:
        raise BuildError(f'sw.js phải có đúng một chỗ đánh dấu {MARKER} (đã chạy script này rồi?)')
    build = build_manifest(build_dir)
    payload = json.dumps(build, ensure_ascii=False, separators=(',', ':'), sort_keys=True)
    sw_path.write_text(sw.replace(MARKER, payload), encoding='utf-8')
    return build


def main(argv) -> int:
    build_dir = Path(argv[1] if len(argv) > 1 else 'build/web')
    try:
        build = inject(build_dir)
    except (BuildError, OSError, ValueError, KeyError) as e:
        print(f'[pwa_build] LỖI: {e}', file=sys.stderr)
        return 1
    total = sum((build_dir / f).stat().st_size for f in build['files'])
    print(f'[pwa_build] sw.js bản {build["version"]} · engine {build["engine"][:10]} · '
          f'{len(build["files"])} tệp · {total / 1e6:.1f} MB (chưa nén)')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
