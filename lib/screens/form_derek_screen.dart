import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'success_screen.dart';

class FormDerekScreen extends StatefulWidget {
  const FormDerekScreen({super.key});

  @override
  State<FormDerekScreen> createState() => _FormDerekScreenState();
}

class _FormDerekScreenState extends State<FormDerekScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController petugas1Controller = TextEditingController();
  final TextEditingController petugas2Controller = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  DateTime tanggal = DateTime.now();
  final TextEditingController nopolController = TextEditingController();
  final TextEditingController identitasKendaraanController = TextEditingController();

  // Controller untuk foto bukti
  final ImagePicker _picker = ImagePicker();
  File? fotoStnk;
  File? fotoSim1;
  File? fotoSim2;
  String? currentLocation;

  final List<String> kelengkapanPetugasList = [
    'Rompi Reflektif',
    'Topi Reflektif',
    'Safety Shoes',
    'Bendera Merah',
    'Handy Talky',
    'Jas Hujan',
    'Kacamata Safety',
    'Helm',
    'Seragam Petugas',
  ];
  final List<String> kelengkapanSaranaList = [
    'Rubber Cone',
    'Senter Lalin',
    'Jirigen Air 20 Ltr',
    'Jirigen Solar 20 Ltr',
    'Balok Kayu',
    'Plat Besi / Alas Dongkrak',
    'Sling',
    'Pipa Besi 1,5 meter',
    'Rantai Pengikat Min. 10 meter',
    'Beban Pemberat',
  ];
  final List<String> kelengkapanKendaraanList = [
    'Kaca Spion Luar',
    'Kaca Spion Dalam',
    'Lampu Kecil',
    'Lampu Besar',
    'Lampu Sein Depan',
    'Lampu Sein Belakang',
    'Lampu Rem',
    'Lampu Mundur',
    'Rotator',
    'Ban Depan & Velg',
    'Ban Belakang & Velg',
    'Ban Cadangan & Velg',
    'Radio Komunikasi/Antena',
    'Dongkrak Besar',
    'Amply/Public Adress',
    'Sling, Rantai, Balok',
    'Kunci Pembuka Roda',
    'Rambu Tanda Panah',
    'Rambu Hati-Hati',
    'Penutup Rantai Lidah Pengait',
    'Takel',
  ];

  final Map<String, Map<String, dynamic>> kelengkapanPetugas = {};
  final Map<String, Map<String, dynamic>> kelengkapanSarana = {};
  final Map<String, Map<String, dynamic>> kelengkapanKendaraan = {};

  final Map<String, TextEditingController> masaBerlakuController = {
    'STNK': TextEditingController(),
    'KIR': TextEditingController(),
    'SIM Operator 1': TextEditingController(),
    'SIM Operator 2': TextEditingController(),
    'Service': TextEditingController(),
    'BBM': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    for (var item in kelengkapanPetugasList) {
      kelengkapanPetugas[item] = {
        'ada': false,
        'jumlah': TextEditingController(),
        'kondisi': 'BAIK'
      };
    }
    for (var item in kelengkapanSaranaList) {
      kelengkapanSarana[item] = {
        'ada': false,
        'jumlah': TextEditingController(),
        'kondisi': 'BAIK'
      };
    }
    for (var item in kelengkapanKendaraanList) {
      kelengkapanKendaraan[item] = {
        'ada': false,
        'jumlah': TextEditingController(),
        'kondisi': 'BAIK'
      };
    }
  }

  @override
  void dispose() {
    petugas1Controller.dispose();
    petugas2Controller.dispose();
    nopolController.dispose();
    identitasKendaraanController.dispose();
    lokasiController.dispose();
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

  // Method untuk mendapatkan lokasi terkini
  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi tidak tersedia')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLocation = '${position.latitude}, ${position.longitude}';
        lokasiController.text = currentLocation!;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mendapatkan lokasi: $e')),
      );
    }
  }

  // Method untuk mengambil foto
  Future<void> pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          switch (type) {
            case 'stnk':
              fotoStnk = File(image.path);
              break;
            case 'sim1':
              fotoSim1 = File(image.path);
              break;
            case 'sim2':
              fotoSim2 = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil foto: $e')),
      );
    }
  }

  Future<void> kirimKeSpreadsheet() async {
    final url = Uri.parse('https://script.google.com/macros/s/AKfycbyfZJCQ_wICVl9f6fgjULmIM4ZH0W0Bm7T1QGPgHuPre4pBV5djCkPYYX1NacD6zAiHGQ/exec');

    final petugasAda = kelengkapanPetugas.entries.where((e) => e.value['ada']).map((e) => e.key).join(', ');
    final petugasTidak = kelengkapanPetugas.entries.where((e) => !e.value['ada']).map((e) => e.key).join(', ');
    final saranaAda = kelengkapanSarana.entries.where((e) => e.value['ada']).map((e) => e.key).join(', ');
    final saranaTidak = kelengkapanSarana.entries.where((e) => !e.value['ada']).map((e) => e.key).join(', ');
    final kendaraanAda = kelengkapanKendaraan.entries.where((e) => e.value['ada']).map((e) => e.key).join(', ');
    final kendaraanTidak = kelengkapanKendaraan.entries.where((e) => !e.value['ada']).map((e) => e.key).join(', ');

    final data = {
      'tanggal': tanggal.toIso8601String(),
      'petugas1': petugas1Controller.text,
      'petugas2': petugas2Controller.text,
      'petugas_ada': petugasAda,
      'petugas_tidak': petugasTidak,
      'sarana_ada': saranaAda,
      'sarana_tidak': saranaTidak,
      'kendaraan_ada': kendaraanAda,
      'kendaraan_tidak': kendaraanTidak,
      'masa_stnk': masaBerlakuController['STNK']!.text,
      'masa_kir': masaBerlakuController['KIR']!.text,
      'masa_sim1': masaBerlakuController['SIM Operator 1']!.text,
      'masa_sim2': masaBerlakuController['SIM Operator 2']!.text,
      'masa_service': masaBerlakuController['Service']!.text,
      'status_bbm': masaBerlakuController['BBM']!.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessScreen()));
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> generatePdf(BuildContext context) async {
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
                    pw.Center(child: pw.Text((entry.value['jumlah'] as TextEditingController).text.isNotEmpty ? (entry.value['jumlah'] as TextEditingController).text : '-', style: pw.TextStyle(font: font, fontSize: 8))),
                    pw.Center(child: kondisi == 'BAIK' ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                    pw.Center(child: kondisi == 'RR' ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                    pw.Center(child: kondisi == 'RB' ? pw.Text('✔', style: pw.TextStyle(font: font, fontSize: 14)) : pw.SizedBox(width: 14, height: 14)),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      );
    }

    // Halaman 1: header, kelengkapan petugas, kelengkapan sarana, ttd petugas
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
                    pw.Text('UNIT      : DEREK', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('NO. POLISI: ${nopolController.text}', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('IDENTITAS KENDARAAN: ${identitasKendaraanController.text}', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('LOKASI TERKINI: ${lokasiController.text.isNotEmpty ? lokasiController.text : 'Tidak ada data'}', style: pw.TextStyle(font: font, fontSize: 9)),
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

    // Halaman 2: kelengkapan kendaraan, masa berlaku, ttd bawah
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

    // Halaman 3 - Lampiran
    if (fotoStnk != null || fotoSim1 != null || fotoSim2 != null) {
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          build: (context) => [
            pw.Text('LAMPIRAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 16)),
            pw.SizedBox(height: 20),
            if (fotoStnk != null) ...[
              pw.Text('Bukti STNK:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Image(pw.MemoryImage(fotoStnk!.readAsBytesSync()), width: 200, height: 150),
              pw.SizedBox(height: 16),
            ],
            if (fotoSim1 != null) ...[
              pw.Text('Bukti SIM Operator 1:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Image(pw.MemoryImage(fotoSim1!.readAsBytesSync()), width: 200, height: 150),
              pw.SizedBox(height: 16),
            ],
            if (fotoSim2 != null) ...[
              pw.Text('Bukti SIM Operator 2:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Image(pw.MemoryImage(fotoSim2!.readAsBytesSync()), width: 200, height: 150),
              pw.SizedBox(height: 16),
            ],
          ],
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) => pdf.save());

    // Simpan riwayat inspeksi ke Hive
    final box = Hive.box('inspection_history');
    box.add({
      'jenis': 'Derek',
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

  pw.Widget table2Col(String col1, String col2, String val1, String val2) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(col1)),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(col2)),
        ]),
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(val1)),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(val2)),
        ]),
      ],
    );
  }

  String getHari(DateTime tanggal) {
    final hariList = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return hariList[tanggal.weekday % 7];
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
              items: ['BAIK', 'RR', 'RB']
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
                      " ${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Derek')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Hari/Tanggal:  ${getHari(tanggal)}, ${tanggal.toIso8601String().split('T')[0]}'),
              const SizedBox(height: 10),
              TextFormField(
                controller: petugas1Controller,
                decoration: const InputDecoration(labelText: 'Petugas 1'),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: petugas2Controller,
                decoration: const InputDecoration(labelText: 'Petugas 2'),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: nopolController,
                decoration: const InputDecoration(labelText: 'No Polisi'),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: identitasKendaraanController,
                decoration: const InputDecoration(labelText: 'Identitas Kendaraan'),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // Lokasi Terkini
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Terkini',
                        hintText: 'Klik tombol untuk mendapatkan lokasi',
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      try {
                        await getCurrentLocation();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Dapatkan Lokasi',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Foto Bukti
              const Text('Foto Bukti:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await pickImage('stnk');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Foto STNK'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (fotoStnk != null)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await pickImage('sim1');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Foto SIM 1'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (fotoSim1 != null)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await pickImage('sim2');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Foto SIM 2'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (fotoSim2 != null)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              buildChecklist('Kelengkapan Petugas', kelengkapanPetugas),
              const SizedBox(height: 16),
              buildChecklist('Kelengkapan Sarana', kelengkapanSarana),
              const SizedBox(height: 16),
              buildChecklist('Kelengkapan Kendaraan', kelengkapanKendaraan),
              const SizedBox(height: 16),
              buildMasaBerlakuFields(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    generatePdf(context);
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
