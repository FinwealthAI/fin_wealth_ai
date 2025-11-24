# Báo cáo Điều tra Lỗi WSL và Git Corruption

Dựa trên các log hệ thống và kiểm tra trạng thái, tôi đã tìm ra nguyên nhân nghiêm trọng gây ra việc WSL mất kết nối và hỏng dự án Git.

## 1. Phát hiện chính (Critical Findings)

### A. Lỗi Hệ thống (System Crashes)
Hệ thống ghi nhận hàng loạt lỗi **Segmentation Fault (Segfault)** từ các ứng dụng quan trọng. Đây là lý do chính khiến WSL bị "sập" (crash) và VS Code báo "Cannot reconnect".

Trích xuất từ log (`dmesg`):
```text
[ 1817.024898] git[23262]: segfault at ... error 4 in git...
[ 3028.592034] potentially unexpected fatal signal 5. (Chrome crash)
[ 3054.711203] potentially unexpected fatal signal 6. (Node crash)
[ 3959.855209] git[110883]: segfault at ... (Git crash)
```
Việc `git`, `node`, và `chrome` đều bị crash ngẫu nhiên là dấu hiệu của sự bất ổn định ở cấp độ thấp (phần cứng hoặc kernel).

### B. Hỏng dữ liệu Git (Git Corruption)
Do `git` bị crash trong quá trình ghi dữ liệu, repository hiện tại đã bị hỏng nặng cấu trúc.
Lệnh `git fsck` trả về hàng loạt lỗi:
```text
error: object file .git/objects/0c/... is empty
error: unable to mmap ... No such file or directory
missing blob ...
```
Các file object bị rỗng (empty) cho thấy quá trình ghi xuống đĩa bị ngắt đột ngột.

## 2. Nguyên nhân Tiềm năng

1.  **Xung đột Antivirus (Windows Defender)**: Đây là nguyên nhân phổ biến nhất. Nếu Windows Defender quét các file Linux trong thời gian thực, nó có thể khóa file khi Git đang ghi, gây ra crash và hỏng dữ liệu.
2.  **Lỗi RAM (Memory Hardware Failure)**: Các lỗi Segfault ngẫu nhiên trên nhiều ứng dụng khác nhau thường là dấu hiệu của RAM bị lỗi.
3.  **WSL 2 Backend Issue**: Phiên bản kernel của WSL có thể đang gặp lỗi tương thích.

## 3. Giải pháp Đề xuất

### Bước 1: Cấu hình Antivirus (Quan trọng nhất)
Bạn cần thêm thư mục làm việc của WSL vào danh sách loại trừ (Exclusion) của Windows Defender.
*   Mở **Windows Security** > **Virus & threat protection**.
*   Chọn **Manage settings**.
*   Kéo xuống **Exclusions** > **Add or remove exclusions**.
*   Thêm Folder: Chọn đường dẫn đến thư mục project Linux (thường truy cập qua `\\wsl$\Ubuntu\home\tinphan...`).

### Bước 2: Cập nhật và Khởi động lại WSL
Mở PowerShell (Run as Administrator) trên Windows và chạy:
```powershell
wsl --update
wsl --shutdown
```
Sau đó mở lại VS Code.

### Bước 3: Khắc phục Git Repository
Do repo hiện tại đã hỏng nặng (missing blobs), việc sửa chữa thủ công rất rủi ro và tốn kém thời gian.
*   **Khuyến nghị**: Xóa thư mục repo hiện tại và `git clone` lại từ remote.
*   **Lưu ý**: Nếu bạn có code chưa push, hãy copy các file code đó ra một chỗ khác trước khi xóa folder.

### Bước 4: Kiểm tra Phần cứng (Nếu lỗi vẫn tiếp diễn)
Nếu sau khi làm các bước trên mà vẫn bị crash, hãy chạy **Windows Memory Diagnostic** để kiểm tra xem RAM máy tính có bị lỗi không.ddd
