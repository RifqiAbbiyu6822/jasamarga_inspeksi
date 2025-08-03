import 'package:flutter/material.dart';
import 'form_ambulance_screen.dart';
import 'form_derek_screen.dart';
import 'form_kamtib_screen.dart';
import 'form_plaza_screen.dart';
import 'form_rescue_screen.dart';

class KendaraanScreen extends StatefulWidget {
  const KendaraanScreen({super.key});

  @override
  State<KendaraanScreen> createState() => _KendaraanScreenState();
}

class _KendaraanScreenState extends State<KendaraanScreen> {
  final List<Map<String, dynamic>> vehicleTypes = [
    {
      'name': 'Ambulance',
      'icon': Icons.medical_services,
      'color': const Color(0xFFE74C3C),
    },
    {
      'name': 'Derek',
      'icon': Icons.car_repair,
      'color': const Color(0xFF3498DB),
    },
    {
      'name': 'Plaza',
      'icon': Icons.local_gas_station,
      'color': const Color(0xFF2ECC71),
    },
    {
      'name': 'Kamtib',
      'icon': Icons.security,
      'color': const Color(0xFF9B59B6),
    },
    {
      'name': 'Rescue',
      'icon': Icons.emergency,
      'color': const Color(0xFFF39C12),
    },
  ];

  String? selectedKategori;

  void navigateToForm(String kategori) {
    switch (kategori) {
      case 'Ambulance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormAmbulanceScreen()),
        );
        break;
      case 'Derek':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormDerekScreen()),
        );
        break;
      case 'Kamtib':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormKamtibScreen()),
        );
        break;
      case 'Plaza':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormPlazaScreen()),
        );
        break;
      case 'Rescue':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormRescueScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form untuk $kategori belum tersedia')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Pilih Jenis Kendaraan'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2257C1),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 48,
                  color: const Color(0xFF2257C1),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih jenis kendaraan yang akan diinspeksi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Vehicle Cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: vehicleTypes.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicleTypes[index];
                  final isSelected = selectedKategori == vehicle['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedKategori = vehicle['name'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? vehicle['color'] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? vehicle['color'] : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: vehicle['color'].withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            vehicle['icon'],
                            size: 48,
                            color: isSelected ? Colors.white : vehicle['color'],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vehicle['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedKategori != null
                      ? () => navigateToForm(selectedKategori!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBEC07),
                    foregroundColor: const Color(0xFF2257C1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}