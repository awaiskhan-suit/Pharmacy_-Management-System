import 'package:flutter/material.dart';
import 'package:pharmacy_invoice/painrelief.dart';
import 'package:pharmacy_invoice/skincare.dart';
import 'package:pharmacy_invoice/view_invoices.dart';
import 'package:pharmacy_invoice/view_medicine.dart';
import 'package:pharmacy_invoice/vitamins.dart';
import 'add_medicine.dart';
import 'allergy.dart';
import 'antiViral.dart';
import 'anti_biotic.dart';
import 'antifungal.dart';
import 'cluandflue.dart';
import 'dummay_page.dart';
import 'eye.dart';
import 'invoice_screen.dart';


class MedicineCategory extends StatelessWidget {
  const MedicineCategory({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.medical_services, 'label': 'Antibiotic', 'page': const AddAntibioticPage()},
      {'icon': Icons.healing, 'label': 'Pain Relief', 'page': AddPainReliefPage()},
      {'icon': Icons.local_florist, 'label': 'Vitamins', 'page': const AddVitaminsPage()},
      {'icon': Icons.wb_sunny, 'label': 'Allergy', 'page': const AddAllergyPage()},
      {'icon': Icons.face, 'label': 'Skincare', 'page': const AddSkinPage()},
      {'icon': Icons.visibility, 'label': 'Eye Care', 'page': const AddEyePage()},
      {'icon': Icons.local_hospital, 'label': 'Cold & Flu', 'page': const AddcoldfluePage()},
      {'icon': Icons.biotech, 'label': 'Anti-viral', 'page': const AddViralPage()},
      {'icon': Icons.clean_hands, 'label': 'Anti-fungal', 'page': const AddAntifungalPage()},

    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Medicine Categories "),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = features[index];
              return InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => item['page']));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'], size: 36, color: Colors.green[700]),
                      const SizedBox(height: 8),
                      Text(item['label'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
