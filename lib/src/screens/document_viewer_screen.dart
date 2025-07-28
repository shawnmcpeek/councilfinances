import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../services/report_file_saver.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String documentUrl;
  final String documentName;

  const DocumentViewerScreen({
    super.key,
    required this.documentUrl,
    required this.documentName,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Uint8List? _documentBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // For now, we'll handle local file paths and URLs
      // In a real implementation, you'd need to handle Supabase storage URLs
      if (widget.documentUrl.startsWith('http')) {
        final response = await http.get(Uri.parse(widget.documentUrl));
        if (response.statusCode == 200) {
          setState(() {
            _documentBytes = response.bodyBytes;
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load document: ${response.statusCode}');
        }
      } else {
        // Handle local file paths (for testing)
        throw Exception('Local file viewing not implemented yet');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadDocument() async {
    if (_documentBytes != null) {
      try {
        await saveOrShareFile(_documentBytes!, widget.documentName, 'Document: ${widget.documentName}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document downloaded successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download document: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentName),
        actions: [
          if (_documentBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadDocument,
              tooltip: 'Download Document',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading document...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading document',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocument,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_documentBytes == null) {
      return const Center(
        child: Text('No document data available'),
      );
    }

    // Determine file type and show appropriate viewer
    final fileName = widget.documentName.toLowerCase();
    if (fileName.endsWith('.pdf')) {
      return _buildPdfViewer();
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
      return _buildImageViewer();
    } else {
      return _buildGenericViewer();
    }
  }

  Widget _buildPdfViewer() {
    // For now, show a placeholder for PDF viewing
    // In a real implementation, you'd use a PDF viewer package
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'PDF Document',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'PDF viewing not implemented yet.\nUse the download button to view the document.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _downloadDocument,
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            'Image Document',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Image viewing not implemented yet.\nUse the download button to view the image.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _downloadDocument,
            child: const Text('Download Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_drive_file,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Document',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Document viewing not implemented yet.\nUse the download button to view the document.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _downloadDocument,
            child: const Text('Download Document'),
          ),
        ],
      ),
    );
  }
} 