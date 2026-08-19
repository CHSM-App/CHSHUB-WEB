import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

class PDFViewerPage extends StatefulWidget {
  final String filepath;

  const PDFViewerPage({super.key, required this.filepath});

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReady
              ? "Page ${_currentPage + 1} / $_totalPages"
              : "PDF Viewer",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                final file = File(widget.filepath);

                if (!await file.exists()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PDF file not found")),
                  );
                  return;
                }

                await Share.shareXFiles(
                  [XFile(widget.filepath)],
                  text: "Sharing PDF Document",
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Couldn't share the PDF. Please try again."),
                  ),
                );
              }
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          PDFView(
            filePath: widget.filepath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageSnap: true,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
                _isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = "We couldn't load this PDF. Please try again.";
              });
            },
            onPageError: (page, error) {
              setState(() {
                _errorMessage = "We couldn't load this PDF. Please try again.";
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page!;
              });
            },
          ),

          // Loading Indicator
          if (!_isReady && _errorMessage == "")
            const Center(child: CircularProgressIndicator()),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
