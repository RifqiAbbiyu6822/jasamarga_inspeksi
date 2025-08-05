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
      final logoBytes = await rootBundle.load('assets/logo_jjc.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final hariList = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final hari = hariList[tanggal.weekday % 7];

      // Halaman 1 - Header, Kelengkapan Petugas, dan Tanda Tangan Petugas 1
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          maxPages: 1,
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2, color: PdfColors.black),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logo, width: 50, height: 50),
                      pw.SizedBox(width: 15),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PT JASAMARGA JALAN CONCESSIONAIRE', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 14)),
                            pw.Text('FORM INSPEKSI KENDARAAN RESCUE', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                            pw.Text('HARI: $hari | TANGGAL: ${tanggal.toLocal().toString().split(' ')[0]}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                            pw.Text('NO. POLISI: ${nopolController.text} | IDENTITAS: ${identitasKendaraanController.text}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                            pw.Text('LOKASI: ${lokasiController.text.isNotEmpty ? lokasiController.text : '-'}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            
            buildTableSection('KELENGKAPAN PETUGAS', kelengkapanPetugas),
            pw.SizedBox(height: 15),
            
            // Tanda tangan - Hanya Petugas 1
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 100,
                      height: 40,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Petugas 1', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.Text('(${petugas1Controller.text})', style: pw.TextStyle(font: font, fontSize: 7)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Halaman 2 - Kelengkapan Sarana, Kelengkapan Kendaraan, Masa Berlaku Dokumen, dan Tanda Tangan lainnya
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          maxPages: 2,
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2, color: PdfColors.black),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logo, width: 50, height: 50),
                      pw.SizedBox(width: 15),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PT JASAMARGA JALAN CONCESSIONAIRE', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 14)),
                            pw.Text('FORM INSPEKSI KENDARAAN RESCUE', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                            pw.Text('HARI: $hari | TANGGAL: ${tanggal.toLocal().toString().split(' ')[0]}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                            pw.Text('NO. POLISI: ${nopolController.text} | IDENTITAS: ${identitasKendaraanController.text}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                            pw.Text('LOKASI: ${lokasiController.text.isNotEmpty ? lokasiController.text : '-'}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            
            buildTableSection('KELENGKAPAN SARANA', kelengkapanSarana),
          ],
        ),
      );

      // Halaman 3 - Kelengkapan Kendaraan, Masa Berlaku Dokumen, dan Tanda Tangan Manager
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          maxPages: 2,
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2, color: PdfColors.black),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logo, width: 50, height: 50),
                      pw.SizedBox(width: 15),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PT JASAMARGA JALAN CONCESSIONAIRE', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 14)),
                            pw.Text('FORM INSPEKSI KENDARAAN RESCUE', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
                            pw.Text('HARI: $hari | TANGGAL: ${tanggal.toLocal().toString().split(' ')[0]}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                            pw.Text('NO. POLISI: ${nopolController.text} | IDENTITAS: ${identitasKendaraanController.text}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                            pw.Text('LOKASI: ${lokasiController.text.isNotEmpty ? lokasiController.text : '-'}', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            
            buildTableSection('KELENGKAPAN KENDARAAN', kelengkapanKendaraan),
            pw.SizedBox(height: 15),
            
            // Masa Berlaku Dokumen
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1, color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MASA BERLAKU DOKUMEN', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 11)),
                  pw.SizedBox(height: 6),
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
                            child: pw.Text(k, style: pw.TextStyle(font: fontBold, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ),
                        )).toList(),
                      ),
                      pw.TableRow(
                        children: masaBerlakuController.values.map((v) => pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Center(
                            child: pw.Text(v.text.isNotEmpty ? v.text : '-', style: pw.TextStyle(font: font, fontSize: 8)),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            
            // Tanda tangan - PT JMTO Manager Traffic dan PT.JJC
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Mengetahui,', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('PT JMTO', style: pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 100,
                      height: 40,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Manager Traffic', style: pw.TextStyle(font: font, fontSize: 7)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Mengetahui,', style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('PT.JJC', style: pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 100,
                      height: 40,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('NIK', style: pw.TextStyle(font: font, fontSize: 7)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Halaman 4 - Lampiran
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
              margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 20),
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
        'jenis': 'Rescue',
        'tanggal': tanggal.toIso8601String(),
        'nopol': nopolController.text,
        'petugas1': petugas1Controller.text,
        'petugas2': petugas2Controller.text,
        'lokasi': lokasiController.text,
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

  pw.Widget buildTableSection(String title, Map<String, Map<String, dynamic>> dataMap) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 12)),
        pw.SizedBox(height: 10),
        pw.Table(
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
        ),
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
              
              // Checklist sections
              buildChecklist('Kelengkapan Petugas', kelengkapanPetugas),
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

