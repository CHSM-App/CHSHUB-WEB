import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/broadcast.dart';
import 'package:society_app/domain/models/helpdesk.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class HelpdeskPage extends ConsumerStatefulWidget {
  const HelpdeskPage({super.key});

  @override
  _HelpdeskPageState createState() => _HelpdeskPageState();
}

class _HelpdeskPageState extends ConsumerState<HelpdeskPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedComplaintType;
  bool _isPersonal = true;
  bool _isUrgent = false;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  
  // ✅ Local loading state to prevent multiple submissions
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(HelpdeskViewModelProvider.notifier).getComplaintType();
      
      // Check if basic info is loaded
      final basicInfo = ref.read(basicInfoViewModelProvider);
      debugPrint('📋 Basic Info Check:');
      debugPrint('   flatId: ${basicInfo.flatId}');
      debugPrint('   ownerId: ${basicInfo.ownerId}');
      debugPrint('   societyID: ${basicInfo.societyID}');
      debugPrint('   unit: ${basicInfo.unit}');
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final granted = await _requestPermission(source);
    if (!granted) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() => _images.add(picked));
      }
    } catch (e) {
      _showSnackBar("Failed to pick image", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _requestPermission(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    if (await permission.isGranted) return true;

    final result = await permission.request();
    return result.isGranted;
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildImageSourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              _buildImageSourceOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a Photo',
                subtitle: 'Use camera to capture',
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A5FBF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF4A5FBF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComplaint() async {
    // ✅ CRITICAL: Prevent multiple submissions
    if (_isSubmitting) {
      debugPrint('⚠️ Submission already in progress, ignoring click');
      return;
    }

    // ✅ Validate form fields
    if (_selectedComplaintType == null ||
        _descriptionController.text.trim().isEmpty) {
      _showSnackBar('Please select complaint type and enter details.', isError: true);
      return;
    }

    // ✅ Get and validate user data
    final basicInfo = ref.read(basicInfoViewModelProvider);
    
    if (basicInfo.flatId == null || basicInfo.ownerId == null) {
      _showSnackBar('User information not loaded. Please try again.', isError: true);
      debugPrint('❌ Missing data - flatId: ${basicInfo.flatId}, ownerId: ${basicInfo.ownerId}');
      return;
    }

    if (basicInfo.societyID == null || basicInfo.societyID!.isEmpty) {
      _showSnackBar('Society information not loaded. Please try again.', isError: true);
      debugPrint('❌ Missing societyID: ${basicInfo.societyID}');
      return;
    }

    // ✅ SET LOADING STATE - This prevents double submission
    setState(() {
      _isSubmitting = true;
    });

    int? helpdeskID;

    try {
      final categoryType = _isPersonal ? 'personal' : 'community';

      debugPrint('📝 Creating helpdesk request with:');
      debugPrint('   flatId: ${basicInfo.flatId}');
      debugPrint('   ownerId: ${basicInfo.ownerId}');
      debugPrint('   societyID: ${basicInfo.societyID}');
      debugPrint('   category: $_selectedComplaintType');
      debugPrint('   categoryType: $categoryType');

      final newRequest = HelpdeskRequest(
        flatId: basicInfo.flatId!,
        category: int.parse(_selectedComplaintType!),
        query: _descriptionController.text.trim(),
        urgency: _isUrgent ? 1 : 0,
        categoryType: categoryType,
        helpdeskId: null,
        date: '',
        status: 1,
        ownerId: basicInfo.ownerId!,
        loginType: basicInfo.loginType!,
      );

      /// Step 1: Insert new helpdesk entry
      debugPrint('📤 Submitting helpdesk request...');
      await ref.read(HelpdeskViewModelProvider.notifier).insertHelpdesk(newRequest);
      
      // Wait for state to update
      await Future.delayed(const Duration(milliseconds: 200));
      
      final state = ref.read(HelpdeskViewModelProvider);

      debugPrint('📥 Response received:');
      debugPrint('   error: ${state.error}');
      debugPrint('   data: ${state.data}');
      debugPrint('   data type: ${state.data.runtimeType}');

      if (state.error != null) {
        if (mounted) {
          _showSnackBar("Error: ${state.error}", isError: true);
        }
        return;
      }

      // ✅ IMPROVED: Handle different response formats
      if (state.data == null) {
        if (mounted) {
          _showSnackBar("No response from server.", isError: true);
        }
        debugPrint('❌ state.data is null');
        return;
      }

      // Try different ways to get helpdesk_id
      dynamic responseData = state.data;
      
      if (responseData is Map<String, dynamic>) {
        // Try different possible key names
        helpdeskID = responseData['helpdesk_id'] as int? ??
                     responseData['helpdeskId'] as int? ??
                     responseData['id'] as int? ??
                     responseData['data']?['helpdesk_id'] as int? ??
                     responseData['data']?['helpdeskId'] as int? ??
                     responseData['data']?['id'] as int?;
      } else if (responseData is int) {
        helpdeskID = responseData;
      }

      if (helpdeskID == null) {
        if (mounted) {
          _showSnackBar("Invalid server response format.", isError: true);
        }
        debugPrint('❌ Could not extract helpdesk_id from response: $responseData');
        return;
      }

      debugPrint('✅ Helpdesk created with ID: $helpdeskID');

      /// Step 2: Upload images (if any)
      if (_images.isNotEmpty) {
        debugPrint('📸 Uploading ${_images.length} images...');
        bool allUploaded = true;

        for (var image in _images) {
          try {
            await ref
                .read(HelpdeskViewModelProvider.notifier)
                .addHelpdeskImages(File(image.path), helpdeskID.toString());
            debugPrint('✅ Uploaded: ${image.path}');
          } catch (e) {
            allUploaded = false;
            debugPrint("❌ Failed to upload image: ${image.path}, error: $e");
          }
        }

        if (!allUploaded && mounted) {
          _showSnackBar("Some images failed to upload.", isError: true);
        }
      }

      /// Step 3: Send push notifications
      debugPrint('📬 Loading tokens for notifications...');
      try {
        await ref
            .read(directoryViewModelProvider.notifier)
            .loadAllTokens(basicInfo.societyID!);

        final tokenState = ref.read(directoryViewModelProvider);

        await tokenState.allTokens.when(
          data: (tokens) async {
            if (tokens.isEmpty) {
              debugPrint('⚠️ No tokens found for notifications');
              return;
            }

            final tokenList = tokens
                .map((e) => e.webToken ?? '')
                .where((t) => t.isNotEmpty)
                .toList();
            debugPrint('✅ Found ${tokenList.length} tokens for notifications');

            // Insert notification for each user
            for (var token in tokens) {
              final broadcast = Broadcast(
                societyId: basicInfo.societyID!,
                title: "New Helpdesk Ticket",
                body: "A new helpdesk ticket has been created from Unit: ${basicInfo.unit ?? 'Unknown'}",
                userType: "Member",
                userId: token.userId,
                notificationType: "Helpdesk",
                seenStatus: 0,
                notificationId: helpdeskID!,
                ownerId: basicInfo.ownerId!,
              );

              try {
                await ref
                    .read(broadcastViewModelProvider.notifier)
                    .insertNotification(broadcast);
              } catch (e) {
                debugPrint('❌ Failed to insert notification for user ${token.userId}: $e');
              }
            }

            if (tokenList.isNotEmpty) {
              // Send Firebase/Web push
              final notification = SendNotification(
                tokens: tokenList,
                title: "New Helpdesk Ticket",
                body: "A new helpdesk ticket has been created from Unit: ${basicInfo.unit ?? 'Unknown'}",
              );

              try {
                await ref
                    .read(alertViewModelProvider.notifier)
                    .sendNotification(notification);
                debugPrint('✅ Push notifications sent successfully');
              } catch (e) {
                debugPrint('❌ Failed to send push notifications: $e');
              }
            }
          },
          loading: () {
            debugPrint('⏳ Loading tokens...');
            return Future.value();
          },
          error: (err, _) {
            debugPrint('❌ Error loading tokens: $err');
            return Future.value();
          },
        );
      } catch (e) {
        debugPrint('❌ Error in notification process: $e');
      }

      if (mounted) {
        _showSnackBar("✅ Ticket created successfully! ID: $helpdeskID");

        // Reset form
        setState(() {
          _selectedComplaintType = null;
          _descriptionController.clear();
          _isUrgent = false;
          _images.clear();
          _isPersonal = true;
        });
      }
    } catch (e, stack) {
      debugPrint("❌ Exception in _submitComplaint: $e");
      debugPrint("Stack trace: $stack");
      if (mounted) {
        _showSnackBar(ErrorMessageMapper.map(e), isError: true);
      }
    } finally {
      // ✅ CRITICAL: ALWAYS reset loading state, even on error
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      debugPrint('🔄 Loading state reset: $_isSubmitting');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(HelpdeskViewModelProvider);
    final basicInfo = ref.watch(basicInfoViewModelProvider);
    
    // Check if required data is available
    final bool hasRequiredData = basicInfo.flatId != null && 
                                 basicInfo.ownerId != null && 
                                 basicInfo.societyID != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () {
        
      Navigator.pop(context, true); // ✅ tell previous screen to refresh
    },
  ),
  title: const Text(
    'Helpdesk',
    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
),

      body: !hasRequiredData
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Loading user information...'),
                  const SizedBox(height: 10),
                  Text(
                    'flatId: ${basicInfo.flatId}, ownerId: ${basicInfo.ownerId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 162, 202, 231),
                            Color.fromARGB(255, 190, 198, 225),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3b82f6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.support_agent,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Submit Complaint',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'re here to help. Please provide details about your issue.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Category Toggle Buttons
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPersonal = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: _isPersonal
                                      ? const Color(0xFF3b82f6)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isPersonal
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF3b82f6).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: _isPersonal
                                          ? Colors.white
                                          : const Color(0xFF64748b),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Personal',
                                      style: TextStyle(
                                        color: _isPersonal
                                            ? Colors.white
                                            : const Color(0xFF64748b),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPersonal = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: !_isPersonal
                                      ? const Color(0xFF3b82f6)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_isPersonal
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF3b82f6).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.groups,
                                      color: !_isPersonal
                                          ? Colors.white
                                          : const Color(0xFF64748b),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Community',
                                      style: TextStyle(
                                        color: !_isPersonal
                                            ? Colors.white
                                            : const Color(0xFF64748b),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Complaint Type Dropdown
                    const Text(
                      'Complaint Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 10),

                    state.allComplainTypes.when(
                      data: (types) {
                        final selectedType = _selectedComplaintType != null
                            ? types.firstWhere(
                                (type) => type.cTypeId.toString() == _selectedComplaintType,
                                orElse: () => types.first,
                              )
                            : null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
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
                              child: DropdownButtonFormField<String>(
                                value: _selectedComplaintType,
                                decoration: InputDecoration(
                                  hintText: 'Select complaint type',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  prefixIcon: const Icon(
                                    Icons.category,
                                    color: Color(0xFF3b82f6),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: types.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type.cTypeId.toString(),
                                    child: Text(type.cTypeName ?? 'Unknown Type'),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedComplaintType = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a complaint type';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            if (_selectedComplaintType != null && selectedType != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3b82f6).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF3b82f6).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF3b82f6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${selectedType.cTypeName}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1e293b),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            selectedType.decription ??
                                                'Please provide detailed information about this complaint type in the description below.',
                                            style: const TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Please select a complaint type to see more details',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Text("Failed to load complaint types"),
                    ),

                    const SizedBox(height: 25),

                    // Description Field
                    const Text(
                      'Brief Complaint Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
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
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe your complaint in detail...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.description, color: Color(0xFF3b82f6)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide a description';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mark as Urgent Checkbox
                    Container(
                      padding: const EdgeInsets.all(15),
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
                          Checkbox(
                            value: _isUrgent,
                            onChanged: (bool? value) {
                              setState(() {
                                _isUrgent = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFef4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Icon(
                            Icons.priority_high,
                            color: _isUrgent ? const Color(0xFFef4444) : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Mark as Urgent',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Attach Photo Section
                    const Text(
                      'Attach Photo (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_images.isNotEmpty)
                      ..._images.map(
                        (image) => Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(10),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(image.path),
                                  fit: BoxFit.cover,
                                  width: 140,
                                  height: 140,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Photo attached',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1e293b),
                                      ),
                                    ),
                                    Text(
                                      'Tap + below to add more',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _images.remove(image);
                                  });
                                },
                                icon: const Icon(Icons.close, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),

                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF3b82f6).withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.add_a_photo,
                              color: Color(0xFF3b82f6),
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _images.isEmpty
                                  ? 'Tap to attach photo'
                                  : 'Tap to add more photos',
                              style: const TextStyle(
                                color: Color(0xFF3b82f6),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Camera or Gallery',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF1e40af)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3b82f6).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitComplaint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Submitting...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.send, color: Colors.white, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'Submit Complaint',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}