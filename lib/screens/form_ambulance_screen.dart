import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signature/signature.dart';

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
  final TextEditingController lokasiController = TextEditingController();
  DateTime tanggal = DateTime.now();

  // Controller untuk foto bukti
  final ImagePicker _picker = ImagePicker();
  File? fotoStnk;
  File? fotoSim1;
  File? fotoSim2;
  File? fotoKir;
  File? fotoSertifikatParamedis;
  File? fotoService;
  File? fotoBbm;
  String? currentLocation;

  // Signature controllers
  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // Variables to store signatures
  Uint8List? petugas1Signature;
  Uint8List? petugas2Signature;
  Uint8List? managerSignature;
  Uint8List? jjcSignature;

  final List<String> kondisiOptions = ['BAIK', 'RR', 'RB', 'TIDAK ADA'];



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
    signatureController.dispose();
    for (var c in masaBerlakuController.values) {
      c.dispose();
    }
    for (var map in [kelengkapanSarana, kelengkapanKendaraan]) {
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

  // Method untuk menangani signature
  Future<void> handleSignature(String type) async {
    try {
      final signature = await signatureController.toPngBytes();
      if (signature != null) {
        setState(() {
          switch (type) {
            case 'petugas1':
              petugas1Signature = signature;
              break;
            case 'petugas2':
              petugas2Signature = signature;
              break;
            case 'manager':
              managerSignature = signature;
              break;
            case 'jjc':
              jjcSignature = signature;
              break;
          }
        });
        signatureController.clear();
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menyimpan tanda tangan: $e')),
      );
    }
  }

  // Method untuk menampilkan dialog signature
  void showSignatureDialog(String type, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 300,
            height: 200,
            child: Signature(
              controller: signatureController,
              backgroundColor: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => handleSignature(type),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
            case 'sertifikatParamedis':
              fotoSertifikatParamedis = File(image.path);
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
            }),
          ],
        ),
      ),
    );
  }

  void generatePdf() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Membuat PDF...'),
            ],
          ),
        );
      },
    );

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();
      final hariList = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final hari = hariList[tanggal.weekday % 7];
      final logoBytes = await rootBundle.load('assets/logo_jjc.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

      pw.Widget buildTableSection(String sectionTitle, Map<String, Map<String, dynamic>> dataMap) {
        int idx = 1;
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header section tanpa border
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(sectionTitle, 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10)),
              ),
              pw.SizedBox(height: 4),
              // Tabel tanpa border dan lebih compact
              pw.Table(
                border: pw.TableBorder.all(width: 0), // Menghilangkan semua border dengan width 0
                columnWidths: {
                  0: const pw.FixedColumnWidth(20),  // No - diperkecil
                  1: const pw.FlexColumnWidth(2.5), // Uraian - diperbesar untuk readability
                  2: const pw.FixedColumnWidth(25), // Ada
                  3: const pw.FixedColumnWidth(25), // Tidak
                  4: const pw.FixedColumnWidth(30), // Jumlah
                  5: const pw.FixedColumnWidth(25), // Baik
                  6: const pw.FixedColumnWidth(25), // RR
                  7: const pw.FixedColumnWidth(25), // RB
                },
                children: [
                  // Header row dengan background abu-abu muda
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                        child: pw.Center(child: pw.Text('NO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 7))),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                        child: pw.Center(child: pw.Text('URAIAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 7))),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Center(child: pw.Text('ADA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 7))),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Center(child: pw.Text('TIDAK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 6))),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Center(child: pw.Text('JUMLAH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 6))),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Center(child: pw.Text('BAIK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 7))),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Center(child: pw.Text('RR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 7))),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Center(child: pw.Text('RB', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 7))),
                      ),
                    ],
                  ),
                  // Data rows dengan alternating background untuk readability
                  ...dataMap.entries.map((entry) {
                    final no = idx++;
                    final ada = entry.value['ada'] == true;
                    final kondisi = entry.value['kondisi'] ?? '';
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: no % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                          child: pw.Center(child: pw.Text(no.toString(), style: pw.TextStyle(font: font, fontSize: 7))),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: pw.Text(entry.key, style: pw.TextStyle(font: font, fontSize: 7)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Center(
                            child: ada 
                              ? pw.Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.black,
                                    shape: pw.BoxShape.circle,
                                  ),
                                )
                              : pw.SizedBox(width: 8, height: 8),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Center(
                            child: !ada 
                              ? pw.Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.black,
                                    shape: pw.BoxShape.circle,
                                  ),
                                )
                              : pw.SizedBox(width: 8, height: 8),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                          child: pw.Center(
                            child: pw.Text(
                              (entry.value['jumlah'] as TextEditingController).text.isNotEmpty 
                                ? (entry.value['jumlah'] as TextEditingController).text 
                                : '-',
                              style: pw.TextStyle(font: font, fontSize: 6),
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Center(
                            child: kondisi == 'BAIK' 
                              ? pw.Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.black,
                                    shape: pw.BoxShape.circle,
                                  ),
                                )
                              : pw.SizedBox(width: 8, height: 8),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Center(
                            child: kondisi == 'RR' 
                              ? pw.Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.black,
                                    shape: pw.BoxShape.circle,
                                  ),
                                )
                              : pw.SizedBox(width: 8, height: 8),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Center(
                            child: kondisi == 'RB' 
                              ? pw.Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.black,
                                    shape: pw.BoxShape.circle,
                                  ),
                                )
                              : pw.SizedBox(width: 8, height: 8),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      }

      // Halaman 1 - Header, Kelengkapan Sarana, dan Tanda Tangan Petugas 1
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 10),
          maxPages: 1,
          build: (context) => [
            // Header yang lebih compact
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1.5, color: PdfColors.black),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logo, width: 80, height: 80),
                      pw.SizedBox(width: 15),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PT JASAMARGA JALANLAYANG CIKAMPEK', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                            pw.Text('FORM INSPEKSI KENDARAAN AMBULANCE', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10)),
                            pw.Text('HARI: $hari | TANGGAL: ${tanggal.toLocal().toString().split(' ')[0]}', 
                              style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('NO. POLISI: ${nopolController.text} | IDENTITAS: ${identitasKendaraanController.text}', 
                              style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('LOKASI: ${lokasiController.text.isNotEmpty ? lokasiController.text : '-'}', 
                              style: pw.TextStyle(font: font, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            
            // Kelengkapan Sarana
            buildTableSection('KELENGKAPAN SARANA', kelengkapanSarana),
            pw.SizedBox(height: 8),
            
            // Tanda tangan - Hanya Petugas 1
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Column(
                  children: [
                    petugas1Signature != null 
                      ? pw.Image(pw.MemoryImage(petugas1Signature!), width: 80, height: 30)
                      : pw.Container(
                          width: 80,
                          height: 30,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(width: 1)),
                          ),
                        ),
                    pw.SizedBox(height: 4),
                    pw.Text('Petugas 1', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                    pw.Text('(${petugas1Controller.text})', style: pw.TextStyle(font: font, fontSize: 6)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Halaman 2 - Kelengkapan Kendaraan dan Masa Berlaku Dokumen (jika diperlukan)
      if (kelengkapanKendaraan.isNotEmpty || masaBerlakuController.values.any((controller) => controller.text.isNotEmpty)) {
        pdf.addPage(
          pw.MultiPage(
            margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 10),
            maxPages: 1,
            build: (context) => [
              // Header yang sama
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1.5, color: PdfColors.black),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Image(logo, width: 80, height: 80),
                        pw.SizedBox(width: 15),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('PT JASAMARGA JALANLAYANG CIKAMPEK', 
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                              pw.Text('FORM INSPEKSI KENDARAAN AMBULANCE', 
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10)),
                              pw.Text('HARI: $hari | TANGGAL: ${tanggal.toLocal().toString().split(' ')[0]}', 
                                style: pw.TextStyle(font: font, fontSize: 8)),
                              pw.Text('NO. POLISI: ${nopolController.text} | IDENTITAS: ${identitasKendaraanController.text}', 
                                style: pw.TextStyle(font: font, fontSize: 8)),
                              pw.Text('LOKASI: ${lokasiController.text.isNotEmpty ? lokasiController.text : '-'}', 
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              
              // Kelengkapan Kendaraan
              buildTableSection('KELENGKAPAN KENDARAAN', kelengkapanKendaraan),
              pw.SizedBox(height: 8),
              
              // Masa Berlaku Dokumen yang lebih compact
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5, color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MASA BERLAKU DOKUMEN', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Table(
                      border: pw.TableBorder.all(width: 0),
                      columnWidths: {
                        for (int i = 0; i < masaBerlakuController.length; i++) 
                          i: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: masaBerlakuController.keys.map((k) => pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                            child: pw.Center(
                              child: pw.Text(k, style: pw.TextStyle(font: fontBold, fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            ),
                          )).toList(),
                        ),
                        pw.TableRow(
                          children: masaBerlakuController.values.map((v) => pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                            child: pw.Center(
                              child: pw.Text(v.text.isNotEmpty ? v.text : '-', style: pw.TextStyle(font: font, fontSize: 7)),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              
              // Tanda tangan PT JMTO Manager Traffic dan PT JJC - diposisikan lebih ke tengah
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 50),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tanda tangan PT JMTO Manager Traffic
                    pw.Column(
                      children: [
                        pw.Text('Mengetahui,', style: pw.TextStyle(font: font, fontSize: 8)),
                        pw.Text('PT JMTO', style: pw.TextStyle(font: fontBold, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        managerSignature != null 
                          ? pw.Image(pw.MemoryImage(managerSignature!), width: 100, height: 35)
                          : pw.Container(
                              width: 100,
                              height: 35,
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(width: 1)),
                              ),
                            ),
                        pw.SizedBox(height: 4),
                        pw.Text('Manager Traffic', style: pw.TextStyle(font: font, fontSize: 6)),
                      ],
                    ),
                    // Tanda tangan PT JJC dengan NIK
                    pw.Column(
                      children: [
                        pw.Text('Mengetahui,', style: pw.TextStyle(font: font, fontSize: 8)),
                        pw.Text('PT.JJC', style: pw.TextStyle(font: fontBold, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        jjcSignature != null 
                          ? pw.Image(pw.MemoryImage(jjcSignature!), width: 100, height: 35)
                          : pw.Container(
                              width: 100,
                              height: 35,
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(width: 1)),
                              ),
                            ),
                        pw.SizedBox(height: 4),
                        pw.Text('NIK', style: pw.TextStyle(font: font, fontSize: 6)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }



              // Halaman 3 - Lampiran (jika ada foto)
        if (fotoStnk != null || fotoSim1 != null || fotoSim2 != null || fotoKir != null || 
            fotoSertifikatParamedis != null || fotoService != null || fotoBbm != null) {
          
          // Buat list foto yang ada
          List<Map<String, dynamic>> fotoList = [];
          if (fotoStnk != null) fotoList.add({'title': 'Bukti STNK:', 'file': fotoStnk});
          if (fotoSim1 != null) fotoList.add({'title': 'Bukti SIM Operator 1:', 'file': fotoSim1});
          if (fotoSim2 != null) fotoList.add({'title': 'Bukti SIM Operator 2:', 'file': fotoSim2});
          if (fotoKir != null) fotoList.add({'title': 'Bukti KIR:', 'file': fotoKir});
          if (fotoSertifikatParamedis != null) fotoList.add({'title': 'Bukti Sertifikat Paramedis:', 'file': fotoSertifikatParamedis});
          if (fotoService != null) fotoList.add({'title': 'Bukti Service:', 'file': fotoService});
          if (fotoBbm != null) fotoList.add({'title': 'Bukti BBM:', 'file': fotoBbm});

          // Bagi foto menjadi halaman dengan maksimal 3 foto per halaman
          for (int i = 0; i < fotoList.length; i += 3) {
            List<Map<String, dynamic>> pageFotos = fotoList.skip(i).take(3).toList();
            
            pdf.addPage(
              pw.MultiPage(
                margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                build: (context) => [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Text('LAMPIRAN FOTO BUKTI', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 16)),
                  ),
                  pw.SizedBox(height: 15),
                  ...pageFotos.map((foto) => [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1, color: PdfColors.grey400),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(foto['title'], 
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                          pw.SizedBox(height: 8),
                          pw.Center(
                            child: pw.Image(pw.MemoryImage(foto['file'].readAsBytesSync()), width: 200, height: 150),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ]).expand((element) => element).toList(),
                ],
              ),
            );
          }
        }

      // Generate and print PDF with delay
      await Future.delayed(const Duration(milliseconds: 500));
      await Printing.layoutPdf(onLayout: (format) => pdf.save());

      // Dismiss loading dialog after successful PDF generation
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Simpan riwayat inspeksi ke Hive
      final box = Hive.box('inspection_history');
      box.add({
        'jenis': 'Ambulance',
        'tanggal': tanggal.toIso8601String(),
        'nopol': nopolController.text,
        'petugas1': petugas1Controller.text,
        'petugas2': petugas2Controller.text,
        'lokasi': lokasiController.text,

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

      // Navigate to success screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      }
    } catch (e) {
      // Dismiss loading dialog if error occurs
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Form Ambulance'),
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
              
              // Checklist sections
              buildChecklist('Kelengkapan Sarana', kelengkapanSarana),
              buildChecklist('Kelengkapan Kendaraan', kelengkapanKendaraan),
              buildMasaBerlakuFields(),
              
              const SizedBox(height: 16),
              
              // Card Foto Bukti - Dipindah ke bawah
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Foto Bukti Dokumen',
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fotoSertifikatParamedis != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: fotoSertifikatParamedis != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await pickImage('sertifikatParamedis');
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: Icon(fotoSertifikatParamedis != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fotoSertifikatParamedis != null ? 'Sertifikat Paramedis ✓' : 'Foto Sertifikat Paramedis'),
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
              
              // Card Tanda Tangan Digital
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanda Tangan Digital',
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
                                backgroundColor: petugas1Signature != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: petugas1Signature != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => showSignatureDialog('petugas1', 'Tanda Tangan Petugas 1'),
                              icon: Icon(petugas1Signature != null ? Icons.check_circle : Icons.edit),
                              label: Text(petugas1Signature != null ? 'Petugas 1 ✓' : 'Tanda Tangan Petugas 1'),
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
                                backgroundColor: managerSignature != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: managerSignature != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => showSignatureDialog('manager', 'Tanda Tangan Manager Traffic'),
                              icon: Icon(managerSignature != null ? Icons.check_circle : Icons.edit),
                              label: Text(managerSignature != null ? 'Manager Traffic ✓' : 'Tanda Tangan Manager Traffic'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: jjcSignature != null ? Colors.green : const Color(0xFFEBEC07),
                                foregroundColor: jjcSignature != null ? Colors.white : const Color(0xFF2257C1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => showSignatureDialog('jjc', 'Tanda Tangan PT JJC'),
                              icon: Icon(jjcSignature != null ? Icons.check_circle : Icons.edit),
                              label: Text(jjcSignature != null ? 'PT JJC ✓' : 'Tanda Tangan PT JJC'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
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


