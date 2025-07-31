import 'package:flutter/material.dart';
import 'form_ambulance_screen.dart';
import 'form_derek_screen.dart';
import 'form_kamtib_screen.dart';
import 'form_plaza_screen.dart';
import 'form_rescue_screen.dart';

class KendaraanScreen extends StatefulWidget {
  const KendaraanScreen({super.key});

  @override
  State<KendaraanScreen> createState() => _KendaraanScreenState();
}

class _KendaraanScreenState extends State<KendaraanScreen> {
  final List<String> kategoriList = [
    'Ambulance',
    'Derek',
    'Plaza',
    'Kamtib',
    'Rescue',
  ];

  String? selectedKategori;

  void navigateToForm(String kategori) {
    if (kategori == 'Ambulance') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FormAmbulanceScreen()),
      );
    } else if (kategori == 'Derek') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FormDerekScreen()),
      );
    } else if (kategori == 'Kamtib') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FormKamtibScreen()),
      );
    } else if (kategori == 'Plaza') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FormPlazaScreen()),
      );
    } else if (kategori == 'Rescue') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FormRescueScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form untuk $kategori belum tersedia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Jenis Kendaraan'),
        backgroundColor: const Color(0xFFEBEC07), // kuning
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // ⬅️ tengahin form
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kategori Kendaraan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Pilih kategori'),
              value: selectedKategori,
              items: kategoriList.map((String kategori) {
                return DropdownMenuItem<String>(
                  value: kategori,
                  child: Text(kategori),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedKategori = val;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: selectedKategori != null
                  ? () => navigateToForm(selectedKategori!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEBEC07),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 6,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lanjut',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
