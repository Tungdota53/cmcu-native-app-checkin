# CMC Check-in

Ứng dụng Flutter xem lịch học, nhập từ khóa điểm danh và xem kết quả học tập từ cổng sinh viên CMC.

## Chức năng

- **Lịch học:** chuyển tuần/ngày, phân biệt lịch học và lịch thi, kéo để tải lại, điểm danh bằng từ khóa giảng viên cung cấp.
- **Kết quả:** chọn chương trình học, lọc học kỳ, tìm theo tên/mã học phần, xem điểm hệ 10/hệ 4/điểm chữ, đánh giá, lần học/lần thi và điểm thành phần.
- **Tổng quan:** GPA tích lũy, trung bình học kỳ, tín chỉ tích lũy và tiến độ chương trình từ số liệu portal. Không tự tính lại GPA bằng cách lấy trung bình các điểm đang lọc.
- **Giao diện:** Material 3, hai tab điều hướng, thẻ tổng quan, tiếng Việt, chế độ sáng/tối theo hệ thống và bố cục thích ứng chữ lớn.
- **Trạng thái:** đang tải, rỗng, lỗi, thử lại, thời điểm cập nhật; giữ dữ liệu đã tải trong RAM khi làm mới thất bại và báo rõ dữ liệu cũ.

## Chạy và kiểm tra

Cần Flutter >= 3.44 / Dart >= 3.12 theo bộ dependency trong `pubspec.lock`. Lượt triển khai này được kiểm tra bằng Flutter 3.47.7 / Dart 3.13.5 trên Windows.

```sh
flutter pub get
flutter analyze
flutter test
```

Kết quả kiểm tra: `flutter analyze` không có vấn đề; 14 unit/widget test chạy thành công, bao gồm giao diện sáng/tối 320px với text scale 150%. Kiểm tra offline HAR đọc được 1 chương trình, 16 học phần và 3 học kỳ; xác nhận bộ chọn GPA toàn khóa/học kỳ. Đây chưa phải kiểm thử trực tiếp tài khoản hoặc thiết bị.

Checkout hiện chỉ chứa mã Dart và một phần cấu hình iOS; chưa có đầy đủ project Android/iOS để chạy trực tiếp. Khi chuẩn bị platform, lưu lại cấu hình `ios/Runner/Info.plist`, widget và signing rồi tạo project theo tài liệu kỹ thuật. Chưa xác nhận build IPA/APK hoặc chạy SSO trên thiết bị thật trong lượt này.

Nếu đang dùng phiên đăng nhập cũ, **đăng xuất rồi đăng nhập lại** để thu nhận thêm quyền menu “Điểm học”. App lấy riêng ID menu lịch và điểm từ phiên portal; phiên cũ thiếu quyền xem điểm sẽ hiện hướng dẫn đăng nhập lại.

HAR cục bộ có thể kiểm tra offline:

```sh
dart run tool/verify_har.dart
# Hoặc dart run tool/verify_har.dart /duong/dan/ban-ghi.har
```

Công cụ chỉ in số chương trình/học phần/học kỳ và kết quả kiểm tra, không gọi mạng hoặc xuất điểm/định danh. HAR được bỏ qua trong Git. Các fixture kiểm thử đều là dữ liệu giả lập.

## Hợp đồng xem điểm

Nguồn: `diemhoc.js` và request/response lưu trong HAR ngày 15/10/2026, kết hợp tài liệu `README_CMC_Checkin_ChiTiet_HAR.md`.

| Chức năng | Action dưới `/sinhvienapi/api/` | Bằng chứng |
|---|---|---|
| Chương trình học | `SV_ThongTin_MH/DSA4FSkuLyYVKC8CKTQuLyYVMygvKQkuIgPP` | Request + response HAR, JS |
| Bảng điểm | `SV_ThongTin_MH/CiQ1EDQgCS4iFSAxAiAPKSAv` | Request + response HAR, JS |
| Điểm thành phần theo mã tổng kết | `SV_ThongTin_MH/DSA4BRIFKCQsFSkgLykRKSAvFSkkLhUKCREP` | Mã JS trong HAR; chưa có request thực tế tới endpoint này trong capture |

Cả ba dùng POST form `A = AE(JSON, action suffix)`; giải mã `Data.B` bằng `AzzSystem` và kiểm tra `Success == true`. Bảng điểm dùng quyền menu điểm, ID người học từ session và ID chương trình do portal trả về. Điểm thành phần dùng `strDiem_NguoiHoc_TongKet_Id` để tách từng kết quả/lần thi.

Response bảng điểm có `rsDiemKetThucHocPhan`, `rsDiemTrungBinhChung` cùng các nhóm dữ liệu khác. Điều kiện chọn trung bình giữ theo JavaScript portal: `THUOCTINHLANTINH == 0`; toàn khóa có `DAOTAO_THOIGIANDAOTAO_ID == null`; học kỳ khớp năm/kỳ, `DOTHOC == null` và phạm vi `HOCKY`. Số `2.0` của học kỳ được chuẩn hóa thành `2`; điểm 0 được giữ nguyên, thiếu điểm hiển thị `—`. Schema không hợp lệ gây lỗi hiển thị, không biến thành bảng điểm rỗng.

Chi tiết kiến trúc lịch/điểm danh nằm trong `README_CMC_Checkin_ChiTiet_HAR.md`. Lộ trình nâng cấp tiếp theo nằm trong [docs/UPGRADES.md](docs/UPGRADES.md).
