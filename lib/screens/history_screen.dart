import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:jasamarga_inspeksi/screens/home_screen.dart';
import 'package:excel/excel.dart' as ex;
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_file/open_file.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box historyBox;
  String selectedMonth = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
  List<String> monthList = [];
  String searchQuery = '';
  String selectedJenis = 'Semua';
  final List<String> jenisKendaraan = ['Semua', 'Ambulance', 'Derek', 'Plaza', 'Kamtib', 'Rescue'];

  @override
  void initState() {
    super.initState();
    historyBox = Hive.box('inspection_history');
    _generateMonthList();
  }

  void _generateMonthList() {
    final all = historyBox.values.toList();
    final months = <String>{};
    for (var item in all) {
      if (item is Map && item['tanggal'] != null) {
        final dt = DateTime.tryParse(item['tanggal']);
        if (dt != null) {
          months.add(DateFormat('MMMM yyyy', 'id_ID').format(dt));
        }
      }
    }
    if (months.isEmpty) {
      months.add(DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()));
    }
    monthList = months.toList()..sort((a, b) {
      final dateA = DateFormat('MMMM yyyy', 'id_ID').parse(a);
      final dateB = DateFormat('MMMM yyyy', 'id_ID').parse(b);
      return dateB.compareTo(dateA);
    });
    selectedMonth = monthList.first;
  }

  List<Map> _getFilteredHistory() {
    return historyBox.values.where((item) {
      if (item is Map && item['tanggal'] != null) {
        final dt = DateTime.tryParse(item['tanggal']);
        final matchMonth = DateFormat('MMMM yyyy', 'id_ID').format(dt ?? DateTime.now()) == selectedMonth;
        final matchJenis = selectedJenis == 'Semua' || item['jenis'] == selectedJenis;
        final matchSearch = searchQuery.isEmpty ||
            (item['nopol'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
            (item['petugas1'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
            (item['petugas2'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());
        return matchMonth && matchJenis && matchSearch;
      }
      return false;
    }).cast<Map>().toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['tanggal'] ?? '');
        final dateB = DateTime.tryParse(b['tanggal'] ?? '');
        return (dateB ?? DateTime.now()).compareTo(dateA ?? DateTime.now());
      });
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'Ambulance':
        return const Color(0xFFE74C3C);
      case 'Derek':
        return const Color(0xFF3498DB);
      case 'Plaza':
        return const Color(0xFF2ECC71);
      case 'Kamtib':
        return const Color(0xFF9B59B6);
      case 'Rescue':
        return const Color(0xFFF39C12);
      default:
        return Colors.grey;
    }
  }

  IconData _getJenisIcon(String jenis) {
    switch (jenis) {
      case 'Ambulance':
        return Icons.medical_services;
      case 'Derek':
        return Icons.car_repair;
      case 'Plaza':
        return Icons.local_gas_station;
      case 'Kamtib':
        return Icons.security;
      case 'Rescue':
        return Icons.emergency;
      default:
        return Icons.directions_car;
    }
  }

  void _showDetailDialog(Map item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Inspeksi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getJenisColor(item['jenis'] ?? '').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getJenisIcon(item['jenis'] ?? ''),
                            size: 40,
                            color: _getJenisColor(item['jenis'] ?? ''),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['jenis'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item['nopol'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Informasi Detail
                    _buildDetailItem('Tanggal', _formatTanggal(item['tanggal'])),
                    _buildDetailItem('Petugas 1', item['petugas1'] ?? '-'),
                    _buildDetailItem('Petugas 2', item['petugas2'] ?? '-'),
                    if (item['lokasi'] != null && item['lokasi'].toString().isNotEmpty)
                      _buildDetailItem('Lokasi', item['lokasi']),

                    const SizedBox(height: 20),

                    // Tombol Aksi
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2257C1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _regeneratePDF(item);
                            },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Lihat PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _shareInspection(item);
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Bagikan'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Ringkasan Inspeksi
                    if (item['kelengkapanPetugas'] != null ||
                        item['kelengkapanSarana'] != null ||
                        item['kelengkapanKendaraan'] != null) ...[
                      const Text(
                        'Ringkasan Inspeksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInspectionSummary(item),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionSummary(Map item) {
    int totalAda = 0;
    int totalTidakAda = 0;
    int totalBaik = 0;
    int totalRR = 0;
    int totalRB = 0;

    void countItems(Map<String, dynamic>? items) {
      if (items != null) {
        items.forEach((key, value) {
          if (value is Map) {
            if (value['ada'] == true) {
              totalAda++;
            } else {
              totalTidakAda++;
            }

            if (value['kondisi'] == 'BAIK') {
              totalBaik++;
            } else if (value['kondisi'] == 'RR') totalRR++;
            else if (value['kondisi'] == 'RB') totalRB++;
          }
        });
      }
    }

    countItems(item['kelengkapanPetugas'] as Map<String, dynamic>?);
    countItems(item['kelengkapanSarana'] as Map<String, dynamic>?);
    countItems(item['kelengkapanKendaraan'] as Map<String, dynamic>?);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Ada', totalAda.toString(), Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard('Tidak Ada', totalTidakAda.toString(), Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Baik', totalBaik.toString(), Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard('RR', totalRR.toString(), Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard('RB', totalRB.toString(), Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null) return '-';
    final dt = DateTime.tryParse(tanggal);
    if (dt == null) return tanggal;
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dt);
  }

  Future<void> _regeneratePDF(Map item) async {
    // Generate PDF berdasarkan jenis kendaraan
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();
      final logoBytes = await rootBundle.load('assets/logo_jjc.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

      final tanggal = DateTime.tryParse(item['tanggal'] ?? '') ?? DateTime.now();
      final hariList = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final hari = hariList[tanggal.weekday % 7];

      // Create PDF based on vehicle type
      // This is a simplified version - you should implement the full PDF generation
      // based on each vehicle type's specific format

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
              pw.SizedBox(height: 20),
              pw.Text('Jenis: ${item['jenis'] ?? '-'}', style: pw.TextStyle(font: font)),
              pw.Text('No. Polisi: ${item['nopol'] ?? '-'}', style: pw.TextStyle(font: font)),
              pw.Text('Tanggal: $hari, ${tanggal.toLocal().toString().split(' ')[0]}', style: pw.TextStyle(font: font)),
              pw.Text('Petugas 1: ${item['petugas1'] ?? '-'}', style: pw.TextStyle(font: font)),
              pw.Text('Petugas 2: ${item['petugas2'] ?? '-'}', style: pw.TextStyle(font: font)),
              if (item['lokasi'] != null)
                pw.Text('Lokasi: ${item['lokasi']}', style: pw.TextStyle(font: font)),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  void _shareInspection(Map item) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur berbagi akan segera tersedia')),
    );
  }

  void _exportDialog(List<Map> filtered) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export ke Excel'),
              onTap: () async {
                Navigator.pop(context);
                await _exportExcel(filtered);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Export ke CSV'),
              onTap: () async {
                Navigator.pop(context);
                await _exportCSV(filtered);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export ke PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _exportPDF(filtered);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportExcel(List<Map> data) async {
    final excelFile = ex.Excel.createExcel();
    final sheet = excelFile['Rekap'];

    // Header
    sheet.appendRow([
      ex.TextCellValue('No'),
      ex.TextCellValue('Tanggal'),
      ex.TextCellValue('Hari'),
      ex.TextCellValue('Jenis'),
      ex.TextCellValue('No Polisi'),
      ex.TextCellValue('Petugas 1'),
      ex.TextCellValue('Petugas 2'),
      ex.TextCellValue('Lokasi'),
    ]);

    // Data
    int no = 1;
    for (var item in data) {
      final tanggal = DateTime.tryParse(item['tanggal'] ?? '');
      final hari = tanggal != null ? DateFormat('EEEE', 'id_ID').format(tanggal) : '-';

      sheet.appendRow([
        ex.TextCellValue(no.toString()),
        ex.TextCellValue(tanggal != null ? DateFormat('dd/MM/yyyy').format(tanggal) : '-'),
        ex.TextCellValue(hari),
        ex.TextCellValue(item['jenis'] ?? '-'),
        ex.TextCellValue(item['nopol'] ?? '-'),
        ex.TextCellValue(item['petugas1'] ?? '-'),
        ex.TextCellValue(item['petugas2'] ?? '-'),
        ex.TextCellValue(item['lokasi'] ?? '-'),
      ]);
      no++;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rekap_inspeksi_${selectedMonth.replaceAll(' ', '_')}.xlsx');
    await file.writeAsBytes(excelFile.encode()!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File Excel disimpan di ${file.path}'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    }
  }

  Future<void> _exportCSV(List<Map> data) async {
    final rows = <List<String>>[];
    rows.add(['No', 'Tanggal', 'Hari', 'Jenis', 'No Polisi', 'Petugas 1', 'Petugas 2', 'Lokasi']);

    int no = 1;
    for (var item in data) {
      final tanggal = DateTime.tryParse(item['tanggal'] ?? '');
      final hari = tanggal != null ? DateFormat('EEEE', 'id_ID').format(tanggal) : '-';

      rows.add([
        no.toString(),
        tanggal != null ? DateFormat('dd/MM/yyyy').format(tanggal) : '-',
        hari,
        item['jenis'] ?? '-',
        item['nopol'] ?? '-',
        item['petugas1'] ?? '-',
        item['petugas2'] ?? '-',
        item['lokasi'] ?? '-',
      ]);
      no++;
    }

    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rekap_inspeksi_${selectedMonth.replaceAll(' ', '_')}.csv');
    await file.writeAsString(csvStr);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File CSV disimpan di ${file.path}'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    }
  }

  Future<void> _exportPDF(List<Map> data) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/logo_jjc.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Row(
            children: [
              pw.Image(logo, width: 60),
              pw.SizedBox(width: 16),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rekap Inspeksi Bulan $selectedMonth',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text('PT Jasamarga Jalanlayang Cikampek'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['No', 'Tanggal', 'Hari', 'Jenis', 'No Polisi', 'Petugas 1', 'Petugas 2', 'Lokasi'],
            data: data.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              final tanggal = DateTime.tryParse(item['tanggal'] ?? '');
              final hari = tanggal != null ? DateFormat('EEEE', 'id_ID').format(tanggal) : '-';

              return [
                index.toString(),
                tanggal != null ? DateFormat('dd/MM/yyyy').format(tanggal) : '-',
                hari,
                item['jenis'] ?? '-',
                item['nopol'] ?? '-',
                item['petugas1'] ?? '-',
                item['petugas2'] ?? '-',
                item['lokasi'] ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 28,
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rekap_inspeksi_${selectedMonth.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File PDF disimpan di ${file.path}'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredHistory();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Riwayat Inspeksi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2257C1)),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF2257C1)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Informasi'),
                  content: const Text(
                    'Riwayat inspeksi menampilkan semua hasil inspeksi yang telah dilakukan. '
                        'Anda dapat melihat detail, mencetak ulang PDF, atau mengekspor data.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan Logo
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              children: [
                Image.asset('assets/logo_jjc.png', height: 50),
                const SizedBox(height: 8),
                Text(
                  'Total ${filtered.length} inspeksi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan no. polisi atau petugas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Row
                Row(
                  children: [
                    // Bulan Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedMonth,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.calendar_month),
                          items: monthList.map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m),
                          )).toList(),
                          onChanged: (val) => setState(() => selectedMonth = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Jenis Kendaraan Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedJenis,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.directions_car),
                          items: jenisKendaraan.map((j) => DropdownMenuItem(
                            value: j,
                            child: Text(j),
                          )).toList(),
                          onChanged: (val) => setState(() => selectedJenis = val!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Export Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEBEC07),
                      foregroundColor: const Color(0xFF2257C1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.download),
                    label: Text('Export ${filtered.length} Data'),
                    onPressed: filtered.isEmpty ? null : () => _exportDialog(filtered),
                  ),
                ),
              ],
            ),
          ),

          // List Section
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data inspeksi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'untuk filter yang dipilih',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];
                final jenis = item['jenis'] ?? '-';
                final tanggal = DateTime.tryParse(item['tanggal'] ?? '');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showDetailDialog(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Icon Container
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getJenisColor(jenis).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getJenisIcon(jenis),
                              color: _getJenisColor(jenis),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getJenisColor(jenis),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        jenis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['nopol'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tanggal != null
                                      ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tanggal)
                                      : '-',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${item['petugas1'] ?? '-'}, ${item['petugas2'] ?? '-'}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item['lokasi'] != null && item['lokasi'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item['lokasi'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Arrow
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}