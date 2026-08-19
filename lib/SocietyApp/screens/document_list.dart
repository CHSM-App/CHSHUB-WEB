import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/full_screen_gallery.dart';
import 'package:society_app/SocietyApp/screens/pdf_share.dart';
import 'package:society_app/SocietyApp/screens/upload_document.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/core/network/token_provider.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';


class DocumentListPage extends ConsumerStatefulWidget {
  const DocumentListPage({super.key});

  @override
  ConsumerState<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends ConsumerState<DocumentListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    ref.read(basicInfoViewModelProvider.notifier).ownerDocumentsList(ref.read(basicInfoViewModelProvider).flatId??0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(basicInfoViewModelProvider);
    final documentsAsync = state.ownerDocumentResult;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Documents',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ---------- Riverpod API Response Handling ----------
      body: documentsAsync?.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, _) => ErrorStatePage(error: error, onRetry: _loadData),

        data: (documents) {
          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadData,
              child: _buildEmptyState(),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final fileType = (doc.docType ?? '').toLowerCase();

                return _buildDocumentCard(
                  DocumentItem(
                    id:doc.documentId??0,
                    name: doc.documentName ?? 'Unknown',
                    type: fileType.isEmpty ? 'PDF' : fileType.toUpperCase(),
                    filePath: doc.docPath??"",
                    //size: '${doc.size ?? 'N/A'} MB',
                    date: doc.uploadDate ?? '',
                    icon: _getFileIcon(fileType),
                   color: _getFileColor(fileType),
                  ),
                  isSmallScreen,
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: _buildUploadButton(isSmallScreen),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

Widget _buildDocumentCard(DocumentItem doc, bool isSmallScreen) {
  // ✅ Detect website uploads
  final isWebsiteUploaded = doc.filePath.startsWith("/Documents/");

  return Container(
    margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        // File icon
        Container(
          width: isSmallScreen ? 45 : 50,
          height: isSmallScreen ? 45 : 50,
          decoration: BoxDecoration(
            color: doc.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(doc.icon, color: doc.color, size: isSmallScreen ? 24 : 28),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),

        // File name + type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    doc.type,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                 Text(
                                    _formatToReadableDate(doc.date),
                                      style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: Colors.grey[400],
                    ),
                 ),
                ],
              ),
            ],
          ),
        ),

        // Action icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.visibility_outlined,
                  size: isSmallScreen ? 20 : 22, color: Colors.grey[600]),
              onPressed: () => _viewDocument(context, doc),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: Icon(Icons.download_outlined,
                  size: isSmallScreen ? 20 : 22, color: Colors.grey[600]),
              onPressed: () => _downloadDocumentDirect(context, doc),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),

            // ✅ Only show delete button for owner-uploaded docs
            if (!isWebsiteUploaded)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: isSmallScreen ? 20 : 22, color: Colors.red[400]),
                onPressed: () => _deleteDocument(doc),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ],
    ),
  );
}


  // ---------- UPLOAD BUTTON ----------
  Widget _buildUploadButton(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadDocument()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 12 : 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: isSmallScreen ? 22 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  'Upload',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- EMPTY STATE ----------
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your first document',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
   String _formatToReadableDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('d MMM yyyy').format(parsedDate); // → 25 Oct 2025
    } catch (e) {
      return rawDate; // fallback if parsing fails
    }
  }

void showLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
}

void hideLoader(BuildContext context) {
  Navigator.pop(context);
}

// Return cached file path (if exists)
Future<String?> getCachedFile(String filename) async {
  final tempDir = await getTemporaryDirectory();
  final path = "${tempDir.path}/$filename";
  final file = File(path);

  if (await file.exists()) {
    return path; // Cached hit ✔
  }
  return null;
}
Future<void> _viewDocument(BuildContext context, DocumentItem doc) async {
  if (doc.filePath.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠️ Document path missing!')),
    );
    return;
  }

  String rawPath = doc.filePath.trim().replaceAll("\\", "/");

  final type = doc.type.toLowerCase();
  final isPdf = type == "pdf";
  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(type);

  // -----------------------------
  // Build final URL
  // -----------------------------
  late String fileUrl;

  if (rawPath.startsWith("http")) {
    fileUrl = rawPath;
  } else if (rawPath.contains("upload")) {
    fileUrl = rawPath.startsWith("/")
        ? "https://society.vengurlatech.com$rawPath"
        : "https://society.vengurlatech.com/$rawPath";
  } else if (rawPath.contains("/Documents")) {
    final encoded = Uri.encodeComponent(rawPath);
    fileUrl = "https://chshub.co.in/getFiles.ashx?path=$encoded";
  } else {
    fileUrl = "https://society.vengurlatech.com/$rawPath";
  }

  final fileName = fileUrl.split('/').last;

  // -----------------------------
  // CACHE CHECK
  // -----------------------------
  final cached = await getCachedFile(fileName);

  if (cached != null) {
    debugPrint("📦 Loaded from CACHE → $cached");
    return _openFile(context, cached, isPdf, isImage, fileUrl);
  }

  // -----------------------------
  // DOWNLOAD WITH LOADER
  // -----------------------------
  showLoader(context);

  try {
    final response = await http.get(Uri.parse(fileUrl),headers: {
    "Authorization": "Bearer ${ref.read(tokenProvider).accessToken}",
    "Accept": "*/*",
  },);

    final tempDir = await getTemporaryDirectory();
    final savedPath = "${tempDir.path}/$fileName";

    final file = File(savedPath);
    await file.writeAsBytes(response.bodyBytes, flush: true);

    hideLoader(context);

    _openFile(context, savedPath, isPdf, isImage, fileUrl);
  } catch (e) {
    hideLoader(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ErrorMessageMapper.map(e))),
    );
  }
}
void _openFile(BuildContext context, String path, bool isPdf, bool isImage, String url) {
  if (isPdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(
          filepath: path,
         
        ),
      ),
    );
  } else if (isImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGallery(
          images: [url],
          initialIndex: 0,
          
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Unsupported file type")),
    );
  }
}

Future<void> _downloadDocumentDirect(BuildContext context, DocumentItem doc) async {
  if (doc.filePath.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Document path missing!')),
    );
    return;
  }

  final fileUrl = doc.filePath.startsWith('http')
      ? doc.filePath
      : "https://yourserver.com/uploads/${doc.filePath}";
  final fileName = doc.name.isNotEmpty ? doc.name : "document_${DateTime.now().millisecondsSinceEpoch}.pdf";

  try {

    // ✅ Get public downloads folder
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory("/storage/emulated/0/Download");
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    final savePath = "${downloadsDir.path}/$fileName";

    debugPrint("⬇️ Downloading from: $fileUrl");
    debugPrint("📁 Saving to: $savePath");

    final response = await http.get(Uri.parse(fileUrl));

    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      debugPrint("✅ File saved successfully: $savePath");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Saved to Downloads: $fileName')),
      );
    } else {
      debugPrint("❌ Server error: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to download (Server Error)')),
      );
    }
  } catch (e) {
    debugPrint("❌ Download error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ErrorMessageMapper.map(e))),
    );
  }
}
  void _deleteDocument(DocumentItem doc) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Document'),
      content: Text('Are you sure you want to delete "${doc.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);

            // 🕓 Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 16),
                    Text('Deleting document...'),
                  ],
                ),
                duration: Duration(seconds: 2),
              ),
            );

            try {
              // ✅ Call your API
              await ref
                  .read(basicInfoViewModelProvider.notifier)
                  .deleteDocuments(doc.id??0);

              // ✅ Refresh the list
              // await ref
              //     .read(basicInfoViewModelProvider.notifier)
              //     .getBasicInfo(
              //       ref.watch(basicInfoViewModelProvider).societyID ?? "",
              //       ref.watch(basicInfoViewModelProvider).ownerId ?? 0,
              //     );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${doc.name} deleted successfully'),
                  backgroundColor: Colors.green[600],
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ErrorMessageMapper.map(e)),
                  backgroundColor: Colors.red[600],
                ),
              );
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}


  IconData _getFileIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.blue;
      case 'doc':
      case 'docx':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
class DocumentItem {
  final int? id;
  final String name;
  final String type;
  final String? size;
  final String date;
    final String filePath;
  final IconData icon;
  final Color color;

  DocumentItem({
    this.id,
    required this.name,
    required this.type,
     this.size,
    required this.filePath,
    required this.date,
    required this.icon,
    required this.color,
  });
}
