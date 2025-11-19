# AI Reader

A Flutter application for reading books with AI features.

## Cấu hình Cloudinary

Ứng dụng sử dụng Cloudinary để upload và lưu trữ ảnh. Firebase chỉ được sử dụng để lưu trữ dữ liệu dạng JSON (Firestore).

### Bước 1: Tạo tài khoản Cloudinary

1. Truy cập https://console.cloudinary.com
2. Đăng ký hoặc đăng nhập tài khoản
3. Vào Dashboard để lấy thông tin:
   - **Cloud Name**: Tên cloud của bạn
   - **API Key**: Khóa API
   - **API Secret**: Secret key (bảo mật)

### Bước 2: Cấu hình trong file .env

Thêm các biến môi trường sau vào file `assets/.env`:

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### Bước 3: Restart ứng dụng

Sau khi thêm cấu hình, restart ứng dụng để áp dụng thay đổi.

## Cấu trúc thư mục Cloudinary

- `book_covers/`: Ảnh bìa sách
- `books/`: File sách (PDF, EPUB, etc.)
- `uploads/`: Các file upload khác (nếu không chỉ định folder)

## Cấu hình Firestore Security Rules

Để ứng dụng có thể đọc/ghi dữ liệu vào Firestore, bạn cần cấu hình Security Rules:

### Cách 1: Cấu hình qua Firebase Console (Khuyến nghị)

1. Truy cập https://console.firebase.google.com
2. Chọn project của bạn
3. Vào **Firestore Database** → **Rules**
4. Copy nội dung từ file `firestore.rules` trong project
5. Paste vào Firebase Console
6. Nhấn **Publish** để lưu rules

### Cách 2: Sử dụng Firebase CLI

```bash
firebase deploy --only firestore:rules
```

### Rules mặc định

File `firestore.rules` đã được tạo với các quy tắc:
- **Books**: Mọi người có thể đọc, chỉ user đã đăng nhập mới có thể tạo
- **Users**: User chỉ có thể đọc/ghi dữ liệu của chính họ
- **Comments**: Mọi người có thể đọc, user đã đăng nhập có thể tạo/sửa/xóa comment của mình
- **Reading History**: User chỉ có thể đọc/ghi lịch sử đọc của chính họ

**Lưu ý**: Nếu bạn muốn chỉ admin mới có thể tạo/sửa/xóa books, hãy uncomment dòng `allow create: if isAdmin();` trong rules.

## Lưu ý

- **Bảo mật**: Không commit file `.env` lên Git. File này đã được thêm vào `.gitignore`
- **Firebase**: Firebase Storage đã được loại bỏ. Chỉ sử dụng Firestore để lưu trữ dữ liệu JSON
- **Upload**: Tất cả upload ảnh/file đều được thực hiện qua Cloudinary API
- **Firestore Rules**: Đảm bảo đã cấu hình Security Rules để tránh lỗi PERMISSION_DENIED
