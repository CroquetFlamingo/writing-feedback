import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'session.dart';
import 'entry_screen.dart'; // Make sure this points to your EntryScreen file

class CreateEntryScreen extends StatefulWidget {
  @override
  _CreateEntryScreenState createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();


  Future<void> _createEntry() async {
    final title = _titleController.text.trim();
    final author = "user";
    final content = _contentController.text.trim();

    if (title.isEmpty || author.isEmpty || content.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Missing Fields"),
          content: Text("Please fill in all fields."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    try {
      final docRef = await FirebaseFirestore.instance.collection('entries').add({
        'title': title,
        'name': author,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add to in-memory session exclusion list
      sessionCreatedEntryIds.add(docRef.id);
      print('Session-created IDs: $sessionCreatedEntryIds');


      final newEntry = Entry(
        entryID: docRef.id,
        username: author,
        title: title,
        content: content,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EntryScreen(entry: newEntry)),
      );
    } catch (e) {
      print('Error creating entry: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Error"),
          content: Text("Something went wrong while creating your entry. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
    }


  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text('Create Entry')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 12),
              Container(
                height: 300,
                child: TextField(
                  controller: _contentController,
                  maxLength: 5000,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  }
}
