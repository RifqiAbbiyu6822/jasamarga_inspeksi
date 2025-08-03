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
                fontSize: 18,
                color: Color(0xFF2257C1),
              ),
            ),
            const Divider(height: 24),
            ...dataMap.keys.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: Colors.grey[600],
                        ),
                        child: Checkbox(
                          value: dataMap[item]!['ada'] as bool,
                          onChanged: (val) => setState(() => dataMap[item]!['ada'] = val ?? false),
                          activeColor: const Color(0xFF2257C1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: TextField(
                            controller: dataMap[item]!['jumlah'] as TextEditingController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: DropdownButton<String>(
                          value: dataMap[item]!['kondisi'] as String,
                          underline: const SizedBox(),
                          items: kondisiOptions
                              .map((k) => DropdownMenuItem(
                                value: k,
                                child: Text(k),
                              ))
                              .toList(),
                          onChanged: (val) => setState(() => dataMap[item]!['kondisi'] = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
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
                fontSize: 18,
                color: Color(0xFF2257C1),
              ),
            ),
            const Divider(height: 24),
            ...masaBerlakuController.keys.map((key) {
              if (key == 'BBM') {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: masaBerlakuController[key],
                    decoration: InputDecoration(
                      labelText: 'Status BBM',
                      prefixIcon: const Icon(Icons.local_gas_station),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              } else {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
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
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ),
                );
              }
            }).toList(),
          ],
        ),
      ),
    );
  }

  void generatePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
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
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(sectionTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
          ),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),  // No
              1: const pw.FlexColumnWidth(3.5), // Uraian
              2: const pw.FixedColumnWidth(35), // Ada
              3: const pw.FixedColumnWidth(35), // Tidak
              4: const pw.FixedColumnWidth(40), // Jumlah
              5: const pw.FixedColumnWidth(35), // Baik
              6: const pw.FixedColumnWidth(35), // RR
              7: const pw.FixedColumnWidth(35), // RB
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('NO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('URAIAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('ADA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('TIDAK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('JUMLAH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('BAIK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('RR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Center(child: pw.Text('RB', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9))),
                  ),
                ],
              ),
              ...dataMap.entries.map((entry) {
                final no = idx++;
                final ada = entry.value['ada'] == true;
                final kondisi = entry.value['kondisi'] ?? '';
                return pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                      child: pw.Center(child: pw.Text(no.toString(), style: pw.TextStyle(font: font, fontSize: 9))),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                      child: pw.Text(entry.key, style: pw.TextStyle(font: font, fontSize: 9)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Center(
                        child: ada 
                          ? pw.Text('●', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green))
                          : pw.SizedBox(width: 16, height: 16),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Center(
                        child: !ada 
                          ? pw.Text('●', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.red))
                          : pw.SizedBox(width: 16, height: 16),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                      child: pw.Center(
                        child: pw.Text(
                          (entry.value['jumlah'] as TextEditingController).text.isNotEmpty 
                            ? (entry.value['jumlah'] as TextEditingController).text 
                            : '-',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Center(
                        child: kondisi == 'BAIK' 
                          ? pw.Text('●', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green))
                          : pw.SizedBox(width: 16, height: 16),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Center(
                        child: kondisi == 'RR' 
                          ? pw.Text('●', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.orange))
                          : pw.SizedBox(width: 16, height: 16),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Center(
                        child: kondisi == 'RB' 
                          ? pw.Text('●', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.red))
                          : pw.SizedBox(width: 16, height: 16),
                      ),
                    ),
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        build: (context) => [
          // HEADER
          pw.Row(
            children: [
              pw.Image(logo, width: 70),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PT JASAMARGA JALANLAYANG CIKAMPEK', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 14)),
                    pw.SizedBox(height: 4),
                    pw.Text('INSPEKSI PERIODIK', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                    pw.Text('KENDARAAN LAYANAN OPERASI', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('HARI      : $hari', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('TANGGAL   : ${tanggal.toLocal().toString().split(' ')[0]}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('UNIT      : DEREK', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('NO. POLISI: ${nopolController.text}', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('IDENTITAS : ${identitasKendaraanController.text}', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('LOKASI    : ${lokasiController.text.isNotEmpty ? lokasiController.text : '-'}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          buildTableSection('KELENGKAPAN PETUGAS', kelengkapanPetugas),
          pw.SizedBox(height: 12),
          buildTableSection('KELENGKAPAN SARANA', kelengkapanSarana),
          pw.SizedBox(height: 60),
          // Tanda tangan petugas dengan space lebih besar
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Petugas 1', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('(${petugas1Controller.text})', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Petugas 2', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('(${petugas2Controller.text})', style: pw.TextStyle(font: font, fontSize: 10)),
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        build: (context) => [
          buildTableSection('KELENGKAPAN KENDARAAN', kelengkapanKendaraan),
          pw.SizedBox(height: 16),
          pw.Text('Masa Berlaku', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              for (int i = 0; i < masaBerlakuController.length; i++) 
                i: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: masaBerlakuController.keys.map((k) => pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(
                    child: pw.Text(k, style: pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                )).toList(),
              ),
              pw.TableRow(
                children: masaBerlakuController.values.map((v) => pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(
                    child: pw.Text(v.text.isNotEmpty ? v.text : '-', style: pw.TextStyle(font: font, fontSize: 9)),
                  ),
                )).toList(),
              ),
            ],
          ),
          pw.SizedBox(height: 120), // Jarak besar sebelum TTD
          // Tanda tangan bawah dengan space lebih besar
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Text('Mengetahui,', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('PT JMTO', style: pw.TextStyle(font: fontBold, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Container(
                    width: 150,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Manager Traffic', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Diperiksa oleh,', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('PT JJC', style: pw.TextStyle(font: fontBold, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Container(
                    width: 150,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('NIK ...................', style: pw.TextStyle(font: font, fontSize: 10)),
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
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          build: (context) => [
            pw.Text('LAMPIRAN FOTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 16)),
            pw.SizedBox(height: 20),
            if (fotoStnk != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bukti STNK:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Image(pw.MemoryImage(fotoStnk!.readAsBytesSync()), width: 300, height: 200),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],
            if (fotoSim1 != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bukti SIM Operator 1:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Image(pw.MemoryImage(fotoSim1!.readAsBytesSync()), width: 300, height: 200),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],
            if (fotoSim2 != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bukti SIM Operator 2:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Image(pw.MemoryImage(fotoSim2!.readAsBytesSync()), width: 300, height: 200),
                    ),
                  ],
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Form Derek'),
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
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