import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'register_provider.dart';
import 'registration_model.dart';

/// Builds a printable A3 landscape PDF of every student's ID-card
/// summary — photo, name, category, team name, chest (registration)
/// number, and their registered program names — laid out in a grid, and
/// hands it to the platform print/share sheet.
///
/// Requires these packages in pubspec.yaml (add if not already present):
///   pdf: ^3.11.1
///   printing: ^5.13.4
///   http: ^1.2.0
class StudentIdCardPdf {
  // ---- Grid layout ----
  static const int _cardsPerPage = 15;
  static const int _columns = 5;
  static const int _rows = 3;

  // ---- Fixed spacing/padding constants ----
  // All spacing in the card (and the grid around it) is drawn from these,
  // so nothing is a one-off magic number sprinkled through the widget
  // tree below.
  static const double _pagePadding = 16; // outer page margin
  static const double _gridGap = 12; // gap between cards, both axes
  static const double _cardPadding = 10; // inner padding of each card
  static const double _cardBorderRadius = 10;
  static const double _cardBorderWidth = 0.7;

  static const double _avatarSize = 58;
  static const double _avatarRadius = 30;

  static const double _gapAfterAvatar = 5;
  static const double _gapAfterCategory = 2;
  static const double _gapBeforeChestNo = 4;
  static const double _gapAfterChestNo = 4;

  static const double _sectionHeaderPaddingTop = 3;
  static const double _sectionHeaderPaddingBottom = 1.5;
  static const double _sectionColumnGap = 6; // gap between the two program columns
  static const double _programLineBottomPadding = 1;

  // ---- Font sizes ----
  static const double _initialsFontSize = 22;
  static const double _nameFontSize = 12;
  static const double _categoryFontSize = 10;
  static const double _teamNameFontSize = 9;
  static const double _chestNoFontSize = 23;
  static const double _noProgramsFontSize = 8;
  static const double _sectionHeaderFontSize = 7.5;
  static const double _programLineFontSize = 7.5;

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
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(_pagePadding),
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
        if (c > 0) rowCards.add(pw.SizedBox(width: _gridGap));
        if (idx < pageGroups.length) {
          final group = pageGroups[idx];
          rowCards.add(pw.Expanded(child: _buildCard(group, teamName, photoBytes[group.studentId])));
        } else {
          rowCards.add(pw.Expanded(child: pw.Container()));
        }
      }
      rows.add(pw.Expanded(child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: rowCards)));
      if (r < _rows - 1) rows.add(pw.SizedBox(height: _gridGap));
    }
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: rows);
  }

  /// Program names for a bucket (Stage / Non Stage / General).
  static List<String> _linesFor(List<RegistrationModel> registrations) {
    return registrations.map((r) => r.programName).toList();
  }

  static pw.Widget _buildCard(StudentRegistrationGroup group, String teamName, Uint8List? photo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: _cardBorderWidth),
        borderRadius: pw.BorderRadius.circular(_cardBorderRadius),
      ),
      padding: const pw.EdgeInsets.all(_cardPadding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          pw.ClipRRect(
            horizontalRadius: _avatarRadius,
            verticalRadius: _avatarRadius,
            child: photo != null
                ? pw.Image(pw.MemoryImage(photo),
                width: _avatarSize, height: _avatarSize, fit: pw.BoxFit.cover)
                : pw.Container(
              width: _avatarSize,
              height: _avatarSize,
              color: PdfColors.grey200,
              alignment: pw.Alignment.center,
              child: pw.Text(
                group.studentName.isNotEmpty ? group.studentName[0].toUpperCase() : '?',
                style: pw.TextStyle(
                    fontSize: _initialsFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600),
              ),
            ),
          ),
          pw.SizedBox(height: _gapAfterAvatar),
          pw.Text(
            group.studentName,
            style: pw.TextStyle(fontSize: _nameFontSize, fontWeight: pw.FontWeight.bold),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
          pw.Text(
            group.programCategory,
            style: const pw.TextStyle(fontSize: _categoryFontSize),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
          pw.SizedBox(height: _gapAfterCategory),
          if (teamName.isNotEmpty)
            pw.Text(teamName,
                style: const pw.TextStyle(fontSize: _teamNameFontSize, color: PdfColors.grey700),
                maxLines: 1,
                overflow: pw.TextOverflow.clip),
          pw.SizedBox(height: _gapBeforeChestNo),
          pw.Text(group.registrationNumber,
              style: pw.TextStyle(
                  fontSize: _chestNoFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo700)),
          pw.SizedBox(height: _gapAfterChestNo),
          // Three separate sections — Stage / Non Stage / General — each
          // with its own header, listing only that bucket's programs
          // underneath. A bucket with no registrations is skipped
          // entirely rather than showing an empty header.
          if (group.totalPrograms == 0)
            pw.Text('No programs registered',
                style: const pw.TextStyle(fontSize: _noProgramsFontSize, color: PdfColors.grey500))
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                ..._buildSection('Stage', _linesFor(group.stagePrograms), PdfColors.orange800),
                ..._buildSection('Non Stage', _linesFor(group.nonStagePrograms), PdfColors.blue800),
                ..._buildSection('General', _linesFor(group.generalPrograms), PdfColors.green800),
              ],
            ),
        ],
      ),
    );
  }

  /// Above this many programs in a single section, the list splits into
  /// two columns (filled column-major: first half down the left, rest
  /// down the right) instead of running one long single column — keeps a
  /// student with many registrations from stretching the card too tall.
  static const int _twoColumnThreshold = 3;

  /// Builds a labeled section ("Stage", "Non Stage", "General") followed
  /// by its list of program names, or nothing at all if this student has
  /// no registrations in that bucket.
  static List<pw.Widget> _buildSection(String label, List<String> lines, PdfColor color) {
    if (lines.isEmpty) return [];

    final header = pw.Padding(
      padding: const pw.EdgeInsets.only(
        top: _sectionHeaderPaddingTop,
        bottom: _sectionHeaderPaddingBottom,
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
            fontSize: _sectionHeaderFontSize, fontWeight: pw.FontWeight.bold, color: color),
      ),
    );

    if (lines.length <= _twoColumnThreshold) {
      return [
        header,
        for (final line in lines) _programLine(line),
      ];
    }

    // Column-major split: e.g. 5 programs -> 3 on the left, 2 on the right.
    //   program 1   program 4
    //   program 2   program 5
    //   program 3
    final splitIndex = (lines.length / 2).ceil();
    final leftColumn = lines.sublist(0, splitIndex);
    final rightColumn = lines.sublist(splitIndex);

    return [
      header,
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [for (final line in leftColumn) _programLine(line)],
            ),
          ),
          pw.SizedBox(width: _sectionColumnGap),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [for (final line in rightColumn) _programLine(line)],
            ),
          ),
        ],
      ),
    ];
  }

  static pw.Widget _programLine(String line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: _programLineBottomPadding),
      child: pw.Text(
        ' $line',
        style: const pw.TextStyle(fontSize: _programLineFontSize, color: PdfColors.grey800),
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  /// Generates the PDF, then opens the platform print/share sheet
  /// (print, save, or share, depending on OS) via the `printing` package.
  /// `format` tells the print dialog what page size/orientation to show
  /// initially — set to match the PDF's own A3 landscape pages.
  static Future<void> printAll({
    required List<StudentRegistrationGroup> groups,
    required String teamName,
  }) async {
    final bytes = await generate(groups: groups, teamName: teamName);
    final fileName = '${teamName.isNotEmpty ? teamName.replaceAll(' ', '_') : 'students'}_id_cards.pdf';
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
      format: PdfPageFormat.a3.landscape,
    );
  }
}