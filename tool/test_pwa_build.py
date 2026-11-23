"""Test tool/pwa_build.py — chạy: python3 -m unittest discover -s tool -p 'test_*.py'"""
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pwa_build  # noqa: E402

ENGINE = 'a' * 40
PNG = b'\x89PNG\r\n\x1a\n' + b'\0' * 32


def fake_build(root: Path, **override):
    files = {
        'index.html': "<base href=\"/\"><script>sw.register('sw.js', {})</script>",
        'flutter_bootstrap.js': '_flutter.buildConfig = {"engineRevision":"%s","builds":[]};\n'
                                '_flutter.loader.load();' % ENGINE,
        'flutter.js': '// loader',
        'main.dart.js': '// app v1',
        'manifest.json': json.dumps({
            'name': 'FinWealth', 'short_name': 'FinWealth', 'start_url': '/', 'display': 'standalone',
            'icons': [{'src': 'icons/Icon-192.png', 'sizes': '192x192', 'type': 'image/png'}],
        }),
        'icons/Icon-192.png': PNG,
        'assets/FontManifest.json': '[]',
        'assets/NOTICES': 'licenses',
        'canvaskit/canvaskit.wasm': 'wasm',
        'flutter_service_worker.js': '// deprecated',
        'main.dart.js.map': '{}',
        'sw.js': "const BUILD = /*__FW_BUILD__*/null;",
    }
    files.update(override)
    for rel, content in files.items():
        if content is None:
            continue
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(content if isinstance(content, bytes) else content.encode())


def injected(root: Path) -> dict:
    sw = (root / 'sw.js').read_text()
    return json.loads(sw[len('const BUILD = '):-1])


class PwaBuildTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_injects_manifest_with_sha256_prefix_matching_sw(self):
        fake_build(self.root)
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 0)
        build = injected(self.root)
        self.assertEqual(build['engine'], ENGINE)
        self.assertEqual(build['files']['main.dart.js'],
                         hashlib.sha256(b'// app v1').hexdigest()[:32])
        self.assertEqual(len(build['version']), 12)

    def test_excludes_files_the_worker_must_not_cache(self):
        fake_build(self.root)
        pwa_build.main(['x', str(self.root)])
        files = injected(self.root)['files']
        for rel in ('sw.js', 'flutter_service_worker.js', 'assets/NOTICES',
                    'canvaskit/canvaskit.wasm', 'main.dart.js.map'):
            self.assertNotIn(rel, files)
        self.assertIn('assets/FontManifest.json', files)
        self.assertIn('icons/Icon-192.png', files)

    def test_version_changes_only_when_content_changes(self):
        fake_build(self.root)
        v1 = pwa_build.build_manifest(self.root)['version']
        self.assertEqual(pwa_build.build_manifest(self.root)['version'], v1)
        (self.root / 'main.dart.js').write_text('// app v2')
        self.assertNotEqual(pwa_build.build_manifest(self.root)['version'], v1)

    def test_running_twice_fails_instead_of_double_injecting(self):
        fake_build(self.root)
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 0)
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 1)

    def test_default_flutter_bootstrap_is_rejected(self):
        # Thiếu web/flutter_bootstrap.js → Flutter sinh bản đăng ký worker tự gỡ của nó.
        fake_build(self.root, **{'flutter_bootstrap.js':
                                 '_flutter.buildConfig = {"engineRevision":"%s"};'
                                 '_flutter.loader.load({serviceWorkerSettings: {}});' % ENGINE})
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 1)
        self.assertIn('/*__FW_BUILD__*/null', (self.root / 'sw.js').read_text())

    def test_loader_code_mentioning_service_worker_is_not_a_false_alarm(self):
        # flutter.js nhúng trong bootstrap có sẵn tên tham số serviceWorkerSettings.
        fake_build(self.root, **{'flutter_bootstrap.js':
                                 'class b{async load({serviceWorkerSettings:e,onEntrypointLoaded:n}={}){}}\n'
                                 '_flutter.buildConfig = {"engineRevision":"%s"};\n'
                                 '// KHÔNG truyền serviceWorkerSettings\n'
                                 '_flutter.loader.load();' % ENGINE})
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 0)

    def test_jpeg_icon_is_rejected(self):
        fake_build(self.root, **{'icons/Icon-192.png': b'\xff\xd8\xff\xe0JFIF'})
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 1)

    def test_unbuilt_index_is_rejected(self):
        fake_build(self.root, **{'index.html':
                                 "<base href=\"$FLUTTER_BASE_HREF\"><script>sw.register('sw.js')</script>"})
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 1)

    def test_missing_required_file_is_rejected(self):
        fake_build(self.root, **{'main.dart.js': None})
        self.assertEqual(pwa_build.main(['x', str(self.root)]), 1)


if __name__ == '__main__':
    unittest.main()
