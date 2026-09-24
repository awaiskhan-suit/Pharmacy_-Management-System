import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewColdFluePage extends StatefulWidget {
  const ViewColdFluePage({super.key});

  @override
  State<ViewColdFluePage> createState() => _ViewColdFluePageState();
}

class _ViewColdFluePageState extends State<ViewColdFluePage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> antibioticsStream = FirebaseFirestore.instance
        .collection('coldflue')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cold and Flu Medicines'),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Generic Name...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          // 🔹 Firestore stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: antibioticsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No Cold and Flu found.'));
                }

                // Filter by generic name
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final genericName =
                  (data['genericName'] ?? '').toString().toLowerCase();
                  return genericName.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching results found.'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.medication,
                            color: Colors.teal, size: 35),
                        title: Text(
                          data['medicineName'] ?? 'Unknown Medicine',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Generic: ${data['genericName'] ?? 'N/A'}'),
                            Text('Company: ${data['companyName'] ?? 'N/A'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✏️ Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditDialog(context, docId, data);
                              },
                            ),

                            // 🗑️ Delete Button
                            IconButton(
                              icon:
                              const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('coldflue')
                                    .doc(docId)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                      Text('Medicine deleted successfully')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🧾 Edit Dialog Box
  void _showEditDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final TextEditingController medicineController =
    TextEditingController(text: data['medicineName']);
    final TextEditingController genericController =
    TextEditingController(text: data['genericName']);
    final TextEditingController companyController =
    TextEditingController(text: data['companyName']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Medicine'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: medicineController,
                  decoration:
                  const InputDecoration(labelText: 'Medicine Name'),
                ),
                TextField(
                  controller: genericController,
                  decoration: const InputDecoration(labelText: 'Generic Name'),
                ),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('coldflue')
                    .doc(docId)
                    .update({
                  'medicineName': medicineController.text.trim(),
                  'genericName': genericController.text.trim(),
                  'companyName': companyController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicine updated successfully')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

