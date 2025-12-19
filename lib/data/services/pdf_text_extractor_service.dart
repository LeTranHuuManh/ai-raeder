import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';

/// Service for extracting text from PDF files using Syncfusion PDF
class PdfTextExtractorService {
  static final PdfTextExtractorService _instance =
      PdfTextExtractorService._internal();
  factory PdfTextExtractorService() => _instance;
  PdfTextExtractorService._internal();

  /// Extract text from PDF bytes
  /// 
  /// Returns a map of page index (0-based) to extracted text
  Future<Map<int, String>> extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      // Create a copy of bytes to prevent ArrayBuffer detachment issues (especially on web)
      final pdfBytesCopy = Uint8List.fromList(pdfBytes);
      final pdfDocument = PdfDocument(inputBytes: pdfBytesCopy);
      final Map<int, String> pageTexts = {};

      for (int i = 0; i < pdfDocument.pages.count; i++) {
        try {
          final text = _extractTextFromPage(pdfDocument, i);
          if (text.isNotEmpty) {
            pageTexts[i] = text;
          }
        } catch (e) {
          debugPrint('Error extracting text from page ${i + 1}: $e');
          // Continue with other pages
        }
      }

      pdfDocument.dispose();
      return pageTexts;
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      rethrow;
    }
  }

  /// Extract text from a single PDF page
  String _extractTextFromPage(PdfDocument document, int pageIndex) {
    try {
      // Extract text from page using Syncfusion PDF
      final textExtractor = PdfTextExtractor(document);
      final extractedText = textExtractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
      return extractedText.trim();
    } catch (e) {
      debugPrint('Error extracting text from page: $e');
      return '';
    }
  }

  /// Extract text from a specific page
  Future<String?> extractTextFromPage(
    Uint8List pdfBytes,
    int pageIndex,
  ) async {
    try {
      // Create a copy of bytes to prevent ArrayBuffer detachment issues (especially on web)
      final pdfBytesCopy = Uint8List.fromList(pdfBytes);
      final pdfDocument = PdfDocument(inputBytes: pdfBytesCopy);
      
      if (pageIndex < 0 || pageIndex >= pdfDocument.pages.count) {
        pdfDocument.dispose();
        return null;
      }

      final textExtractor = PdfTextExtractor(pdfDocument);
      final extractedText = textExtractor.extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );
      
      pdfDocument.dispose();
      return extractedText.trim();
    } catch (e) {
      debugPrint('Error extracting text from page ${pageIndex + 1}: $e');
      return null;
    }
  }

  /// Extract text from a specific page range
  Future<Map<int, String>> extractTextFromPageRange(
    Uint8List pdfBytes,
    int startPage,
    int endPage,
  ) async {
    try {
      // Create a copy of bytes to prevent ArrayBuffer detachment issues (especially on web)
      final pdfBytesCopy = Uint8List.fromList(pdfBytes);
      final pdfDocument = PdfDocument(inputBytes: pdfBytesCopy);
      final Map<int, String> pageTexts = {};

      final actualStartPage = startPage.clamp(0, pdfDocument.pages.count - 1);
      final actualEndPage = endPage.clamp(0, pdfDocument.pages.count - 1);

      final textExtractor = PdfTextExtractor(pdfDocument);
      final allText = textExtractor.extractText(
        startPageIndex: actualStartPage,
        endPageIndex: actualEndPage,
      );
      
      // Split text by pages if possible, otherwise assign to first page
      if (allText.trim().isNotEmpty) {
        // For simplicity, assign all text to the start page
        // In a more sophisticated implementation, you could try to split by page
        pageTexts[actualStartPage] = allText.trim();
      }

      pdfDocument.dispose();
      return pageTexts;
    } catch (e) {
      debugPrint('Error extracting text from page range: $e');
      rethrow;
    }
  }
}

