import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:jasamarga_inspeksi/screens/form_plaza_screen.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class FormPlazaScreen extends StatefulWidget {
  const FormPlazaScreen({super.key});

  @override
  State<FormPlazaScreen> createState() => _FormPlazaScreenState();
}

class _FormPlazaScreenState extends State<FormPlazaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController petugas1Controller = TextEditingController();
  final TextEditingController petugas2Controller = TextEditingController();
  final TextEditingController nopolController = TextEditingController();
  final TextEditingController identitasKendaraanController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  DateTime tanggal = DateTime.now();

  // Controller untuk foto bukti
  final ImagePicker _picker = ImagePicker();
  File? fotoStnk;
  File? fotoSim1;
  File? fotoSim2;
  String? currentLocation;

  final List<String> kondisiOptions = ['BAIK', 'RR', 'RB'];

  final List<String> kelengkapanPetugasList = [
    'Tas Ransel Petugas', 'Safety Shoes', 'Sepatu Boots', 'Lap Kanebo',
    'Rompi Reflektif', 'Topi Reflektif', 'Jas Hujan', 'Bendera Merah/Tongkat',
    'Kacamata Safety', 'Sarung Tangan Kulit', 'Senter Lalin', 'Masker Safety'
  ];

  final List<String> kelengkapanSaranaList = [
    'Rubber Cone', 'Rambu Hati-Hati', 'Rambu Tanda Panah', 'Sekop', 'Sapu Lidi',
    'Balok Kayu', 'Serbuk Gergaji', 'Linggis', 'Jerigen Air 20 Ltr', 'Jerigen BBM 5 Ltr',
    'Perlak Penutup Jenazah', 'Corong Plastik', 'Webbing/Sling'
  ];

  final List<String> kelengkapanKendaraanList = [
    'Kaca Spion Luar', 'Kaca Spion Dalam', 'Lampu Kecil', 'Lampu Besar', 'Lampu Sorot',
    'Lampu Sein Depan', 'Lampu Sein Belakang', 'Lampu Rem', 'Rotator', 'Ban Depan & Velg',
    'Ban Belakang &Velg', 'Ban Cadangan & Velg', 'Radio Kunikasi / Antena',
    'Handy Talky & Charger', 'Amply / Public Address', 'Kunci Roda', 'Sirine',
    'Rak Rambu', 'Box Besi', 'Perlengkapan P3K', 'Apar 6 Kg'
  ];

  final Map<String, Map<String, dynamic>> kelengkapanPetugas = {};
  final Map<String, Map<String, dynamic>> kelengkapanSarana = {};
  final Map<String, Map<String, dynamic>> kelengkapanKendaraan = {};

  // Tambahkan deklarasi dan inisialisasi masaBerlakuMap
  final List<String> masaBerlakuList = [
    'STNK',
    'SIM Operator 1',
    'SIM Operator 2',
    'Service Terakhir',
    'BBM',
  ];
  late final Map<String, TextEditingController> masaBerlakuMap;

  @override
  void initState() {
    super.initState();
    masaBerlakuMap = {for (var k in masaBerlakuList) k: TextEditingController()};
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
                    pw.Text('UNIT      : PLAZA', style: pw.TextStyle(font: font, fontSize: 9)),
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
                children: masaBerlakuList.map((k) => pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(k, style: pw.TextStyle(font: font, fontSize: 8)),
                )).toList(),
              ),
              pw.TableRow(
                children: masaBerlakuList.map((k) {
                  if (k == 'BBM') {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(masaBerlakuMap[k]?.text ?? '', style: pw.TextStyle(font: font, fontSize: 8)),
                    );
                  } else {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(masaBerlakuMap[k]?.text ?? '', style: pw.TextStyle(font: font, fontSize: 8)),
                    );
                  }
                }).toList(),
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
      'jenis': 'Plaza',
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

  Widget buildMasaBerlakuFields() {
    return Column(
      children: masaBerlakuList.map((key) {
        if (key == 'BBM') {
          return TextFormField(
            controller: masaBerlakuMap[key],
            decoration: InputDecoration(labelText: 'Status BBM'),
          );
        } else {
          return GestureDetector(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(masaBerlakuMap[key]?.text ?? '') ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  masaBerlakuMap[key]?.text =
                      "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                });
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: masaBerlakuMap[key],
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
      appBar: AppBar(title: const Text('Form Plaza')),
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
