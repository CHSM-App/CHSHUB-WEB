import 'package:flutter/material.dart';
import 'package:society_app/SocietyApp/screens/login.dart';

class Language {
  final String name;
  final String code;

  Language({required this.name, required this.code});
}

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String selectedLanguage = 'English'; // Default selection

  final List<Language> languages = [
    Language(name: 'English', code: 'en'),
    Language(name: 'عربي', code: 'ar'),
    Language(name: 'Portugal', code: 'pt'),
    Language(name: 'Français', code: 'fr'),
    Language(name: 'Bahasa Indonesia', code: 'id'),
    Language(name: 'Español', code: 'es'),
    Language(name: 'Italiano', code: 'it'),
    Language(name: 'Türk', code: 'tr'),
    Language(name: 'Kiswahili', code: 'sw'),
  ];

  void _onLanguageChanged(String? languageName) {
    if (languageName != null) {
      setState(() {
        selectedLanguage = languageName;
      });
    }
  }

  void _onConfirm() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected Language: $selectedLanguage'),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Widget _buildLanguageOption(Language language) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: RadioListTile<String>(
        value: language.name,
        groupValue: selectedLanguage,
        onChanged: _onLanguageChanged,
        title: Text(
          language.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        activeColor: Colors.black,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select Preferred app language',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ...languages.map((language) => _buildLanguageOption(language)),
            const SizedBox(height: 100), // Extra space for FAB
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: _onConfirm,
          backgroundColor: Colors.black,
          elevation: 0,
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LanguageSelectionPage(),
    ),
  );
}
