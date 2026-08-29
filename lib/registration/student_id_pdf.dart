import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'register_provider.dart';

/// Builds a printable A4 PDF of every student's ID-card summary — photo,
/// name, team name, and chest (registration) number — laid out 6 per
/// page (2 columns x 3 rows), and hands it to the platform print/share
/// sheet.
///
/// Requires these packages in pubspec.yaml (add if not already present):
///   pdf: ^3.11.1
///   printing: ^5.13.4
///   http: ^1.2.0
class StudentIdCardPdf {
  static const int _cardsPerPage = 6;
  static const int _columns = 2;
  static const int _rows = 3;

  /// Generates the PDF bytes. Student photos are downloaded first since
  /// pdf building itself is synchronous — a missing/broken photo just
  /// falls back to an initials avatar rather than failing the export.
  static Future<Uint8List> generate({
    required List<StudentRegistrationGroup> groups,
    required String teamName,
  }) async {
    final doc = pw.Document();

    final photoBytes = <String, Uint8List>{};
    for (final g in groups) {
      final url = g.photoUrl;
      if (url == null || url.isEmpty) continue;
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          photoBytes[g.studentId] = response.bodyBytes;
        }
      } catch (_) {
        // Ignore — card falls back to an initials avatar for this student.
      }
    }

    for (var i = 0; i < groups.length; i += _cardsPerPage) {
      final pageGroups = groups.sublist(
        i,
        (i + _cardsPerPage > groups.length) ? groups.length : i + _cardsPerPage,
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => _buildPageGrid(pageGroups, teamName, photoBytes),
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _buildPageGrid(
      List<StudentRegistrationGroup> pageGroups,
      String teamName,
      Map<String, Uint8List> photoBytes,
      ) {
    final rows = <pw.Widget>[];
    for (var r = 0; r < _rows; r++) {
      final rowCards = <pw.Widget>[];
      for (var c = 0; c < _columns; c++) {
        final idx = r * _columns + c;
        if (c == 1) rowCards.add(pw.SizedBox(width: 12));
        if (idx < pageGroups.length) {
          final group = pageGroups[idx];
          rowCards.add(pw.Expanded(child: _buildCard(group, teamName, photoBytes[group.studentId])));
        } else {
          rowCards.add(pw.Expanded(child: pw.Container()));
        }
      }
      rows.add(pw.Expanded(child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: rowCards)));
      if (r < _rows - 1) rows.add(pw.SizedBox(height: 12));
    }
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: rows);
  }

  static pw.Widget _buildCard(StudentRegistrationGroup group, String teamName, Uint8List? photo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.ClipRRect(
            horizontalRadius: 30,
            verticalRadius: 30,
            child: photo != null
                ? pw.Image(pw.MemoryImage(photo), width: 58, height: 58, fit: pw.BoxFit.cover)
                : pw.Container(
              width: 58,
              height: 58,
              color: PdfColors.grey200,
              alignment: pw.Alignment.center,
              child: pw.Text(
                group.studentName.isNotEmpty ? group.studentName[0].toUpperCase() : '?',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  group.studentName,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.SizedBox(height: 2),
                if (teamName.isNotEmpty)
                  pw.Text(teamName,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip),
                pw.SizedBox(height: 4),
                pw.Text('Chest No: ${group.registrationNumber}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                pw.SizedBox(height: 2),
                pw.Text('${group.totalPrograms} programs',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generates the PDF, then opens the platform print/share sheet
  /// (print, save, or share, depending on OS) via the `printing` package.
  static Future<void> printAll({
    required List<StudentRegistrationGroup> groups,
    required String teamName,
  }) async {
    final bytes = await generate(groups: groups, teamName: teamName);
    final fileName = '${teamName.isNotEmpty ? teamName.replaceAll(' ', '_') : 'students'}_id_cards.pdf';
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
  }
}