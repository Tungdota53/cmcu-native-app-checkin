# Đề xuất nâng cấp toàn diện CMC Check-in

Đây là backlog đề xuất sau phần đã triển khai ngày 15/10/2026. Các mục bên dưới chưa được coi là chức năng đã có.

## Ưu tiên 1 — Sẵn sàng dùng trên thiết bị thật

| Nâng cấp | Giá trị | Tiêu chí hoàn thành |
|---|---|---|
| Hoàn thiện project iOS/Android | Có bản cài tái lập được | Tạo platform project, kiểm tra deployment target, URL scheme, App Group, manifest, ký bản build và chạy thử hai nền tảng |
| Kiểm thử SSO và quyền menu | Đăng nhập ổn định, xem đúng dữ liệu tài khoản | Thử tài khoản có nhiều chương trình, phiên cũ, hết hạn, chuyển tài khoản và thiếu quyền điểm; xác minh endpoint chi tiết điểm trên phiên được phép |
| Quản lý phiên tập trung | Các tab hết phiên đồng nhất | Một trạng thái đăng nhập dùng chung, chặn request cũ sau logout, không lưu dữ liệu tài khoản cũ, thử lại sau khi tái xác thực |
| Củng cố điều hướng WebView | Đăng nhập và quay lại app nhất quán | Allowlist host portal/SSO dựa trên luồng thực tế; xử lý popup, callback, lỗi tải trang và nút quay lại trên thiết bị |
| Cổng kiểm tra CI | Phát hiện API/UI hỏng trước khi đóng gói | Chạy analyze/test trước build; fixture tổng hợp đã khử dữ liệu, kiểm tra logout/widget/deep link và bản build thiết bị |

## Ưu tiên 2 — Trợ lý học tập hằng ngày

| Nâng cấp | Giá trị | Lưu ý triển khai |
|---|---|---|
| Trang Tổng quan | Thấy lớp sắp học, lịch thi gần nhất, điểm mới và hạn quan trọng | Dùng dữ liệu portal đã xác minh; mỗi khối có lần cập nhật riêng |
| Lịch thi riêng | Dễ chuẩn bị, tránh nhầm lịch học | HAR có `lichthi.js`; đối chiếu đầy đủ request/schema trước khi mở rộng |
| Nhắc lịch cục bộ | Nhắc trước giờ học/thi theo tùy chọn | Xin quyền thông báo khi bật; lập lại lịch khi portal đổi; không gửi điểm danh tự động |
| Widget Android và hoàn thiện iOS | Xem buổi học gần nhất ngoài màn hình chính | Đồng bộ snapshot, trạng thái cũ/hết phiên, kiểm tra App Group và deep link cold start |
| Theo dõi tiến độ tín chỉ | Biết nhóm kiến thức còn thiếu | Dùng các nhóm bắt buộc/tự chọn và kết quả tích lũy trong API; xử lý môn tương đương, học lại và ngoài chương trình |
| Chi tiết môn và lịch sử lần thi | Hiểu sự thay đổi kết quả từng môn | Giữ riêng từng kết quả, học kỳ, lần học/lần thi; không suy đoán công thức GPA chính thức |
| Học phí | Xem khoản phải nộp, đã nộp và hạn thanh toán | HAR có tài nguyên học phí; cần kiểm tra ngữ nghĩa số tiền/công nợ và quyền truy cập; giai đoạn đầu chỉ đọc |

## Ưu tiên 3 — Cá nhân hóa và khả năng truy cập

- Cho chọn sáng/tối/hệ thống, màu nhấn, tiếng Việt/Anh; lưu tùy chọn trên máy.
- Tìm kiếm không dấu, sắp xếp điểm/tên/tín chỉ; có bộ lọc theo đánh giá chính thức từ portal.
- Biểu đồ xu hướng GPA học kỳ từ số liệu chính thức, đi kèm bảng dữ liệu dễ đọc bằng trình đọc màn hình.
- Công cụ lập mục tiêu GPA có nhãn “ước tính”; chỉ bật sau khi xác nhận quy chế tính điểm, môn được tính và cách thay thế điểm học lại.
- Hỗ trợ VoiceOver/TalkBack, focus bàn phím, nhãn nút rõ nghĩa, màn hình ngang/tablet, text scale 200% và kiểm tra tương phản.
- Chế độ ẩn điểm khi chia sẻ màn hình, mở khóa sinh trắc học tùy chọn và xuất bảng điểm do người dùng chủ động yêu cầu.

## Ưu tiên 4 — Dữ liệu và vận hành

- Cache lịch/điểm offline theo tài khoản, có mã hóa, thời hạn và nhãn ngày giờ cập nhật; xóa cache khi logout. Hiện điểm chỉ được giữ trong RAM.
- Tách repository/API contract khỏi controller; thêm injection clock/network để kiểm thử ổn định các mốc giờ.
- Nhận biết lỗi mạng, timeout, HTTP, từ chối nghiệp vụ và schema thay đổi riêng; tránh retry thao tác điểm danh có thể tạo ghi nhận lặp.
- Theo dõi thay đổi API bằng contract test có dữ liệu giả lập; nếu cần báo lỗi từ xa, chỉ thu endpoint mẫu, mã lỗi và thời gian đáp ứng sau khi người dùng bật.
- Hoàn thiện test crypto theo test vector README, ma trận cookie/session, widget stale, lịch thi và chuyển tuần nhanh.
- Chuẩn hóa release: version/changelog, cấu hình theo môi trường, signing và checklist thiết bị trước phát hành.

## Thứ tự triển khai đề nghị

1. Platform + SSO/quyền xem điểm + nghiệm thu bảng điểm/chi tiết trên thiết bị thật.
2. Tổng quan + lịch thi + nhắc lịch + widget.
3. Tiến độ chương trình + biểu đồ học kỳ + học phí chỉ đọc.
4. Cá nhân hóa + cache offline mã hóa + công cụ lập kế hoạch học tập.

Mỗi đợt cần tiêu chí nghiệm thu riêng, tránh đưa các suy đoán từ một HAR thành quy tắc học vụ cho mọi sinh viên.
