import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ListLocationScreen extends StatefulWidget {
  const ListLocationScreen({super.key, required this.refresh});

  final Function refresh;

  @override
  State<ListLocationScreen> createState() => _ListLocationScreenState();
}

class _ListLocationScreenState extends State<ListLocationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('List of Locations'),
        ),
        body: FutureBuilder(
          future: FirebaseFirestore.instance.collection('locations').get(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return Card(
                  child: ListTile(
                    title: Text(doc['title']),
                    subtitle: Text(
                      doc['description'],
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('locations')
                            .doc(doc.id)
                            .delete();
                        setState(() {});
                        widget.refresh();
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}
