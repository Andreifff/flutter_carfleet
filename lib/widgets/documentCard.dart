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

  // Future<void> _deleteDocument(CarDocument document) async {
  //   String documentPath = 'cars/${widget.car.id}/documents/${document.id}';

  //   await FirebaseFirestore.instance
  //       .collection('cars')
  //       .doc(widget.car.id)
  //       .collection('documents')
  //       .doc(document.id)
  //       .delete();
  //   await FirebaseStorage.instance.ref(documentPath).delete();
  //   print('File deleted successfully from Firebase Storage.');

  //   fetchDocuments(); // Refresh documents list after deletion.
  // }
  Future<void> _deleteDocument(CarDocument document) async {
    String documentPath = 'cars/${widget.car.id}/documents/${document.id}';

    try {
      // Attempt to delete the document from Firestore
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.car.id)
          .collection('documents')
          .doc(document.id)
          .delete();

      // Attempt to delete the file from Firebase Storage
      await FirebaseStorage.instance.ref(documentPath).delete();
    } catch (e) {
      // Log error or handle it accordingly if the document does not exist
      print('Error deleting document: $e');
    }

    // Update the local list of documents to remove the deleted item
    setState(() {
      documents.removeWhere((CarDocument d) => d.id == document.id);
    });

    // Optionally show a message that the document was deleted
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Document deleted successfully")));
  }

  void _openImageScreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageScreen(imageUrl: imageUrl),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      try {
        await launchUrl(
          url,
          mode: LaunchMode
              .externalApplication, // Opens the URL outside your app in the default browser
        );
      } catch (e) {
        print('Failed to launch $url: $e');
        // Optionally, handle the error in the UI, for example:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to open document. Please try again.')));
      }
    } else {
      print('Could not launch $url');
      // Optionally, alert the user that the URL could not be handled
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open the link, unsupported URL')));
    }
  }

  // Future<void> testLaunchURL() async {
  //   const String testUrl = 'https://www.google.com';
  //   if (await canLaunchUrl(Uri.parse(testUrl))) {
  //     try {
  //       await launchUrl(
  //         Uri.parse(testUrl),
  //         mode: LaunchMode.externalApplication,
  //       );
  //     } catch (e) {
  //       print('Failed to launch test URL: $e');
  //     }
  //   } else {
  //     print('Cannot launch test URL');
  //   }
  // }

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
                        onTap: () =>
                            //testLaunchURL(),
                            isImage
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
