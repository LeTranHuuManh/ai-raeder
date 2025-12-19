# AI Reader

Ứng dụng đọc sách thông minh được phát triển bằng Flutter, tích hợp các tính năng AI.

---

## 📋 ĐẶC TẢ USE CASE

### 1. Tổng quan hệ thống

**AI Reader** là ứng dụng đọc sách thông minh được phát triển bằng Flutter, tích hợp các tính năng AI để nâng cao trải nghiệm đọc sách của người dùng. Ứng dụng hỗ trợ đa nền tảng (iOS, Android, Web, Desktop).

### 2. Danh sách tác nhân (Actors)

| Tác nhân                  | Mô tả                                                                |
| ------------------------- | -------------------------------------------------------------------- |
| **Khách (Guest)**         | Người dùng chưa đăng nhập, có thể xem danh sách sách và tìm kiếm     |
| **Người dùng (User)**     | Người dùng đã đăng ký và đăng nhập, có đầy đủ quyền sử dụng ứng dụng |
| **Quản trị viên (Admin)** | Người dùng có quyền quản trị hệ thống                                |
| **Hệ thống AI**           | Gemini AI xử lý các yêu cầu trí tuệ nhân tạo                         |
| **Firebase**              | Hệ thống backend lưu trữ dữ liệu                                     |
| **Cloudinary**            | Hệ thống lưu trữ file và hình ảnh                                    |

---

### 3. Danh sách Use Case

#### 3.1. Nhóm Use Case: Xác thực (Authentication)

| UC ID | Tên Use Case          | Mô tả                                            |
| ----- | --------------------- | ------------------------------------------------ |
| UC-01 | Đăng ký tài khoản     | Người dùng tạo tài khoản mới bằng email/password |
| UC-02 | Đăng nhập             | Người dùng đăng nhập vào hệ thống                |
| UC-03 | Đăng nhập bằng Google | Người dùng đăng nhập nhanh bằng tài khoản Google |
| UC-04 | Đăng xuất             | Người dùng thoát khỏi tài khoản                  |
| UC-05 | Quên mật khẩu         | Người dùng khôi phục mật khẩu qua email          |

#### 3.2. Nhóm Use Case: Quản lý sách (Book Management)

| UC ID | Tên Use Case        | Mô tả                                                     |
| ----- | ------------------- | --------------------------------------------------------- |
| UC-06 | Xem danh sách sách  | Hiển thị danh sách sách theo thể loại, phổ biến, mới nhất |
| UC-07 | Tìm kiếm sách       | Tìm kiếm sách theo tên, tác giả, thể loại                 |
| UC-08 | Xem chi tiết sách   | Xem thông tin chi tiết của một cuốn sách                  |
| UC-09 | Đọc sách (PDF)      | Đọc sách định dạng PDF với các tùy chọn                   |
| UC-10 | Đọc sách (EPUB)     | Đọc sách định dạng EPUB                                   |
| UC-11 | Thêm sách yêu thích | Thêm sách vào danh sách yêu thích                         |
| UC-12 | Xóa sách yêu thích  | Xóa sách khỏi danh sách yêu thích                         |
| UC-13 | Xem lịch sử đọc     | Xem lịch sử các sách đã đọc                               |

#### 3.3. Nhóm Use Case: Tính năng AI

| UC ID | Tên Use Case         | Mô tả                                       |
| ----- | -------------------- | ------------------------------------------- |
| UC-14 | Chat với AI          | Trò chuyện với AI về sách và văn học        |
| UC-15 | Tóm tắt sách bằng AI | AI tóm tắt nội dung sách                    |
| UC-16 | Gợi ý sách bằng AI   | AI gợi ý sách phù hợp với sở thích          |
| UC-17 | Text-to-Speech       | Chuyển văn bản thành giọng nói để nghe sách |

#### 3.4. Nhóm Use Case: Quản lý người dùng

| UC ID | Tên Use Case               | Mô tả                            |
| ----- | -------------------------- | -------------------------------- |
| UC-18 | Xem hồ sơ cá nhân          | Xem thông tin tài khoản          |
| UC-19 | Chỉnh sửa hồ sơ            | Cập nhật thông tin cá nhân       |
| UC-20 | Thay đổi cài đặt thông báo | Tùy chỉnh thông báo              |
| UC-21 | Cài đặt bảo mật            | Thay đổi mật khẩu, bảo mật 2 lớp |

#### 3.5. Nhóm Use Case: Quản trị (Admin)

| UC ID | Tên Use Case       | Mô tả                                      |
| ----- | ------------------ | ------------------------------------------ |
| UC-22 | Thêm sách mới      | Admin thêm sách mới vào hệ thống           |
| UC-23 | Sửa thông tin sách | Admin cập nhật thông tin sách              |
| UC-24 | Xóa sách           | Admin xóa sách khỏi hệ thống               |
| UC-25 | Quản lý thể loại   | Thêm, sửa, xóa thể loại sách               |
| UC-26 | Quản lý người dùng | Xem, khóa/mở khóa tài khoản người dùng     |
| UC-27 | Xem thống kê       | Xem thống kê về sách, người dùng, lượt đọc |

---

### 4. Đặc tả chi tiết Use Case

#### UC-01: Đăng ký tài khoản

| Thuộc tính               | Mô tả                                                     |
| ------------------------ | --------------------------------------------------------- |
| **Tên Use Case**         | Đăng ký tài khoản                                         |
| **Mã Use Case**          | UC-01                                                     |
| **Tác nhân**             | Khách (Guest)                                             |
| **Mô tả**                | Cho phép người dùng tạo tài khoản mới để sử dụng ứng dụng |
| **Điều kiện tiên quyết** | Người dùng chưa có tài khoản                              |
| **Điều kiện kết thúc**   | Tài khoản được tạo thành công và lưu vào Firebase         |

**Luồng sự kiện chính:**

1. Người dùng mở ứng dụng và chọn "Đăng ký"
2. Hệ thống hiển thị form đăng ký
3. Người dùng nhập email, mật khẩu, xác nhận mật khẩu
4. Hệ thống validate dữ liệu đầu vào
5. Hệ thống tạo tài khoản trên Firebase Auth
6. Hệ thống lưu thông tin user vào Firestore
7. Hệ thống chuyển người dùng đến màn hình chính

**Luồng sự kiện thay thế:**

- 4a. Email không hợp lệ → Hiển thị thông báo lỗi
- 4b. Mật khẩu không đủ mạnh → Hiển thị yêu cầu mật khẩu
- 5a. Email đã tồn tại → Hiển thị thông báo và đề xuất đăng nhập

---

#### UC-02: Đăng nhập

| Thuộc tính               | Mô tả                                      |
| ------------------------ | ------------------------------------------ |
| **Tên Use Case**         | Đăng nhập                                  |
| **Mã Use Case**          | UC-02                                      |
| **Tác nhân**             | Khách (Guest)                              |
| **Mô tả**                | Cho phép người dùng đăng nhập vào hệ thống |
| **Điều kiện tiên quyết** | Người dùng đã có tài khoản                 |
| **Điều kiện kết thúc**   | Người dùng đăng nhập thành công            |

**Luồng sự kiện chính:**

1. Người dùng mở ứng dụng
2. Hệ thống hiển thị màn hình đăng nhập
3. Người dùng nhập email và mật khẩu
4. Người dùng nhấn nút "Đăng nhập"
5. Hệ thống xác thực với Firebase Auth
6. Hệ thống lấy thông tin user từ Firestore
7. Hệ thống chuyển đến màn hình chính (Home)

**Luồng sự kiện thay thế:**

- 5a. Sai email/mật khẩu → Hiển thị thông báo lỗi
- 5b. Tài khoản bị khóa → Hiển thị thông báo và hướng dẫn liên hệ

---

#### UC-03: Đăng nhập bằng Google

| Thuộc tính               | Mô tả                                                     |
| ------------------------ | --------------------------------------------------------- |
| **Tên Use Case**         | Đăng nhập bằng Google                                     |
| **Mã Use Case**          | UC-03                                                     |
| **Tác nhân**             | Khách (Guest)                                             |
| **Mô tả**                | Cho phép người dùng đăng nhập nhanh bằng tài khoản Google |
| **Điều kiện tiên quyết** | Người dùng có tài khoản Google                            |
| **Điều kiện kết thúc**   | Người dùng đăng nhập thành công                           |

**Luồng sự kiện chính:**

1. Người dùng chọn "Đăng nhập bằng Google"
2. Hệ thống mở popup xác thực Google
3. Người dùng chọn tài khoản Google
4. Google trả về thông tin xác thực
5. Hệ thống xác thực với Firebase Auth
6. Nếu là user mới → Tạo profile trong Firestore
7. Hệ thống chuyển đến màn hình chính

---

#### UC-06: Xem danh sách sách

| Thuộc tính               | Mô tả                                               |
| ------------------------ | --------------------------------------------------- |
| **Tên Use Case**         | Xem danh sách sách                                  |
| **Mã Use Case**          | UC-06                                               |
| **Tác nhân**             | Người dùng (User), Khách (Guest)                    |
| **Mô tả**                | Hiển thị danh sách sách theo các tiêu chí khác nhau |
| **Điều kiện tiên quyết** | Không                                               |
| **Điều kiện kết thúc**   | Danh sách sách được hiển thị                        |

**Luồng sự kiện chính:**

1. Người dùng truy cập màn hình chính hoặc thư viện
2. Hệ thống truy vấn danh sách sách từ Firestore
3. Hệ thống hiển thị sách theo các mục:
   - Sách phổ biến (theo lượt xem)
   - Sách mới nhất (theo ngày thêm)
   - Sách theo thể loại
4. Người dùng có thể cuộn để xem thêm (pagination)

---

#### UC-07: Tìm kiếm sách

| Thuộc tính               | Mô tả                            |
| ------------------------ | -------------------------------- |
| **Tên Use Case**         | Tìm kiếm sách                    |
| **Mã Use Case**          | UC-07                            |
| **Tác nhân**             | Người dùng (User), Khách (Guest) |
| **Mô tả**                | Tìm kiếm sách theo từ khóa       |
| **Điều kiện tiên quyết** | Không                            |
| **Điều kiện kết thúc**   | Hiển thị kết quả tìm kiếm        |

**Luồng sự kiện chính:**

1. Người dùng nhấn vào thanh tìm kiếm
2. Người dùng nhập từ khóa (tên sách, tác giả, thể loại)
3. Hệ thống tìm kiếm trong Firestore
4. Hệ thống hiển thị danh sách sách phù hợp
5. Người dùng có thể lọc theo thể loại, tác giả

**Luồng sự kiện thay thế:**

- 4a. Không tìm thấy kết quả → Hiển thị thông báo và gợi ý

---

#### UC-08: Xem chi tiết sách

| Thuộc tính               | Mô tả                                    |
| ------------------------ | ---------------------------------------- |
| **Tên Use Case**         | Xem chi tiết sách                        |
| **Mã Use Case**          | UC-08                                    |
| **Tác nhân**             | Người dùng (User), Khách (Guest)         |
| **Mô tả**                | Xem thông tin chi tiết của một cuốn sách |
| **Điều kiện tiên quyết** | Không                                    |
| **Điều kiện kết thúc**   | Thông tin chi tiết sách được hiển thị    |

**Luồng sự kiện chính:**

1. Người dùng chọn một cuốn sách từ danh sách
2. Hệ thống truy vấn thông tin chi tiết từ Firestore
3. Hệ thống hiển thị:
   - Ảnh bìa sách
   - Tiêu đề, tác giả
   - Mô tả/giới thiệu
   - Thể loại, số trang
   - Đánh giá, lượt xem
4. Hiển thị các nút: Đọc sách, Thêm yêu thích, Chia sẻ

---

#### UC-09: Đọc sách (PDF)

| Thuộc tính               | Mô tả                                          |
| ------------------------ | ---------------------------------------------- |
| **Tên Use Case**         | Đọc sách PDF                                   |
| **Mã Use Case**          | UC-09                                          |
| **Tác nhân**             | Người dùng (User)                              |
| **Mô tả**                | Cho phép người dùng đọc sách định dạng PDF     |
| **Điều kiện tiên quyết** | Người dùng đã đăng nhập, sách có định dạng PDF |
| **Điều kiện kết thúc**   | Sách được hiển thị và có thể đọc               |

**Luồng sự kiện chính:**

1. Người dùng chọn sách từ danh sách
2. Người dùng nhấn "Đọc sách"
3. Hệ thống tải file PDF từ Cloudinary
4. Hệ thống hiển thị PDF trong reader (pdfx)
5. Người dùng có thể:
   - Chuyển trang
   - Zoom in/out
   - Bật chế độ đọc ban đêm
   - Bật Text-to-Speech
6. Hệ thống lưu vị trí đọc vào lịch sử

---

#### UC-10: Đọc sách (EPUB)

| Thuộc tính               | Mô tả                                           |
| ------------------------ | ----------------------------------------------- |
| **Tên Use Case**         | Đọc sách EPUB                                   |
| **Mã Use Case**          | UC-10                                           |
| **Tác nhân**             | Người dùng (User)                               |
| **Mô tả**                | Cho phép người dùng đọc sách định dạng EPUB     |
| **Điều kiện tiên quyết** | Người dùng đã đăng nhập, sách có định dạng EPUB |
| **Điều kiện kết thúc**   | Sách được hiển thị và có thể đọc                |

**Luồng sự kiện chính:**

1. Người dùng chọn sách từ danh sách
2. Người dùng nhấn "Đọc sách"
3. Hệ thống tải file EPUB từ Cloudinary
4. Hệ thống hiển thị EPUB trong reader
5. Người dùng có thể:
   - Chuyển chương
   - Thay đổi font chữ, cỡ chữ
   - Bật chế độ đọc ban đêm
   - Bật Text-to-Speech
6. Hệ thống lưu vị trí đọc vào lịch sử

---

#### UC-11: Thêm sách yêu thích

| Thuộc tính               | Mô tả                                            |
| ------------------------ | ------------------------------------------------ |
| **Tên Use Case**         | Thêm sách yêu thích                              |
| **Mã Use Case**          | UC-11                                            |
| **Tác nhân**             | Người dùng (User)                                |
| **Mô tả**                | Thêm sách vào danh sách yêu thích của người dùng |
| **Điều kiện tiên quyết** | Người dùng đã đăng nhập                          |
| **Điều kiện kết thúc**   | Sách được thêm vào danh sách yêu thích           |

**Luồng sự kiện chính:**

1. Người dùng xem chi tiết sách
2. Người dùng nhấn nút "Yêu thích" (icon trái tim)
3. Hệ thống thêm book ID vào danh sách favoriteBooks của user
4. Hệ thống cập nhật Firestore
5. Hiển thị thông báo "Đã thêm vào yêu thích"

---

#### UC-14: Chat với AI

| Thuộc tính               | Mô tả                                         |
| ------------------------ | --------------------------------------------- |
| **Tên Use Case**         | Chat với AI                                   |
| **Mã Use Case**          | UC-14                                         |
| **Tác nhân**             | Người dùng (User), Hệ thống AI (Gemini)       |
| **Mô tả**                | Cho phép người dùng trò chuyện với AI về sách |
| **Điều kiện tiên quyết** | Người dùng đã đăng nhập, có API key Gemini    |
| **Điều kiện kết thúc**   | AI phản hồi tin nhắn của người dùng           |

**Luồng sự kiện chính:**

1. Người dùng mở màn hình Chat
2. Người dùng nhập tin nhắn (câu hỏi về sách, gợi ý, thảo luận)
3. Hệ thống gửi tin nhắn đến Gemini API
4. Gemini xử lý và trả về phản hồi
5. Hệ thống hiển thị phản hồi trong giao diện chat
6. Lịch sử chat được lưu trong phiên làm việc

**Các tính năng AI hỗ trợ:**

- Gợi ý sách hay
- Trả lời câu hỏi về nội dung sách
- Tóm tắt sách
- Thảo luận văn học

---

#### UC-15: Tóm tắt sách bằng AI

| Thuộc tính               | Mô tả                                     |
| ------------------------ | ----------------------------------------- |
| **Tên Use Case**         | Tóm tắt sách bằng AI                      |
| **Mã Use Case**          | UC-15                                     |
| **Tác nhân**             | Người dùng (User), Hệ thống AI            |
| **Mô tả**                | AI tóm tắt nội dung sách hoặc chương sách |
| **Điều kiện tiên quyết** | Người dùng đang đọc sách                  |
| **Điều kiện kết thúc**   | Bản tóm tắt được hiển thị                 |

**Luồng sự kiện chính:**

1. Người dùng đang đọc sách
2. Người dùng nhấn nút "Tóm tắt"
3. Hệ thống trích xuất nội dung văn bản
4. Hệ thống gửi nội dung đến AI (Gemini/OpenAI)
5. AI xử lý và trả về bản tóm tắt
6. Hệ thống hiển thị tóm tắt cho người dùng

---

#### UC-17: Text-to-Speech

| Thuộc tính               | Mô tả                                       |
| ------------------------ | ------------------------------------------- |
| **Tên Use Case**         | Text-to-Speech                              |
| **Mã Use Case**          | UC-17                                       |
| **Tác nhân**             | Người dùng (User)                           |
| **Mô tả**                | Chuyển văn bản thành giọng nói để nghe sách |
| **Điều kiện tiên quyết** | Đang đọc sách                               |
| **Điều kiện kết thúc**   | Văn bản được đọc thành tiếng                |

**Luồng sự kiện chính:**

1. Người dùng đang ở màn hình đọc sách
2. Người dùng nhấn nút "Nghe sách"
3. Hệ thống trích xuất văn bản từ trang hiện tại
4. Hệ thống sử dụng TTS (flutter_tts hoặc Google Cloud TTS) để đọc
5. Người dùng có thể:
   - Tạm dừng/tiếp tục
   - Điều chỉnh tốc độ đọc
   - Điều chỉnh âm lượng
   - Chọn giọng đọc (vi-VN)

---

#### UC-18: Xem hồ sơ cá nhân

| Thuộc tính               | Mô tả                           |
| ------------------------ | ------------------------------- |
| **Tên Use Case**         | Xem hồ sơ cá nhân               |
| **Mã Use Case**          | UC-18                           |
| **Tác nhân**             | Người dùng (User)               |
| **Mô tả**                | Xem thông tin tài khoản cá nhân |
| **Điều kiện tiên quyết** | Người dùng đã đăng nhập         |
| **Điều kiện kết thúc**   | Thông tin hồ sơ được hiển thị   |

**Luồng sự kiện chính:**

1. Người dùng chọn tab "Hồ sơ" trên bottom navigation
2. Hệ thống lấy thông tin user từ Firestore
3. Hiển thị:
   - Ảnh đại diện
   - Tên hiển thị, email
   - Số sách yêu thích
   - Lịch sử đọc
4. Hiển thị các tùy chọn: Chỉnh sửa, Cài đặt, Đăng xuất

---

#### UC-22: Thêm sách mới (Admin)

| Thuộc tính               | Mô tả                                      |
| ------------------------ | ------------------------------------------ |
| **Tên Use Case**         | Thêm sách mới                              |
| **Mã Use Case**          | UC-22                                      |
| **Tác nhân**             | Quản trị viên (Admin)                      |
| **Mô tả**                | Admin thêm sách mới vào hệ thống           |
| **Điều kiện tiên quyết** | Người dùng có quyền Admin (isAdmin = true) |
| **Điều kiện kết thúc**   | Sách được thêm thành công vào Firestore    |

**Luồng sự kiện chính:**

1. Admin truy cập trang Quản trị → Quản lý sách
2. Admin nhấn "Thêm sách mới"
3. Admin nhập thông tin sách:
   - Tiêu đề, tác giả, mô tả
   - Thể loại, ngôn ngữ, số trang
   - Upload ảnh bìa (lưu lên Cloudinary)
   - Upload file sách PDF/EPUB (lưu lên Cloudinary)
4. Hệ thống validate dữ liệu
5. Hệ thống upload file lên Cloudinary
6. Hệ thống lưu thông tin sách vào Firestore
7. Hiển thị thông báo thành công

**Luồng sự kiện thay thế:**

- 4a. Thiếu thông tin bắt buộc → Hiển thị lỗi validation
- 5a. Upload file thất bại → Hiển thị thông báo lỗi

---

#### UC-23: Sửa thông tin sách (Admin)

| Thuộc tính               | Mô tả                               |
| ------------------------ | ----------------------------------- |
| **Tên Use Case**         | Sửa thông tin sách                  |
| **Mã Use Case**          | UC-23                               |
| **Tác nhân**             | Quản trị viên (Admin)               |
| **Mô tả**                | Admin cập nhật thông tin sách đã có |
| **Điều kiện tiên quyết** | Người dùng có quyền Admin           |
| **Điều kiện kết thúc**   | Thông tin sách được cập nhật        |

**Luồng sự kiện chính:**

1. Admin vào Quản lý sách
2. Admin chọn sách cần sửa
3. Hệ thống hiển thị form với thông tin hiện tại
4. Admin chỉnh sửa thông tin
5. Admin nhấn "Lưu"
6. Hệ thống cập nhật Firestore
7. Hiển thị thông báo thành công

---

#### UC-25: Quản lý thể loại (Admin)

| Thuộc tính               | Mô tả                        |
| ------------------------ | ---------------------------- |
| **Tên Use Case**         | Quản lý thể loại             |
| **Mã Use Case**          | UC-25                        |
| **Tác nhân**             | Quản trị viên (Admin)        |
| **Mô tả**                | Thêm, sửa, xóa thể loại sách |
| **Điều kiện tiên quyết** | Người dùng có quyền Admin    |
| **Điều kiện kết thúc**   | Thể loại được cập nhật       |

**Luồng sự kiện chính:**

1. Admin vào Quản trị → Quản lý thể loại
2. Hệ thống hiển thị danh sách thể loại
3. Admin có thể:
   - Thêm thể loại mới (tên, mô tả, icon)
   - Sửa thể loại đã có
   - Xóa thể loại (nếu không có sách nào thuộc thể loại đó)
4. Hệ thống cập nhật Firestore

---

#### UC-26: Quản lý người dùng (Admin)

| Thuộc tính               | Mô tả                               |
| ------------------------ | ----------------------------------- |
| **Tên Use Case**         | Quản lý người dùng                  |
| **Mã Use Case**          | UC-26                               |
| **Tác nhân**             | Quản trị viên (Admin)               |
| **Mô tả**                | Xem và quản lý tài khoản người dùng |
| **Điều kiện tiên quyết** | Người dùng có quyền Admin           |
| **Điều kiện kết thúc**   | Thông tin người dùng được cập nhật  |

**Luồng sự kiện chính:**

1. Admin vào Quản trị → Quản lý người dùng
2. Hệ thống hiển thị danh sách người dùng
3. Admin có thể:
   - Xem chi tiết thông tin user
   - Cấp/thu hồi quyền Admin
   - Khóa/mở khóa tài khoản
4. Hệ thống cập nhật Firestore

---

#### UC-27: Xem thống kê (Admin)

| Thuộc tính               | Mô tả                                  |
| ------------------------ | -------------------------------------- |
| **Tên Use Case**         | Xem thống kê                           |
| **Mã Use Case**          | UC-27                                  |
| **Tác nhân**             | Quản trị viên (Admin)                  |
| **Mô tả**                | Xem thống kê về hoạt động của hệ thống |
| **Điều kiện tiên quyết** | Người dùng có quyền Admin              |
| **Điều kiện kết thúc**   | Thống kê được hiển thị                 |

**Luồng sự kiện chính:**

1. Admin vào Quản trị → Thống kê
2. Hệ thống truy vấn dữ liệu từ Firestore
3. Hiển thị các thống kê:
   - Tổng số sách
   - Tổng số người dùng
   - Sách được đọc nhiều nhất
   - Người dùng hoạt động
   - Biểu đồ lượt đọc theo thời gian

---

### 5. Sơ đồ Use Case

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           AI READER SYSTEM                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────┐                                           ┌─────────┐     │
│  │  Guest  │                                           │  Admin  │     │
│  └────┬────┘                                           └────┬────┘     │
│       │                                                     │          │
│       ├──► UC-01: Đăng ký tài khoản                        │          │
│       ├──► UC-02: Đăng nhập                                │          │
│       ├──► UC-03: Đăng nhập Google                         │          │
│       ├──► UC-06: Xem danh sách sách                       │          │
│       └──► UC-07: Tìm kiếm sách                            │          │
│                                                             │          │
│  ┌─────────┐                                               │          │
│  │  User   │                                               │          │
│  └────┬────┘                                               │          │
│       │                                                     │          │
│       ├──► UC-04: Đăng xuất                                │          │
│       ├──► UC-08: Xem chi tiết sách                        │          │
│       ├──► UC-09: Đọc sách PDF                             │          │
│       ├──► UC-10: Đọc sách EPUB                            │          │
│       ├──► UC-11: Thêm yêu thích                           │          │
│       ├──► UC-12: Xóa yêu thích                            │          │
│       ├──► UC-13: Xem lịch sử đọc                          │          │
│       ├──► UC-14: Chat với AI ◄────────────┐               │          │
│       ├──► UC-15: Tóm tắt sách AI          │               │          │
│       ├──► UC-16: Gợi ý sách AI            │               │          │
│       ├──► UC-17: Text-to-Speech           │               │          │
│       ├──► UC-18: Xem hồ sơ                │               │          │
│       ├──► UC-19: Chỉnh sửa hồ sơ          │               │          │
│       ├──► UC-20: Cài đặt thông báo        │               │          │
│       └──► UC-21: Cài đặt bảo mật          │               │          │
│                                             │               │          │
│                              ┌──────────────┘               │          │
│                              │                              │          │
│                         ┌────▼────┐                        ▼          │
│                         │ Gemini  │              ┌──────────────────┐ │
│                         │   AI    │              │ Admin Use Cases  │ │
│                         └─────────┘              ├──────────────────┤ │
│                                                  │ UC-22: Thêm sách │ │
│                                                  │ UC-23: Sửa sách  │ │
│                                                  │ UC-24: Xóa sách  │ │
│                                                  │ UC-25: QL Thể loại│ │
│                                                  │ UC-26: QL Users  │ │
│                                                  │ UC-27: Thống kê  │ │
│                                                  └──────────────────┘ │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                       External Systems                            │ │
│  │  ┌───────────┐  ┌────────────┐  ┌──────────┐  ┌───────────────┐  │ │
│  │  │ Firebase  │  │ Cloudinary │  │  Gemini  │  │ Google Cloud  │  │ │
│  │  │ Auth/DB   │  │  Storage   │  │    AI    │  │     TTS       │  │ │
│  │  └───────────┘  └────────────┘  └──────────┘  └───────────────┘  │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 6. Mô hình dữ liệu chính

#### 6.1. Book Model

```
BookModel {
  id: String                    // ID duy nhất
  title: String                 // Tiêu đề sách
  author: String                // Tên tác giả
  description: String           // Mô tả/giới thiệu
  coverImageUrl: String         // URL ảnh bìa (Cloudinary)
  fileUrl: String               // URL file sách (Cloudinary)
  format: Enum (pdf, epub, txt) // Định dạng file
  category: String              // Thể loại
  tags: List<String>            // Nhãn/tags
  rating: Double                // Điểm đánh giá (0-5)
  reviewCount: Int              // Số lượt đánh giá
  pageCount: Int                // Số trang
  language: String              // Ngôn ngữ (vi, en,...)
  publishedDate: DateTime       // Ngày xuất bản
  addedAt: DateTime             // Ngày thêm vào hệ thống
  viewCount: Int                // Lượt xem
  downloadCount: Int            // Lượt tải
  isFree: Boolean               // Sách miễn phí?
  price: Double?                // Giá (nếu có)
}
```

#### 6.2. User Model

```
UserModel {
  id: String                    // ID duy nhất (Firebase UID)
  email: String                 // Email
  displayName: String           // Tên hiển thị
  photoUrl: String?             // URL ảnh đại diện
  phoneNumber: String?          // Số điện thoại
  isAdmin: Boolean              // Quyền admin
  createdAt: DateTime           // Ngày tạo tài khoản
  lastLoginAt: DateTime?        // Lần đăng nhập cuối
  favoriteBooks: List<String>   // Danh sách ID sách yêu thích
  preferences: Map?             // Tùy chọn cá nhân
}
```

#### 6.3. Reading History Model

```
ReadingHistoryModel {
  id: String                    // ID duy nhất
  userId: String                // ID người dùng
  bookId: String                // ID sách
  lastReadAt: DateTime          // Thời gian đọc cuối
  currentPage: Int              // Trang đang đọc
  totalPages: Int               // Tổng số trang
  progress: Double              // Tiến độ đọc (0-100%)
}
```

#### 6.4. Category Model

```
CategoryModel {
  id: String                    // ID duy nhất
  name: String                  // Tên thể loại
  description: String?          // Mô tả
  iconName: String?             // Tên icon
  bookCount: Int                // Số sách thuộc thể loại
}
```

#### 6.5. Comment Model

```
CommentModel {
  id: String                    // ID duy nhất
  bookId: String                // ID sách
  userId: String                // ID người bình luận
  userName: String              // Tên người bình luận
  content: String               // Nội dung bình luận
  rating: Double                // Điểm đánh giá
  createdAt: DateTime           // Thời gian tạo
  updatedAt: DateTime?          // Thời gian cập nhật
}
```

---

### 7. Công nghệ sử dụng

| Thành phần           | Công nghệ                   | Mô tả                            |
| -------------------- | --------------------------- | -------------------------------- |
| **Frontend**         | Flutter (Dart)              | Framework phát triển đa nền tảng |
| **State Management** | Provider, GetX              | Quản lý trạng thái ứng dụng      |
| **Backend**          | Firebase                    | Xác thực và cơ sở dữ liệu        |
| **Database**         | Cloud Firestore             | NoSQL database real-time         |
| **Authentication**   | Firebase Auth               | Xác thực người dùng              |
| **File Storage**     | Cloudinary                  | Lưu trữ ảnh và file sách         |
| **AI Service**       | Google Gemini API           | Chatbot và xử lý ngôn ngữ        |
| **Text-to-Speech**   | flutter_tts                 | Chuyển văn bản thành giọng nói   |
| **Google Cloud TTS** | googleapis_auth             | TTS chất lượng cao               |
| **PDF Reader**       | pdfx                        | Đọc file PDF                     |
| **HTTP Client**      | dio, http                   | Gọi API                          |
| **Local Storage**    | shared_preferences, sqflite | Lưu trữ cục bộ                   |

---

### 8. Yêu cầu phi chức năng

| Yêu cầu              | Mô tả                                              |
| -------------------- | -------------------------------------------------- |
| **Hiệu suất**        | Ứng dụng phải tải danh sách sách trong vòng 3 giây |
| **Khả năng mở rộng** | Hỗ trợ hàng nghìn người dùng đồng thời             |
| **Bảo mật**          | Dữ liệu người dùng được mã hóa, xác thực an toàn   |
| **Đa nền tảng**      | Hoạt động trên iOS, Android, Web, Desktop          |
| **Offline**          | Hỗ trợ đọc sách đã tải offline                     |
| **UX/UI**            | Giao diện thân thiện, dễ sử dụng                   |
| **Ngôn ngữ**         | Hỗ trợ tiếng Việt                                  |

---

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

# Gemini AI Configuration
GEMINI_API_KEY=your_gemini_api_key
```

### Bước 3: Restart ứng dụng

Sau khi thêm cấu hình, restart ứng dụng để áp dụng thay đổi.

## Cấu trúc thư mục Cloudinary

- `book_covers/`: Ảnh bìa sách
- `books/`: File sách (PDF, EPUB, etc.)
- `uploads/`: Các file upload khác

## Cấu hình Firestore Security Rules

Để ứng dụng có thể đọc/ghi dữ liệu vào Firestore, bạn cần cấu hình Security Rules:

### Cách 1: Cấu hình qua Firebase Console

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

## Lưu ý

- **Bảo mật**: Không commit file `.env` lên Git
- **Firebase**: Firebase Storage đã được loại bỏ. Chỉ sử dụng Firestore
- **Upload**: Tất cả upload ảnh/file đều qua Cloudinary API
- **Firestore Rules**: Đảm bảo đã cấu hình Security Rules
