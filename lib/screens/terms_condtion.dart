import 'package:flutter/material.dart';

class TermsConditionScreen extends StatelessWidget {
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
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.share, color: Colors.black87),
        //     onPressed: () => _shareTerms(context),
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Colors.blue[600],
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          'Last updated: March 2024',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Terms Content
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
                    '1. Acceptance of Terms',
                    'By accessing and using the Gate Manager application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                  ),
                  
                  _buildSection(
                    '2. Use License',
                    'Permission is granted to temporarily use the Gate Manager app for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• modify or copy the materials\n• use the materials for any commercial purpose or for any public display\n• attempt to reverse engineer any software contained in the app\n• remove any copyright or other proprietary notations from the materials',
                  ),
                  
                  _buildSection(
                    '3. User Responsibilities',
                    'As a user of the Gate Manager application, you agree to:\n\n• Provide accurate and complete information when registering visitors\n• Maintain the confidentiality of your account credentials\n• Report any security breaches immediately\n• Use the app only for legitimate security and visitor management purposes\n• Comply with all applicable laws and regulations',
                  ),
                  
                  _buildSection(
                    '4. Privacy and Data Protection',
                    'Your privacy is important to us. The app collects and processes personal data in accordance with our Privacy Policy. By using the app, you consent to the collection and use of information as outlined in our Privacy Policy.',
                  ),
                  
                  _buildSection(
                    '5. Data Security',
                    'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet or electronic storage is 100% secure. We cannot guarantee absolute security of your data.',
                  ),
                  
                  _buildSection(
                    '6. Visitor Information',
                    'You acknowledge that visitor information entered into the app may be:\n\n• Stored on secure servers\n• Shared with authorized personnel within your society\n• Used for security and access control purposes\n• Retained for record-keeping as required by law',
                  ),
                  
                  _buildSection(
                    '7. Service Availability',
                    'We strive to keep the app available 24/7, but we do not guarantee continuous availability. The service may be temporarily unavailable due to:\n\n• Scheduled maintenance\n• System updates\n• Technical difficulties\n• Force majeure events',
                  ),
                  
                  _buildSection(
                    '8. Limitation of Liability',
                    'In no event shall Gate Manager or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the app, even if Gate Manager or its authorized representative has been notified orally or in writing of the possibility of such damage.',
                  ),
                  
                  _buildSection(
                    '9. Modifications to Terms',
                    'Gate Manager may revise these terms of service at any time without notice. By using this app, you are agreeing to be bound by the then current version of these terms of service.',
                  ),
                  
                  _buildSection(
                    '10. Termination',
                    'We may terminate or suspend your account and access to the service immediately, without prior notice or liability, for any reason, including if you breach the Terms.',
                  ),
                  
                  _buildSection(
                    '11. Governing Law',
                    'These terms and conditions are governed by and construed in accordance with the laws of India, and you irrevocably submit to the exclusive jurisdiction of the courts in that state or location.',
                  ),
                  
                  _buildSection(
                    '12. Contact Information',
                    'If you have any questions about these Terms & Conditions, please contact us at:\n\nEmail: support@gatemanager.com\nPhone: +91 1800-123-4567\nAddress: SevenGen Society, Gate Management Office',
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Agreement Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green[600],
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'By using this application, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
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
  
  void _shareTerms(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terms & Conditions sharing feature would be implemented here'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
}