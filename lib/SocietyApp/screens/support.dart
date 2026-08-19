import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: GetSupportScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class GetSupportScreen extends StatefulWidget {
  const GetSupportScreen({super.key});

  @override
  _GetSupportScreenState createState() => _GetSupportScreenState();
}

class _GetSupportScreenState extends State<GetSupportScreen> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Ask us or suggest anyway we can improve',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 30),

            // Topic Field
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                hintText: 'Enter Topic',
                hintStyle: TextStyle(color: Colors.grey),
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),

            // Message Field
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your message',
                hintStyle: TextStyle(color: Colors.grey),
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Handle submission
                  print("Topic: ${topicController.text}");
                  print("Message: ${messageController.text}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Submit Message',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
