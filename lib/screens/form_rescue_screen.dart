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

class FormRescueScreen extends StatefulWidget {
  const FormRescueScreen({super.key});

  @override
  State<FormRescueScreen> createState() => _FormRescueScreenState();
}

class _FormRescueScreenState extends State<FormRescueScreen> {
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
  File? fotoKir;
  File? fotoService;
  File? fotoBbm;
  String? currentLocation;

  final List<String> kondisiOptions = ['BAIK', 'RR', 'RB', 'TIDAK ADA'];

  final List<String> kelengkapanPetugasList = [
    'Tas Ransel Petugas', 'Safety Shoes', 'Sepatu Boots', 'Lap Kanebo',
    'Rompi Reflektif', 'Topi Reflektif', 'Jas Hujan', 'Bendera Merah/Tongkat',
    'Kacamata Safety', 'Sarung Tangan Kulit', 'Senter Lalin', 'Masker Safety'
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
    'SIM Operator 1': TextEditingController(),
    'SIM Operator 2': TextEditingController(),
    'Service Terakhir': TextEditingController(),
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
          'kondisi': 'TIDAK ADA'
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
            case 'kir':
              fotoKir = File(image.path);
              break;
            case 'service':
              fotoService = File(image.path);
              break;
            case 'bbm':
              fotoBbm = File(image.path);
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2257C1),
              ),
            ),
            const Divider(height: 24),
            ...dataMap.entries.map((entry) {
              final item = entry.key;
              final data = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Checkbox(
                        value: data['ada'] as bool,
                        onChanged: (value) {
                          setState(() {
                            data['ada'] = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: data['jumlah'] as TextEditingController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: data['kondisi'] as String,
                        decoration: const InputDecoration(
                          labelText: 'Kondisi',
                          border: OutlineInputBorder(),
                        ),
                        items: kondisiOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            data['kondisi'] = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildMasaBerlakuFields() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masa Berlaku Dokumen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2257C1),
              ),
            ),
            const Divider(height: 24),
            ...masaBerlakuController.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void generatePdf() async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();

      // Halaman 1: Header + Kelengkapan Petugas + Kelengkapan Sarana + Tanda Tangan
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          build: (context) => [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PT. JASAMARGA JALAN CONCESSION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 14)),
                    pw.Text('FORM INSPEKSI RESCUE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 16)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal: ${tanggal.day}/${tanggal.month}/${tanggal.year}', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('Lokasi: ${lokasiController.text}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Informasi Petugas
            pw.Text('Petugas 1: ${petugas1Controller.text}', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Text('Petugas 2: ${petugas2Controller.text}', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Text('Nomor Polisi: ${nopolController.text}', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Text('Identitas Kendaraan: ${identitasKendaraanController.text}', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.SizedBox(height: 20),

            // Kelengkapan Petugas
            pw.Text('KELENGKAPAN PETUGAS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
            pw.SizedBox(height: 10),
            buildTableSection(kelengkapanPetugas, font, fontBold),
            pw.SizedBox(height: 20),

            // Kelengkapan Sarana
            pw.Text('KELENGKAPAN SARANA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
            pw.SizedBox(height: 10),
            buildTableSection(kelengkapanSarana, font, fontBold),
            pw.SizedBox(height: 20),

            // Tanda tangan - Petugas 1 dan Petugas 2
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Petugas 1:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 40),
                    pw.Text(petugas1Controller.text, style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Petugas 2:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 40),
                    pw.Text(petugas2Controller.text, style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Halaman 2: Kelengkapan Kendaraan + Masa Berlaku Dokumen + Tanda Tangan
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          build: (context) => [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PT. JASAMARGA JALAN CONCESSION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 14)),
                    pw.Text('FORM INSPEKSI RESCUE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 16)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal: ${tanggal.day}/${tanggal.month}/${tanggal.year}', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('Lokasi: ${lokasiController.text}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Kelengkapan Kendaraan
            pw.Text('KELENGKAPAN KENDARAAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
            pw.SizedBox(height: 10),
            buildTableSection(kelengkapanKendaraan, font, fontBold),
            pw.SizedBox(height: 20),

            // Masa Berlaku Dokumen
            pw.Text('MASA BERLAKU DOKUMEN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
            pw.SizedBox(height: 10),
            buildMasaBerlakuTable(font, fontBold),
            pw.SizedBox(height: 20),

            // Tanda tangan - PT JMTO Manager Traffic dan PT JJC
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  children: [
                    pw.Text('PT JMTO Manager Traffic:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 40),
                    pw.Text('', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('PT JJC:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 20),
                    pw.Text('NIK:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 20),
                    pw.Text('', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Lampiran Foto (jika ada)
      if (fotoStnk != null || fotoSim1 != null || fotoSim2 != null || fotoKir != null || 
          fotoService != null || fotoBbm != null) {
        
        // Buat list foto yang ada
        List<Map<String, dynamic>> fotoList = [];
        if (fotoStnk != null) fotoList.add({'title': 'Bukti STNK:', 'file': fotoStnk});
        if (fotoSim1 != null) fotoList.add({'title': 'Bukti SIM Operator 1:', 'file': fotoSim1});
        if (fotoSim2 != null) fotoList.add({'title': 'Bukti SIM Operator 2:', 'file': fotoSim2});
        if (fotoKir != null) fotoList.add({'title': 'Bukti KIR:', 'file': fotoKir});
        if (fotoService != null) fotoList.add({'title': 'Bukti Service:', 'file': fotoService});
        if (fotoBbm != null) fotoList.add({'title': 'Bukti BBM:', 'file': fotoBbm});

        // Bagi foto menjadi halaman dengan maksimal 3 foto per halaman
        for (int i = 0; i < fotoList.length; i += 3) {
          List<Map<String, dynamic>> pageFotos = fotoList.skip(i).take(3).toList();
          
          pdf.addPage(
            pw.MultiPage(
              margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              build: (context) => [
                pw.Text('LAMPIRAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 16)),
                pw.SizedBox(height: 20),
                ...pageFotos.map((foto) => [
                  pw.Text(foto['title'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 12)),
                  pw.SizedBox(height: 8),
                  pw.Image(pw.MemoryImage(foto['file'].readAsBytesSync()), width: 200, height: 150),
                  pw.SizedBox(height: 16),
                ]).expand((element) => element).toList(),
              ],
            ),
          );
        }
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  pw.Widget buildTableSection(Map<String, Map<String, dynamic>> dataMap, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Uraian', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 8)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Ada', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 6)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Tidak', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 6)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 6)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Kondisi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 8)),
            ),
          ],
        ),
        ...dataMap.entries.map((entry) {
          final item = entry.key;
          final data = entry.value;
          final ada = data['ada'] as bool;
          final jumlah = (data['jumlah'] as TextEditingController).text;
          final kondisi = data['kondisi'] as String;

          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(item, style: pw.TextStyle(font: font, fontSize: 8)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: ada ? pw.Container(
                  width: 8,
                  height: 8,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                    shape: pw.BoxShape.circle,
                  ),
                ) : pw.SizedBox(),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: !ada ? pw.Container(
                  width: 8,
                  height: 8,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                    shape: pw.BoxShape.circle,
                  ),
                ) : pw.SizedBox(),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(jumlah, style: pw.TextStyle(font: font, fontSize: 6)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(kondisi, style: pw.TextStyle(font: font, fontSize: 8)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget buildMasaBerlakuTable(pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Dokumen', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Masa Berlaku', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10)),
            ),
          ],
        ),
        ...masaBerlakuController.entries.map((entry) {
          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(entry.key, style: pw.TextStyle(font: font, fontSize: 10)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(entry.value.text, style: pw.TextStyle(font: font, fontSize: 10)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Form Rescue'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2257C1),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Informasi Dasar
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Dasar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2257C1),
                        ),
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: petugas1Controller,
                        decoration: InputDecoration(
                          labelText: 'Nama Petugas 1',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: petugas2Controller,
                        decoration: InputDecoration(
                          labelText: 'Nama Petugas 2',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nopolController,
                        decoration: InputDecoration(
                          labelText: 'Nomor Polisi',
                          prefixIcon: const Icon(Icons.directions_car),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: identitasKendaraanController,
                        decoration: InputDecoration(
                          labelText: 'Identitas Kendaraan',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: lokasiController,
                              decoration: InputDecoration(
                                labelText: 'Lokasi Terkini',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2257C1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
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
                              icon: const Icon(Icons.my_location, color: Colors.white),
                              tooltip: 'Dapatkan Lokasi',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Card Foto Bukti
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Foto Bukti',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2257C1),
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fotoStnk != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: fotoStnk != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
                              icon: Icon(fotoStnk != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fotoStnk != null ? 'STNK ✓' : 'Foto STNK'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fotoKir != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: fotoKir != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await pickImage('kir');
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: Icon(fotoKir != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fotoKir != null ? 'KIR ✓' : 'Foto KIR'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fotoSim1 != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: fotoSim1 != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
                              icon: Icon(fotoSim1 != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fotoSim1 != null ? 'SIM 1 ✓' : 'Foto SIM 1'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fotoSim2 != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: fotoSim2 != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
                              icon: Icon(fotoSim2 != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fotoSim2 != null ? 'SIM 2 ✓' : 'Foto SIM 2'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fotoService != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: fotoService != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await pickImage('service');
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: Icon(fotoService != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fotoService != null ? 'Service ✓' : 'Foto Service'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fotoBbm != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: fotoBbm != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await pickImage('bbm');
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: Icon(fotoBbm != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fotoBbm != null ? 'BBM ✓' : 'Foto BBM'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Checklist sections
              buildChecklist('Kelengkapan Petugas', kelengkapanPetugas),
              buildChecklist('Kelengkapan Sarana', kelengkapanSarana),
              buildChecklist('Kelengkapan Kendaraan', kelengkapanKendaraan),
              buildMasaBerlakuFields(),
              
              const SizedBox(height: 24),
              
              // Tombol Cetak
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2257C1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      generatePdf();
                    }
                  },
                  icon: const Icon(Icons.print, size: 24),
                  label: const Text(
                    'Cetak Laporan PDF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

