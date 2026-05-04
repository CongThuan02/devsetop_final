# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 1. Tổng quan dự án

**Đề tài**: Triển khai DevSecOps — Tích hợp chính sách an ninh tự động vào chu trình CI/CD.

**Hình thức**: Bài tập cá nhân (1 người).

**Sản phẩm minh hoạ**: **Password Manager Mini** — ứng dụng quản lý mật khẩu cá nhân theo mô hình **zero-knowledge** (server không đọc được dữ liệu người dùng).

**Stack**:
- Client app: **Flutter** (Dart 3.x) — build cho **cả Android APK và Web**
- Backend / DB / Hosting: **Firebase** (Auth, Firestore, App Check, **Hosting** cho bản web)
- Source & CI/CD: **GitHub** + **GitHub Actions**

**Đa nền tảng**: cùng một codebase Flutter sẽ build ra:
- APK Android (cho demo mobile + MobSF scan)
- Web bundle (deploy lên Firebase Hosting → có URL công khai để demo + DAST scan bằng OWASP ZAP)

**Trọng tâm chấm điểm**: Pipeline DevSecOps (~70%) > Ứng dụng (~30%). Ứng dụng cố ý giữ gọn để tập trung công sức vào pipeline an ninh.

---

## 2. Yêu cầu chức năng (MVP)

| # | Tính năng | Ghi chú bảo mật |
|---|-----------|-----------------|
| 1 | Đăng ký / Đăng nhập (email + master password) | Firebase Auth |
| 2 | Mở khoá bằng sinh trắc học | `local_auth` |
| 3 | CRUD mật khẩu (tên dịch vụ, URL, username, password, ghi chú) | Mã hoá phía client |
| 4 | Sinh mật khẩu ngẫu nhiên mạnh | `Random.secure` |
| 5 | Copy mật khẩu, tự xoá clipboard sau 30s | Chống leak |
| 6 | Tìm kiếm theo tên dịch vụ | Chỉ field này là plaintext |
| 7 | Auto-lock khi app vào background hoặc idle 5 phút | Chống shoulder-surfing |
| 8 | Đổi master password (re-encrypt toàn bộ) | Vận hành khóa |

---

## 3. Cơ chế bảo mật cốt lõi

- **Zero-knowledge**: dữ liệu nhạy cảm được mã hoá **trên thiết bị** trước khi gửi lên Firestore. Firestore chỉ lưu **ciphertext**.
- **Mã hoá**: AES-256-GCM. Encryption key dẫn xuất từ master password bằng **PBKDF2** (≥100k iterations, salt ngẫu nhiên 16 bytes).
- **Lưu trữ cục bộ**: salt và metadata không nhạy cảm lưu bằng `flutter_secure_storage`. Master password **không bao giờ** được lưu.
- **Firestore Security Rules**: user chỉ đọc/ghi document có `userId == request.auth.uid`.
- **Firebase App Check**: chống lạm dụng API từ client giả mạo.
- **Certificate pinning** cho mọi HTTPS call.
- **Chặn screenshot** (FLAG_SECURE trên Android).
- **Khoá tạm** sau 5 lần nhập sai master password.
- **Cho bản Web**:
  - Bắt buộc HTTPS (Firebase Hosting tự cấp).
  - Cấu hình **Content Security Policy (CSP)**, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy` qua `firebase.json` headers.
  - Không dùng `localStorage` cho dữ liệu nhạy cảm; key chỉ giữ trong RAM (memory) của tab.
  - Tự logout khi đóng tab / mất focus quá 5 phút.

---

## 4. Kiến trúc & cấu trúc thư mục

```
lib/
├── core/          # crypto (AES-GCM, PBKDF2), secure_storage, constants
├── data/          # repositories, firebase clients, DTOs
├── domain/        # models, use_cases (thuần Dart, dễ test)
├── presentation/  # screens, widgets, state (Riverpod)
└── main.dart
test/                  # unit test (crypto, repository với mocked firebase)
integration_test/      # integration test trên emulator
.github/workflows/     # CI/CD pipelines
firestore.rules        # Firestore Security Rules
firebase.json
```

State management: **Riverpod** (default — sẽ xác nhận khi bắt đầu).

---

## 5. Pipeline DevSecOps (GitHub Actions)

Sơ đồ tổng:

```
[Push/PR]
   ↓
1. Lint & Format       — flutter analyze, dart format --set-exit-if-changed
2. Secrets Scan        — Gitleaks
3. SAST                — Semgrep + CodeQL
4. SCA                 — OSV-Scanner, dart pub outdated, Dependabot
5. Unit Test           — flutter test --coverage
6. Firestore Rules Test — @firebase/rules-unit-testing
7. Build APK           — flutter build apk --release
8. Build Web           — flutter build web --release
9. Mobile Scan         — MobSF quét APK artifact
10. IaC Scan           — Checkov cho firebase.json + firestore.rules
11. Deploy Web         — Firebase Hosting (chỉ khi merge main); preview channel cho mỗi PR
12. DAST               — OWASP ZAP baseline scan trên URL Hosting
13. Report             — Upload SARIF → GitHub Security tab
```

Workflow files dự kiến:

```
.github/workflows/
├── ci.yml          # Lint, test, build mỗi PR
├── security.yml    # Secrets / SAST / SCA / MobSF
├── codeql.yml      # CodeQL
├── deploy.yml      # CD lên Firebase khi merge main
.github/dependabot.yml
```

Policy-as-Code:
- Branch protection: bắt buộc pass mọi check trước khi merge `main`.
- Required signed commits.
- (Nâng cao) OPA/Conftest: chặn merge nếu severity ≥ HIGH.

---

## 6. Lệnh thường dùng

> Sẽ được điền chính xác sau khi `flutter create` xong. Mẫu dự kiến:

```bash
# Cài deps
flutter pub get

# Chạy app (debug)
flutter run

# Lint & format
flutter analyze
dart format --set-exit-if-changed .

# Test
flutter test                              # toàn bộ unit test
flutter test test/core/crypto_test.dart   # 1 file
flutter test --coverage                   # kèm coverage

# Build
flutter build apk --release            # Android APK
flutter build appbundle --release      # Android AAB (Play Store)
flutter build web --release            # Web → build/web/

# Firebase Hosting
firebase deploy --only hosting                       # deploy production
firebase hosting:channel:deploy pr-<num> --expires 7d  # preview channel cho PR

# Firestore Rules test (Node.js)
cd firestore_tests && npm test

# Firebase emulator (local dev)
firebase emulators:start
```

---

## 7. Luồng người dùng cốt lõi

1. **Lần đầu**: Đăng ký → tạo salt → dẫn xuất key → cảnh báo "master password không thể khôi phục".
2. **Hằng ngày**: Mở app → sinh trắc học (hoặc master password) → giải mã key → load list.
3. **Thêm mật khẩu**: nhập form → AES-GCM encrypt → ghi Firestore (chỉ ciphertext + tên dịch vụ plaintext).
4. **Dùng mật khẩu**: tìm kiếm → tap → reveal/copy → clipboard tự xoá sau 30s.
5. **Đổi master password**: nhập cũ → giải mã tất cả → nhập mới → re-encrypt tất cả → ghi lại.

---

## 8. Threat model rút gọn (STRIDE)

| Mối đe doạ | Đối phó |
|------------|---------|
| **S**poofing — giả mạo client | Firebase App Check |
| **T**ampering — sửa dữ liệu | AES-GCM (auth tag), Firestore Rules |
| **R**epudiation — chối bỏ hành động | Audit log qua Firebase |
| **I**nformation Disclosure — lộ dữ liệu | Zero-knowledge, ciphertext-only |
| **D**oS | App Check, Firestore quotas |
| **E**levation of Privilege | Firestore Rules theo `request.auth.uid` |

---

## 9. Kịch bản demo (cho báo cáo)

1. **Server bị xem trộm** → kẻ tấn công chỉ thấy ciphertext.
2. **Mất điện thoại đã mở khoá** → app vẫn yêu cầu sinh trắc / master password.
3. **Commit nhầm API key** → Gitleaks chặn ngay tại CI, không vào được `main`.
4. **Thêm dependency có CVE** → OSV-Scanner cảnh báo, build fail.
5. **Đổi Firestore Rules sai** → rules-unit-testing fail, không deploy được.

---

## 10. Lộ trình 8 tuần (cá nhân)

| Tuần | Việc |
|------|------|
| 1 | Setup repo, Flutter project, Firebase project, branch protection |
| 2 | Auth + Firestore Rules + secure storage |
| 3 | Crypto module (AES-GCM + PBKDF2) + unit test |
| 4 | UI CRUD, generator, biometric, auto-lock |
| 5 | Pipeline cơ bản: lint, test, build, Gitleaks, OSV-Scanner |
| 6 | Semgrep, CodeQL, MobSF, Checkov |
| 7 | Build web, deploy Firebase Hosting + preview channel + DAST (ZAP) + threat model |
| 8 | Viết báo cáo, slide, quay demo |

---

## 11. Quy ước làm việc trong repo

- **Branch**: `main` (protected) + `feat/*`, `fix/*`, `chore/*`.
- **Commit**: Conventional Commits, viết bằng tiếng Việt được (vd. `feat(auth): them dang nhap bang sinh trac hoc`).
- **PR**: tự review, mọi check phải xanh trước khi merge.
- **Không commit**: `google-services.json`, `GoogleService-Info.plist`, `.env`, keystore. Dùng GitHub Secrets cho CI/CD.

---

## 12. Việc còn cần xác nhận

- Tên repo GitHub chính thức.
- Region Firebase (mặc định: `asia-southeast1`).
- State management: Riverpod (mặc định) vs Bloc.
- Có dùng Argon2 thay PBKDF2 không (Argon2 mạnh hơn nhưng package Dart hạn chế).
