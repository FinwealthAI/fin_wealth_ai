#!/usr/bin/env python3
"""Sinh icon PWA (web/icons/*, web/favicon.png) từ assets/images/logo_standard.jpg.

    pip install pillow && python3 tool/make_pwa_icons.py

Chỉ lấy biểu tượng FW (bỏ chữ "Finwealth": ở cỡ 48px chữ thành vệt mờ, và tên app
đã hiện ngay dưới icon). Toạ độ cắt đo trên logo_standard.jpg 1024×1024 — đổi logo
thì đo lại (ngưỡng "mực" = tổng |RGB − 254| > 90). Xem docs/pwa.md.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets/images/logo_standard.jpg'
OUT = ROOT / 'web'
BG = (254, 254, 254)  # đúng màu nền của file logo

# Biểu tượng FW: hàng 303–596, cột 319–692.
MARK_BOX = (315, 299, 697, 598)
# Hàng 592–598, cột 660–697 là đỉnh chữ «lth» của wordmark → xoá. Đuôi ngôi sao giữa
# (cột 529–537, tới hàng 596) nằm ngoài vùng này nên giữ nguyên.
WORDMARK_TIPS = (660, 592, 697, 598)

# tỷ lệ bề ngang biểu tượng / cạnh icon
SPECS = {
    'icons/Icon-192.png': (192, 0.70),
    'icons/Icon-512.png': (512, 0.70),
    # maskable: Android cắt tròn/bo góc — biểu tượng phải nằm trong vòng tròn 80% giữa
    'icons/Icon-maskable-192.png': (192, 0.56),
    'icons/Icon-maskable-512.png': (512, 0.56),
    'icons/apple-touch-icon.png': (180, 0.66),  # iOS tự bo góc, không nhận nền trong suốt
    'favicon.png': (64, 0.88),
}


def main():
    logo = Image.open(SRC).convert('RGB')
    mark = logo.crop(MARK_BOX)
    x0, y0 = MARK_BOX[:2]
    tx0, ty0, tx1, ty1 = WORDMARK_TIPS
    ImageDraw.Draw(mark).rectangle((tx0 - x0, ty0 - y0, tx1 - x0, ty1 - y0), fill=BG)
    mw, mh = mark.size

    for name, (size, frac) in SPECS.items():
        canvas = Image.new('RGB', (size, size), BG)
        w = round(size * frac)
        h = round(w * mh / mw)
        canvas.paste(mark.resize((w, h), Image.LANCZOS), ((size - w) // 2, (size - h) // 2))
        canvas.save(OUT / name, 'PNG', optimize=True)
        print(f'{name}: {size}px')

    w = SPECS['icons/Icon-maskable-512.png'][1]
    half_diag = 0.5 * math.hypot(w, w * mh / mw)
    assert half_diag <= 0.40, f'maskable lọt khỏi vùng an toàn: {half_diag:.3f}'


if __name__ == '__main__':
    main()
