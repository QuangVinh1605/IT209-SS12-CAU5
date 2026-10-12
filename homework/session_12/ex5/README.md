# Bài 5: Chẩn đoán và khắc phục 3 sự cố đứt gãy Pipeline CI/CD thực tế

## Thông tin học viên
- **Học viên:** Nguyễn Quang Vinh (Vinh Nguyen)
- **Tài khoản GitHub:** [`QuangVinh1605`](https://github.com/QuangVinh1605)
- **Môn học:** DevOps (IT209) - Session 12
- **Bài tập:** Bài 5 (EX5)
- **Kho lưu trữ GitHub thực thi:** [QuangVinh1605/IT209-SS12-CAU5](https://github.com/QuangVinh1605/IT209-SS12-CAU5)

---

## 1. Tóm tắt 3 lỗi & Giải pháp khắc phục

| Lỗi | Tên lỗi | Mô tả & Nguyên nhân | Giải pháp |
| :---: | :--- | :--- | :--- |
| **Lỗi 1** | **Permission Denied** | `./gradlew` thiếu quyền thực thi trên Runner Linux (Exit code 126). | Thêm `run: chmod +x gradlew` trước lệnh chạy test. |
| **Lỗi 2** | **Authentication Failed** | Tên biến Secret bị gõ sai chính tả thành `${{ secrets.REGISTRY_TOKKEN }}`. | Sửa lại thành `${{ secrets.REGISTRY_TOKEN \|\| secrets.GITHUB_TOKEN }}`. |
| **Lỗi 3** | **Build Context Error** | Tham số `context` trong bước build Docker Image bị đặt thành `./build` thay vì `.`. | Đặt `context: .` và `file: ./Dockerfile`. |

---

## 2. Kết quả tích xanh hoàn tất

Toàn bộ pipeline phục hồi thành công và đạt trạng thái tích xanh trên GitHub Actions (Run [#38279326495](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38279326495)):

![Pipeline Success](screenshots/pipeline_success.png)

---

## 3. Danh mục tài liệu nộp bài
1. **Báo cáo chi tiết chẩn đoán:** [`troubleshooting.md`](troubleshooting.md)
2. **Tệp kịch bản đã sửa:** [`broken-pipeline.yml`](broken-pipeline.yml)
3. **Ảnh chụp kết quả tích xanh:** [`screenshots/pipeline_success.png`](screenshots/pipeline_success.png)
4. **Script kiểm tra:** [`commands.sh`](commands.sh)
