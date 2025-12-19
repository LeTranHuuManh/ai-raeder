import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Model cho tin nhắn chat
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Lưu lịch sử chat để có context
  final List<ChatMessage> _chatHistory = [];

  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  /// Xóa lịch sử chat
  void clearChatHistory() {
    _chatHistory.clear();
  }

  /// Gửi tin nhắn chat và nhận phản hồi
  Future<String> sendChatMessage(String userMessage) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Vui lòng cấu hình GEMINI_API_KEY trong file .env');
    }

    // Thêm tin nhắn user vào lịch sử
    _chatHistory.add(ChatMessage(content: userMessage, isUser: true));

    try {
      // Build conversation context từ lịch sử
      final conversationContext = _buildConversationContext();

      final prompt =
          '''Bạn là một trợ lý AI thông minh chuyên về sách và đọc sách tên là "AI Reader Assistant". 

Nhiệm vụ của bạn:
- Giúp người dùng tìm kiếm và gợi ý sách hay
- Trả lời câu hỏi về nội dung sách, tác giả, thể loại
- Tóm tắt sách khi được yêu cầu
- Thảo luận về văn học và các chủ đề liên quan đến sách
- Hỗ trợ người dùng trong việc đọc và hiểu sách

Quy tắc:
- Trả lời bằng tiếng Việt, thân thiện và dễ hiểu
- Câu trả lời ngắn gọn, súc tích nhưng đầy đủ thông tin
- Nếu không biết thông tin chính xác, hãy nói rõ
- Có thể đề xuất sách liên quan khi phù hợp

$conversationContext

Tin nhắn mới từ người dùng: $userMessage

Trả lời:''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null &&
              content['parts'] != null &&
              content['parts'].isNotEmpty) {
            final botResponse =
                content['parts'][0]['text']?.toString().trim() ??
                'Xin lỗi, tôi không thể trả lời lúc này.';

            // Thêm phản hồi bot vào lịch sử
            _chatHistory.add(ChatMessage(content: botResponse, isUser: false));

            return botResponse;
          }
        }

        throw Exception('Không nhận được phản hồi từ AI');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error']?['message'] ?? 'Lỗi không xác định';
        throw Exception('Lỗi: $errorMessage');
      }
    } catch (e) {
      // Xóa tin nhắn user nếu gửi thất bại
      if (_chatHistory.isNotEmpty && _chatHistory.last.isUser) {
        _chatHistory.removeLast();
      }
      debugPrint('Error in chat: $e');
      rethrow;
    }
  }

  /// Build context từ lịch sử hội thoại (giữ 10 tin nhắn gần nhất)
  String _buildConversationContext() {
    if (_chatHistory.isEmpty) return '';

    final recentMessages = _chatHistory.length > 10
        ? _chatHistory.sublist(_chatHistory.length - 10)
        : _chatHistory;

    final buffer = StringBuffer('Lịch sử hội thoại gần đây:\n');
    for (final msg in recentMessages) {
      final role = msg.isUser ? 'Người dùng' : 'AI';
      buffer.writeln('$role: ${msg.content}');
    }

    return buffer.toString();
  }

  /// Tóm tắt sách dựa trên nội dung văn bản
  Future<String> summarizeBook({
    required String bookTitle,
    required String bookAuthor,
    required String bookContent,
    String language = 'vi',
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Vui lòng cấu hình GEMINI_API_KEY trong file .env');
    }

    try {
      final prompt = _buildSummarizePrompt(
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        bookContent: bookContent,
        language: language,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      debugPrint('Gemini API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null &&
              content['parts'] != null &&
              content['parts'].isNotEmpty) {
            return content['parts'][0]['text'] ?? 'Không thể tạo tóm tắt';
          }
        }

        throw Exception('Không nhận được kết quả từ Gemini API');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error']?['message'] ?? 'Lỗi không xác định';
        debugPrint('Gemini API error: $errorMessage');
        throw Exception('Lỗi Gemini API: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error summarizing book: $e');
      rethrow;
    }
  }

  /// Tóm tắt một trang cụ thể
  Future<String> summarizePage({
    required String bookTitle,
    required String pageContent,
    required int pageNumber,
    String language = 'vi',
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Vui lòng cấu hình GEMINI_API_KEY trong file .env');
    }

    try {
      final prompt =
          '''
Bạn là một trợ lý AI chuyên tóm tắt sách. Hãy tóm tắt nội dung trang $pageNumber của sách "$bookTitle" bên dưới.

Yêu cầu:
- Tóm tắt ngắn gọn, súc tích trong khoảng 100-150 từ
- Giữ lại các ý chính và thông tin quan trọng
- Sử dụng ngôn ngữ ${language == 'vi' ? 'tiếng Việt' : 'tiếng Anh'}
- Trình bày rõ ràng, dễ hiểu

Nội dung trang $pageNumber:
"""
$pageContent
"""

Tóm tắt:
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null &&
              content['parts'] != null &&
              content['parts'].isNotEmpty) {
            return content['parts'][0]['text'] ?? 'Không thể tạo tóm tắt';
          }
        }

        throw Exception('Không nhận được kết quả từ Gemini API');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error']?['message'] ?? 'Lỗi không xác định';
        throw Exception('Lỗi Gemini API: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error summarizing page: $e');
      rethrow;
    }
  }

  /// Build prompt cho việc tóm tắt sách
  String _buildSummarizePrompt({
    required String bookTitle,
    required String bookAuthor,
    required String bookContent,
    required String language,
  }) {
    final langText = language == 'vi' ? 'tiếng Việt' : 'tiếng Anh';

    return '''
Bạn là một trợ lý AI chuyên tóm tắt và phân tích sách. Hãy tạo một bản tóm tắt chi tiết cho quyển sách dựa trên nội dung được cung cấp.

📚 THÔNG TIN SÁCH:
- Tên sách: $bookTitle
- Tác giả: $bookAuthor

📝 YÊU CẦU TÓM TẮT:
1. **Tổng quan**: Giới thiệu ngắn gọn về sách (2-3 câu)
2. **Nội dung chính**: Tóm tắt các ý chính, chủ đề và thông điệp quan trọng của sách
3. **Các điểm nổi bật**: Liệt kê 3-5 điểm nổi bật hoặc bài học quan trọng
4. **Đánh giá tổng thể**: Nhận xét ngắn về giá trị của sách

📋 QUY TẮC:
- Sử dụng ngôn ngữ $langText
- Tóm tắt trong khoảng 300-500 từ
- Trình bày rõ ràng với các mục được đánh số
- Giữ lại các thông tin quan trọng và loại bỏ chi tiết không cần thiết
- Sử dụng emoji để làm nổi bật các phần

📖 NỘI DUNG SÁCH:
"""
$bookContent
"""

Bản tóm tắt:
''';
  }

  /// Tóm tắt sách dựa trên thông tin cơ bản (không có nội dung chi tiết)
  Future<String> summarizeBookByInfo({
    required String bookTitle,
    required String bookAuthor,
    String? bookDescription,
    String? bookCategory,
    String language = 'vi',
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Vui lòng cấu hình GEMINI_API_KEY trong file .env');
    }

    try {
      final categoryInfo = (bookCategory != null && bookCategory.isNotEmpty)
          ? 'Thể loại: $bookCategory.'
          : '';
      final descInfo = (bookDescription != null && bookDescription.isNotEmpty)
          ? 'Mô tả thêm: $bookDescription.'
          : '';

      final prompt =
          '''Hãy viết một bài giới thiệu và tóm tắt chi tiết về cuốn sách "$bookTitle" của tác giả $bookAuthor. $categoryInfo $descInfo

Bài viết cần đảm bảo các yêu cầu sau:

1. Độ dài: Khoảng 250-300 từ tiếng Việt

2. Nội dung bắt buộc phải có:
   - Đoạn mở đầu: Giới thiệu tổng quan về tác phẩm, tác giả và vị trí của cuốn sách trong văn học
   - Bối cảnh: Thời gian, không gian diễn ra câu chuyện
   - Nhân vật: Giới thiệu nhân vật chính và các nhân vật quan trọng khác (tên, đặc điểm nổi bật)
   - Cốt truyện: Tóm tắt nội dung chính, các sự kiện quan trọng (không tiết lộ kết thúc)
   - Ý nghĩa: Thông điệp, giá trị và bài học từ tác phẩm

3. Phong cách viết:
   - Văn phong hấp dẫn, cuốn hút, giàu chất văn học
   - Viết thành các đoạn văn liền mạch, tự nhiên
   - KHÔNG sử dụng emoji, bullet points, đánh số hay định dạng markdown
   - KHÔNG có tiêu đề hay phân mục
   - Viết hoàn chỉnh từ đầu đến cuối, không được cắt giữa chừng

Hãy bắt đầu viết ngay, không cần lời mở đầu hay giải thích gì thêm:''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
        }),
      );

      debugPrint('Gemini response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('Gemini response data: $data');

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];

          // Check if response was blocked or truncated
          final finishReason = candidate['finishReason'];
          debugPrint('Finish reason: $finishReason');

          final content = candidate['content'];
          if (content != null &&
              content['parts'] != null &&
              content['parts'].isNotEmpty) {
            final text = content['parts'][0]['text']?.toString().trim() ?? '';
            if (text.isNotEmpty) {
              return text;
            }
          }
        }

        throw Exception('Không nhận được kết quả từ Gemini API');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error']?['message'] ?? 'Lỗi không xác định';
        throw Exception('Lỗi Gemini API: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error summarizing book by info: $e');
      rethrow;
    }
  }
}
