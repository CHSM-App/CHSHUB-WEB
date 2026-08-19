import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';
  
  final List<Map<String, dynamic>> _languages = [
    {
      'name': 'English',
      'nativeName': 'English',
      'code': 'en',
      'flag': '🇺🇸',
    },
    {
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
      'code': 'hi',
      'flag': '🇮🇳',
    },
    {
      'name': 'Marathi',
      'nativeName': 'मराठी',
      'code': 'mr',
      'flag': '🇮🇳',
    },
    {
      'name': 'Gujarati',
      'nativeName': 'ગુજરાતી',
      'code': 'gu',
      'flag': '🇮🇳',
    },
    {
      'name': 'Tamil',
      'nativeName': 'தமிழ்',
      'code': 'ta',
      'flag': '🇮🇳',
    },
    {
      'name': 'Telugu',
      'nativeName': 'తెలుగు',
      'code': 'te',
      'flag': '🇮🇳',
    },
    {
      'name': 'Kannada',
      'nativeName': 'ಕನ್ನಡ',
      'code': 'kn',
      'flag': '🇮🇳',
    },
    {
      'name': 'Bengali',
      'nativeName': 'বাংলা',
      'code': 'bn',
      'flag': '🇮🇳',
    },
    {
      'name': 'Punjabi',
      'nativeName': 'ਪੰਜਾਬੀ',
      'code': 'pa',
      'flag': '🇮🇳',
    },
    {
      'name': 'Spanish',
      'nativeName': 'Español',
      'code': 'es',
      'flag': '🇪🇸',
    },
    {
      'name': 'French',
      'nativeName': 'Français',
      'code': 'fr',
      'flag': '🇫🇷',
    },
    {
      'name': 'German',
      'nativeName': 'Deutsch',
      'code': 'de',
      'flag': '🇩🇪',
    },
  ];

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
          'Language',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveLanguageSelection,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Description Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select your preferred language for the app interface',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Languages List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguage == language['name'];
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLanguage = language['name'];
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue[600]! : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Flag
                          Text(
                            language['flag'],
                            style: TextStyle(fontSize: 24),
                          ),
                          
                          SizedBox(width: 16),
                          
                          // Language Names
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.blue[600] : Colors.black87,
                                  ),
                                ),
                                if (language['name'] != language['nativeName'])
                                  Text(
                                    language['nativeName'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.blue[500] : Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Selection Indicator
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue[600],
                              size: 24,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _saveLanguageSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Language'),
          content: Text('Are you sure you want to change the language to $_selectedLanguage? The app will restart to apply changes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyLanguageChange();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }
  
  void _applyLanguageChange() {
    // Here you would implement the language change logic
    // This might involve updating shared preferences, restarting the app, etc.
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to $_selectedLanguage'),
        backgroundColor: Colors.green[600],
      ),
    );
    
    // Simulate app restart delay
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }
}