import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/domain/models/helpdesk.dart';

import '../../presentation/providers/viewmodel_provider.dart';

class RaiseComplaintScreen extends ConsumerStatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  _RaiseComplaintScreenState createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends ConsumerState<RaiseComplaintScreen> {
  @override
  void initState() {
    super.initState();
    // Load complaint types
    _loadData();
   
  }
  Future<void> _loadData() async {
  Future.microtask(() {
      ref.read(HelpdeskViewModelProvider.notifier).getAllComplainTypes();
    });
}

  int? selectedComplaintType;
  List<bool> isSelected = [true, false];
  final TextEditingController complaintController = TextEditingController();
  List<File> selectedImages = [];
  bool isUrgent = false;

  Future<void> _showPhotoOptionsDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Attach Photo"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final permissionGranted = await _requestPermission(source);
    if (!permissionGranted) return;

    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage();
      setState(() {
        selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    } else {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          selectedImages.add(File(pickedFile.path));
        });
      }
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    if (await permission.isGranted) return true;

    final result = await permission.request();
    return result.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    final complainTypesAsync = ref
        .watch(HelpdeskViewModelProvider)
        .allComplainTypes;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Raise Complaint', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: complainTypesAsync.when(
          data: (complainTypes) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<int>(
                    value: selectedComplaintType,
                    hint: const Text('Select Complaint type'),
                    isExpanded: true,
                    items: complainTypes.map((type) {
                      return DropdownMenuItem<int>(
                        value: type.pTypeId,
                        child: Text(type.pTypeName ?? 'Unknown Type'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedComplaintType = newValue;
                      });
                    },
                  ),

                  SizedBox(height: 16),

                  ToggleButtons(
                    borderRadius: BorderRadius.circular(8),
                    isSelected: isSelected,
                    onPressed: (int index) {
                      setState(() {
                        for (int i = 0; i < isSelected.length; i++) {
                          isSelected[i] = i == index;
                        }
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.lock, size: 18),
                            SizedBox(width: 6),
                            Text('Personal'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 18),
                            SizedBox(width: 6),
                            Text('Community'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  TextField(
                    controller: complaintController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Brief Your Complaint...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),

                  CheckboxListTile(
                    title: Text(
                      'Mark as Urgent',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: isUrgent,
                    onChanged: (value) {
                      setState(() {
                        isUrgent = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 12),

                  Text(
                    'Attach Photos (Optional)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...selectedImages.map(
                        (img) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                img,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () {
                                  setState(() => selectedImages.remove(img));
                                },
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _showPhotoOptionsDialog,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Submit Complaint',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
         error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (selectedComplaintType == null ||
        complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a complaint type and enter details.'),
        ),
      );
      return;
    }

    String categoryType = isSelected[0] ? 'personal' : 'community';

    final HelpdeskRequest newRequest = HelpdeskRequest(
      flatId: ref.watch(basicInfoViewModelProvider).flatId,
      category: selectedComplaintType ?? 0,
      query: complaintController.text.trim(),
      urgency: isUrgent ? 1 : 0,
      categoryType: categoryType,
      helpdeskId: null,
      date: '',
      status: 1,
    );
    // await ref
    //     .read(HelpdeskViewModelProvider.notifier)
    //     .insertHelpdesk(newRequest);
    final state = ref.read(HelpdeskViewModelProvider);

    if (state.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error")));
    } else if (state.data != null) {
      final helpdeskID = state.data?["helpdesk_id"];

      if (selectedImages.isNotEmpty) {
        for (var image in selectedImages) {
          // ScaffoldMessenger.of(
          //   context,
          // ).showSnackBar(SnackBar(content: Text("Helpdesk ID: $helpdeskID")));
          await ref
              .read(HelpdeskViewModelProvider.notifier)
              .addHelpdeskImages(File(image.path), helpdeskID);
        }
      }
      setState(() {
        selectedComplaintType = null;
        complaintController.clear();
        isUrgent = false;
        selectedImages.clear();
        isSelected = [true, false];
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Ticket created successfully! ID: $helpdeskID")),
      // );
    }
  }

  @override
  void dispose() {
    complaintController.dispose();
    super.dispose();
  }
}
