import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../utils/logger.dart';

Future<void> saveOrShareFile(List<int> pdfBytes, String fileName, String subject) async {
  try {
    // Convert List<int> to Uint8List if needed
    final Uint8List uint8List = pdfBytes is Uint8List ? pdfBytes : Uint8List.fromList(pdfBytes);
    
    // Create a blob from the PDF bytes
    final blob = web.Blob([uint8List.toJS].toJS);
    
    // Create object URL from blob
    final url = web.URL.createObjectURL(blob);
    
    // Create anchor element and trigger download
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    
    // Add to document, click, and remove
    web.document.body!.appendChild(anchor);
    anchor.click();
    web.document.body!.removeChild(anchor);
    
    // Clean up the object URL
    web.URL.revokeObjectURL(url);
    
    AppLogger.debug('Web download initiated');
  } catch (e, stackTrace) {
    AppLogger.error('Error in saveOrShareFile (web)', e, stackTrace);
    rethrow;
  }
}