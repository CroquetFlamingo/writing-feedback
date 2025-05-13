import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';

class EntryScreen extends StatefulWidget {
  final Entry entry;

  const EntryScreen({Key? key, required this.entry}) : super(key: key);

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  List<String> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('entries')
          .doc(widget.entry.entryID)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      final comments = snapshot.docs
          .map((doc) => (doc.data()['content'] ?? '').toString())
          .toList();

      setState(() {
        _comments = comments;
      });
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();

    if (comment.length < 5) return;

    try {
      await FirebaseFirestore.instance
          .collection('entries')
          .doc(widget.entry.entryID)
          .collection('comments')
          .add({
        'content': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      _loadComments();
    } catch (e) {
      print('Error submitting comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.entry.content,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _commentController,
                maxLength: 1000,
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Add a comment',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _submitComment,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              _comments.isEmpty
                  ? const Center(child: Text('No comments yet.'))
                  : ListView.builder(
                itemCount: _comments.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _comments[index],
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );


}
}
