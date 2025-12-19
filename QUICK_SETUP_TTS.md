# Hướng dẫn nhanh cấu hình Google Cloud TTS

## Bạn đang gặp lỗi:
```
❌ Error initializing Google Cloud TTS: Exception: Google Cloud TTS key not configured.
```

## Giải pháp:

### Bước 1: Mở file `.env`
File nằm tại: `assets/.env`

### Bước 2: Thêm cấu hình Google Cloud TTS

Thêm các dòng sau vào cuối file `.env`:

```env
# Google Cloud TTS Configuration
GOOGLE_CLOUD_TTS_KEY_JSON={"type":"service_account","project_id":"your-project-id","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}
GOOGLE_CLOUD_PROJECT_ID=your-project-id
```

### Bước 3: Lấy giá trị từ file JSON key

1. **Tải file JSON key từ Google Cloud Console:**
   - Vào [Google Cloud Console](https://console.cloud.google.com/)
   - IAM & Admin → Service Accounts
   - Tạo service account mới (nếu chưa có)
   - Tạo key JSON và download

2. **Copy nội dung JSON:**
   - Mở file JSON đã download
   - Copy toàn bộ nội dung (Ctrl+A, Ctrl+C)
   - **Quan trọng:** Phải trên 1 dòng, không xuống dòng

3. **Paste vào `.env`:**
   ```env
   GOOGLE_CLOUD_TTS_KEY_JSON={"type":"service_account","project_id":"ai-book-reader-bca96",...}
   GOOGLE_CLOUD_PROJECT_ID=ai-book-reader-bca96
   ```

### Bước 4: Restart ứng dụng

Sau khi thêm cấu hình:
1. Stop ứng dụng
2. Chạy lại: `flutter run`
3. Kiểm tra console log để xem "✅ Google Cloud TTS service initialized successfully"

## Ví dụ file `.env` hoàn chỉnh:

```env
# Firebase (đã có)
API_KEY_WEB=AIzaSyDtRM5LfefQkFJXGk2lxybU21ws6hf8vHQ
APP_ID_WEB=1:239107880733:web:d4fcd4c5293a20996693f4
MESSAGING_SENDER_ID=239107880733
PROJECT_ID=ai-book-reader-bca96
AUTH_DOMAIN=ai-book-reader-bca96.firebaseapp.com

# Google Cloud TTS (THÊM VÀO)
GOOGLE_CLOUD_TTS_KEY_JSON={"type":"service_account","project_id":"ai-book-reader-bca96","private_key_id":"abc123","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n","client_email":"tts@ai-book-reader-bca96.iam.gserviceaccount.com","client_id":"123456789","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/tts%40ai-book-reader-bca96.iam.gserviceaccount.com"}
GOOGLE_CLOUD_PROJECT_ID=ai-book-reader-bca96
```

## Lưu ý quan trọng:

1. **JSON phải trên 1 dòng** - Không được xuống dòng trong JSON
2. **Project ID** - Lấy từ file JSON hoặc dùng PROJECT_ID hiện tại: `ai-book-reader-bca96`
3. **Escape quotes** - Nếu có lỗi, thử dùng single quotes bên ngoài:
   ```env
   GOOGLE_CLOUD_TTS_KEY_JSON='{"type":"service_account",...}'
   ```

## Nếu vẫn lỗi:

1. Kiểm tra file `.env` có đúng format không
2. Kiểm tra console log để xem debug messages
3. Xem file `SETUP_GOOGLE_CLOUD_TTS.md` để biết chi tiết hơn


