import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacy_invoice/view_eye.dart';



class AddEyePage extends StatefulWidget {
  const AddEyePage({super.key});

  @override
  State<AddEyePage> createState() => _AddEyePageState();
}

class _AddEyePageState extends State<AddEyePage> {
  final TextEditingController _medicineNameController = TextEditingController();

  // ✅ List of Common Generic Antibiotic Names
  final List<String> _genericNames = [
    "Timolol",
    "Brimonidine",
    "Dorzolamide",
    "Travoprost",
    "Latanoprost",
    "Tobramycin",
    "Moxifloxacin",
    "Ciprofloxacin",
    "Ofloxacin",
    "Dexamethasone",
    "Prednisolone Acetate",
    "Carboxymethylcellulose Sodium",
    "Olopatadine",
    "Ketotifen",
    "Naphazoline",
  ];

  // ✅ Top Pakistani Pharmaceutical Companies
  final List<String> _companyNames = [
    'GSK (GlaxoSmithKline)',
    'Abbott Laboratories',
    'Getz Pharma',
    'Searle Company',
    'Hilton Pharma',
    'Martin Dow',
    'OBS Pakistan',
    'PharmEvo',
    'Highnoon Laboratories',
    'Ferozsons Laboratories',
  ];

  String? _selectedGeneric;
  String? _selectedCompany;
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addAntibiotic() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('eye').add({
        'medicineName': _medicineNameController.text.trim(),
        'genericName': _selectedGeneric,
        'companyName': _selectedCompany,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eye medicine added successfully')),
      );

      _medicineNameController.clear();
      setState(() {
        _selectedGeneric = null;
        _selectedCompany = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Eye Medicine'),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              // 🔹 Medicine Name
              TextFormField(
                controller: _medicineNameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name....',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medicine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 🔹 Generic Name Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGeneric,
                decoration: const InputDecoration(
                  labelText: 'Select Generic Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.science),
                ),
                items: _genericNames
                    .map((generic) => DropdownMenuItem(
                  value: generic,
                  child: Text(generic),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGeneric = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a generic name';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 🔹 Company Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCompany,
                decoration: const InputDecoration(
                  labelText: 'Select Company (Pakistan)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                items: _companyNames
                    .map((company) => DropdownMenuItem(
                  value: company,
                  child: Text(company),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCompany = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a company';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // 🔹 Save Button
              ElevatedButton.icon(
                onPressed: _addAntibiotic,
                icon: const Icon(Icons.save),
                label: const Text('Add Eye'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15),

              // 🔹 Save Button
              ElevatedButton.icon(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewEyePage()));
                },
                icon: const Icon(Icons.shower),
                label: const Text('show'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
