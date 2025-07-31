import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import 'success_screen.dart';

class FormAmbulanceScreen extends StatefulWidget {
  const FormAmbulanceScreen({super.key});

  @override
  State<FormAmbulanceScreen> createState() => _FormAmbulanceScreenState();
}

class _FormAmbulanceScreenState extends State<FormAmbulanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController petugas1Controller = TextEditingController();
  final TextEditingController petugas2Controller = TextEditingController();
  final TextEditingController nopolController = TextEditingController();
  final TextEditingController identitasKendaraanController = TextEditingController();
  DateTime tanggal = DateTime.now();

  final List<String> kondisiOptions = ['BAIK', 'RR', 'RB'];

  final List<String> kelengkapanPetugasList = [
    'Tas Ransel Petugas', 'Safety Shoes', 'Lap Kanebo', 'Rompi Reflektif',
    'Topi Reflektif', 'Jas Hujan', 'Kacamata Safety', 'Senter Kepala', 'Masker Safety'
  ];

  final List<String> kelengkapanSaranaList = [
    'Tas Medis', 'Tensi Meter', 'Stetoscope', 'Thermo Meter Digital',
    'Tongue Spatel', 'Resuscitate Marks/Air Bag', 'Tromol Gas', 'Tabung Oksigen',
    'Vertebrace Collars Set', 'Kantong Jenazah', 'Spalk Kayu Kaki & Tangan', 'Spalk Leher',
    'Head Immobilizer', 'Infus Set / Abocath', 'Cairan Infus RL / NaCl', 'Brankar / Scope',
    'Mitella', 'Scoop Strecher / Tandu', 'Long Spine Board (LSB)', 'Selimut Penderita',
    'Kendrik Ekstation', 'Obat-obatan', 'Face Masker', 'Sarung Tangan Karet', 'Celemek'
  ];

  final List<String> kelengkapanKendaraanList = [
    'Kaca Spion Luar', 'Kaca Spion Dalam', 'Lampu Kecil', 'Lampu Besar',
    'Lampu Sein Depan', 'Lampu Sein Belakang', 'Lampu Rem', 'Rotator',
    'Ban Depan & Velg', 'Ban Belakang &Velg', 'Ban Cadangan & Velg',
    'Radio Kunikasi', 'Antena', 'Amply', 'Public Address',
    'Sirine', 'Wastafel Tempel', 'Apar 6 Kg'
  ];

  final Map<String, Map<String, dynamic>> kelengkapanPetugas = {};
  final Map<String, Map<String, dynamic>> kelengkapanSarana = {};
  final Map<String, Map<String, dynamic>> kelengkapanKendaraan = {};

  final Map<String, TextEditingController> masaBerlakuController = {
    'STNK': TextEditingController(),
    'KIR': TextEditingController(),
    'SIM Operator 1': TextEditingController(),
    'SIM Operator 2': TextEditingController(),
    'Sertifikat Paramedis': TextEditingController(),
    'Service': TextEditingController(),
    'BBM': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    for (var listName in [
      {'list': kelengkapanPetugasList, 'target': kelengkapanPetugas},
      {'list': kelengkapanSaranaList, 'target': kelengkapanSarana},
      {'list': kelengkapanKendaraanList, 'target': kelengkapanKendaraan}
    ]) {
      final list = listName['list'] as List<String>;
      final target = listName['target'] as Map<String, Map<String, dynamic>>;
      for (var item in list) {
        target[item] = {
          'ada': false,
          'jumlah': TextEditingController(),
          'kondisi': 'BAIK'
        };
      }
    }
  }

  @override
  void dispose() {
    petugas1Controller.dispose();
    petugas2Controller.dispose();
    nopolController.dispose();
    identitasKendaraanController.dispose();
    for (var c in masaBerlakuController.values) {
      c.dispose();
    }
    for (var map in [kelengkapanPetugas, kelengkapanSarana, kelengkapanKendaraan]) {
      for (var item in map.values) {
        (item['jumlah'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  Widget buildChecklist(String title, Map<String, Map<String, dynamic>> dataMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...dataMap.keys.map((item) => Row(
          children: [
            Checkbox(
              value: dataMap[item]!['ada'] as bool,
              onChanged: (val) => setState(() => dataMap[item]!['ada'] = val ?? false),
            ),
            Expanded(child: Text(item)),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextField(
                controller: dataMap[item]!['jumlah'] as TextEditingController,
                decoration: const InputDecoration(labelText: 'Jml', isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: dataMap[item]!['kondisi'] as String,
              items: kondisiOptions
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (val) => setState(() => dataMap[item]!['kondisi'] = val!),
            ),
          ],
        )),
        const SizedBox(height: 12)
      ],
    );
  }

  Widget buildMasaBerlakuFields() {
    return Column(
      children: masaBerlakuController.keys.map((key) {
        if (key == 'BBM') {
          return TextFormField(
            controller: masaBerlakuController[key],
            decoration: InputDecoration(labelText: 'Masa Berlaku $key'),
          );
        } else {
          return GestureDetector(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(masaBerlakuController[key]!.text) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  masaBerlakuController[key]!.text =
                      "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                });
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: masaBerlakuController[key],
                decoration: InputDecoration(
                  labelText: 'Masa Berlaku $key',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  void generatePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final hariList = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final hari = hariList[tanggal.weekday % 7];
    final logoBytes = await rootBundle.load('assets/logo_jjc.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pw.Widget buildTableSection(String sectionTitle, Map<String, Map<String, dynamic>> dataMap) {
      int idx = 1;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            color: PdfColors.grey400,
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Text(sectionTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 11)),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FixedColumnWidth(18), // No
              1: const pw.FlexColumnWidth(3),   // Uraian
              2: const pw.FixedColumnWidth(30), // Ada
              3: const pw.FixedColumnWidth(30), // Tidak
              4: const pw.FixedColumnWidth(35), // Jumlah
              5: const pw.FixedColumnWidth(35), // Baik
              6: const pw.FixedColumnWidth(35), // RR
              7: const pw.FixedColumnWidth(35), // RB
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Center(child: pw.Text('NO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                  pw.Center(child: pw.Text('URAIAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                  pw.Center(child: pw.Text('ADA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                  pw.Center(child: pw.Text('TIDAK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                  pw.Center(child: pw.Text('JUMLAH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                  pw.Center(child: pw.Text('BAIK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                  pw.Center(child: pw.Text('RR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                  pw.Center(child: pw.Text('RB', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 8))),
                ],
              ),
              ...dataMap.entries.map((entry) {
                final no = idx++;
                final ada = entry.value['ada'] == true;
                final kondisi = entry.value['kondisi'] ?? '';
                return pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text(no.toString(), style: pw.TextStyle(font: font, fontSize: 8))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                      child: pw.Text(entry.key, style: pw.TextStyle(font: font, fontSize: 8)),
                    ),
                    pw.Center(child: ada ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                    pw.Center(child: !ada ? pw.Text('✗', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                    pw.Center(child: (entry.value['jumlah'] as TextEditingController).text.isNotEmpty ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                    pw.Center(child: kondisi == 'BAIK' ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                    pw.Center(child: kondisi == 'RR' ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                    pw.Center(child: kondisi == 'RB' ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                  ],
                );
              }),
            ],
          ),
        ],
      );
    }

    // Halaman 1
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        build: (context) => [
          // HEADER
          pw.Row(
            children: [
              pw.Image(logo, width: 60),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PT JASAMARGA JALANLAYANG CIKAMPEK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 13)),
                    pw.SizedBox(height: 2),
                    pw.Text('INSPEKSI PERIODIK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 11)),
                    pw.Text('KENDARAAN LAYANAN OPERASI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('HARI      : $hari', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('TANGGAL   : ${tanggal.toLocal().toString().split(' ')[0]}', style: pw.TextStyle(font: font, fontSize: 9)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('UNIT      : AMBULANCE', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('NO. POLISI: ${nopolController.text}', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('IDENTITAS KENDARAAN: ${identitasKendaraanController.text}', style: pw.TextStyle(font: font, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          buildTableSection('KELENGKAPAN PETUGAS', kelengkapanPetugas),
          pw.SizedBox(height: 8),
          buildTableSection('KELENGKAPAN SARANA', kelengkapanSarana),
          pw.SizedBox(height: 32),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Text('(...............................)', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 120,
                    alignment: pw.Alignment.center,
                    child: pw.Text('Petugas 1', style: pw.TextStyle(font: font, fontSize: 10)),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('(...............................)', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 120,
                    alignment: pw.Alignment.center,
                    child: pw.Text('Petugas 2', style: pw.TextStyle(font: font, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // Halaman 2
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        build: (context) => [
          buildTableSection('KELENGKAPAN KENDARAAN', kelengkapanKendaraan),
          pw.SizedBox(height: 12),
          pw.Text('Masa Berlaku', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 11)),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: masaBerlakuController.keys.map((k) => pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(k, style: pw.TextStyle(font: font, fontSize: 8)),
                )).toList(),
              ),
              pw.TableRow(
                children: masaBerlakuController.values.map((v) => pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(v.text, style: pw.TextStyle(font: font, fontSize: 8)),
                )).toList(),
              ),
            ],
          ),
          pw.SizedBox(height: 80), // Jarak besar sebelum TTD
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Text('PT JMTO', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.SizedBox(height: 30),
                  pw.Text('Manager Traffic', style: pw.TextStyle(font: font, fontSize: 9)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('PT JJC', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.SizedBox(height: 30),
                  pw.Text('NIK .', style: pw.TextStyle(font: font, fontSize: 9)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());

    // Simpan riwayat inspeksi ke Hive
    final box = Hive.box('inspection_history');
    box.add({
      'jenis': 'Ambulance',
      'tanggal': tanggal.toIso8601String(),
      'nopol': nopolController.text,
      'petugas1': petugas1Controller.text,
      'petugas2': petugas2Controller.text,
      'kelengkapanPetugas': kelengkapanPetugas.map((k, v) => MapEntry(k, {
        'ada': v['ada'],
        'jumlah': v['jumlah'].text,
        'kondisi': v['kondisi'],
      })),
      'kelengkapanSarana': kelengkapanSarana.map((k, v) => MapEntry(k, {
        'ada': v['ada'],
        'jumlah': v['jumlah'].text,
        'kondisi': v['kondisi'],
      })),
      'kelengkapanKendaraan': kelengkapanKendaraan.map((k, v) => MapEntry(k, {
        'ada': v['ada'],
        'jumlah': v['jumlah'].text,
        'kondisi': v['kondisi'],
      })),
    });
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
                controller: petugas1Controller,
                decoration: const InputDecoration(labelText: 'Petugas 1'),
              ),
              TextFormField(
                controller: petugas2Controller,
                decoration: const InputDecoration(labelText: 'Petugas 2'),
              ),
              TextFormField(
                controller: nopolController,
                decoration: const InputDecoration(labelText: 'No Polisi'),
              ),
              TextFormField(
                controller: identitasKendaraanController,
                decoration: const InputDecoration(labelText: 'Identitas Kendaraan'),
              ),
              const SizedBox(height: 16),
              buildChecklist('Kelengkapan Petugas', kelengkapanPetugas),
              buildChecklist('Kelengkapan Sarana', kelengkapanSarana),
              buildChecklist('Kelengkapan Kendaraan', kelengkapanKendaraan),
              const SizedBox(height: 16),
              buildMasaBerlakuFields(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    generatePdf();
                  }
                },
                child: const Text('Cetak Laporan PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

