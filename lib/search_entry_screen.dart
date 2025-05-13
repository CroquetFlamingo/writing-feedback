import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart'; // <-- Make sure this is where your Entry class is
import 'entry_screen.dart'; // <-- Update with your actual path
import 'dart:async';


class SearchEntryScreen extends StatefulWidget {
  @override
  _SearchEntryScreenState createState() => _SearchEntryScreenState();
}

class _SearchEntryScreenState extends State<SearchEntryScreen> {
  String searchTerm = '';
  List<Entry> searchResults = [];
  bool isLoading = false;
  Timer? _debounce;


  void _searchEntries(String value) async {
    setState(() {
      searchTerm = value;
      isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('entries')
          .get();

      final lowerValue = value.toLowerCase();

      final results = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final title = data['title']?.toLowerCase() ?? '';
        final content = data['content']?.toLowerCase() ?? '';
        return title.contains(lowerValue) || content.contains(lowerValue);
      }).map((doc) {
        final data = doc.data();
        return Entry(
          entryID: doc.id,
          username: data['name'] ?? '',
          title: data['title'] ?? '',
          content: data['content'] ?? '',
        );
      }).toList();

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      print('Error during search: $e');
      setState(() {
        searchResults = [];
        isLoading = false;
      });
    }
  }


  void _navigateToEntry(Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryScreen(entry: entry),
      ),
    );
  }
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by title or content',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  _searchEntries(value);
                });
              },
            ),
            SizedBox(height: 16),
            if (isLoading) CircularProgressIndicator(),
            if (!isLoading)
              Expanded(
                child: searchResults.isEmpty && searchTerm.isNotEmpty
                    ? Center(
                  child: Text(
                    'No Entries Found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final entry = searchResults[index];
                    return Card(
                      child: ListTile(
                        title: Text(entry.title),
                        subtitle: Text(
                          entry.content.split(' ').take(10).join(' ') + '...',
                        ),
                        onTap: () => _navigateToEntry(entry),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
