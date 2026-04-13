import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

/// Service for downloading and managing documents
class DocumentDownloadService {
  static final DocumentDownloadService _instance = DocumentDownloadService._internal();

  factory DocumentDownloadService() {
    return _instance;
  }

  DocumentDownloadService._internal();

  /// Download a document from URL
  Future<File> downloadDocument({
    required String url,
    required String fileName,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } on Object catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// Share a document file
  Future<void> shareDocument(File file, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
      );
    } on Object catch (e) {
      throw Exception('Share failed: $e');
    }
  }

  /// Delete a downloaded document
  Future<void> deleteDocument(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on Object catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  /// Get file size in human-readable format
  static String getFileSizeString(int sizeInBytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = sizeInBytes.toDouble();
    int suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[suffixIndex]}';
  }

  /// Get file extension from URL or filename
  static String getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1) {
        return path.substring(lastDot + 1).toLowerCase();
      }
    } catch (e) {
      // ignore
    }
    return 'file';
  }

  /// Check if file is an image
  static bool isImage(String url) {
    final ext = getFileExtension(url).toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Check if file is a PDF
  static bool isPdf(String url) {
    return getFileExtension(url).toLowerCase() == 'pdf';
  }

  /// Check if file is a video
  static bool isVideo(String url) {
    final ext = getFileExtension(url).toLowerCase();
    return ['mp4', 'avi', 'mov', 'mkv', 'webm', '3gp'].contains(ext);
  }

  /// Get appropriate MIME type for file
  static String getMimeType(String url) {
    final ext = getFileExtension(url).toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}
