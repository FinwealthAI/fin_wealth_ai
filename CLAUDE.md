# CLAUDE.md

Hướng dẫn cho Claude Code khi làm việc trong dự án này.

## Tổng quan

`mobile_finwealth` là app **Flutter** (package `fin_wealth`) — client di động của nền tảng đầu tư chứng khoán **Finwealth**. App tiêu thụ API của backend Django đặt tại `../finwealth` (`/home/tinphan/workspace/finwealth`). Giao diện và nghiệp vụ mobile bám theo web Django finwealth; label hiển thị cho người dùng dùng **tiếng Việt**.

- Flutter SDK Dart: `>=3.2.3 <4.0.0`
- Giao diện **dark-first** (theo `lib/theme/`).

## Lệnh thường dùng

```bash
flutter pub get                                   # cài deps
flutter run                                        # chạy (mặc định gọi backend production)
flutter run --dart-define=USE_LOCAL_BACKEND=true   # chạy với backend local
flutter analyze                                    # lint/phân tích tĩnh
flutter test                                       # chạy test
dart run build_runner build --delete-conflicting-outputs  # sinh code json_serializable
```

## Kiến trúc

Phân tầng: **UI (screens/widgets) → BLoC → Repository → Dio → Backend Django**.

- **State management**: `flutter_bloc`. Các BLoC chính trong `lib/blocs/`: `auth/` (AuthBloc — login, refresh token, hết hạn tài khoản), `search/` (SearchBloc), `market/` (MarketBloc), `stock_reports/` (StockReportsBloc). Nhiều màn hình V2 dùng `StatefulWidget` gọi thẳng repository.
- **Repository**: `lib/respositories/` (lưu ý: thư mục viết là `respositories`, không phải `repositories`) — `auth_repository.dart`, `watchlist_repository.dart`, `market_evaluation_repository.dart`, `strategy_repository.dart`, `blog_repository.dart`, ...
- **Networking**: `dio`. Auth bằng **JWT** — header `Authorization: Bearer <token>`, có interceptor tự refresh khi gặp 401. Token lưu trong `flutter_secure_storage`; conversation id / cache nhẹ trong `shared_preferences`.
- **Routing**: named-route khai báo trong `lib/main.dart` (`/splash-v2`, `/login-v2`, `/v2`, `/stock-detail-v2`, ...). Hub điều hướng chính là `RootShellV2` (`lib/screens/v2/root_shell_v2.dart`): bottom nav **4 tab** (Home / Strategy / Market Evaluation / More) + FAB "Mr.Wealth" mở **thẳng màn Chat** (`ChatScreenV2`, bỏ trang AI Toolbox trung gian). **Blog** đã chuyển vào tab **More** (cùng Lọc cổ phiếu / Tính margin / Biểu đồ kinh tế). Icon tab: Strategy `rocket_launch`, Market `speed` (để phân biệt rõ). Các màn con push bằng `MaterialPageRoute`.

## Cấu trúc `lib/`

```
lib/
├── blocs/            # BLoC state (auth, market, search, stock_reports)
├── config/           # api_config.dart (base URL/endpoints), secrets.dart (OAuth)
├── models/           # data models (dashboard_home, market_evaluation, watchlist_item,
│                     #   stock_*, chat_models, blog_post, ...)
├── respositories/    # tầng dữ liệu (gọi Dio) — CHÚ Ý chính tả
├── screens/v2/       # toàn bộ màn hình đang dùng (kiến trúc V2)
├── services/         # chat_history_service.dart, ...
├── widgets/          # common/, dashboard/, stock_detail/, strategy/, blog/ ...
├── theme/            # design system
├── utils/            # currency_formatter, date_formatter, strategy_icon
└── main.dart         # entry + named routes
```

Màn hình sống trong `lib/screens/v2/` (hậu tố `_v2`): `home_screen_v2`, `chat_screen_v2`, `ai_toolbox_screen_v2`, `ai_report_screen_v2`, `strategy_screen_v2`, `stock_detail_screen_v2`, `market_evaluation_screen_v2`, `screener_screen_v2`, `margin_screen_v2`, `blog_screen_v2`, `reports_screen_v2`, `notifications_screen_v2`, `profile_screen_v2`, `upgrade_screen_v2`, `login/signup/forgot/change_password`, `splash_screen_v2`, `root_shell_v2`.

## Cấu hình API

`lib/config/api_config.dart`:
- Production: `https://finwealth.vn`
- Local: `http://localhost:8000` (web/desktop) hoặc `http://10.0.2.2:8000` (Android emulator)
- Chọn bằng `--dart-define=USE_LOCAL_BACKEND=true` (mặc định bật ở debug).

Tiền tố endpoint:
- `{baseUrl}/mobile/api` — phần lớn API riêng cho mobile (dashboard-home, market-evaluation, screener, margin, blog, account-status, value-chain, charts...).
- `{baseUrl}/api` — auth, reports, workflows, **chat** (`/api/chat/...`).
- `{baseUrl}/watchlist`, `{baseUrl}/filter-stock/api/v1` — watchlist & marketplace chiến lược.

Auth: `POST /mobile/api/token/` (login), `/mobile/api/token/refresh/` (refresh).

## Design system (`lib/theme/`)

- `app_colors.dart` — bảng màu dark-first (brand purple `#7C3AED`, blue `#2563EB`; nền `darkBg #0D0F17`, surface `darkSurface`/`darkSurfaceElevated`; text primary/secondary/muted; `purpleGlow`).
- `app_typography.dart` — font **Inter**.
- `app_spacing.dart` — thang spacing (xs4 … xxxl48) và border-radius (sm8 … pill999).
- Tham khảo `lib/theme/DESIGN_GUIDE.md`. Ưu tiên tái dùng widget trong `lib/widgets/common/` (vd `FwAppBar`, `FwFilterPill`).

## Chat / Agent (Mr.Wealth)

Backend đã có **Agent V2 (Native ReAct Orchestrator)** trong app Django `agent` — pipeline nhiều bước: classify → chạy các agent (retrieve) → tổng hợp (synthesize), stream kết quả qua **SSE**.

Mobile đã code lại phần chat thành **V3** bám pipeline Agent V2 (class vẫn tên `ChatScreenV2` để giữ wiring). Các file:
- `lib/screens/v2/chat_screen_v2.dart` — UI chat V3: hiển thị panel tiến trình agent (classify card + các bước agent) **chỉ khi đang stream** rồi tự ẩn; toggle **Flash/Pro**; tự nhận diện ticker từ `valid-tickers`; like/dislike + copy; drawer danh sách hội thoại (mở/đổi tên/xoá/mới); suggested prompts. Hiệu ứng "đang gõ" dùng widget `_TypingDots` (3 chấm, KHÔNG dùng `CircularProgressIndicator`). Auto-scroll bám đáy theo từng chunk qua `_followStream()` (chỉ cuộn khi user đang ở gần đáy); nút scroll-to-bottom đổi sang tím nổi bật khi đang stream. Bảng markdown render qua `_ScrollableTableBuilder` (`builders: {'table': ...}`) → **cuộn ngang**, cột giữ độ rộng tự nhiên (giống Claude/ChatGPT/Gemini app), tránh bị bóp vỡ chữ.
- `lib/services/chat_history_service.dart` — `streamMessage()` trả `Stream<Map>` đã decode từng event SSE (kèm sentinel `{type:'__done__'}`); thêm `getValidTickers()` (cache), `listConversations()`, `renameConversation()`, `deleteConversation()`.
- `lib/models/chat_models.dart` — `ChatMode` (flash/pro), `AgentStep` + `AgentStepStatus`, `ClassifyEvent`, `ChatConversationSummary`, `ChatMessage` (steps/classify/mode/ticker/rating/isStreaming), `ChatFeedback`.

Dependency thêm: `markdown` (để custom `MarkdownElementBuilder` cho bảng).

Endpoint (đều dưới `{baseUrl}/api/chat/`): `send/` (POST, SSE stream), `stop/`, `feedback/`, `conversations/`, `conversations[/<id>]/messages/`, `conversations[/<id>]/rename/`, `conversations[/<id>]/delete/`, `valid-tickers/`.

**Wire format SSE của `POST /api/chat/send/`** (mỗi sự kiện là `data: {json}\n\n`, kết thúc `data: [DONE]\n\n`):
1. `{conversation_id, task_id}`
2. `{message_id, task_id}`
3. `{type:"classify", intent, ticker, activated_agents[], reasoning, mode}`
4. mỗi agent: `{type:"agent_start", role_id, label, icon, version}` → `{type:"agent_done", role_id, elapsed_ms, summary}` (có thể có `agent_error`, `skill_loaded`)
5. token trả lời: `{answer:"<chunk>"}` (ghép thành markdown)
6. `[DONE]`

Request body: `{ query, conversation_id?, mode: "flash"|"pro", inputs: { category?, ticker? } }`.

Nguồn tham chiếu backend: `../finwealth/agent/views.py` (`send_chat_message`), `../finwealth/agent/agent_service.py` (`run_pipeline` / `stream_response`), `../finwealth/agent/urls.py`.

## Quy ước

- Bám theme + widget có sẵn; không hardcode màu/spacing.
- Label người dùng bằng tiếng Việt.
- Model JSON dùng `json_serializable` (chạy `build_runner` sau khi sửa model có annotation).
- Khi đổi tầng dữ liệu, sửa ở `respositories/` + `models/`, không nhét logic API vào widget.
