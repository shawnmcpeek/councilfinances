import 'dart:html' as html;
import '../utils/logger.dart';

Future<void> saveOrShareFile(List<int> pdfBytes, String fileName, String subject) async {
  try {
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    AppLogger.debug('Web download initiated');
  } catch (e, stackTrace) {
    AppLogger.error('Error in saveOrShareFile (web)', e, stackTrace);
    rethrow;
  }
} 