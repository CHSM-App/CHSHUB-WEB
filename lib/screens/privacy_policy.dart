import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.share, color: Colors.black87),
        //     onPressed: () => _sharePrivacyPolicy(context),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[100]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip,
                    color: Colors.purple[600],
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[800],
                          ),
                        ),
                        Text(
                          'Effective from: March 1, 2024',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Privacy Content
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Introduction',
                    'Gate Manager ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
                  ),
                  
                  _buildSection(
                    '2. Information We Collect',
                    'We collect information you provide directly to us, such as:\n\n• Personal Information: Name, phone number, email address, profile photo\n• Account Information: Username, password, gate assignment, duty status\n• Visitor Information: Names, contact details, visit purposes, timestamps\n• Device Information: Device type, operating system, unique device identifiers\n• Usage Information: App interactions, feature usage, error logs',
                  ),
                  
                  _buildSection(
                    '3. How We Use Your Information',
                    'We use the collected information for:\n\n• Providing and maintaining our services\n• Managing visitor access and security\n• Communicating with you about the service\n• Improving our app functionality\n• Ensuring security and preventing fraud\n• Complying with legal obligations\n• Analyzing usage patterns to enhance user experience',
                  ),
                  
                  _buildSection(
                    '4. Information Sharing',
                    'We may share your information with:\n\n• Society Management: For security and administrative purposes\n• Authorized Personnel: Guards, admin staff, security heads\n• Service Providers: For app maintenance and cloud storage\n• Legal Authorities: When required by law or to protect rights\n\nWe do not sell, trade, or rent your personal information to third parties.',
                  ),
                  
                  _buildSection(
                    '5. Data Security',
                    'We implement appropriate security measures including:\n\n• Encryption of data in transit and at rest\n• Secure authentication mechanisms\n• Regular security audits and updates\n• Access controls and user permission management\n• Secure cloud storage with reputable providers',
                  ),
                  
                  _buildSection(
                    '6. Data Retention',
                    'We retain your information for as long as necessary to:\n\n• Provide our services effectively\n• Comply with legal obligations\n• Resolve disputes and enforce agreements\n• Maintain security records as required\n\nVisitor logs may be retained for up to 2 years for security purposes.',
                  ),
                  
                  _buildSection(
                    '7. Your Privacy Rights',
                    'You have the right to:\n\n• Access your personal information\n• Update or correct your information\n• Delete your account and associated data\n• Opt-out of non-essential communications\n• Request data portability\n• Lodge complaints with supervisory authorities',
                  ),
                  
                  _buildSection(
                    '8. Camera and Photo Permissions',
                    'Our app may request access to your device camera and photo gallery to:\n\n• Update your profile picture\n• Scan QR codes for visitor entry\n• Capture visitor photos (with consent)\n\nYou can revoke these permissions at any time through your device settings.',
                  ),
                  
                  _buildSection(
                    '9. Location Information',
                    'We may collect location data to:\n\n• Verify you are at your assigned gate\n• Enhance security features\n• Provide location-based services\n\nLocation tracking can be disabled in app settings.',
                  ),
                  
                  _buildSection(
                    '10. Children\'s Privacy',
                    'Our service is not intended for children under 18. We do not knowingly collect personal information from children. If we become aware of such collection, we will take steps to delete the information.',
                  ),
                  
                  _buildSection(
                    '11. International Data Transfers',
                    'Your information may be transferred to and stored in countries other than your own. We ensure appropriate safeguards are in place for such transfers.',
                  ),
                  
                  _buildSection(
                    '12. Changes to Privacy Policy',
                    'We may update this Privacy Policy periodically. We will notify you of significant changes through:\n\n• In-app notifications\n• Email communications\n• Updates on our website\n\nContinued use after changes constitutes acceptance.',
                  ),
                  
                  _buildSection(
                    '13. Contact Us',
                    'If you have questions about this Privacy Policy, please contact us:\n\nEmail: privacy@gatemanager.com\nPhone: +91 1800-123-4567\nAddress: Privacy Officer, SevenGen Society Management\n\nData Protection Officer: dpo@gatemanager.com',
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Privacy Commitment
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.blue[600],
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'We are committed to protecting your personal information and respecting your privacy rights.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  

                ],
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void _sharePrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Privacy Policy sharing feature would be implemented here'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
  
}