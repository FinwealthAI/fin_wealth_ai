# FinWealth Mobile — Design System Reference

File chuẩn cho **mọi component và màn hình mới**. Khi viết UI, tham chiếu file này trước khi tự tạo style.

---

## 1. Tokens (lib/theme/)

### Màu sắc
```dart
import 'package:fin_wealth/theme/theme.dart';

AppColors.brandPrimary       // #7C3AED — purple, action chính
AppColors.brandPrimaryDark   // #C084FC — purple sáng (text/icon trên dark)
AppColors.brandSecondary     // #2563EB — blue
AppColors.brandSecondaryDark // #60A5FA

AppColors.successDark        // #34D399 — tích cực, %change xanh, FA "Mạnh"
AppColors.warningDark        // #FBBF24 — chú ý, FA "Trung bình"
AppColors.dangerDark         // #FB7185 — tiêu cực, %change đỏ, FA "Yếu"

AppColors.darkBg             // #0D0F17 — scaffold
AppColors.darkSurface        // #151923 — card
AppColors.darkSurfaceElevated// #1E2230 — popover, elevated
AppColors.darkBorder         // #2A2F3D — border 1px

AppColors.darkTextPrimary    // #F8FAFC — text chính
AppColors.darkTextSecondary  // #CBD5E1 — text phụ
AppColors.darkTextMuted      // #64748B — caption
```

### Spacing & Radius
```dart
AppSpacing.xs / sm / md / lg / xl / xxl / xxxl  // 4 / 8 / 12 / 16 / 24 / 32 / 48
AppRadius.sm / md / lg / xl / pill              // 8 / 12 / 16 / 20 / 999
```

### Typography
- Font: **Inter** (`AppTypography.fontFamily`)
- Lấy qua `Theme.of(context).textTheme.titleLarge` ...
- Scale: `displayLarge` (32) → `displayMedium` (28) → `headlineLarge` (24) → `headlineMedium` (20) → `headlineSmall` (18) → `titleLarge` (16) → `titleMedium` (14) → `titleSmall` (13) → `bodyLarge` (15) → `bodyMedium` (14) → `bodySmall` (12) → `labelLarge` (14) → `labelMedium` (12) → `labelSmall` (11)

---

## 2. Shared Components (lib/widgets/common/)

Import qua barrel:
```dart
import 'package:fin_wealth/widgets/common/common.dart';
```

### Buttons

| Khi nào dùng | Component | Variants | Size |
|---|---|---|---|
| Action chính full-width (login, submit) | `FwButton` | primary / secondary / ghost / danger | sm (36) / md (44) / lg (52) |
| **Action nhỏ trong card** (Xem thêm, Chi tiết, Phân tích) | **`FwMiniButton`** | gradient / soft / outline | **fixed compact (8h/6v, icon 13, text 11)** |

**QUY TẮC**: mọi button nhỏ trên card BẮT BUỘC dùng `FwMiniButton`. Không tự code Material+InkWell+Container nữa.

```dart
// Primary action trong card (gradient purple→blue, white text)
FwMiniButton.primary(label: 'Lưu', icon: Icons.save, onTap: ...)

// Soft tinted (default tone purple, có thể override)
FwMiniButton.soft(label: 'Xem thêm', icon: Icons.menu_book_outlined, onTap: ...)
FwMiniButton.soft(label: 'Sơ đồ', icon: Icons.account_tree_outlined,
                  tone: AppColors.brandSecondaryDark, onTap: ...)

// Full-width trong Expanded
Expanded(child: FwMiniButton.soft(label: '...', fullWidth: true, onTap: ...))
```

### Card / Container

| Component | Khi nào dùng |
|---|---|
| `FwCard` | Container chuẩn radius lg + border + padding lg |
| `FwAppBar` | AppBar có title + subtitle + auto Home button |
| `FwSectionHeader` | Tiêu đề section trong list (icon + title + actionLabel) |
| `FwSegmentedTabs` | Tab chuyển (Top Wealth / Following / Community) |
| `FwFilterPillBar` | Filter pill scroll ngang |
| `FwBadge` | Status pill nhỏ (6 tones) |
| `FwSkeleton` | Loading shimmer |
| `FwEmptyState` | Empty placeholder (icon + title + message + action) |

### Specialized cards

| Component | Vị trí dùng |
|---|---|
| `WealthScoreCard` | 3 variants Golden/Wave/Value (deprecated cho home, dùng `OpportunityCard` thay) |
| `OpportunityCard` | Top cơ hội hôm nay — có status badge + score + FA/TA + CTA "Chi tiết" |
| `OpportunityFilterBar` | Pill filter cho 4 nhóm cơ hội |
| `AiInsightCard` | Mr.Wealth nhận định + VN-Index chip + "Xem thêm" |
| `ValueChainVolatilityList` | Horizontal scroll yếu tố vĩ mô (Phân tích / Sơ đồ buttons) |
| `BlogCard` | Card blog 2-col grid |
| `StrategyTickerCard` / `StrategySummaryCard` | Cards màn Chiến lược |
| `SignalRow`, `WatchlistRow`, `ReportRow` | Row trong list dashboard |

---

## 3. Layout patterns

### Page padding
- ListView body: `padding: EdgeInsets.symmetric(vertical: AppSpacing.md)` rồi mỗi section tự `EdgeInsets.symmetric(horizontal: AppSpacing.lg)` nếu cần.
- Bottom padding cho FAB/nav: `AppSpacing.xxxl` (48).

### Section structure
```dart
FwSectionHeader(title: '...', icon: ..., actionLabel: 'Xem tất cả'),
const SizedBox(height: AppSpacing.xs),
// content (List/Grid/Card)
const SizedBox(height: AppSpacing.lg),  // gap giữa sections
```

### Horizontal scroll lists
- Card width: `MediaQuery.of(context).size.width * 0.74` (peek ~25% card kế)
- Separator: `SizedBox(width: AppSpacing.md)`
- List padding: `EdgeInsets.symmetric(horizontal: AppSpacing.lg)`

---

## 4. Quy tắc viết UI mobile

1. **Mobile-first, không bê layout web**: web 2-col → mobile 1-col, sidebar → bottom-sheet, modal → full-screen route.
2. **Compact**: ưu tiên content actionable, bỏ banner/profile bar full-width.
3. **1 dòng text mặc định, tap để mở rộng** — không show paragraph dài trên dashboard.
4. **Nút nhỏ → `FwMiniButton`** — không tự code, không inline padding.
5. **Mọi inner screen có `FwAppBar`** với `showHome: true` (default) → tự động hiện nút Home.
6. **Spacing rhythm**: chỉ dùng `AppSpacing.*`, không hardcode padding.
7. **Màu theo trạng thái**: positive → `successDark`, warning → `warningDark`, negative → `dangerDark`.
8. **Strength label** (FA/TA): dùng `OpportunityCard._strengthColor()` quy ước:
   - "Mạnh"/"Tốt" → green
   - "Chú ý"/"Trung bình" → amber
   - "Yếu"/"Xấu" → red

---

## 5. Khi tạo screen mới

```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';

class MyScreenV2 extends StatelessWidget {
  const MyScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FwAppBar(title: 'Tên màn hình', subtitle: 'Mô tả'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          // ...
        ],
      ),
    );
  }
}
```
