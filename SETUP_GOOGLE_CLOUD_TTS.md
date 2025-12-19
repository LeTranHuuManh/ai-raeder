# Hướng dẫn cấu hình Google Cloud TTS

## Bước 1: Tạo Service Account trong Google Cloud Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn project của bạn hoặc tạo project mới
3. Enable **Cloud Text-to-Speech API**:
   - Vào **APIs & Services** → **Library**
   - Tìm "Cloud Text-to-Speech API"
   - Click **Enable**

4. Tạo Service Account:
   - Vào **IAM & Admin** → **Service Accounts**
   - Click **Create Service Account**
   - Điền tên và mô tả
   - Click **Create and Continue**
   - Chọn role: **Cloud Text-to-Speech API User**
   - Click **Continue** → **Done**

5. Tạo và download JSON key:
   - Click vào service account vừa tạo
   - Vào tab **Keys**
   - Click **Add Key** → **Create new key**
   - Chọn **JSON**
   - Click **Create** (file JSON sẽ được download)

## Bước 2: Cấu hình trong file `.env`

### Tạo file `.env` trong thư mục `assets/`

```bash
# Từ thư mục gốc của project
cp assets/.env.example assets/.env
```

### Chọn một trong 3 cách cấu hình:

#### **Cách 1: Lưu JSON trực tiếp (Khuyến nghị - Dễ nhất)**

1. Mở file JSON key đã download
2. Copy toàn bộ nội dung (Ctrl+A, Ctrl+C)
3. Mở file `assets/.env`
4. Thêm dòng sau (paste JSON vào sau dấu `=`):

```env
GOOGLE_CLOUD_TTS_KEY_JSON={"type":"service_account","project_id":"your-project","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}
GOOGLE_CLOUD_PROJECT_ID=your-project-id
```

**Lưu ý:** 
- JSON phải trên 1 dòng (không xuống dòng)
- Nếu có dấu ngoặc kép trong JSON, cần escape: `\"`
- Hoặc dùng single quotes bên ngoài: `GOOGLE_CLOUD_TTS_KEY_JSON='{"type":"service_account",...}'`

#### **Cách 2: Lưu JSON dưới dạng Base64**

1. Encode file JSON thành base64:

```bash
# Trên Mac/Linux
base64 -i your-service-account-key.json

# Hoặc
cat your-service-account-key.json | base64
```

2. Copy kết quả và thêm vào `.env`:

```env
GOOGLE_CLOUD_TTS_KEY_BASE64=eyJ0eXBlIjoic2VydmljZV9hY2NvdW50Ii...
GOOGLE_CLOUD_PROJECT_ID=your-project-id
```

#### **Cách 3: Đường dẫn đến file JSON (Chỉ cho mobile/desktop, không dùng cho web)**

```env
GOOGLE_CLOUD_TTS_KEY_PATH=/absolute/path/to/your/service-account-key.json
GOOGLE_CLOUD_PROJECT_ID=your-project-id
```

## Bước 3: Lấy Project ID

Project ID có thể tìm thấy:
- Trong file JSON key: `"project_id": "your-project-id"`
- Hoặc trong Google Cloud Console: **Project Settings** → **Project ID**

## Bước 4: Restart ứng dụng

Sau khi cấu hình xong:
1. Stop ứng dụng (nếu đang chạy)
2. Restart lại ứng dụng
3. Kiểm tra console log để xem có thông báo "✅ Google Cloud TTS service initialized successfully"

## Kiểm tra cấu hình

Nếu thấy lỗi:
- `Google Cloud TTS key not configured`: Kiểm tra lại tên biến trong `.env`
- `Invalid JSON format`: Kiểm tra lại format JSON (phải trên 1 dòng)
- `Service account key file not found`: Kiểm tra lại đường dẫn file

## Ví dụ file `.env` hoàn chỉnh

```env
# Google Cloud TTS
GOOGLE_CLOUD_TTS_KEY_JSON={"type":"service_account","project_id":"my-project-123","private_key_id":"abc123","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n","client_email":"tts@my-project-123.iam.gserviceaccount.com","client_id":"123456789","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/tts%40my-project-123.iam.gserviceaccount.com"}
GOOGLE_CLOUD_PROJECT_ID=my-project-123
```

## Troubleshooting

### Lỗi: "Invalid JSON format"
- Đảm bảo JSON trên 1 dòng
- Escape các dấu ngoặc kép: `\"`
- Hoặc dùng single quotes bên ngoài

### Lỗi: "File not found" (với cách 3)
- Dùng đường dẫn tuyệt đối: `/Users/username/path/to/key.json`
- Kiểm tra quyền truy cập file

### Lỗi: "Project ID not configured"
- Đảm bảo có dòng `GOOGLE_CLOUD_PROJECT_ID=your-project-id`
- Kiểm tra project ID có đúng không


