import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:jasamarga_inspeksi/screens/home_screen.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box historyBox;
  String selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  List<String> monthList = [];

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
          months.add(DateFormat('MMMM yyyy').format(dt));
        }
      }
    }
    if (months.isEmpty) {
      months.add(DateFormat('MMMM yyyy').format(DateTime.now()));
    }
    monthList = months.toList()..sort((a, b) => b.compareTo(a));
    selectedMonth = monthList.first;
  }

  List<Map> _getFilteredHistory() {
    return historyBox.values.where((item) {
      if (item is Map && item['tanggal'] != null) {
        final dt = DateTime.tryParse(item['tanggal']);
        return DateFormat('MMMM yyyy').format(dt ?? DateTime.now()) == selectedMonth;
      }
      return false;
    }).cast<Map>().toList();
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
    final excel = Excel.createExcel();
    final sheet = excel['Rekap'];
    sheet.appendRow(['Tanggal', 'Jenis', 'No Polisi', 'Petugas 1', 'Petugas 2']);
    for (var item in data) {
      sheet.appendRow([
        item['tanggal'] ?? '',
        item['jenis'] ?? '',
        item['nopol'] ?? '',
        item['petugas1'] ?? '',
        item['petugas2'] ?? '',
      ]);
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rekap_inspeksi_${selectedMonth.replaceAll(' ', '_')}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File Excel disimpan di ${file.path}')));
  }

  Future<void> _exportCSV(List<Map> data) async {
    final rows = <List<String>>[];
    rows.add(['Tanggal', 'Jenis', 'No Polisi', 'Petugas 1', 'Petugas 2']);
    for (var item in data) {
      rows.add([
        item['tanggal'] ?? '',
        item['jenis'] ?? '',
        item['nopol'] ?? '',
        item['petugas1'] ?? '',
        item['petugas2'] ?? '',
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rekap_inspeksi_${selectedMonth.replaceAll(' ', '_')}.csv');
    await file.writeAsString(csvStr);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File CSV disimpan di ${file.path}')));
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
                  pw.Text('Rekap Inspeksi Bulan $selectedMonth', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text('PT Jasamarga Jalanlayang Cikampek'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Jenis', 'No Polisi', 'Petugas 1', 'Petugas 2'],
            data: data.map((item) => [
              item['tanggal'] ?? '',
              item['jenis'] ?? '',
              item['nopol'] ?? '',
              item['petugas1'] ?? '',
              item['petugas2'] ?? '',
            ]).toList(),
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File PDF disimpan di ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredHistory();
    return Scaffold(
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Image.asset('assets/logo_jjc.png', height: 60),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Bulan:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedMonth,
                  items: monthList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => selectedMonth = val!),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBEC07),
                    foregroundColor: const Color(0xFF2257C1),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  onPressed: filtered.isEmpty ? null : () => _exportDialog(filtered),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Belum ada riwayat inspeksi bulan ini'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text('${item['jenis'] ?? '-'} | ${item['nopol'] ?? '-'}'),
                        subtitle: Text('Tanggal: ${item['tanggal'] ?? '-'}\nPetugas: ${item['petugas1'] ?? '-'}, ${item['petugas2'] ?? '-'}'),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF2257C1)),
                        onTap: () {
                          // TODO: Show detail inspeksi
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Model data inspeksi (untuk referensi)
// {
//   'jenis': 'Ambulance',
//   'tanggal': '2024-06-13',
//   'nopol': 'B 1234 CD',
//   'petugas1': 'Andi',
//   'petugas2': 'Budi',
//   ...
// } 