import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cv_data.dart';

class CvPdfService {
  CvPdfService._();

  static const PdfColor _accent = PdfColor.fromInt(0xFF159C92);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1F2933);
  static const PdfColor _muted = PdfColor.fromInt(0xFF56616A);

  static Future<void> exportAndShare(CvData cv) async {
    final doc = await _build(cv);
    final bytes = await doc.save();
    final name = (cv.fullName ?? 'cv').trim().isEmpty
        ? 'cv'
        : cv.fullName!.trim().replaceAll(RegExp(r'\s+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
  }

  static Future<pw.Document> _build(CvData cv) async {
    final base = await PdfGoogleFonts.manropeRegular();
    final bold = await PdfGoogleFonts.manropeBold();
    final semi = await PdfGoogleFonts.manropeSemiBold();

    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: base, bold: bold);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        ),
        build: (context) => [
          _header(cv, bold, semi),
          if ((cv.objective ?? '').trim().isNotEmpty) ...[
            _sectionTitle('Objective', bold),
            pw.Text(cv.objective!.trim(),
                style: pw.TextStyle(fontSize: 10.5, color: _ink, height: 1.45)),
            pw.SizedBox(height: 14),
          ],
          if (cv.education.isNotEmpty) ...[
            _sectionTitle('Education', bold),
            ...cv.education.map((e) => _education(e, semi)),
          ],
          if (cv.skillCategories.isNotEmpty) ...[
            _sectionTitle('Skills & Abilities', bold),
            _skills(cv.skillCategories, semi),
            pw.SizedBox(height: 14),
          ],
          if (cv.experience.isNotEmpty) ...[
            _sectionTitle('Experience', bold),
            ...cv.experience.map((e) => _experience(e, semi)),
          ],
          if (cv.projects.isNotEmpty) ...[
            _sectionTitle('Projects', bold),
            ...cv.projects.map((p) => _project(p, semi)),
          ],
          if (cv.achievements.isNotEmpty) ...[
            _sectionTitle('Achievements', bold),
            ...cv.achievements.map(
              (a) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Bullet(
                  text: a,
                  style: pw.TextStyle(fontSize: 10.5, color: _ink, height: 1.4),
                  bulletColor: _accent,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
          ],
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _header(CvData cv, pw.Font bold, pw.Font semi) {
    final line1 = <String>[
      if ((cv.phone ?? '').trim().isNotEmpty) cv.phone!.trim(),
      if ((cv.location ?? '').trim().isNotEmpty) cv.location!.trim(),
    ];
    final line2 = <String>[
      if ((cv.email ?? '').trim().isNotEmpty) cv.email!.trim(),
      ...cv.links.map((l) => l.label.isNotEmpty ? l.label : l.url),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: pw.Text(
            (cv.fullName ?? 'Your Name').trim(),
            style: pw.TextStyle(font: bold, fontSize: 22, color: _ink),
          ),
        ),
        if ((cv.headline ?? '').trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              cv.headline!.trim(),
              style: pw.TextStyle(fontSize: 11, color: _ink),
            ),
          ),
        ],
        if (line1.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              line1.join('   ⋄   '),
              style: pw.TextStyle(fontSize: 9.5, color: _muted),
            ),
          ),
        ],
        if (line2.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              line2.join('   ⋄   '),
              style: pw.TextStyle(fontSize: 9.5, color: _muted),
            ),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Divider(color: _ink, thickness: 1.5, height: 1),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font bold) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: bold,
              fontSize: 10.5,
              color: _ink,
              letterSpacing: 1.2,
            ),
          ),
          pw.Divider(color: _ink, thickness: 0.8, height: 6),
          pw.SizedBox(height: 6),
        ],
      );

  static pw.Widget _skills(List<CvSkillCategory> categories, pw.Font semi) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: categories.map((cat) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${cat.category}: ',
                    style: pw.TextStyle(
                      font: semi,
                      fontSize: 10.5,
                      color: _ink,
                    ),
                  ),
                  pw.TextSpan(
                    text: cat.items.join(', '),
                    style: pw.TextStyle(fontSize: 10.5, color: _ink),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

  static pw.Widget _experience(CvExperience e, pw.Font semi) {
    final roleCompany = [e.role, e.company]
        .where((s) => (s ?? '').trim().isNotEmpty)
        .join(' — ');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  roleCompany.isEmpty ? 'Role' : roleCompany,
                  style: pw.TextStyle(font: semi, fontSize: 11, color: _ink),
                ),
              ),
              if ((e.period ?? '').trim().isNotEmpty)
                pw.Text(e.period!.trim(),
                    style: pw.TextStyle(fontSize: 9.5, color: _muted)),
            ],
          ),
          if ((e.location ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(e.location!.trim(),
                style: pw.TextStyle(
                    fontSize: 9.5, color: _muted, fontStyle: pw.FontStyle.italic)),
          ],
          pw.SizedBox(height: 4),
          ...e.highlights.map(
            (h) => pw.Bullet(
              text: h,
              style: pw.TextStyle(fontSize: 10.5, color: _ink, height: 1.4),
              bulletColor: _accent,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _project(CvProject p, pw.Font semi) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  (p.name ?? 'Project').trim(),
                  style: pw.TextStyle(font: semi, fontSize: 11, color: _ink),
                ),
                if ((p.link ?? '').trim().isNotEmpty)
                  pw.Text('[Link]',
                      style: pw.TextStyle(fontSize: 9.5, color: _accent)),
              ],
            ),
            pw.SizedBox(height: 3),
            ...p.highlights.map(
              (h) => pw.Bullet(
                text: h,
                style: pw.TextStyle(fontSize: 10.5, color: _ink, height: 1.35),
                bulletColor: _accent,
              ),
            ),
            if (p.tech.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'Stack: ${p.tech.join(', ')}',
                style: pw.TextStyle(fontSize: 9.5, color: _muted),
              ),
            ],
          ],
        ),
      );

  static pw.Widget _education(CvEducation ed, pw.Font semi) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    [ed.degree, ed.institution]
                        .where((s) => (s ?? '').trim().isNotEmpty)
                        .join(', '),
                    style: pw.TextStyle(font: semi, fontSize: 11, color: _ink),
                  ),
                ),
                if ((ed.period ?? '').trim().isNotEmpty)
                  pw.Text(ed.period!.trim(),
                      style: pw.TextStyle(fontSize: 9.5, color: _muted)),
              ],
            ),
            if ((ed.details ?? '').trim().isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(ed.details!.trim(),
                  style: pw.TextStyle(fontSize: 10, color: _muted)),
            ],
          ],
        ),
      );
}
