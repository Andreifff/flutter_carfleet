// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/models/car_document.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageScreen extends StatelessWidget {
  final String imageUrl;

  const ImageScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Image'),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}

class DocumentsCard extends StatefulWidget {
  final Car car;
  final Function() onDocumentAdded;
  final VoidCallback onRefreshRequested;

  const DocumentsCard({
    Key? key,
    required this.car,
    required this.onDocumentAdded,
    required this.onRefreshRequested,
  }) : super(key: key);

  @override
  _DocumentsCardState createState() => _DocumentsCardState();
}

class _DocumentsCardState extends State<DocumentsCard> {
  List<CarDocument> documents = [];

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(widget.car.id)
        .collection('documents')
        .get();

    var docs = snapshot.docs
        .map((doc) => CarDocument.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    setState(() {
      documents = docs;
    });
  }

  Future<void> _deleteDocument(CarDocument document) async {
    String documentPath = 'cars/${widget.car.id}/documents/${document.id}';

    await FirebaseFirestore.instance
        .collection('cars')
        .doc(widget.car.id)
        .collection('documents')
        .doc(document.id)
        .delete();
    await FirebaseStorage.instance.ref(documentPath).delete();
    print('File deleted successfully from Firebase Storage.');

    fetchDocuments(); // Refresh documents list after deletion.
  }

  void _openImageScreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageScreen(imageUrl: imageUrl),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  Widget _documentListItem(CarDocument document) {
    bool isImage =
        document.url.endsWith('.jpg') || document.url.endsWith('.png');
    return ListTile(
      leading: isImage
          ? Image.network(document.url, width: 50, height: 50)
          : Icon(Icons.file_present),
      title: Text(document.name),
      onTap: () =>
          isImage ? _openImageScreen(document.url) : _launchURL(document.url),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _deleteDocument(document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Container(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cars')
                    .doc(widget.car.id)
                    .collection('documents')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  List<DocumentSnapshot> documentSnapshots =
                      snapshot.data?.docs ?? [];
                  List<CarDocument> documents = documentSnapshots
                      .map((doc) => CarDocument.fromFirestore(
                          doc.data() as Map<String, dynamic>, doc.id))
                      .toList();

                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      bool isImage = documents[index].url.endsWith('.jpg') ||
                          documents[index].url.endsWith('.png');
                      return ListTile(
                        leading: isImage
                            ? Image.network(documents[index].url,
                                width: 50, height: 50)
                            : Icon(Icons.file_present),
                        title: Text(documents[index].name),
                        onTap: () => isImage
                            ? Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ImageScreen(
                                    imageUrl: documents[index].url)))
                            : _launchURL(documents[index].url),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deleteDocument(documents[index]);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: widget.onDocumentAdded,
              icon: Icon(Icons.add),
              label: Text('Add Document'),
            ),
          ],
        ),
      ),
    );
  }
}
