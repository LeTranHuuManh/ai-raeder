import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // Thay bằng API key thực
  static const String _baseUrl = 'https://api.openai.com/v1';

  // Tóm tắt văn bản
  Future<String> summarizeText(String text, {int maxWords = 200}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Bạn là một trợ lý AI chuyên tóm tắt văn bản tiếng Việt một cách ngắn gọn và dễ hiểu.',
            },
            {
              'role': 'user',
              'content':
                  'Hãy tóm tắt đoạn văn sau trong khoảng $maxWords từ:\n\n$text',
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi tóm tắt văn bản: ${e.toString()}');
    }
  }

  // Tóm tắt chương sách
  Future<String> summarizeChapter(String chapterContent) async {
    try {
      return await summarizeText(chapterContent, maxWords: 300);
    } catch (e) {
      throw Exception('Lỗi tóm tắt chương: ${e.toString()}');
    }
  }

  // Tóm tắt toàn bộ sách (từ nhiều chương)
  Future<String> summarizeBook(List<String> chapters) async {
    try {
      final combinedText = chapters.join('\n\n');

      // Nếu nội dung quá dài, tóm tắt từng phần rồi kết hợp
      if (combinedText.length > 10000) {
        List<String> summaries = [];

        for (var chapter in chapters) {
          if (chapter.length > 2000) {
            final summary = await summarizeText(chapter, maxWords: 150);
            summaries.add(summary);
          }
        }

        final combinedSummaries = summaries.join('\n\n');
        return await summarizeText(combinedSummaries, maxWords: 500);
      } else {
        return await summarizeText(combinedText, maxWords: 500);
      }
    } catch (e) {
      throw Exception('Lỗi tóm tắt sách: ${e.toString()}');
    }
  }

  // Phân tích cảm xúc văn bản
  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Phân tích cảm xúc của văn bản và trả về kết quả dưới dạng JSON với các trường: sentiment (positive/negative/neutral), score (0-1), keywords (danh sách từ khóa).',
            },
            {'role': 'user', 'content': text},
          ],
          'max_tokens': 200,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].trim();
        return jsonDecode(content);
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      return {'sentiment': 'neutral', 'score': 0.5, 'keywords': []};
    }
  }

  // Gợi ý sách dựa trên sở thích
  Future<List<String>> recommendBooks(
    List<String> favoriteCategories,
    List<String> readBooks,
  ) async {
    try {
      final prompt =
          '''
Dựa trên thông tin sau:
- Thể loại yêu thích: ${favoriteCategories.join(', ')}
- Đã đọc: ${readBooks.join(', ')}

Hãy gợi ý 5 cuốn sách phù hợp (chỉ trả về tên sách, mỗi tên một dòng).
''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].trim();
        return content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Trích xuất key points từ văn bản
  Future<List<String>> extractKeyPoints(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Trích xuất 5-7 ý chính quan trọng nhất từ văn bản. Mỗi ý một dòng, bắt đầu bằng dấu "-".',
            },
            {'role': 'user', 'content': text},
          ],
          'max_tokens': 400,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].trim();
        return content
            .split('\n')
            .where((line) => line.trim().startsWith('-'))
            .map((line) => line.trim().substring(1).trim())
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
