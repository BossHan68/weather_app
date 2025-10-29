import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Islamic Companion",
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const SalahadScreen(),
      routes: {'/salahad': (context) => const SalahadScreen()},
    );
  }
}

// Main Screen with Bottom Navigation
class SalahadScreen extends StatefulWidget {
  const SalahadScreen({super.key});

  @override
  State<SalahadScreen> createState() => _SalahadScreenState();
}

class _SalahadScreenState extends State<SalahadScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const PrayerTimesScreen(),
    const QiblaCompassScreen(),
    const TasbihScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              label: 'Prayer Times',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Qibla'),
            BottomNavigationBarItem(
              icon: Icon(Icons.radio_button_checked),
              label: 'Tasbih',
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Prayer Times Screen =================
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with TickerProviderStateMixin {
  Map<String, String> prayerTimes = {};
  bool isLoading = true;
  String? errorMsg;
  Position? currentPosition;
  String currentCity = "";
  String currentDate = "";
  late AnimationController _refreshController;

  String selectedCity = "Hat Yai";
  String selectedCountry = "Thailand";

  final List<Map<String, String>> cityOptions = [
    {"city": "Bangkok", "country": "Thailand", "thaiName": "กรุงเทพมหานคร"},
    {"city": "Chiang Mai", "country": "Thailand", "thaiName": "เชียงใหม่"},
    {"city": "Chiang Rai", "country": "Thailand", "thaiName": "เชียงราย"},
    {"city": "Nakhon Ratchasima", "country": "Thailand", "thaiName": "นครราชสีมา"},
    {"city": "Khon Kaen", "country": "Thailand", "thaiName": "ขอนแก่น"},
    {"city": "Udon Thani", "country": "Thailand", "thaiName": "อุดรธานี"},
    {"city": "Ubon Ratchathani", "country": "Thailand", "thaiName": "อุบลราชธานี"},
    {"city": "Nakhon Si Thammarat", "country": "Thailand", "thaiName": "นครศรีธรรมราช"},
    {"city": "Phuket", "country": "Thailand", "thaiName": "ภูเก็ต"},
    {"city": "Hat Yai", "country": "Thailand", "thaiName": "หาดใหญ่"},
    {"city": "Songkhla", "country": "Thailand", "thaiName": "สงขลา"},
    {"city": "Pattani", "country": "Thailand", "thaiName": "ปัตตานี"},
    {"city": "Yala", "country": "Thailand", "thaiName": "ยะลา"},
    {"city": "Narathiwat", "country": "Thailand", "thaiName": "นราธิวาส"},
    {"city": "Satun", "country": "Thailand", "thaiName": "สตูล"},
    {"city": "Surat Thani", "country": "Thailand", "thaiName": "สุราษฎร์ธานี"},
    {"city": "Krabi", "country": "Thailand", "thaiName": "กระบี่"},
    {"city": "Phangnga", "country": "Thailand", "thaiName": "พังงา"},
    {"city": "Ranong", "country": "Thailand", "thaiName": "ระนอง"},
    {"city": "Chumphon", "country": "Thailand", "thaiName": "ชุมพร"},
    {"city": "Prachuap Khiri Khan", "country": "Thailand", "thaiName": "ประจวบคีรีขันธ์"},
    {"city": "Phetchaburi", "country": "Thailand", "thaiName": "เพชรบุรี"},
    {"city": "Ratchaburi", "country": "Thailand", "thaiName": "ราชบุรี"},
    {"city": "Kanchanaburi", "country": "Thailand", "thaiName": "กาญจนบุรี"},
    {"city": "Suphan Buri", "country": "Thailand", "thaiName": "สุพรรณบุรี"},
    {"city": "Nakhon Pathom", "country": "Thailand", "thaiName": "นครปฐม"},
    {"city": "Samut Sakhon", "country": "Thailand", "thaiName": "สมุทรสาคร"},
    {"city": "Samut Songkhram", "country": "Thailand", "thaiName": "สมุทรสงคราม"},
    {"city": "Samut Prakan", "country": "Thailand", "thaiName": "สมุทรปราการ"},
    {"city": "Nonthaburi", "country": "Thailand", "thaiName": "นนทบุรี"},
    {"city": "Pathum Thani", "country": "Thailand", "thaiName": "ปทุมธานี"},
    {"city": "Ayutthaya", "country": "Thailand", "thaiName": "พระนครศรีอยุธยา"},
    {"city": "Lopburi", "country": "Thailand", "thaiName": "ลพบุรี"},
    {"city": "Saraburi", "country": "Thailand", "thaiName": "สระบุรี"},
    {"city": "Nakhon Nayok", "country": "Thailand", "thaiName": "นครนายก"},
    {"city": "Prachuap", "country": "Thailand", "thaiName": "ประจวบ"},
    {"city": "Chonburi", "country": "Thailand", "thaiName": "ชลบุรี"},
    {"city": "Rayong", "country": "Thailand", "thaiName": "ระยอง"},
    {"city": "Chanthaburi", "country": "Thailand", "thaiName": "จันทบุรี"},
    {"city": "Trat", "country": "Thailand", "thaiName": "ตราด"},
    {"city": "Sa Kaeo", "country": "Thailand", "thaiName": "สระแก้ว"},
    {"city": "Nakhon Sawan", "country": "Thailand", "thaiName": "นครสวรรค์"},
    {"city": "Uthai Thani", "country": "Thailand", "thaiName": "อุทัยธานี"},
    {"city": "Chainat", "country": "Thailand", "thaiName": "ชัยนาท"},
    {"city": "Singburi", "country": "Thailand", "thaiName": "สิงห์บุรี"},
    {"city": "Angthong", "country": "Thailand", "thaiName": "อ่างทอง"},
    {"city": "Phitsanulok", "country": "Thailand", "thaiName": "พิษณุโลก"},
    {"city": "Phichit", "country": "Thailand", "thaiName": "พิจิตร"},
    {"city": "Kamphaeng Phet", "country": "Thailand", "thaiName": "กำแพงเพชร"},
    {"city": "Tak", "country": "Thailand", "thaiName": "ตาก"},
    {"city": "Sukhothai", "country": "Thailand", "thaiName": "สุโขทัย"},
    {"city": "Uttaradit", "country": "Thailand", "thaiName": "อุตรดิตถ์"},
    {"city": "Phrae", "country": "Thailand", "thaiName": "แพร่"},
    {"city": "Nan", "country": "Thailand", "thaiName": "น่าน"},
    {"city": "Phayao", "country": "Thailand", "thaiName": "พะเยา"},
    {"city": "Lampang", "country": "Thailand", "thaiName": "ลำปาง"},
    {"city": "Lamphun", "country": "Thailand", "thaiName": "ลำพูน"},
    {"city": "Mae Hong Son", "country": "Thailand", "thaiName": "แม่ฮ่องสอน"},
    {"city": "Loei", "country": "Thailand", "thaiName": "เลย"},
    {"city": "Nong Khai", "country": "Thailand", "thaiName": "หนองคาย"},
    {"city": "Nong Bua Lam Phu", "country": "Thailand", "thaiName": "หนองบัวลำภู"},
    {"city": "Sakon Nakhon", "country": "Thailand", "thaiName": "สกลนคร"},
    {"city": "Nakhon Phanom", "country": "Thailand", "thaiName": "นครพนม"},
    {"city": "Mukdahan", "country": "Thailand", "thaiName": "มุกดาหาร"},
    {"city": "Kalasin", "country": "Thailand", "thaiName": "กาฬสินธุ์"},
    {"city": "Roi Et", "country": "Thailand", "thaiName": "ร้อยเอ็ด"},
    {"city": "Maha Sarakham", "country": "Thailand", "thaiName": "มหาสารคาม"},
    {"city": "Yasothon", "country": "Thailand", "thaiName": "ยโสธร"},
    {"city": "Amnat Charoen", "country": "Thailand", "thaiName": "อำนาจเจริญ"},
    {"city": "Sisaket", "country": "Thailand", "thaiName": "ศรีสะเกษ"},
    {"city": "Surin", "country": "Thailand", "thaiName": "สุรินทร์"},
    {"city": "Buriram", "country": "Thailand", "thaiName": "บุรีรัมย์"},
    {"city": "Chaiyaphum", "country": "Thailand", "thaiName": "ชัยภูมิ"},
    {"city": "Phatthalung", "country": "Thailand", "thaiName": "พัทลุง"},
    {"city": "Trang", "country": "Thailand", "thaiName": "ตรัง"},
  ];

  List<Map<String, String>> filteredCities = [];
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCities = cityOptions;
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _getLocationAndPrayerTimes();
    _updateCurrentDate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _updateCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    currentDate = "${now.day} ${months[now.month - 1]} ${now.year}";
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCities = cityOptions;
        isSearching = false;
      } else {
        final lowerQuery = query.toLowerCase();
        filteredCities = cityOptions.where((city) {
          return city["city"]!.toLowerCase().contains(lowerQuery) ||
                 city["thaiName"]!.contains(query) ||
                 city["country"]!.toLowerCase().contains(lowerQuery);
        }).toList();
        isSearching = true;
      }
    });
  }

  Future<void> _refreshPrayerTimes() async {
    _refreshController.forward();
    await _getLocationAndPrayerTimes();
    await _refreshController.reverse();
  }

  Future<void> _getLocationAndPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMsg = "Location service is disabled";
          currentCity = selectedCity;
        });
        await _fetchPrayerTimes();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          errorMsg = "Location permission denied";
          currentCity = selectedCity;
        });
        await _fetchPrayerTimes();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        currentPosition = position;
        currentCity = selectedCity;
      });

      await _fetchPrayerTimes();
    } catch (e) {
      setState(() {
        errorMsg = "Error: ${e.toString()}";
        currentCity = selectedCity;
      });
      await _fetchPrayerTimes();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      final today = DateTime.now();
      final url =
          "https://api.aladhan.com/v1/calendarByCity?city=$selectedCity&country=$selectedCountry&method=2&month=${today.month}&year=${today.year}";
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data["data"][today.day - 1]["timings"];

        setState(() {
          prayerTimes = {
            "Fajr": timings["Fajr"],
            "Dhuhr": timings["Dhuhr"],
            "Asr": timings["Asr"],
            "Maghrib": timings["Maghrib"],
            "Isha": timings["Isha"],
          };
          errorMsg = null;
        });
      } else {
        setState(() => errorMsg = "Failed to load prayer times");
      }
    } catch (e) {
      setState(() => errorMsg = "Network error: ${e.toString()}");
    }
  }

  String _getNextPrayer() {
    if (prayerTimes.isEmpty) return "";

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final entry in prayerTimes.entries) {
      final time = entry.value.substring(0, 5).split(':');
      final prayerMinutes = int.parse(time[0]) * 60 + int.parse(time[1]);

      if (prayerMinutes > nowMinutes) {
        return entry.key;
      }
    }
    return "Fajr";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Prayer Times",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshController.value * 2 * pi,
                child: IconButton(
                  onPressed: isLoading ? null : _refreshPrayerTimes,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 16),
                    Text(
                      "Loading prayer times...",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF8F9FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentDate,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.green[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          currentCity,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (_getNextPrayer().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Next",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                        Text(
                                          _getNextPrayer(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_city,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "เลือกสถานที่",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _searchController,
                              onChanged: _filterCities,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: "ค้นหาจังหวัด เมือง...",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.green[600],
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterCities('');
                                        },
                                      )
                                    : Icon(
                                        Icons.location_on,
                                        color: Colors.green[400],
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.green[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.green[600]!,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "เลือก: ${cityOptions.firstWhere((c) => c['city'] == selectedCity)['thaiName']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isSearching && filteredCities.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  itemCount: filteredCities.length,
                                  itemBuilder: (context, index) {
                                    final city = filteredCities[index];
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        Icons.location_city,
                                        color: Colors.green[600],
                                        size: 16,
                                      ),
                                      title: Text(
                                        "${city["thaiName"]} (${city["city"]})",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedCity = city["city"]!;
                                          selectedCountry = city["country"]!;
                                          isSearching = false;
                                          _searchController.clear();
                                          filteredCities = cityOptions;
                                        });
                                        _getLocationAndPrayerTimes();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],

                            if (currentPosition != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                "GPS: ${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],

                            if (errorMsg != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.orange[700],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMsg!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ...prayerTimes.entries.map((entry) {
                      final prayerIcons = {
                        "Fajr": Icons.brightness_2,
                        "Dhuhr": Icons.wb_sunny,
                        "Asr": Icons.wb_cloudy,
                        "Maghrib": Icons.brightness_3,
                        "Isha": Icons.brightness_2,
                      };

                      final prayerColors = {
                        "Fajr": Colors.indigo,
                        "Dhuhr": Colors.orange,
                        "Asr": Colors.amber,
                        "Maghrib": Colors.deepOrange,
                        "Isha": Colors.purple,
                      };

                      final isNext = _getNextPrayer() == entry.key;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: isNext ? 8 : 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: isNext
                                    ? [Colors.green[100]!, Colors.green[50]!]
                                    : [Colors.white, const Color(0xFFF8F9FA)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              border: isNext
                                  ? Border.all(
                                      color: Colors.green[400]!,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: prayerColors[entry.key]!.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  prayerIcons[entry.key]!,
                                  color: prayerColors[entry.key]!,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isNext ? Colors.green[800] : Colors.black87,
                                ),
                              ),
                              subtitle: isNext
                                  ? Text(
                                      "Next Prayer",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isNext ? Colors.green[200] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  entry.value.substring(0, 5),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isNext ? Colors.green[800] : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
      ),
    );
  }
}

// ================= Enhanced Qibla Compass Screen =================
class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double? qiblaDirection;
  double? currentHeading = 0.0;
  double smoothedHeading = 0.0;
  bool isLoading = true;
  String? errorMsg;
  Position? currentPosition;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool isCalibrating = false;
  int compassAccuracy = 0;

  // Smoothing parameters
  final List<double> _headingHistory = [];
  static const int _historySize = 5;

  @override
  void initState() {
    super.initState();
    _getQiblaDirection();
    _startCompassListener();
  }

  void _startCompassListener() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        _updateHeading(event.heading!);
        
        // Update accuracy indicator
        if (event.accuracy != null) {
          setState(() {
            compassAccuracy = event.accuracy!.toInt();
          });
        }
      }
    });
  }

  void _updateHeading(double newHeading) {
    // Add to history
    _headingHistory.add(newHeading);
    if (_headingHistory.length > _historySize) {
      _headingHistory.removeAt(0);
    }

    // Calculate smoothed heading using weighted average
    double sum = 0;
    double weightSum = 0;
    for (int i = 0; i < _headingHistory.length; i++) {
      double weight = (i + 1).toDouble(); // More recent values have higher weight
      sum += _headingHistory[i] * weight;
      weightSum += weight;
    }

    setState(() {
      currentHeading = newHeading;
      smoothedHeading = sum / weightSum;
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  double _calculateQiblaDirection(double lat, double lng) {
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;

    final double lat1 = lat * pi / 180;
    final double lng1 = lng * pi / 180;
    final double lat2 = kaabaLat * pi / 180;
    final double lng2 = kaabaLng * pi / 180;

    final double dLng = lng2 - lng1;

    final double y = sin(dLng) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    double bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  Future<void> _getQiblaDirection() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => errorMsg = "กรุณาเปิดใช้งาน Location Service");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => errorMsg = "กรุณาอนุญาตการใช้งานตำแหน่ง");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        currentPosition = position;
        qiblaDirection = _calculateQiblaDirection(
          position.latitude,
          position.longitude,
        );
        errorMsg = null;
      });
    } catch (e) {
      setState(() => errorMsg = "ข้อผิดพลาด: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool get _isAligned {
    if (qiblaDirection == null || smoothedHeading == null) return false;
    double diff = ((qiblaDirection! - smoothedHeading) % 360).abs();
    if (diff > 180) diff = 360 - diff;
    return diff < 5; // Within 5 degrees
  }

  double get _angleDifference {
    if (qiblaDirection == null || smoothedHeading == null) return 0;
    double diff = (qiblaDirection! - smoothedHeading) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  void _startCalibration() {
    setState(() {
      isCalibrating = true;
    });
    
    // Auto-stop calibration after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          isCalibrating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "เข็มทิศกิบลัต",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _getQiblaDirection,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "รีเฟรช",
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 16),
                    Text(
                      "กำลังหาทิศทางกิบลัต...",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Location Info Card
                    if (currentPosition != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF8F9FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ตำแหน่งปัจจุบัน",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "Lat: ${currentPosition!.latitude.toStringAsFixed(6)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      "Lng: ${currentPosition!.longitude.toStringAsFixed(6)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isAligned)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.mosque,
                                    color: Colors.green[800],
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Calibration Card
                    if (isCalibrating)
                      Card(
                        elevation: 4,
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.screen_rotation, 
                                   color: Colors.blue[700], size: 40),
                              const SizedBox(height: 8),
                              Text(
                                "กำลังปรับเทียบเข็มทิศ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "หมุนโทรศัพท์เป็นวงกลม 2-3 รอบ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(),
                            ],
                          ),
                        ),
                      ),

                    if (isCalibrating) const SizedBox(height: 16),

                    // Error Message
                    if (errorMsg != null)
                      Card(
                        elevation: 2,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (errorMsg != null) const SizedBox(height: 16),

                    // Main Compass Card
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF8F9FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Status Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isAligned
                                        ? Colors.green[100]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.mosque,
                                    color: _isAligned
                                        ? Colors.green[800]
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isAligned
                                          ? "ตรงทิศกิบลัตแล้ว!"
                                          : "หมุนไปหาทิศกิบลัต",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _isAligned
                                            ? Colors.green[800]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                    if (!_isAligned && qiblaDirection != null)
                                      Text(
                                        "เหลือ ${_angleDifference.abs().toStringAsFixed(0)}°",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Compass
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer golden ring
                                Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFDAA520),
                                        Color(0xFFB8860B),
                                      ],
                                      stops: [0.7, 0.85, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),

                                // Inner compass face
                                Container(
                                  width: 270,
                                  height: 270,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFF8DC),
                                        Color(0xFFFFFAF0),
                                        Color(0xFFF5DEB3),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    painter: GoldenCompassFacePainter(
                                      currentHeading: smoothedHeading,
                                    ),
                                  ),
                                ),

                                // Compass needle
                                if (qiblaDirection != null)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: (qiblaDirection! - smoothedHeading) * pi / 180,
                                    ),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    builder: (context, angle, child) {
                                      return Transform.rotate(
                                        angle: angle,
                                        child: CustomPaint(
                                          size: const Size(200, 200),
                                          painter: GoldenCompassNeedlePainter(
                                            isAligned: _isAligned,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // Center golden button
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFB8860B),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF8B4513),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Direction Info
                            if (qiblaDirection != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isAligned 
                                      ? Colors.green[50]
                                      : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isAligned 
                                        ? Colors.green[200]!
                                        : Colors.blue[200]!,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    if (_isAligned)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "ตรงกับทิศกิบลัตแล้ว!",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              Column(
                                                children: [
                                                  Text(
                                                    "ทิศกิบลัต",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    "${qiblaDirection!.toStringAsFixed(1)}°",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Text(
                                                    "ทิศปัจจุบัน",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    "${smoothedHeading.toStringAsFixed(1)}°",
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Calibration Button
                            if (!isCalibrating)
                              ElevatedButton.icon(
                                onPressed: _startCalibration,
                                icon: const Icon(Icons.settings_backup_restore),
                                label: const Text("ปรับเทียบเข็มทิศ"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Instructions
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        color: Colors.orange[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "วิธีใช้งาน:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "• ถือมือถือให้เรียบและระดับ\n"
                                    "• หมุนตัวเองช้าๆ ตามทิศที่เข็มชี้\n"
                                    "• เข็มสีแดง/เขียวชี้ไปทิศกิบลัต\n"
                                    "• เมื่อตรงทิศจะแจ้งเตือน\n"
                                    "• หากเข็มไม่แม่นให้กดปรับเทียบ\n"
                                    "• หลีกเลี่ยงสิ่งที่มีแม่เหล็ก",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Custom painter for golden compass face with degree markings
class GoldenCompassFacePainter extends CustomPainter {
  final double currentHeading;

  GoldenCompassFacePainter({required this.currentHeading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw degree markers
    for (int i = 0; i < 72; i++) {
      final angle = (i * 5.0 - currentHeading) * pi / 180;
      final isMainDirection = i % 18 == 0;
      final isSecondary = i % 9 == 0;
      final isTertiary = i % 3 == 0;

      double lineLength;
      double lineWidth;
      Color lineColor;

      if (isMainDirection) {
        lineLength = 25;
        lineWidth = 3;
        lineColor = const Color(0xFF8B4513);
      } else if (isSecondary) {
        lineLength = 18;
        lineWidth = 2.5;
        lineColor = const Color(0xFFB8860B);
      } else if (isTertiary) {
        lineLength = 12;
        lineWidth = 2;
        lineColor = const Color(0xFFDAA520);
      } else {
        lineLength = 8;
        lineWidth = 1;
        lineColor = const Color(0xFFDAA520).withOpacity(0.5);
      }

      final startX = center.dx + (radius - lineLength - 5) * cos(angle);
      final startY = center.dy + (radius - lineLength - 5) * sin(angle);
      final endX = center.dx + (radius - 5) * cos(angle);
      final endY = center.dy + (radius - 5) * sin(angle);

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }

    // Draw cardinal directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final directionAngles = [0, 90, 180, 270];

    for (int i = 0; i < directions.length; i++) {
      final angle = (directionAngles[i] - currentHeading) * pi / 180;
      final x = center.dx + (radius - 40) * cos(angle - pi / 2);
      final y = center.dy + (radius - 40) * sin(angle - pi / 2);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: i == 0 ? const Color(0xFFDC143C) : const Color(0xFF8B4513),
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw degree numbers
    for (int i = 0; i < 36; i++) {
      if (i % 3 == 0) {
        final degree = i * 10;
        final angle = (degree - currentHeading) * pi / 180;
        final x = center.dx + (radius - 60) * cos(angle - pi / 2);
        final y = center.dy + (radius - 60) * sin(angle - pi / 2);

        textPainter.text = TextSpan(
          text: "$degree",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(GoldenCompassFacePainter oldDelegate) {
    return oldDelegate.currentHeading != currentHeading;
  }
}

// Custom painter for golden compass needle
class GoldenCompassNeedlePainter extends CustomPainter {
  final bool isAligned;

  GoldenCompassNeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.width / 2 - 40;

    // North pointer (red/green - points to Qibla)
    final northPath = Path();
    northPath.moveTo(center.dx, center.dy - needleLength);
    northPath.lineTo(center.dx - 12, center.dy + 15);
    northPath.lineTo(center.dx, center.dy);
    northPath.lineTo(center.dx + 12, center.dy + 15);
    northPath.close();

    final northGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isAligned
            ? [Colors.green[400]!, Colors.green[700]!]
            : [const Color(0xFFFF4444), const Color(0xFFCC0000)],
      ).createShader(northPath.getBounds());

    canvas.drawPath(northPath, northGradient);

    // North pointer border (golden)
    final northBorderPaint = Paint()
      ..color = const Color(0xFFDAA520)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(northPath, northBorderPaint);

    // South pointer (black/grey)
    final southPath = Path();
    southPath.moveTo(center.dx, center.dy + needleLength);
    southPath.lineTo(center.dx - 10, center.dy - 15);
    southPath.lineTo(center.dx, center.dy);
    southPath.lineTo(center.dx + 10, center.dy - 15);
    southPath.close();

    final southGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF333333), Color(0xFF666666)],
      ).createShader(southPath.getBounds());

    canvas.drawPath(southPath, southGradient);

    // South pointer border (golden)
    canvas.drawPath(southPath, northBorderPaint);

    // Add shine effect on north pointer
    final shinePath = Path();
    shinePath.moveTo(center.dx - 4, center.dy - needleLength + 15);
    shinePath.lineTo(center.dx - 6, center.dy);
    shinePath.lineTo(center.dx - 2, center.dy);
    shinePath.close();

    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5);

    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(GoldenCompassNeedlePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}

// ================= Tasbih Screen =================
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with TickerProviderStateMixin {
  int count = 0;
  bool isEditMode = false;
  bool showDropdown = false;
  int selectedIncrement = 1;
  final TextEditingController _editController = TextEditingController();
  late AnimationController _tapController;
  late AnimationController _resetController;
  late AnimationController _dropdownController;

  final List<int> incrementOptions = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 30, 50, 100,
  ];

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dropdownController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _editController.dispose();
    _tapController.dispose();
    _resetController.dispose();
    _dropdownController.dispose();
    super.dispose();
  }

  void _addCount(int value) {
    setState(() {
      count += value;
    });
    _tapController.forward().then((_) => _tapController.reverse());
  }

  void _subtractCount() {
    if (count > 0) {
      setState(() {
        count -= 1;
      });
      _tapController.forward().then((_) => _tapController.reverse());
    }
  }

  void _resetCount() {
    setState(() {
      count = 0;
    });
    _resetController.forward().then((_) => _resetController.reverse());
  }

  void _toggleEditMode() {
    setState(() {
      if (isEditMode) {
        final newValue = int.tryParse(_editController.text) ?? count;
        count = newValue < 0 ? 0 : newValue;
        isEditMode = false;
      } else {
        _editController.text = count.toString();
        isEditMode = true;
      }
    });
  }

  void _toggleDropdown() {
    setState(() {
      showDropdown = !showDropdown;
      if (showDropdown) {
        _dropdownController.forward();
      } else {
        _dropdownController.reverse();
      }
    });
  }

  void _selectIncrement(int value) {
    setState(() {
      selectedIncrement = value;
      showDropdown = false;
    });
    _dropdownController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          "ดิจิตอล ตัสบีห์",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextButton(
                            onPressed: _toggleDropdown,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "+$selectedIncrement",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  showDropdown
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextButton(
                            onPressed: _toggleEditMode,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              isEditMode ? "บันทึก" : "แก้ไข",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextButton(
                            onPressed: _resetCount,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              "รีเซ็ต",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    AnimatedBuilder(
                      animation: _tapController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_tapController.value * 0.1),
                          child: isEditMode
                              ? SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _editController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                )
                              : Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Main Tap Button
                    GestureDetector(
                      onTap: () => _addCount(selectedIncrement),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4CAF50),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Subtract Button
                    GestureDetector(
                      onTap: _subtractCount,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: count > 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF333333),
                          boxShadow: count > 0
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 25,
                          color: count > 0 ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Backdrop to close dropdown
            if (showDropdown)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleDropdown,
                  child: Container(color: Colors.transparent),
                ),
              ),

            // Dropdown Menu
            if (showDropdown)
              Positioned(
                top: 100,
                left: 24,
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedBuilder(
                    animation: _dropdownController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _dropdownController.value,
                        alignment: Alignment.topLeft,
                        child: Opacity(
                          opacity: _dropdownController.value,
                          child: Container(
                            width: 140,
                            height: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF444444),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: incrementOptions.length,
                                itemBuilder: (context, index) {
                                  final value = incrementOptions[index];
                                  final isSelected = value == selectedIncrement;

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _selectIncrement(value),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 1,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF4CAF50)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "+$value",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}