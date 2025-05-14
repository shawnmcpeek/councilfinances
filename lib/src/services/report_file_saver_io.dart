import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../utils/logger.dart';
import 'package:file_selector/file_selector.dart';

Future<void> saveOrShareFile(List<int> pdfBytes, String fileName, String subject) async {
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms - use file_picker save dialog
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsBytes(pdfBytes);
        AppLogger.debug('Report saved to: $outputPath');
      } else {
        AppLogger.debug('File picker was cancelled by user');
      }
    } else {
      // Mobile platforms - use share_plus
      final XFile pdfXFile = XFile.fromData(
        Uint8List.fromList(pdfBytes),
        name: fileName,
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles(
        [pdfXFile],
        subject: subject,
      );
      AppLogger.debug('File shared successfully');
    }
  } catch (e, stackTrace) {
    AppLogger.error('Error in saveOrShareFile (IO)', e, stackTrace);
    rethrow;
  }
} 