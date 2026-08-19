import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:society_app/core/network/error_message_mapper.dart';

import '../../presentation/providers/viewmodel_provider.dart';

class UploadDocument extends ConsumerStatefulWidget {
  const UploadDocument({super.key});
  @override
  ConsumerState<UploadDocument> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends ConsumerState<UploadDocument> {
  List<File> selectedFiles = [];
  List<String> selectedFileNames = [];
  bool isUploading = false; // ✅ Already present, now properly used
  final TextEditingController _docNameController = TextEditingController();

  @override
  void dispose() {
    _docNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDocuments() async {
    // ✅ Prevent file picking during upload
    if (isUploading) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFiles = result.paths.map((p) => File(p!)).toList();
          selectedFileNames =
              result.files.map((file) => path.basename(file.path!)).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedFiles.length} file(s) selected')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select files. Please try again.')),
      );
    }
  }

  // ✅ FIXED: Upload with multiple submission prevention
  Future<void> _uploadDocument() async {
    if (selectedFiles.isEmpty) return;

    // ✅ Check if already uploading
    if (isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload already in progress')),
      );
      return;
    }

    final profileVM = ref.read(basicInfoViewModelProvider.notifier);
    final docName = _docNameController.text.trim();

    // ✅ Set uploading state - BLOCKS all actions
    setState(() {
      isUploading = true;
    });

    try {
      for (int i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        final fileName = docName.isNotEmpty ? docName : selectedFileNames[i];
        await profileVM.addOwnerDocuments(
          file,
          ref.read(basicInfoViewModelProvider).flatId ?? 0,
          fileName,
        );
      }

      if (!mounted) return;

      // ✅ Refresh the document list before going back
      await ref.read(basicInfoViewModelProvider.notifier).ownerDocumentsList(
        ref.read(basicInfoViewModelProvider).flatId ?? 0
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All documents uploaded successfully')),
      );

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // ✅ Return true to trigger refresh in DocumentListPage
      debugPrint("✅ Upload successful, returning true");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessageMapper.map(e))),
      );
    } finally {
      // ✅ ALWAYS reset uploading state
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Upload Documents',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[800]),
          // ✅ Disable back button during upload
          onPressed: isUploading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // ✅ Make entire body scrollable
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Document Name Field
              TextField(
                controller: _docNameController,
                enabled: !isUploading, // ✅ Disable during upload
                decoration: InputDecoration(
                  labelText: 'Document Name',
                  hintText: 'Enter document name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Upload Area
              GestureDetector(
                // ✅ Disable tap during upload
                onTap: isUploading ? null : _pickDocuments,
                child: Opacity(
                  opacity: isUploading ? 0.5 : 1.0, // ✅ Visual feedback
                  child: Container(
                    height: isSmallScreen ? 180 : 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: isSmallScreen ? 50 : 60,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedFiles.isEmpty
                              ? 'Tap to select documents'
                              : '${selectedFiles.length} document(s) selected',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PDF, JPG, PNG, DOC (Max 10MB each)',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // File preview list - ✅ Fixed to not use Expanded
              if (selectedFiles.isNotEmpty)
                ...selectedFileNames.asMap().entries.map((entry) {
                  final index = entry.key;
                  final fileName = entry.value;
                  final file = selectedFiles[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: _buildFileIcon(fileName, file),
                      title: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isUploading
                          ? null // ✅ Hide remove button during upload
                          : IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  selectedFiles.removeAt(index);
                                  selectedFileNames.removeAt(index);
                                });
                              },
                            ),
                    ),
                  );
                }).toList(),
              
              if (selectedFiles.isEmpty)
                const SizedBox(height: 20),

              // Upload Button - ✅ COMPLETE OVERFLOW FIX
              SizedBox(
                width: double.infinity, // ✅ Take full width
                child: ElevatedButton(
                  onPressed:
                      selectedFiles.isNotEmpty && !isUploading ? _uploadDocument : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    disabledBackgroundColor: Colors.grey[300],
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 14 : 16,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Uploading...',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown, // ✅ Scale down if needed
                          child: Text(
                            'Upload All Documents',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20), // ✅ Extra bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(String fileName, File file) {
    if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          file,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    } else if (fileName.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40);
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return const Icon(Icons.description, color: Colors.blue, size: 40);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 40);
    }
  }
}