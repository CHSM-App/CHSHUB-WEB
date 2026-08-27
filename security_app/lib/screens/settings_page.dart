import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/core/network/token_provider.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/screens/login.dart';
import 'package:security_app/screens/terms_condtion.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_profile_screen.dart';
import 'gatekeeper_attendance_screen.dart';
import 'language_screen.dart';
import 'support_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  ConsumerState<SettingsScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingsScreen> {
  late String mobile;
  String? adminMobile;
String? secretaryMobile;
  @override
   void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _refreshContacts();
  });
  }

  Future<void> _refreshContacts() async {
    final list = await ref
        .read(securitymodelProvider.notifier)
        .getCommitteeContacts("C10001");

    if (list.isNotEmpty && mounted) {
      setState(() {
        adminMobile = list[0].contactNo;      // Admin
        secretaryMobile = list[1].contactNo;  // Secretary
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(securitymodelProvider).loginDetails.value?.first;
    final isCheckedIn = ref.watch(staffmodelProvider).isCheckedIn;
    
    
    return Scaffold(
         backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        color: const Color(0xFF5E72E4),
        onRefresh: _refreshContacts,
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Modern App Bar
          // SliverAppBar(
          //  // expandedHeight: 120,
          //   floating: false,
          //   pinned: true,
          //   backgroundColor: Colors.white,
          //   elevation: 0,
          //   flexibleSpace: FlexibleSpaceBar(
          //     title: const Text(
          //       'Settings',
          //       style: TextStyle(
          //         color: Color(0xFF1A1A1A),
          //         fontSize: 24,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //     centerTitle: false,
          //     titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          //   ),
          // ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Profile Card
                  _buildProfileCard(user, isCheckedIn, context),
                  
                  const SizedBox(height: 28),
                  
                  // Quick Actions Section
                  _buildSectionHeader('Quick Actions', Icons.flash_on),
                  
                  const SizedBox(height: 12),
                  
                  _buildQuickActionsGrid(context),
                  
                  const SizedBox(height: 28),
                  
                  // Settings Section
                  _buildSectionHeader('Preferences', Icons.settings_outlined),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingsGroup([
                    _SettingItem(
                      title: 'Language',
                      icon: Icons.language_outlined,
                      color: const Color(0xFF5E72E4),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LanguageScreen()),
                      ),
                    ),
                    _SettingItem(
                      title: 'Get Support',
                      icon: Icons.help_outline_rounded,
                      color: const Color(0xFF2DCE89),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SupportScreen()),
                      ),
                    ),
                  ]),
                  
                  const SizedBox(height: 28),
                  
                  // Legal Section
                  _buildSectionHeader('Legal', Icons.gavel_outlined),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingsGroup([
                    _SettingItem(
                      title: 'Terms & Conditions',
                      icon: Icons.description_outlined,
                      color: const Color(0xFF11CDEF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TermsConditionScreen()),
                      ),
                    ),
                    _SettingItem(
                      title: 'Privacy Policy',
                      icon: Icons.privacy_tip_outlined,
                      color: const Color(0xFFFB6340),
                      onTap: () => _openPrivacyPolicy(context),
                    ),
                  ]),
                  
                  const SizedBox(height: 28),
                  
                  // Logout Button
                  _buildLogoutButton(context),
                  
                  // const SizedBox(height: 40),
                  
                  // // App Version
                  // Center(
                  //   child: Text(
                  //     'Version 1.0.0',
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       color: Colors.grey[400],
                  //     ),
                  //   ),
                  // ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic user, bool isCheckedIn, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5E72E4),
            const Color(0xFF825EE4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E72E4).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (user?.staffId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    gateKeeperId: user!.staffId ?? 0,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Enhanced Profile Image
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    foregroundImage: (user != null && user.image != null && user.image!.isNotEmpty)
                        ? NetworkImage(user.image!)
                        : null,
                    child: (user == null || user.image == null || user.image!.isEmpty)
                        ? const Icon(Icons.person, size: 38, color: Colors.white)
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Profile Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Guest User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.contactNo ?? 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_city,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user?.societyName ?? 'N/A',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCheckedIn
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCheckedIn
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCheckedIn
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCheckedIn ? 'On Duty' : 'Off Duty',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Edit Button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF5E72E4),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickActionsGrid(BuildContext context) {
    final user = ref.watch(securitymodelProvider).loginDetails.value?.first;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Call Admin',
                Icons.phone_outlined,
                const Color(0xFF2DCE89),
                () => _makeCall(context, 'Admin'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Call Secretary',
                Icons.phone_outlined,
                const Color(0xFF11CDEF),
                () => _makeCall(context, 'Secretary'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'My Attendance',
                Icons.calendar_month_outlined,
                const Color(0xFF5E72E4),
                () {
                  if (user?.staffId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GateKeeperAttendanceScreen(
                          staffId: user!.staffId!,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsGroup(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          
          return Column(
            children: [
              _buildSettingsTile(item),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildSettingsTile(_SettingItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutConfirmation(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // border: Border.all(
            //   color: Colors.red[100]!,
            //   width: 1.5,
            // ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.red.withOpacity(0.1),
            //     blurRadius: 10,
            //    // offset: const Offset(0, 4),
            //   ),
            // ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
Future<void> _openPrivacyPolicy(BuildContext context) async {
  final Uri uri = Uri.parse("https://chshub.co.in/privacy-policy");

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Could not open privacy policy")),
    );
  }
}

Future<void> _makeCall(BuildContext context, String role) async {
  String? number;

  if (role == "Admin") {
    number = adminMobile;
  } else if (role == "Secretary") {
    number = secretaryMobile;
  }

  if (number == null || number.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$role number not available")),
    );
    return;
  }

  final Uri uri = Uri.parse("tel:$number");

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Could not open dialer")),
    );
  }
}

  
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(tokenProvider.notifier).clearTokens();
                ref.read(securitymodelProvider.notifier).clearLogin();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MobileNumberScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _SettingItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}