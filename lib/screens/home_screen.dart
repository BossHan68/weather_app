import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

// Import from local services
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables
  String city = "Bangkok"; // Default city set to Bangkok
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? errorMessage;
  File? _profileImage;
  String _userName = "";
  String _studentId = ""; // Student ID variable

  // Lifecycle initState: เรียกใช้งานเมื่อเริ่มต้นหน้าจอ
  @override
  void initState() {
    super.initState();
    _loadHomeCity(); // โหลดเมืองหลักก่อน
    _loadUserProfile();
  }

  // โหลดเมืองหลักจากฐานข้อมูล
  Future<void> _loadHomeCity() async {
    try {
      final homeCity = await ApiService.getHomeCity();
      setState(() {
        if (homeCity != null && homeCity.isNotEmpty) {
          city = homeCity;
          print("📌 Loaded home city: $city");
        }
      });
      // โหลดข้อมูลสภาพอากาศหลังจากได้เมืองแล้ว
      fetchWeather();
    } catch (e) {
      print("🚨 Error loading home city: $e");
      // ถ้าโหลดเมืองหลักไม่ได้ ก็ใช้ Bangkok เป็น default
      fetchWeather();
    }
  }

  // Fetch weather data
  void fetchWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print("📌 Fetching weather for city: $city");
      final data = await ApiService.fetchWeather(city);
      setState(() {
        weatherData = data;
        isLoading = false;
        if (data == null || data.containsKey('error')) {
          errorMessage = "ไม่สามารถโหลดข้อมูลสภาพอากาศได้";
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "เกิดข้อผิดพลาด: $e";
      });
    }
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? imagePath = prefs.getString('profileImagePath');
      final String userName = prefs.getString('userName') ?? '';
      final String studentId = prefs.getString('studentId') ?? '';

      setState(() {
        _studentId = studentId; // Set student ID

        if (imagePath != null && imagePath.isNotEmpty) {
          final file = File(imagePath);
          if (file.existsSync()) {
            _profileImage = file;
          }
        }
        _userName = userName;
      });
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  // รีเฟรชข้อมูลทั้งหมด
  Future<void> _refreshAll() async {
    await _loadHomeCity();
    await _loadUserProfile();
  }

  // get weather icon
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud_queue;
      default:
        return Icons.cloud;
    }
  }

  // Helper method to build weather info widget
  Widget _buildWeatherInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // เมื่อกลับมาจากหน้าอื่น
  void _onResumed() {
    print("📌 HomeScreen resumed - refreshing data");
    _refreshAll();
  }

  // main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ตั้งค่าแถบหัวข้อของแอป (AppBar)
      appBar: AppBar(
        title: Text("Weather App"),
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: "รีเฟรชข้อมูล",
          ),
          // Profile button
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/profile');
              // Reload user profile when returning from profile page
              _loadUserProfile();
            },
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                // ขยับโปรไฟล์(รัศมี)
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child:
                    _profileImage == null
                        ? Icon(Icons.account_circle, color: Colors.blue)
                        : null,
              ),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text("ลองใหม่"),
                      onPressed: _refreshAll,
                    ),
                  ],
                ),
              )
              : Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // แสดงเมืองปัจจุบัน
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "เมืองหลัก",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "${weatherData!['name']}",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Icon(
                      _getWeatherIcon(weatherData!['weather'][0]['main']),
                      size: 80,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "${weatherData!['main']['temp']}°C",
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      "${weatherData!['weather'][0]['description']}",
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWeatherInfo(
                          Icons.water_drop,
                          "ความชื้น",
                          "${weatherData!['main']['humidity']}%",
                        ),
                        _buildWeatherInfo(
                          Icons.air,
                          "ความเร็วลม",
                          "${weatherData!['wind']['speed']} m/s",
                        ),
                        _buildWeatherInfo(
                          Icons.compress,
                          "ความกดอากาศ",
                          "${weatherData!['main']['pressure']} hPa",
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: Icon(Icons.search),
                      label: Text("ค้นหาเมืองอื่น"),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/search');
                        _onResumed(); // รีเฟรชเมื่อกลับมา
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(Icons.location_city),
                      label: Text("เมืองที่บันทึกไว้"),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/saved');
                        _onResumed(); // รีเฟรชเมื่อกลับมา
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      // เมนู 3 ขีด
      drawer: Drawer(
        // เลื่อน ListView ดูได้
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 56, 103, 146),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show profile image in drawer header
                  Row(
                    children: [
                      CircleAvatar(
                        // ปรับขนาดรูป
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                        child:
                            _profileImage == null
                                ? Icon(Icons.account_circle, color: Colors.blue)
                                : null,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ที่ปลี่ยนชื่อที่แถบ 3 ขีด
                            Text(
                              'Weather App',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                foreground:
                                    Paint()
                                      ..shader = LinearGradient(
                                        colors: [
                                          const Color.fromARGB(221, 0, 0, 0),
                                          const Color.fromARGB(135, 41, 40, 40),
                                        ],
                                      ).createShader(
                                        Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                      ),
                              ),
                            ),
                            Text(
                              _userName.isNotEmpty ? _userName : 'ยินดีต้อนรับ',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            // Add student ID display
                            Text(
                              _studentId.isNotEmpty
                                  ? 'รหัสนักศึกษา: $_studentId'
                                  : '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
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
            ListTile(
              leading: Icon(Icons.home),
              title: Text('หน้าหลัก'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('ค้นหาเมือง'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/search');
                _onResumed();
              },
            ),
            ListTile(
              leading: Icon(Icons.location_city),
              title: Text('เมืองที่บันทึกไว้'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/saved');
                _onResumed();
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('เวลาละหมาด'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/salahad');
                _onResumed();
              },
            ),
            ListTile(
              leading: Icon(Icons.article),
              title: Text('ข่าวสาร'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/news');
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('โปรไฟล์'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/profile');
                _loadUserProfile();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('ตั้งค่า'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('เกี่ยวกับ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
          ],
        ),
      ),
    );
  }
}
