import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Service for generating and sharing PDF reports
class PdfGeneratorService {
  static final PdfGeneratorService _instance = PdfGeneratorService._internal();

  factory PdfGeneratorService() {
    return _instance;
  }

  PdfGeneratorService._internal();

  /// Generate a formatted issue report PDF
  Future<File> generateIssueReportPdf({
    required Map<String, dynamic> issue,
    required Map<String, dynamic> asset,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ISSUE REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Issue #${issue['id'] ?? 'N/A'}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _formatDate(issue['date']?.toString() ?? issue['createdAt']?.toString()),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      _capitalized(issue['status']?.toString() ?? 'Open'),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Issue Title
          pw.Text(
            issue['title'] ?? 'Issue Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),

          // Asset Information Section
          _buildPdfSection(
            'ASSET INFORMATION',
            [
              _buildDetailItem('Asset Name', asset['name'] ?? 'N/A'),
              _buildDetailItem('Model', asset['model'] ?? 'N/A'),
              _buildDetailItem('Brand', asset['brand'] ?? 'N/A'),
              _buildDetailItem('Serial Number', asset['serialNumber'] ?? 'N/A'),
              _buildDetailItem('Location', asset['location'] ?? 'N/A'),
              _buildDetailItem('Purchase Date', asset['purchasedAt'] ?? 'N/A'),
            ],
          ),
          pw.SizedBox(height: 16),

          // Service Details Section
          _buildPdfSection(
            'SERVICE DETAILS',
            [
              _buildDetailItem('Severity', _capitalized(issue['severity']?.toString() ?? 'Medium')),
              _buildDetailItem('Status', _capitalized(issue['status']?.toString() ?? 'Open')),
              _buildDetailItem('Reported On', _formatDate(issue['date']?.toString() ?? issue['createdAt']?.toString())),
              _buildDetailItem('Last Updated', _formatDate(issue['updatedAt']?.toString())),
            ],
          ),
          pw.SizedBox(height: 16),

          // Problem Description Section
          pw.Text(
            'PROBLEM DESCRIPTION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              issue['description'] ?? 'No description available.',
              style: pw.TextStyle(
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Resolution Section (if resolved)
          if (issue['status']?.toString().toLowerCase() == 'resolved' ||
              issue['status']?.toString().toLowerCase() == 'closed')
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RESOLUTION',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Issue has been resolved successfully.',
                    style: pw.TextStyle(
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),

          // Footer
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on ${DateTime.now().toString().split('.')[0]}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'HomeIQ - Home Asset Lifecycle Management',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'issue_${issue['id'] ?? 'report'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Generate a maintenance report PDF
  Future<File> generateMaintenanceReportPdf({
    required Map<String, dynamic> maintenance,
    required Map<String, dynamic> asset,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            'MAINTENANCE REPORT',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          _buildPdfSection(
            'ASSET INFORMATION',
            [
              _buildDetailItem('Asset Name', asset['name'] ?? 'N/A'),
              _buildDetailItem('Model', asset['model'] ?? 'N/A'),
              _buildDetailItem('Maintenance Type', maintenance['type'] ?? 'N/A'),
              _buildDetailItem('Date', _formatDate(maintenance['date']?.toString())),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'NOTES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Text(
              maintenance['notes'] ?? 'No notes',
              style: pw.TextStyle(fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'maintenance_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build a section with details for PDF
  static pw.Widget _buildPdfSection(String title, List<pw.Widget> details) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: details,
          ),
        ),
      ],
    );
  }

  /// Build a detail item for PDF
  static pw.Widget _buildDetailItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Format date for PDF
  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Capitalize first letter
  static String _capitalized(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Share PDF file
  static Future<void> sharePdf(File file, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: subject,
    );
  }
}
