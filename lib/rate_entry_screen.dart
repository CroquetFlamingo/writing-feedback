import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'create_entry_screen.dart';
import 'session.dart';

class RateEntryScreen extends StatefulWidget {
  @override
  _RateEntryScreenState createState() => _RateEntryScreenState();
}

class _RateEntryScreenState extends State<RateEntryScreen> {
  final TextEditingController _commentController = TextEditingController();

  final int totalReviewsRequired = 2;
  int reviewsLeft = 2;
  List<Entry> entriesToReview = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRandomEntries());
  }

  Future<void> _loadRandomEntries() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('entries').get();
      final docs = snapshot.docs;

      print('All entry IDs: ${docs.map((d) => d.id).toList()}');
      print('Session-created IDs: $sessionCreatedEntryIds');

      final filteredDocs = docs.where((doc) {
        return !sessionCreatedEntryIds.contains(doc.id);
      }).toList();

      print('Filtered entries: ${filteredDocs.map((d) => d.id).toList()}');

      if (filteredDocs.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CreateEntryScreen()),
        );
        return;
      }

      final random = Random();
      final shuffledDocs = List.from(filteredDocs)..shuffle(random);

      final selected = shuffledDocs
          .where((doc) => !sessionCreatedEntryIds.contains(doc.id))
          .take(totalReviewsRequired)
          .map((doc) {
        final data = doc.data();
        return Entry(
          entryID: doc.id,
          username: data['name'] ?? '',
          title: data['title'] ?? '',
          content: data['content'] ?? '',
        );
      }).toList();

      for (var entry in selected) {
        assert(!sessionCreatedEntryIds.contains(entry.entryID), 'Selected entry was created this session!');
        print('Final selected entry ID: ${entry.entryID}');
      }

      setState(() {
        entriesToReview = selected;
        reviewsLeft = selected.length;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading entries: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Error"),
          content: Text("Something went wrong while loading entries. Please try again later."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();

    if (comment.length < 100) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Please give more feedback"),
          content: Text("Minimum 100 characters required."),
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

    final entry = entriesToReview[currentIndex];
    final commentsRef = FirebaseFirestore.instance
        .collection('entries')
        .doc(entry.entryID)
        .collection('comments');

    await commentsRef.add({
      'content': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();

    if (currentIndex + 1 < entriesToReview.length) {
      setState(() {
        currentIndex++;
        reviewsLeft--;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CreateEntryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Rate Entries')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final entry = entriesToReview[currentIndex];
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text('Give Entry Feedback')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '$reviewsLeft Reviews Left',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  entry.title,
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: screenHeight * 0.3,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    entry.content,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLength: 1000,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your comment',
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
                      onPressed: _submitComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Next'),
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
