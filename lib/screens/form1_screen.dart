import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'success_screen.dart';

class FormAmbulanceScreen extends StatefulWidget {
  const FormAmbulanceScreen({super.key});

  @override
  State<FormAmbulanceScreen> createState() => _FormAmbulanceScreenState();
}

class _FormAmbulanceScreenState extends State<FormAmbulanceScreen> {
  final _formKey = GlobalKey<FormState>();
  String? petugas1;
  String? petugas2;
  DateTime tanggal = DateTime.now();

  // Checklist
  final List<String> kelengkapanSarana = [
    'Oksigen',
    'Tandu',
    'P3K',
    'APAR',
    'Lampu Strobo'
  ];

  final List<String> kelengkapanKendaraan = [
    'Dongkrak',
    'Segitiga Pengaman',
    'Ban Cadangan',
    'Kunci Roda'
  ];

  Map<String, bool> saranaChecklist = {};
  Map<String, bool> kendaraanChecklist = {};

  // Masa berlaku dokumen
  final Map<String, TextEditingController> masaBerlakuController = {
    'STNK': TextEditingController(),
    'KIR': TextEditingController(),
    'SIM': TextEditingController(),
    'Sertifikat Paramedis': TextEditingController(),
    'Service': TextEditingController(),
    'BBM': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    saranaChecklist = {for (var item in kelengkapanSarana) item: false};
    kendaraanChecklist = {for (var item in kelengkapanKendaraan) item: false};
  }

  Future<void> kirimKeSpreadsheet() async {
    final url = Uri.parse('https://script.google.com/macros/s/AKfycbyfZJCQ_wICVl9f6fgjULmIM4ZH0W0Bm7T1QGPgHuPre4pBV5djCkPYYX1NacD6zAiHGQ/exec');

    final saranaAda = saranaChecklist.entries.where((e) => e.value).map((e) => e.key).join(', ');
    final saranaTidak = saranaChecklist.entries.where((e) => !e.value).map((e) => e.key).join(', ');
    final kendaraanAda = kendaraanChecklist.entries.where((e) => e.value).map((e) => e.key).join(', ');
    final kendaraanTidak = kendaraanChecklist.entries.where((e) => !e.value).map((e) => e.key).join(', ');

    final data = {
      'tanggal': tanggal.toIso8601String(),
      'petugas1': petugas1,
      'petugas2': petugas2,
      'sarana_ada': saranaAda,
      'sarana_tidak': saranaTidak,
      'kendaraan_ada': kendaraanAda,
      'kendaraan_tidak': kendaraanTidak,
      'masa_stnk': masaBerlakuController['STNK']!.text,
      'masa_kir': masaBerlakuController['KIR']!.text,
      'masa_sim': masaBerlakuController['SIM']!.text,
      'masa_paramedis': masaBerlakuController['Sertifikat Paramedis']!.text,
      'masa_service': masaBerlakuController['Service']!.text,
      'status_bbm': masaBerlakuController['BBM']!.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('📤 Spreadsheet status: ${response.statusCode}');
      print('📄 Spreadsheet response: ${response.body}');

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessScreen()));
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Widget buildChecklist(String title, Map<String, bool> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...items.keys.map((item) => CheckboxListTile(
          title: Text(item),
          value: items[item],
          onChanged: (val) => setState(() => items[item] = val ?? false),
        ))
      ],
    );
  }

  Widget buildMasaBerlakuFields() {
    return Column(
      children: masaBerlakuController.keys.map((key) => TextFormField(
        controller: masaBerlakuController[key],
        decoration: InputDecoration(labelText: 'Masa Berlaku $key'),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Ambulance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Petugas 1'),
                onSaved: (val) => petugas1 = val,
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Petugas 2'),
                onSaved: (val) => petugas2 = val,
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              buildChecklist('Kelengkapan Sarana', saranaChecklist),
              const SizedBox(height: 16),
              buildChecklist('Kelengkapan Kendaraan', kendaraanChecklist),
              const SizedBox(height: 16),
              buildMasaBerlakuFields(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    kirimKeSpreadsheet();
                  }
                },
                child: const Text('Simpan'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
