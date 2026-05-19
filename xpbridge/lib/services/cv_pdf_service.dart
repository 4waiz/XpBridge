import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cv_data.dart';

/// Renders a [CvData] to a clean, single-column A4 PDF and hands it to the
/// platform share/print sheet. No server round-trip — the LaTeX-style layout
/// is reproduced here with the `pdf` package.
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
          margin: const pw.EdgeInsets.fromLTRB(40, 42, 40, 42),
        ),
        build: (context) => [
          _header(cv, bold, semi),
          if ((cv.summary ?? '').trim().isNotEmpty) ...[
            _sectionTitle('Profile', bold),
            pw.Text(cv.summary!.trim(),
                style: pw.TextStyle(fontSize: 10.5, color: _ink, height: 1.4)),
            pw.SizedBox(height: 14),
          ],
          if (cv.experience.isNotEmpty) ...[
            _sectionTitle('Experience', bold),
            ...cv.experience.map((e) => _experience(e, bold, semi)),
          ],
          if (cv.projects.isNotEmpty) ...[
            _sectionTitle('Projects', bold),
            ...cv.projects.map((p) => _project(p, bold, semi)),
          ],
          if (cv.education.isNotEmpty) ...[
            _sectionTitle('Education', bold),
            ...cv.education.map((ed) => _education(ed, bold, semi)),
          ],
          if (cv.skills.isNotEmpty) ...[
            _sectionTitle('Skills', bold),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cv.skills.map(_chip).toList(),
            ),
            pw.SizedBox(height: 14),
          ],
          if (cv.certifications.isNotEmpty) ...[
            _sectionTitle('Certifications', bold),
            ...cv.certifications.map(
              (c) => pw.Bullet(
                text: c,
                style: pw.TextStyle(fontSize: 10.5, color: _ink),
              ),
            ),
          ],
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _header(CvData cv, pw.Font bold, pw.Font semi) {
    final contact = <String>[
      if ((cv.location ?? '').trim().isNotEmpty) cv.location!.trim(),
      if ((cv.email ?? '').trim().isNotEmpty) cv.email!.trim(),
      if ((cv.phone ?? '').trim().isNotEmpty) cv.phone!.trim(),
      ...cv.links.map((l) => l.url.isNotEmpty ? l.url : l.label),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          (cv.fullName ?? 'Your Name').trim(),
          style: pw.TextStyle(font: bold, fontSize: 24, color: _ink),
        ),
        if ((cv.headline ?? '').trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            cv.headline!.trim(),
            style: pw.TextStyle(font: semi, fontSize: 12, color: _accent),
          ),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            contact.join('  •  '),
            style: pw.TextStyle(fontSize: 9.5, color: _muted),
          ),
        ],
        pw.SizedBox(height: 12),
        pw.Divider(color: _accent, thickness: 1.2, height: 1),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font bold) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: bold,
            fontSize: 11,
            color: _accent,
            letterSpacing: 1.4,
          ),
        ),
      );

  static pw.Widget _experience(CvExperience e, pw.Font bold, pw.Font semi) {
    final title = [e.role, e.company]
        .where((s) => (s ?? '').trim().isNotEmpty)
        .join(' · ');
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
                  title.isEmpty ? 'Role' : title,
                  style: pw.TextStyle(font: semi, fontSize: 11.5, color: _ink),
                ),
              ),
              if ((e.period ?? '').trim().isNotEmpty)
                pw.Text(e.period!.trim(),
                    style: pw.TextStyle(fontSize: 9.5, color: _muted)),
            ],
          ),
          if ((e.location ?? '').trim().isNotEmpty)
            pw.Text(e.location!.trim(),
                style: pw.TextStyle(fontSize: 9.5, color: _muted)),
          pw.SizedBox(height: 4),
          ...e.highlights.map(
            (h) => pw.Bullet(
              text: h,
              style: pw.TextStyle(fontSize: 10.5, color: _ink, height: 1.35),
              bulletColor: _accent,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _project(CvProject p, pw.Font bold, pw.Font semi) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              (p.name ?? 'Project').trim(),
              style: pw.TextStyle(font: semi, fontSize: 11.5, color: _ink),
            ),
            if ((p.description ?? '').trim().isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(p.description!.trim(),
                  style:
                      pw.TextStyle(fontSize: 10.5, color: _ink, height: 1.35)),
            ],
            if (p.tech.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                p.tech.join(' · '),
                style: pw.TextStyle(fontSize: 9.5, color: _muted),
              ),
            ],
          ],
        ),
      );

  static pw.Widget _education(CvEducation ed, pw.Font bold, pw.Font semi) =>
      pw.Padding(
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
                        .join(' · '),
                    style:
                        pw.TextStyle(font: semi, fontSize: 11.5, color: _ink),
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

  static pw.Widget _chip(String label) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFEAF9F6),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(label,
            style: pw.TextStyle(fontSize: 9.5, color: _ink)),
      );
}
