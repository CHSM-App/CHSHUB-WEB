import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:society_app/SocietyApp/screens/edit_profile.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/settings_screen.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/basicinfo.dart';
import 'package:society_app/domain/models/helper.dart';
import 'package:society_app/domain/models/vehicle.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
_loadData();
    // Load data when screen initializes
   
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(basicInfoViewModelProvider.notifier).getBasicInfo();
      _loadFamilyMembers();
      _loadVehicles();
      _loadHelpers();
      // _loadFrequentEntries();
      ref.read(profileSettingsViewModelProvider.notifier).getPersonList();
    });
  }

  void _loadFamilyMembers() async {
    final ownerDetails = ref.watch(basicInfoViewModelProvider);
    try {
      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .getFamilyMembers(
            ownerDetails.flatId ?? 0,
            ownerDetails.ownerId ?? 0,
            ownerDetails.loginType ?? '',
          );
    } catch (e) {
      print('Error loading family members: $e');
    }
  }

  void _loadVehicles() async {
    final ownerDetails = ref.watch(basicInfoViewModelProvider);
    try {
      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .getVehicleList(
            ownerDetails.flatId ?? 0,
            ownerDetails.societyID ?? '',
          );
    } catch (e) {
      print('Error loading vehicles: $e');
    }
  }

  void _loadHelpers() async {
    final ownerDetails = ref.watch(basicInfoViewModelProvider);
    try {
      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .getFamilyMemberHelper(
            ownerDetails.flatId ?? 0
          );
    } catch (e) {
      print('Error loading helpers: $e');
    }
  }

  void _loadFrequentEntries() async {
    final ownerDetails = ref.watch(basicInfoViewModelProvider);
    try {
      // await ref
      //     .read(ProfileSettingsViewModelProvider.notifier)
      //     .getFrequentEntries(
      //       ownerDetails.flatId ?? 0,
      //       ownerDetails.ownerId ?? 0,
      //       ownerDetails.societyID ?? '',
      //     );
    } catch (e) {
      print('Error loading frequent entries: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showQRCode(String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QRCodeDialog(data: data);
      },
    );
  }

  void _showAddDialog(String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AddDialog(type: type, onAdd: (data) => _handleAdd(type, data));
      },
    );
  }

  void _handleAdd(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'family':
        _addFamilyMember(data);
        break;
      case 'vehicles':
        _addVehicle(data);
        break;
      case 'helpers':
        _addHelper(data);
        break;
      case 'entries':
        _addFrequentEntry(data);
        break;
    }
  }

  void _addFamilyMember(Map<String, dynamic> data) async {
    try {
      final ownerDetails = ref.watch(basicInfoViewModelProvider);

      final int oId = ownerDetails.ownerId ?? 0;
      final String fName = data['name'] ?? '';
      final String contact = data['phone'] ?? '';
      final String relation = data['relation'] ?? '';
      final String societyID = ownerDetails.societyID ?? '';

      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .addFamilyMember(oId, fName, contact, relation, societyID);

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['message'] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Member added successfully')));
      }
      _loadFamilyMembers();
    } catch (e) {
      debugPrint('Error while adding family member: $e');
    }
  }

  void _addVehicle(Map<String, dynamic> data) async {
    try {
      final vehicleData = Vehicle(
        vehicleNo: data['number'] ?? '',
        modelName: data['model'] ?? '',
        vehicleType: data['type'] ?? '',
        ownerId: ref.watch(basicInfoViewModelProvider).ownerId,
        flatId: ref.watch(basicInfoViewModelProvider).flatId,
        societyId: ref.watch(basicInfoViewModelProvider).societyID,
      );

      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .addFamilyVehicle(vehicleData);

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Vehicle added successfully')));
      }
      _loadVehicles();
    } catch (e) {
      debugPrint('Error while adding vehicle: $e');
    }
  }

  void _addHelper(Map<String, dynamic> data) async {
    try {
      final ownerDetails = ref.watch(basicInfoViewModelProvider);

      final helperData = Helper(
        contactNo: data['phone'] ?? '',
        pName: data['name'] ?? '',
        pTypeId: data['serviceId'] ?? '',
        ownerId: ref.watch(basicInfoViewModelProvider).ownerId,
        flatId: ref.watch(basicInfoViewModelProvider).flatId,
        societyId: ref.watch(basicInfoViewModelProvider).societyID,
      );

      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .addFamilyHelper(helperData);

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Helper added successfully')));
      }
      _loadHelpers();
    } catch (e) {
      debugPrint('Error while adding helper: $e');
    }
  }

  void _addFrequentEntry(Map<String, dynamic> data) async {
    try {
      final ownerDetails = ref.watch(basicInfoViewModelProvider);

      // await ref
      //     .read(ProfileSettingsViewModelProvider.notifier)
      //     .addFrequentEntry(
      //       ownerDetails.ownerId ?? 0,
      //       ownerDetails.flatId ?? 0,
      //       ownerDetails.societyID ?? '',
      //       data['name'] ?? '',
      //       data['type'] ?? '',
      //       data['phone'] ?? '',
      //     );

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Entry added successfully')));
      }
      _loadFrequentEntries();
    } catch (e) {
      debugPrint('Error while adding frequent entry: $e');
    }
  }

  void _handleDelete(String type, int id) {
    switch (type) {
      case 'family':
        _deleteFamilyMember(id);
        break;
      case 'vehicles':
        _deleteVehicle(id);
        break;
      case 'helpers':
        _deleteHelper(id);
        break;
      case 'entries':
        _deleteFrequentEntry(id);
        break;
    }
  }

  void _deleteFamilyMember(int id) async {
    try {
      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .deleteFamilyMember(id);

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['sucess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Family member removed successfully')),
        );
      }
      _loadFamilyMembers();
    } catch (e) {
      debugPrint('Error while deleting family member: $e');
    }
  }

  void _deleteVehicle(int id) async {
    try {
      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .deleteFamilyVehicle(id);

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Vehicle removed successfully')));
      }
      _loadVehicles();
    } catch (e) {
      debugPrint('Error while deleting vehicle: $e');
    }
  }

  void _deleteHelper(int id) async {
    try {
      await ref
          .read(profileSettingsViewModelProvider.notifier)
          .deleteFamilyHelper(id);

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Helper removed successfully')));
      }
      _loadHelpers();
    } catch (e) {
      debugPrint('Error while deleting helper: $e');
    }
  }

  void _deleteFrequentEntry(int id) async {
    try {
      // await ref
      //     .read(ProfileSettingsViewModelProvider.notifier)
      //     .deleteFrequentEntry(id);

      final state = ref.watch(profileSettingsViewModelProvider);
      if (state.data != null && state.data!['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Entry removed successfully')));
      }
      _loadFrequentEntries();
    } catch (e) {
      debugPrint('Error while deleting frequent entry: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(basicInfoViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey[600]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: 
      AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: profileState.basicInfoResult.when(
                data: (basicInfo) => basicInfo.isEmpty
                    ?ErrorStatePage(message: "No Profile data found",onRetry: _loadData,)
                    : _buildProfileContent(basicInfo),
                loading: () => _buildLoadingState(),
                  error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
                
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildProfileContent(dynamic basicInfoData) {
    final BasicInfo basicInfo = basicInfoData is List
        ? (basicInfoData.isNotEmpty ? basicInfoData.first : null)
        : basicInfoData;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(basicInfo),
          SizedBox(height: 24),
          _buildFamilySection(),
          SizedBox(height: 24),
          _buildVehiclesSection(),
          SizedBox(height: 24),
          _buildHelpersSection(),
          SizedBox(height: 24),
         // _buildFrequentEntriesSection(),
         // SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }



  

// Widget _buildErrorState(Object error) {
//   return Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(Icons.error_outline, color: Colors.red, size: 48),
//         SizedBox(height: 16),
//         Text(
//           'Failed to load profile',
//           style: TextStyle(
//             color: Colors.grey[800],
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         SizedBox(height: 8),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 32),
//           child: Text(
//             error.toString(),
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey[600], fontSize: 14),
//           ),
//         ),
//         SizedBox(height: 16),
//         ElevatedButton(
//           onPressed: () {
//             // Reload all data
//             ref.read(basicInfoViewModelProvider.notifier).getBasicInfo();
//             _loadFamilyMembers();
//             _loadVehicles();
//             _loadHelpers();
//             // Remove _loadFrequentEntries() call since it's not implemented
//             ref.read(profileSettingsViewModelProvider.notifier).getPersonList();
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue[600],
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: Text('Retry'),
//         ),
//       ],
//     ),
//   );
// }


  Widget _buildProfileCard(BasicInfo basicInfo) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // 🔹 Top Row (Profile Image + Info)
        Row(
          children: [
            // 🔸 Profile Image Tap -> Preview
            GestureDetector(
              onTap: () => _showImagePreview(basicInfo.profileImage),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[500]!, Colors.purple[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: _buildProfileAvatar(basicInfo),
              ),
            ),
            const SizedBox(width: 16),
Expanded(
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfilePage()),
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
       // color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 239, 240, 242).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            basicInfo.name ?? 'Unknown User',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            basicInfo.login ?? 'Resident',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  ),
),


            // QR icon unchanged
            IconButton(
              icon: const Icon(Icons.qr_code, size: 20),
              onPressed: () => _showQRCode(_generateQRData(basicInfo)),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 🔹 Info Row (unchanged)
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                '${basicInfo.societyName}\n${basicInfo.buildName ?? ""}',
                Icons.home,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Flat no:\n${basicInfo.flatNo ?? "N/A"}',
                Icons.location_on,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Unit:\n${basicInfo.unit ?? "N/A"}',
                Icons.home_work,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  void _showImagePreview(String? imageUrl) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: imageUrl != null
                ? NetworkImage(imageUrl)
                : const AssetImage('assets/images/default_user.png')
                    as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    ),
  );
}

String getInitial(String? name) {
  if (name == null || name.trim().isEmpty) return 'U';

  // Common prefixes
  final prefixes = [
    'mr ', 'mr.', 
    'mrs ', 'mrs.', 
    'miss ', 
    'ms ', 'ms.',
    'dr ', 'dr.'
  ];

  String cleaned = name.toLowerCase().trim();

  for (var p in prefixes) {
    if (cleaned.startsWith(p)) {
      cleaned = cleaned.replaceFirst(p, '').trim();
      break;
    }
  }

  return cleaned.substring(0, 1).toUpperCase();
}

Widget _buildProfileAvatar(BasicInfo user) {
 
  final hasDbImage = user.profileImage != null && user.profileImage!.isNotEmpty;
  if (hasDbImage) {
    return ClipOval(
      child: Image.network(
        user.profileImage!,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // return CircleAvatar(
          //   radius: 48,
          //   backgroundColor: Colors.blue[400],
          //   child: Text(
          //     user.name?.isNotEmpty == true
          //         ? user.name!.substring(0, 1).toUpperCase()
          //         : 'U',
          //     style: const TextStyle(
          //       color: Colors.white,
          //       fontSize: 36,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // );
          return CircleAvatar(
  radius: 48,
  backgroundColor: Colors.blue[400],
  child: Text(
    getInitial(user.name),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 36,
      fontWeight: FontWeight.bold,
    ),
  ),
);

        },
      ),
    );
  }
 
  // fallback → no picked image and no DB image
  // return CircleAvatar(
  //   radius: 48,
  //   backgroundColor: Colors.blue[400],
  //   child: Text(
  //     user.name?.isNotEmpty == true
  //         ? user.name!.substring(0, 1).toUpperCase()
  //         : 'U',
  //     style: const TextStyle(
  //       color: Colors.white,
  //       fontSize: 36,
  //       fontWeight: FontWeight.bold,
  //     ),
  //   ),
  // );
  return CircleAvatar(
  radius: 48,
  backgroundColor: Colors.blue[400],
  child: Text(
    getInitial(user.name),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 36,
      fontWeight: FontWeight.bold,
    ),
  ),
);

}
  Widget _buildInfoCard(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    VoidCallback onAdd,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
        if (ref.watch(basicInfoViewModelProvider).loginType?.toLowerCase() ==
            'owner')
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add, size: 16),
            label: Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
      ],
    );
  }

//   // Dynamic card widget for all sections
//   Widget _buildDynamicCard({
//     required String title,
//     required String subtitle,
//     String? thirdLine,
//    required IconData icon,
//     Color iconColor = Colors.blue,
//     required String qrData,
//     required int id,
//     required String sectionType,
//     String?profileImage,
// int?parking,
// String? parkingStatus,
//     double width = 140,
//   }) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         double cardWidth = MediaQuery.of(context).size.width * 0.35;
//         cardWidth = cardWidth.clamp(width, width + 40);
//  //print('🅿️ park_place_id for $title → $parking');
//         return Container(
//           width: cardWidth,
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//            child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // ✅ Profile Image or Icon
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(21),
//                   child: profileImage != null && profileImage.isNotEmpty
//                       ? Image.network(
//                           profileImage,
//                           width: 42,
//                           height: 42,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return CircleAvatar(
//                               radius: 21,
//                               backgroundColor: iconColor.withOpacity(0.1),
//                               child: Icon(icon, size: 22, color: iconColor),
//                             );
//                           },
//                         )
//                       : CircleAvatar(
//                           radius: 21,
//                           backgroundColor: iconColor.withOpacity(0.1),
//                           child: Icon(icon, size: 22, color: iconColor),
//                         ),
//                 ),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       GestureDetector(
//                         onTap: () => _showQRCode(qrData),
//                         child: Container(
//                           padding: EdgeInsets.all(4),
//                           child: Icon(
//                             Icons.qr_code,
//                             size: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ),
//                       if (ref
//                               .read(basicInfoViewModelProvider)
//                               .loginType
//                               ?.toLowerCase() ==
//                           'owner')
//                         GestureDetector(
//                           onTap: () => _handleDelete(sectionType, id),
//                           child: Container(
//                             padding: EdgeInsets.all(4),
//                             child: Icon(
//                               Icons.delete,
//                               size: 14,
//                               color: Colors.red,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//               SizedBox(height: 8),
//               Flexible(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[800],
//                     fontSize: 13,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               SizedBox(height: 2),
//               Flexible(
//                 child: Text(
//                   subtitle,
//                   style: TextStyle(color: Colors.grey[500], fontSize: 11),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               if (thirdLine != null) ...[
//                 SizedBox(height: 2),
//                 Flexible(
//                   child: Text(
//                     thirdLine,
//                     style: TextStyle(color: Colors.grey[400], fontSize: 10),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
            
//              if (parkingStatus != null && parkingStatus.isNotEmpty) ...[
//   const SizedBox(height: 4),
//   Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//     decoration: BoxDecoration(
//       color: Colors.red, // red background
//       borderRadius: BorderRadius.circular(8),
//     ),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(Icons.local_parking, size: 12, color: Colors.white), // white icon
//         const SizedBox(width: 4),
//         Text(
//           parkingStatus,
//           style: const TextStyle(
//             color: Colors.white, // white text
//             fontSize: 10,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     ),
//   ),
// ],
//           ],

//           ),
//         );
//       },
//     );
//   }
// Dynamic card widget with responsive bottom overlay design
Widget _buildDynamicCard({
  required String title,
  required String subtitle,
  String? thirdLine,
  required IconData icon,
  Color iconColor = Colors.blue,
  required String qrData,
   int? id,
  required String sectionType,
  String? profileImage,
  String? parkingStatus,
  double width = 140,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Responsive sizing based on screen width
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

      // Dynamic card width
      double cardWidth = isSmallScreen
          ? screenWidth * 0.42
          : isMediumScreen
              ? screenWidth * 0.38
              : screenWidth * 0.30;
      cardWidth = cardWidth.clamp(130.0, 200.0);

      // Dynamic sizing
      final cardPadding = isSmallScreen ? 8.0 : 10.0;
      final iconSize = isSmallScreen ? 18.0 : 22.0;
      final avatarRadius = isSmallScreen ? 18.0 : 21.0;
      final titleFontSize = isSmallScreen ? 12.0 : 13.0;
      final subtitleFontSize = isSmallScreen ? 10.0 : 11.0;
      final thirdLineFontSize = isSmallScreen ? 9.0 : 10.0;
      final actionIconSize = isSmallScreen ? 12.0 : 14.0;

      return Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main Card Content
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row with Profile and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image or Icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(avatarRadius),
                        child: profileImage != null && profileImage.isNotEmpty
                            ? Image.network(
                                profileImage,
                                width: avatarRadius * 2,
                                height: avatarRadius * 2,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: iconColor.withOpacity(0.1),
                                    child: Icon(icon, size: iconSize, color: iconColor),
                                  );
                                },
                              )
                            : CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: iconColor.withOpacity(0.1),
                                child: Icon(icon, size: iconSize, color: iconColor),
                              ),
                      ),
                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _showQRCode(qrData),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.qr_code,
                                size: actionIconSize,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          if (ref
                                  .read(basicInfoViewModelProvider)
                                  .loginType
                                  ?.toLowerCase() ==
                              'owner')
                            GestureDetector(
                              onTap: () => _handleDelete(sectionType, id??0),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete,
                                  size: actionIconSize,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: subtitleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Third Line (Optional)
                  if (thirdLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      thirdLine,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: thirdLineFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Extra spacing for overlay if parking status exists
                  if (parkingStatus != null && parkingStatus.isNotEmpty)
                    SizedBox(height: isSmallScreen ? 20 : 24),
                ],
              ),
            ),
            
            // Bottom Overlay - Parking Status Badge
            if (parkingStatus != null && parkingStatus.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 128, 247, 113),
                             const Color.fromARGB(255, 147, 228, 137),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_parking,
                        size: isSmallScreen ? 12 : 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          parkingStatus.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}


  Widget _buildFamilySection() {
    final profileState = ref.watch(profileSettingsViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'My family',
          'Add family member for quick entry',
          () => _showAddDialog('family'),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: profileState.familyMemberResult.when(
            data: (familyMembers) {
              if (familyMembers.isEmpty) {
                return Center(
                  child: Text(
                    'No family members added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4),
                itemCount: familyMembers.length,
                itemBuilder: (context, index) {
                  final member = familyMembers[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: _buildDynamicCard(
                      title: member.name ?? 'Unknown',
                      subtitle: member.login??"N/A",
                      icon: member.profileImage != null && member.profileImage!.isNotEmpty
                          ? Icons.person
                          : Icons.person_outline,
                      iconColor: Colors.blue,
                      qrData: 'Family: ${member.name} - ${member.preMob}',
                      id: member.ownerId ?? 0,
                      sectionType: 'family',
                      profileImage: member.profileImage
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Error loading family members',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _loadFamilyMembers,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesSection() {
    final profileState = ref.watch(profileSettingsViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'My vehicles',
          'Add your vehicles for quick entry',
          () => _showAddDialog('vehicles'),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: profileState.vehicleResult.when(
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return Center(
                  child: Text(
                    'No vehicles added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: _buildDynamicCard(
                      title: vehicle.modelName ?? 'Unknown Vehicle',
                      subtitle: vehicle.vehicleNo ?? 'No Number',
                    //  thirdLine: 'ID: ${vehicle.vehicleId ?? "N/A"}',
                      icon: Icons.directions_car,
                      iconColor: Colors.green,
                      qrData:
                          'Vehicle: ${vehicle.modelName} - ${vehicle.vehicleNo}',
                     // id: vehicle.vehicleId ?? 0,
                      sectionType: 'vehicles',
                      parkingStatus: vehicle.parkingStatus??"",
                      width: 150,
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Error loading vehicles',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  TextButton(onPressed: _loadVehicles, child: Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpersSection() {
    final profileState = ref.watch(profileSettingsViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Daily help',
          'Add maid, laundry, helper for quick entry',
          () => _showAddDialog('helpers'),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: profileState.familyMemberHelper.when(
            data: (helpers) {
              if (helpers.isEmpty) {
                return Center(
                  child: Text(
                    'No helpers added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4),
                itemCount: helpers.length,
                itemBuilder: (context, index) {
                  final helper = helpers[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: _buildDynamicCard(
                      title: helper.pName ?? 'Unknown Helper',
                      subtitle: helper.pTypeName ?? 'N/A',
                      icon: Icons.cleaning_services,
                      iconColor: Colors.orange,
                      qrData: 'Helper: ${helper.pName} - ${helper.pName} - ${helper.contactNo}',
                      id: helper.workId?? 0,
                      sectionType: 'helpers',
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Error loading helpers',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _loadHelpers,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequentEntriesSection() {
    final profileState = ref.watch(profileSettingsViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Frequent entry',
          'Add delivery, services for quick entry',
          () => _showAddDialog('entries'),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: profileState.frequentEntriesResult.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    'No frequent entries added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: _buildDynamicCard(
                      title: entry.vName ?? 'Unknown Entry',
                      subtitle: entry.type ?? 'Service',
                      icon: Icons.delivery_dining,
                      iconColor: Colors.purple,
                      qrData: 'Entry: ${entry.vName} - ${entry.type} - ${entry.contactNo}',
                      id: entry.visitorId ?? 0,
                      sectionType: 'entries',
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Error loading frequent entries',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _loadFrequentEntries,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getAvatarEmoji(String? gender) {
    return '👤';
  }

  String _generateQRData(BasicInfo basicInfo) {
    return '${basicInfo.name} - ${basicInfo.societyName} - ${basicInfo.unit ?? basicInfo.flatNo}';
  }
}

class AddDialog extends ConsumerStatefulWidget {
  final String type;
  final Function(Map<String, dynamic>) onAdd;

  const AddDialog({super.key, required this.type, required this.onAdd});

  @override
  _AddDialogState createState() => _AddDialogState();
}

class _AddDialogState extends ConsumerState<AddDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Map<String, dynamic> formData = {};

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
     // await  ref.read(ProfileSettingsViewModelProvider.notifier).getPersonList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);

  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // adds margin on small screens
    child: AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.85, // ✅ prevent vertical overflow
                  maxWidth: mediaQuery.size.width * 0.95,
                ),
                child: SingleChildScrollView( // ✅ makes dialog scrollable if needed
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Add ${widget.type.substring(0, 1).toUpperCase()}${widget.type.substring(1)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ..._buildFormFields(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      widget.onAdd(formData);
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}


  List<Widget> _buildFormFields() {
    switch (widget.type) {
      case 'family':
        return [
          _buildTextField('Name', 'name'),
          SizedBox(height: 16),
          _buildTextField('Relation', 'relation'),
          SizedBox(height: 16),
          _buildTextField('Phone Number', 'phone'),
          SizedBox(height: 16),
        ];
      case 'helpers':
        return [
          _buildTextField('Name', 'name'),
          // SizedBox(height: 16),
          // _buildTextField('Service', 'service'),
          SizedBox(height: 16),
          _buildTextField('Phone Number', 'phone'),
          SizedBox(height: 16),
          _buildHelperDropdown(),
          // _buildDropdown(
          //   'Service Icon',
          //   'image',
          //   ['🧹', '👔', '🥛', '🍕'],
          //   ['🧹 Cleaning', '👔 Laundry', '🥛 Milkman', '🍕 Cook'],
          // ),
        ];
      case 'vehicles':
        return [
          _buildDropdown(
            'Vehicle Type',
            'type',
            [1,0].map((e) => e.toString()).toList(),
            [' Car', ' Bike'],
          ),
          SizedBox(height: 16),
          _buildTextField('Vehicle Number', 'number'),
          SizedBox(height: 16),
          _buildTextField('Model', 'model'),
          SizedBox(height: 16),
          _buildTextField('Color', 'color'),
        ];
      // case 'entries':
      //   return [
      //     _buildTextField('Name/Company', 'name'),
      //     SizedBox(height: 16),
      //     _buildTextField('Type (Delivery, Service, etc.)', 'type'),
      //     SizedBox(height: 16),
      //     _buildTextField('Phone Number', 'phone'),
      //   ];
      default:
        return [];
    }
  }


  Widget _buildHelperDropdown() {
  final state = ref.watch(profileSettingsViewModelProvider);

  return state.personListResult.when(
     loading: () => const CircularProgressIndicator(),
    error: (e, _) => Text(ErrorMessageMapper.map(e)),
    data: (helpers) {
      return DropdownButtonFormField<int>(
        onChanged: (value) {
                    formData['serviceId']= value;
        },
        validator: (value) {
          if (value == null) {
            return 'Please select Service';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: "Service",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!),
          ),
        ),
        items: helpers.map((helper) {
          return DropdownMenuItem<int>(
            value: helper.pTypeId,
            child: Text(helper.pTypeName ?? 'Unknown'),
          );
        }).toList(),
      );
    }
   
  );
}

  // Widget _buildTextField(String label, String key) {
  //   return TextFormField(
  //     onChanged: (value) {
  //       formData[key] = value;
  //     },
  //     validator: (value) {
  //       if (value == null || value.isEmpty) {
  //         return 'Please enter $label';
  //       }
  //       return null;
  //     },
  //     decoration: InputDecoration(
  //       labelText: label,
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide(color: Colors.blue[600]!),
  //       ),
  //     ),
  //   );
  // }

Widget _buildTextField(String label, String key) {
  return TextFormField(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    keyboardType: key == 'phone' ? TextInputType.number : TextInputType.text,
    inputFormatters: key == 'phone'
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ]
        : [],
    onChanged: (value) => formData[key] = value,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter $label';
      }
      if (key == 'phone' && value.length != 10) {
        return 'Enter valid 10-digit phone number';
      }
      return null;
    },
  );
}

  Widget _buildDropdown(
    String label,
    String key,
    List<String> values,
    List<String> displayValues,
  ) {
    return DropdownButtonFormField<String>(
      onChanged: (value) {
        formData[key] = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!),
        ),
      ),
      items: List.generate(values.length, (index) {
        return DropdownMenuItem<String>(
          value: values[index],
          child: Text(displayValues[index]),
        );
      }),
    );
  }
}

class QRCodeDialog extends StatefulWidget {
  final String data;

  const QRCodeDialog({super.key, required this.data});

  @override
  _QRCodeDialogState createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }
 
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QR Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: widget.data,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.data,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
