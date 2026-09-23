import 'dart:math';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR via Google ML Kit (no network, no Gemini tokens).
class OcrService {
  OcrService();

  Future<String> extractLineByLine(String imagePath) async {
    final recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));

      final lines = <Map<String, dynamic>>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final box = line.boundingBox;
          lines.add({
            'text': line.text.trim(),
            'left': box.left,
            'cy': (box.top + box.bottom) / 2.0,
            'height': box.height,
          });
        }
      }
      if (lines.isEmpty) return '';

      final avgH =
          lines.map((m) => m['height'] as double).reduce((a, b) => a + b) /
              lines.length;
      final tol = max(6.0, avgH * 0.6);

      lines.sort((a, b) => (a['cy'] as double).compareTo(b['cy'] as double));

      final rows = <List<Map<String, dynamic>>>[];
      for (final line in lines) {
        var placed = false;
        for (final row in rows) {
          final rowCy =
              row.map((m) => m['cy'] as double).reduce((a, b) => a + b) /
                  row.length;
          if (((line['cy'] as double) - rowCy).abs() <= tol) {
            row.add(line);
            placed = true;
            break;
          }
        }
        if (!placed) rows.add([line]);
      }

      final buffer = StringBuffer();
      for (final row in rows) {
        row.sort(
          (a, b) => (a['left'] as double).compareTo(b['left'] as double),
        );
        buffer.writeln(
          row
              .map((m) => m['text'] as String)
              .where((t) => t.isNotEmpty)
              .join('  '),
        );
      }
      return buffer.toString().trimRight();
    } finally {
      await recognizer.close();
    }
  }
}
