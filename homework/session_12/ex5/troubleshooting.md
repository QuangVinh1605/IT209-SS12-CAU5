# Báo Cáo Chẩn Đoán & Khắc Phục Sự Cố: 3 Lỗi Đứt Gãy Pipeline CI/CD Thực Tế (Troubleshooting Report)

## Thông tin bài tập
- **Học viên:** Nguyễn Quang Vinh (Vinh Nguyen)
- **Tài khoản GitHub:** [`QuangVinh1605`](https://github.com/QuangVinh1605)
- **Môn học:** DevOps (IT209) - Session 12
- **Bài tập:** Bài 5 (EX5) - Chẩn đoán và khắc phục 3 sự cố đứt gãy Pipeline CI/CD thực tế
- **Đường dẫn nộp bài:** [`homework/session_12/ex5/`](file:///home/vinh/Desktop/devoops/SS12/homework/session_12/ex5/)
- **Kho lưu trữ GitHub thực thi:** [QuangVinh1605/IT209-SS12-CAU5](https://github.com/QuangVinh1605/IT209-SS12-CAU5)

---

## 1. Tổng quan sự cố & Mục tiêu kỹ thuật

Trong quy trình tự động hóa CI/CD cho dự án Spring Boot đóng gói Container Docker, tệp kịch bản ban đầu `.github/workflows/broken-pipeline.yml` gặp phải 3 lỗi nghiêm trọng dẫn đến việc pipeline bị đứt gãy:

1. **Lỗi 1:** Quyền thực thi của tệp khởi chạy Gradle Wrapper trên Linux Runner.
2. **Lỗi 2:** Sai lệch tên biến định danh Secret khi xác thực Container Registry.
3. **Lỗi 3:** Sai lệch thư mục ngữ cảnh (Build Context) trong tiến trình đóng gói Docker Image bằng Docker Buildx.

Mục tiêu của bài thực hành là phân tích chi tiết log lỗi từ hệ thống GitHub Actions Runner, xác định nguyên nhân gốc rễ (Root Cause Analysis - RCA), áp dụng giải pháp khắc phục chuẩn DevOps và kiểm chứng luồng CI/CD phục hồi trạng thái tích xanh (:white_check_mark: Success).

---

## 2. Bảng tổng hợp đối chiếu lỗi (Before vs. After)

| Lỗi | Tên lỗi & Triệu chứng | Nguyên nhân gốc rễ | Dòng mã lỗi (Before) | Dòng mã sửa (After) | Kết quả sau sửa |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **Lỗi 1** | **Permission Denied**<br>Gradle Wrapper bị từ chối thực thi (Exit code 126). | Tệp `gradlew` lưu trên Git ở chế độ `100644` (thiếu quyền `+x`). Khi runner Linux gọi thực thi `./gradlew` thì hệ điều hành chặn lại. | *(Thiếu bước phân quyền)*<br>`run: ./gradlew test bootJar` | `run: chmod +x gradlew`<br>`run: ./gradlew test bootJar` | :white_check_mark:<br>Job Test chạy thành công trong 22s. |
| **Lỗi 2** | **Authentication Failed**<br>Đăng nhập GHCR thất bại (`Password required`). | Biến Secret bị gõ sai chính tả thành `REGISTRY_TOKKEN` (thừa chữ K). GitHub Actions trả về giá trị rỗng `""`. | `password: ${{ secrets.REGISTRY_TOKKEN }}` | `password: ${{ secrets.REGISTRY_TOKEN \|\| secrets.GITHUB_TOKEN }}` | :white_check_mark:<br>Đăng nhập Registry thành công 100%. |
| **Lỗi 3** | **Build Context Error**<br>Docker Buildx không tìm thấy file JAR (`not found`). | Tham số `context` bị trỏ vào `./build`, khiến lệnh `COPY build/libs/app.jar` tìm kiếm sai thành `./build/build/libs/app.jar`. | `context: ./build`<br>`file: ./Dockerfile` | `context: .`<br>`file: ./Dockerfile` | :white_check_mark:<br>Build và đẩy Docker Image lên GHCR thành công. |

---

## 3. Phân tích chi tiết từng sự cố & Giải pháp khắc phục

### 3.1. Sự cố 1: Permission Denied trên Gradle Wrapper

#### a. Triệu chứng & Trích xuất Log thực tế trên GitHub Actions
Khi chạy Job `test` (Workflow Run [#38278855486](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38278855486)):
```text
Run Gradle Tests & Package JAR	Run JUnit Tests & Package JAR
Run ./gradlew test bootJar
shell: /usr/bin/bash -e {0}
env:
  JAVA_HOME: /opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.20-1/x64
  JAVA_HOME_17_X64: /opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.20-1/x64

/home/runner/work/_temp/75d581cc-8270-411f-a6f5-e55eeb5a4d46.sh: line 1: ./gradlew: Permission denied
##[error]Process completed with exit code 126.
```

#### b. Nguyên nhân gốc rễ (Root Cause Analysis)
- Hệ điều hành trên GitHub Actions Runner là `ubuntu-latest` (Linux).
- Trong hệ thống tệp POSIX của Linux, một tệp chỉ có thể được thực thi như một kịch bản khi tệp đó sở hữu bit thực thi (`executable bit` - cờ `x`).
- Do tệp `gradlew` khi được commit lên Git mang mode `100644` (rw-r--r--) thay vì `100755` (rwxr-xr-x), lệnh gọi `./gradlew` bị kernel chặn với lỗi `Permission denied` (mã thoát `126`).

#### c. Giải pháp khắc phục
Thêm bước cấp quyền thực thi `chmod +x gradlew` ngay trước khi gọi lệnh chạy test và đóng gói JAR:
```yaml
      # KHẮC PHỤC LỖI 1: Phân quyền thực thi cho Gradle Wrapper trước khi chạy test
      - name: Grant Execute Permission to Gradle Wrapper
        run: chmod +x gradlew

      - name: Run JUnit Tests & Package JAR
        run: ./gradlew test bootJar
```

---

### 3.2. Sự cố 2: Authentication Failed trên Container Registry (GHCR)

#### a. Triệu chứng & Trích xuất Log thực tế trên GitHub Actions
Khi chạy bước `Login to GitHub Container Registry` (Workflow Run [#38278943442](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38278943442)):
```text
Run docker/login-action@v3
with:
  registry: ghcr.io
  username: QuangVinh1605
  logout: true
env:
  IMAGE_NAME: ghcr.io/quangvinh1605/it209-ss12-cau5

##[error]Password required
Post job cleanup.
Removing login credentials for ghcr.io
```

#### b. Nguyên nhân gốc rễ (Root Cause Analysis)
- Trong Action `docker/login-action@v3`, giá trị tham số `password` được cấu hình là `${{ secrets.REGISTRY_TOKKEN }}`.
- Tên biến bí mật thực tế được đăng ký trong Repository Secrets là `REGISTRY_TOKEN` (chỉ có 1 chữ 'k').
- Khi một biến Secret được gọi sai tên chính tả, GitHub Actions ngầm định giá trị trả về là chuỗi rỗng `""`.
- Action kiểm tra đầu vào và nhận thấy tham số `password` rỗng, dẫn đến cảnh báo lỗi `##[error]Password required` và chấm dứt tiến trình đăng nhập.

#### c. Giải pháp khắc phục
Sửa đúng chính tả tên biến bí mật thành `${{ secrets.REGISTRY_TOKEN }}`. Đồng thời thiết lập cơ chế fallback sang `${{ secrets.GITHUB_TOKEN }}` để tăng tính sẵn sàng của pipeline:
```yaml
      # KHẮC PHỤC LỖI 2: Đã sửa chính tả biến Secret thành REGISTRY_TOKEN (hoặc GITHUB_TOKEN)
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.REGISTRY_TOKEN || secrets.GITHUB_TOKEN }}
```

---

### 3.3. Sự cố 3: Build Context Error trong bước Docker Build & Push

#### a. Triệu chứng & Trích xuất Log thực tế trên GitHub Actions
Khi chạy bước `Build and Push Docker Image` (Workflow Run [#38279128718](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38279128718)):
```text
[command]/usr/bin/docker buildx build --file ./Dockerfile ... --push ./build
#0 building with "builder-529da20f" instance using docker-container driver
#1 [internal] load build definition from Dockerfile
#1 DONE 0.0s
...
#8 [4/5] COPY build/libs/app.jar app.jar
#8 ERROR: failed to calculate checksum of ref ...: "/build/libs/app.jar": not found
------
 > [4/5] COPY build/libs/app.jar app.jar:
------
Dockerfile:16
--------------------
  15 |     # Sao chép tệp JAR đã được đóng gói từ Job test
  16 | >>> COPY build/libs/app.jar app.jar
  17 |     
--------------------
ERROR: failed to build: failed to solve: failed to compute cache key: failed to calculate checksum of ref ...: "/build/libs/app.jar": not found
##[error]buildx failed with: ERROR: failed to build: failed to solve: failed to compute cache key: failed to calculate checksum of ref ...: "/build/libs/app.jar": not found
```

#### b. Nguyên nhân gốc rễ (Root Cause Analysis)
- Trong cấu hình `docker/build-push-action@v5`, tham số `context` bị đặt là `./build` thay vì `.`.
- Trong Dockerfile, chỉ thị là `COPY build/libs/app.jar app.jar`.
- Khi Docker Buildx thiết lập gốc của Build Context là `./build`, mọi đường dẫn tương đối trong Dockerfile sẽ bắt đầu từ `./build/`. Vì vậy, lệnh `COPY build/libs/app.jar` sẽ tìm tệp tại đường dẫn `./build/build/libs/app.jar` (thừa một tầng thư mục `build`), dẫn tới lỗi `not found`.

#### c. Giải pháp khắc phục
Cấu hình chuẩn xác `context: .` (thư mục gốc của repository, nơi chứa cả cấu trúc `build/libs/app.jar` được download từ artifact) và `file: ./Dockerfile`:
```yaml
      # KHẮC PHỤC LỖI 3: Cấu hình đúng ngữ cảnh build context (.) và đường dẫn Dockerfile (./Dockerfile)
      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ env.IMAGE_NAME }}:latest
```

---

## 4. Tệp kịch bản hoàn chỉnh sau khắc phục `.github/workflows/broken-pipeline.yml`

```yaml
name: CI Pipeline - Broken (Fixed)

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:

jobs:
  test:
    name: Run Gradle Tests & Package JAR
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Setup Java JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: 'gradle'

      # KHẮC PHỤC LỖI 1: Phân quyền thực thi cho Gradle Wrapper trước khi chạy test
      - name: Grant Execute Permission to Gradle Wrapper
        run: chmod +x gradlew

      - name: Run JUnit Tests & Package JAR
        run: ./gradlew test bootJar

      - name: Upload Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-jar
          path: build/libs/app.jar
          retention-days: 1

  docker-build:
    name: Build and Push Docker Image
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Download Build Artifact
        uses: actions/download-artifact@v4
        with:
          name: app-jar
          path: build/libs

      - name: Set Lowercase Image Name
        run: |
          echo "IMAGE_NAME=ghcr.io/$(echo '${{ github.repository }}' | tr '[:upper:]' '[:lower:]')" >> $GITHUB_ENV

      # KHẮC PHỤC LỖI 2: Đã sửa chính tả biến Secret thành REGISTRY_TOKEN (hoặc GITHUB_TOKEN)
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.REGISTRY_TOKEN || secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # KHẮC PHỤC LỖI 3: Cấu hình đúng ngữ cảnh build context (.) và đường dẫn Dockerfile (./Dockerfile)
      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ env.IMAGE_NAME }}:latest
```

---

## 5. Kết quả kiểm chứng thực tế & Minh chứng hình ảnh

### 5.1. Nhật ký tiến trình khắc phục qua 4 lần chạy trên GitHub Actions
1. **Run #1 (`c02308d`)** - [Run #38278855486](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38278855486): **Thất bại tại Job `test`** do Lỗi 1 (`./gradlew: Permission denied`).
2. **Run #2 (`3e7b5af`)** - [Run #38278943442](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38278943442): **Job `test` thành công**, Job `docker-build` thất bại tại bước `Login to GitHub Container Registry` do Lỗi 2 (`Password required`).
3. **Run #3 (`03c66af`)** - [Run #38279128718](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38279128718): **Đăng nhập Registry thành công**, thất bại tại bước `Build and Push Docker Image` do Lỗi 3 (`/build/libs/app.jar: not found` vì sai context).
4. **Run #4 (`fb2f6ac`)** - [Run #38279326495](https://github.com/QuangVinh1605/IT209-SS12-CAU5/actions/runs/38279326495): **Toàn bộ pipeline thành công tích xanh 100%**!
   - `Run Gradle Tests & Package JAR`: :white_check_mark: Success (22s).
   - `Build and Push Docker Image`: :white_check_mark: Success (28s).
   - Đã tải lên artifact `app-jar` và đẩy Docker Image thành công lên `ghcr.io/quangvinh1605/it209-ss12-cau5:latest`.

---

### 5.2. Ảnh chụp màn hình kết quả tích xanh (Success)
![Pipeline Success](screenshots/pipeline_success.png)

*(Đường dẫn tệp: [`homework/session_12/ex5/screenshots/pipeline_success.png`](screenshots/pipeline_success.png))*

---

## 6. Danh mục sản phẩm nộp bài
1. **Tệp kịch bản đã sửa:** [`homework/session_12/ex5/broken-pipeline.yml`](file:///home/vinh/Desktop/devoops/SS12/homework/session_12/ex5/broken-pipeline.yml).
2. **Tệp kịch bản tại gốc:** [`.github/workflows/broken-pipeline.yml`](file:///home/vinh/Desktop/devoops/SS12/.github/workflows/broken-pipeline.yml).
3. **Tệp báo cáo chẩn đoán sự cố:** [`homework/session_12/ex5/troubleshooting.md`](file:///home/vinh/Desktop/devoops/SS12/homework/session_12/ex5/troubleshooting.md).
4. **Ảnh chụp màn hình tích xanh:** [`homework/session_12/ex5/screenshots/pipeline_success.png`](file:///home/vinh/Desktop/devoops/SS12/homework/session_12/ex5/screenshots/pipeline_success.png).
5. **Kho mã nguồn thực thi:** [QuangVinh1605/IT209-SS12-CAU5](https://github.com/QuangVinh1605/IT209-SS12-CAU5).
