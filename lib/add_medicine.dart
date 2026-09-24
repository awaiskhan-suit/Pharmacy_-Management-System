// add_medicine_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMedicinePage extends StatefulWidget {
  final String? medicineId;
  final Map<String, dynamic>? existingData;

  const AddMedicinePage({super.key, this.medicineId, this.existingData});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String? _selectedCategory;
  String? _selectedBrand;
  DateTime? _expiryDate;
  DateTime? _preparationDate;
  bool _loading = false;

  final List<String> _categories = [
    'Tablet',
    'Syrup',
    'Capsule',
    'Injection',
    'Cream',
    'Drops',
    'Powder',
  ];

  final List<String> _brands = [
    'Antibiotic',
    'Painkiller',
    'Vitamin',
    'Antiseptic',
    'Antifungal',
    'Antiviral',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _nameController.text = data['name'];
      _batchController.text = data['batchNo'];
      _buyPriceController.text = data['purchasePrice'].toString();
      _sellPriceController.text = data['sellingPrice'].toString();
      _stockController.text = data['stock'].toString();
      _selectedCategory = data['category'];
      _selectedBrand = data['brand'];
      // We won't parse date strings back to DateTime here to keep it simple
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isPreparation) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPreparation
          ? (_preparationDate ?? now)
          : (_expiryDate ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );

    if (picked != null) {
      setState(() {
        if (isPreparation) {
          _preparationDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showError('Please select a category.');
      return;
    }
    if (_selectedBrand == null) {
      _showError('Please select a brand.');
      return;
    }
    if (_preparationDate == null) {
      _showError('Please select a preparation date.');
      return;
    }
    if (_expiryDate == null) {
      _showError('Please select an expiry date.');
      return;
    }

    final buyPrice = double.tryParse(_buyPriceController.text.trim());
    final sellPrice = double.tryParse(_sellPriceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (buyPrice == null) {
      _showError('Enter a valid purchase price.');
      return;
    }
    if (sellPrice == null) {
      _showError('Enter a valid selling price.');
      return;
    }
    if (stock == null) {
      _showError('Enter a valid stock quantity.');
      return;
    }

    setState(() => _loading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'brand': _selectedBrand,
        'batchNo': _batchController.text.trim(),
        'preparationDate': _formatDate(_preparationDate!),
        'expiryDate': _formatDate(_expiryDate!),
        'purchasePrice': buyPrice,
        'sellingPrice': sellPrice,
        'stock': stock,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.medicineId == null) {
        await FirebaseFirestore.instance.collection('medicines').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('medicines')
            .doc(widget.medicineId)
            .update(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Medicine saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _selectedCategory = null;
        _selectedBrand = null;
        _expiryDate = null;
        _preparationDate = null;
      });
    } catch (e) {
      _showError('Failed to save medicine: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicineId == null
            ? 'Add New Medicine'
            : 'Edit Medicine'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Medicine Name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Required field'
                      : null,
                ),
                const SizedBox(height: 15),

                // Brand Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  items: _brands
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Brand / Type *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _selectedBrand = val),
                  validator: (value) =>
                  (value == null) ? 'Required field' : null,
                ),
                const SizedBox(height: 15),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (value) =>
                  (value == null) ? 'Required field' : null,
                ),
                const SizedBox(height: 15),

                // Batch No
                TextFormField(
                  controller: _batchController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Batch No *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Required field'
                      : null,
                ),
                const SizedBox(height: 15),

                // Preparation Date
                _buildDatePickerField(
                  label: 'Preparation Date *',
                  date: _preparationDate,
                  onTap: () => _pickDate(true),
                ),
                const SizedBox(height: 15),

                // Expiry Date
                _buildDatePickerField(
                  label: 'Expiry Date *',
                  date: _expiryDate,
                  onTap: () => _pickDate(false),
                ),
                const SizedBox(height: 15),

                // Purchase Price
                TextFormField(
                  controller: _buyPriceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 10.50',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Required field';
                    if (double.tryParse(value.trim()) == null)
                      return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Selling Price
                TextFormField(
                  controller: _sellPriceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Selling Price *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 15.00',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Required field';
                    if (double.tryParse(value.trim()) == null)
                      return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Stock Quantity
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Required field';
                    if (int.tryParse(value.trim()) == null)
                      return 'Enter a valid integer';
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text(
                      'Save Medicine',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return FormField<DateTime>(
      initialValue: date,
      validator: (value) => (value == null) ? 'Required field' : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  errorText: state.errorText,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date == null ? 'Select Date' : _formatDate(date),
                      style: TextStyle(
                        fontSize: 16,
                        color: date == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            Builder(builder: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (state.value != date) state.didChange(date);
              });
              return const SizedBox.shrink();
            })
          ],
        );
      },
    );
  }
}
