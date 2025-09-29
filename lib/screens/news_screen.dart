import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// Model สำหรับพยากรณ์อากาศ 7 วัน
class WeatherForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String weather;
  final String description;
  final String icon;
  final double humidity;
  final double windSpeed;
  final double pop; // Probability of precipitation

  WeatherForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weather,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pop,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      maxTemp: json['temp']['max']?.toDouble() ?? 0.0,
      minTemp: json['temp']['min']?.toDouble() ?? 0.0,
      weather: json['weather'][0]['main'] ?? '',
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
      humidity: json['humidity']?.toDouble() ?? 0.0,
      windSpeed: json['wind_speed']?.toDouble() ?? 0.0,
      pop: (json['pop']?.toDouble() ?? 0.0) * 100,
    );
  }
}

// Model สำหรับ Air Quality
class AirQuality {
  final int aqi;
  final String level;
  final Color color;
  final Map<String, double> components;

  AirQuality({
    required this.aqi,
    required this.level,
    required this.color,
    required this.components,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    int aqi = json['main']['aqi'] ?? 1;
    String level = _getAQILevel(aqi);
    Color color = _getAQIColor(aqi);

    return AirQuality(
      aqi: aqi,
      level: level,
      color: color,
      components: {
        'co': json['components']['co']?.toDouble() ?? 0.0,
        'no2': json['components']['no2']?.toDouble() ?? 0.0,
        'o3': json['components']['o3']?.toDouble() ?? 0.0,
        'pm2_5': json['components']['pm2_5']?.toDouble() ?? 0.0,
        'pm10': json['components']['pm10']?.toDouble() ?? 0.0,
      },
    );
  }

  static String _getAQILevel(int aqi) {
    switch (aqi) {
      case 1: return 'ดีมาก';
      case 2: return 'ดี';
      case 3: return 'ปานกลาง';
      case 4: return 'แย่';
      case 5: return 'แย่มาก';
      default: return 'ไม่ทราบ';
    }
  }

  static Color _getAQIColor(int aqi) {
    switch (aqi) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.yellow;
      case 4: return Colors.orange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }
}

// Model สำหรับการตั้งค่าการแจ้งเตือน
class NotificationSettings {
  final bool morningAlert;
  final bool rainAlert;
  final bool temperatureAlert;
  final bool uvAlert;
  final bool airQualityAlert;
  final TimeOfDay morningTime;
  final double temperatureThreshold;
  final int uvThreshold;
  final int airQualityThreshold;
  final List<String> selectedCities;

  NotificationSettings({
    this.morningAlert = false,
    this.rainAlert = false,
    this.temperatureAlert = false,
    this.uvAlert = false,
    this.airQualityAlert = false,
    this.morningTime = const TimeOfDay(hour: 7, minute: 0),
    this.temperatureThreshold = 35.0,
    this.uvThreshold = 8,
    this.airQualityThreshold = 3,
    this.selectedCities = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'morningAlert': morningAlert,
      'rainAlert': rainAlert,
      'temperatureAlert': temperatureAlert,
      'uvAlert': uvAlert,
      'airQualityAlert': airQualityAlert,
      'morningHour': morningTime.hour,
      'morningMinute': morningTime.minute,
      'temperatureThreshold': temperatureThreshold,
      'uvThreshold': uvThreshold,
      'airQualityThreshold': airQualityThreshold,
      'selectedCities': selectedCities,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      morningAlert: json['morningAlert'] ?? false,
      rainAlert: json['rainAlert'] ?? false,
      temperatureAlert: json['temperatureAlert'] ?? false,
      uvAlert: json['uvAlert'] ?? false,
      airQualityAlert: json['airQualityAlert'] ?? false,
      morningTime: TimeOfDay(
        hour: json['morningHour'] ?? 7,
        minute: json['morningMinute'] ?? 0,
      ),
      temperatureThreshold: json['temperatureThreshold']?.toDouble() ?? 35.0,
      uvThreshold: json['uvThreshold'] ?? 8,
      airQualityThreshold: json['airQualityThreshold'] ?? 3,
      selectedCities: List<String>.from(json['selectedCities'] ?? []),
    );
  }

  // เพิ่ม copyWith method สำหรับการอัพเดทการตั้งค่า
  NotificationSettings copyWith({
    bool? morningAlert,
    bool? rainAlert,
    bool? temperatureAlert,
    bool? uvAlert,
    bool? airQualityAlert,
    TimeOfDay? morningTime,
    double? temperatureThreshold,
    int? uvThreshold,
    int? airQualityThreshold,
    List<String>? selectedCities,
  }) {
    return NotificationSettings(
      morningAlert: morningAlert ?? this.morningAlert,
      rainAlert: rainAlert ?? this.rainAlert,
      temperatureAlert: temperatureAlert ?? this.temperatureAlert,
      uvAlert: uvAlert ?? this.uvAlert,
      airQualityAlert: airQualityAlert ?? this.airQualityAlert,
      morningTime: morningTime ?? this.morningTime,
      temperatureThreshold: temperatureThreshold ?? this.temperatureThreshold,
      uvThreshold: uvThreshold ?? this.uvThreshold,
      airQualityThreshold: airQualityThreshold ?? this.airQualityThreshold,
      selectedCities: selectedCities ?? this.selectedCities,
    );
  }
}

// คลาสหลักของแอป
class EnhancedNewsScreen extends StatefulWidget {
  @override
  _EnhancedNewsScreenState createState() => _EnhancedNewsScreenState();
}

class _EnhancedNewsScreenState extends State<EnhancedNewsScreen>
    with SingleTickerProviderStateMixin {
  
  // ตัวแปรสำหรับฟีเจอร์ใหม่
  List<WeatherForecast> weeklyForecast = [];
  Map<String, AirQuality> airQualityData = {};
  Map<String, double> uvIndexData = {};
  NotificationSettings notificationSettings = NotificationSettings();
  Position? currentLocation;
  Timer? scheduledNotificationTimer;
  
  // ตัวแปรเดิม
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final String apiKey = '4fc2c86a0eb437d589ef2a0efc3fd6de';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  List<Map<String, dynamic>> weatherNews = [];
  List<Map<String, dynamic>> weatherAlerts = [];
  bool isLoading = false;
  Timer? newsTimer;
  String selectedRegion = 'ทั่วประเทศ';
  late TabController _tabController;
  String error = '';

  // ข้อมูลภูมิภาค
  final List<String> regions = [
    'ทั่วประเทศ',
    'ภาคเหนือ',
    'ภาคตะวันออกเฉียงเหนือ',
    'ภาคกลาง',
    'ภาคตะวันออก',
    'ภาคใต้',
  ];

  final Map<String, List<String>> regionCities = {
    'ทั่วประเทศ': [
      'กรุงเทพมหานคร',
      'เชียงใหม่',
      'หาดใหญ่',
      'ขอนแก่น',
      'ภูเก็ต',
    ],
    'ภาคเหนือ': [
      'เชียงใหม่',
      'เชียงราย',
      'ลำปาง',
      'พิษณุโลก',
      'สุโขทัย',
    ],
    'ภาคตะวันออกเฉียงเหนือ': [
      'ขอนแก่น',
      'นครราชสีมา',
      'อุดรธานี',
      'อุบลราชธานี',
      'เลย',
    ],
    'ภาคกลาง': [
      'กรุงเทพมหานคร',
      'นนทบุรี',
      'ปทุมธานี',
      'สมุทรปราการ',
      'นครปฐม',
    ],
    'ภาคตะวันออก': [
      'ชลบุรี',
      'ระยอง',
      'จันทบุรี',
      'ตราด',
      'ฉะเชิงเทรา',
    ],
    'ภาคใต้': [
      'ภูเก็ต',
      'หาดใหญ่',
      'สุราษฎร์ธานี',
      'กระบี่',
      'นครศรีธรรมราช',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    initializeNotifications();
    loadNotificationSettings();
    getCurrentLocation();
    
    if (apiKey != 'YOUR_OPENWEATHER_API_KEY') {
      fetchAllWeatherData();
      setupScheduledNotifications();
      newsTimer = Timer.periodic(Duration(minutes: 15), (timer) {
        fetchAllWeatherData();
      });
    } else {
      loadSampleData();
    }
  }

  // ===== INITIALIZATION FUNCTIONS =====
  
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? settingsJson = prefs.getString('notification_settings');
    
    if (settingsJson != null) {
      setState(() {
        notificationSettings = NotificationSettings.fromJson(
          json.decode(settingsJson),
        );
      });
    }
  }

  Future<void> saveNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notification_settings',
      json.encode(notificationSettings.toJson()),
    );
  }

  Future<void> getCurrentLocation() async {
    print('Getting current location...'); // Debug log
    
    try {
      // แสดง loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('กำลังดึงตำแหน่งปัจจุบัน...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // ตรวจสอบว่า Location services เปิดอยู่หรือไม่
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โปรดเปิดบริการตำแหน่งในเครื่อง'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'เปิดการตั้งค่า',
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          ),
        );
        return;
      }

      // ตรวจสอบ permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission: $permission'); // Debug log
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Requested permission: $permission'); // Debug log
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('การเข้าถึงตำแหน่งถูกปฏิเสธถาวร โปรดเปิดในการตั้งค่าแอป'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'เปิดการตั้งค่า',
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        );
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10), // กำหนด timeout
        );
        
        print('Location obtained: ${position.latitude}, ${position.longitude}'); // Debug log
        
        setState(() {
          currentLocation = position;
        });
        
        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ดึงตำแหน่งสำเร็จ กำลังอัพเดทข้อมูล...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // ดึงข้อมูลสภาพอากาศใหม่หลังได้ตำแหน่ง
        if (apiKey != 'YOUR_OPENWEATHER_API_KEY') {
          await fetchAllWeatherData();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ต้องการสิทธิ์เข้าถึงตำแหน่งเพื่อแสดงข้อมูลสภาพอากาศ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e'); // Debug log
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถดึงตำแหน่งได้: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // ===== DATA FETCHING FUNCTIONS =====

  Future<void> fetchAllWeatherData() async {
    await Future.wait([
      fetchCurrentWeather(),
      fetchWeeklyForecast(),
      fetchAirQualityData(),
      fetchUVIndexData(),
    ]);
  }

  Future<void> fetchCurrentWeather() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    if (apiKey == 'YOUR_OPENWEATHER_API_KEY') {
      setState(() {
        isLoading = false;
        error = 'โปรดใส่ API Key จาก OpenWeatherMap';
      });
      return;
    }

    try {
      List<Map<String, dynamic>> newsItems = [];
      List<Map<String, dynamic>> alerts = [];

      List<String> cities =
          regionCities[selectedRegion] ?? regionCities['ทั่วประเทศ']!;

      for (String city in cities) {
        try {
          final response = await http
              .get(
                Uri.parse(
                  '$baseUrl/weather?q=$city,TH&appid=$apiKey&units=metric&lang=th',
                ),
              )
              .timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            Map<String, dynamic> data = json.decode(response.body);

            Map<String, dynamic> newsItem = createNewsItem(data, city);
            newsItems.add(newsItem);

            await _checkAdvancedAlerts(data, city, alerts);
          }
        } catch (e) {
          print('Error fetching data for $city: $e');
        }
      }

      if (newsItems.isNotEmpty) {
        setState(() {
          weatherNews = newsItems;
          weatherAlerts = alerts;
        });

        await saveNewsData(newsItems, alerts);
      }
    } catch (e) {
      print('Error fetching weather news: $e');
      setState(() {
        error = 'ไม่สามารถดึงข้อมูลได้: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchWeeklyForecast() async {
    if (currentLocation == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${baseUrl}/onecall?lat=${currentLocation!.latitude}&lon=${currentLocation!.longitude}&appid=$apiKey&units=metric&lang=th&exclude=minutely,hourly,alerts',
        ),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> dailyData = data['daily'] ?? [];
        
        setState(() {
          weeklyForecast = dailyData
              .take(7)
              .map((day) => WeatherForecast.fromJson(day))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching weekly forecast: $e');
    }
  }

  Future<void> fetchAirQualityData() async {
    if (currentLocation == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://api.openweathermap.org/data/2.5/air_pollution?lat=${currentLocation!.latitude}&lon=${currentLocation!.longitude}&appid=$apiKey',
        ),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data['list'] != null && data['list'].isNotEmpty) {
          setState(() {
            airQualityData['current'] = AirQuality.fromJson(data['list'][0]);
          });
        }
      }
    } catch (e) {
      print('Error fetching air quality: $e');
    }
  }

  Future<void> fetchUVIndexData() async {
    if (currentLocation == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${baseUrl}/uvi?lat=${currentLocation!.latitude}&lon=${currentLocation!.longitude}&appid=$apiKey',
        ),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          uvIndexData['current'] = data['value']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print('Error fetching UV index: $e');
    }
  }

  // ===== NOTIFICATION FUNCTIONS =====

  void setupScheduledNotifications() {
    scheduledNotificationTimer?.cancel();
    
    if (notificationSettings.morningAlert) {
      Duration timeDifference = _calculateTimeDifference(
        notificationSettings.morningTime,
      );
      
      scheduledNotificationTimer = Timer(timeDifference, () {
        sendMorningNotification();
        scheduledNotificationTimer = Timer.periodic(
          Duration(days: 1),
          (timer) => sendMorningNotification(),
        );
      });
    }
  }

  Duration _calculateTimeDifference(TimeOfDay targetTime) {
    DateTime now = DateTime.now();
    DateTime target = DateTime(
      now.year,
      now.month,
      now.day,
      targetTime.hour,
      targetTime.minute,
    );
    
    if (target.isBefore(now)) {
      target = target.add(Duration(days: 1));
    }
    
    return target.difference(now);
  }

  Future<void> sendMorningNotification() async {
    if (weeklyForecast.isNotEmpty) {
      WeatherForecast today = weeklyForecast.first;
      String message = 'วันนี้ ${today.maxTemp.toStringAsFixed(0)}°/${today.minTemp.toStringAsFixed(0)}° ${today.description}';
      
      if (today.pop > 70) {
        message += ' โอกาสฝน ${today.pop.toStringAsFixed(0)}% อย่าลืมร่ม!';
      }
      
      await sendScheduledNotification(
        'สวัสดีตอนเช้า',
        message,
        'morning_weather',
      );
    }
  }

  Future<void> sendScheduledNotification(
    String title,
    String body,
    String channelId,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'scheduled_weather',
      'การแจ้งเตือนตามเวลา',
      channelDescription: 'การแจ้งเตือนสภาพอากาศตามเวลาที่กำหนด',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> _checkAdvancedAlerts(
    Map<String, dynamic> data,
    String city,
    List<Map<String, dynamic>> alerts,
  ) async {
    double temp = data['main']['temp']?.toDouble() ?? 0.0;
    String weatherMain = data['weather'][0]['main'] ?? '';
    
    if (notificationSettings.temperatureAlert && temp > notificationSettings.temperatureThreshold) {
      Map<String, dynamic> alert = {
        'id': '${city}_temp_alert_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'อุณหภูมิสูงเกินกำหนด',
        'message': 'อุณหภูมิที่ $city สูงถึง ${temp.toStringAsFixed(1)}°C เกินขีดจำกัดที่ตั้งไว้',
        'city': city,
        'severity': 'high',
        'timestamp': DateTime.now().toIso8601String(),
      };
      alerts.add(alert);
      await sendNotification(alert);
    }

    if (notificationSettings.rainAlert && weatherMain == 'Rain') {
      Map<String, dynamic> alert = {
        'id': '${city}_rain_alert_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'เตือนฝนตก',
        'message': 'มีฝนตกในพื้นที่ $city อย่าลืมเตรียมร่ม',
        'city': city,
        'severity': 'medium',
        'timestamp': DateTime.now().toIso8601String(),
      };
      alerts.add(alert);
      await sendNotification(alert);
    }

    if (notificationSettings.uvAlert && uvIndexData.containsKey('current')) {
      double uv = uvIndexData['current']!;
      if (uv > notificationSettings.uvThreshold) {
        Map<String, dynamic> alert = {
          'id': 'uv_alert_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'UV Index สูง',
          'message': 'ดัชนี UV สูงถึง ${uv.toStringAsFixed(1)} โปรดป้องกันตัวจากแสงแดด',
          'city': city,
          'severity': 'medium',
          'timestamp': DateTime.now().toIso8601String(),
        };
        alerts.add(alert);
        await sendNotification(alert);
      }
    }
  }

  Future<void> sendNotification(Map<String, dynamic> alert) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'weather_alerts',
            'การแจ้งเตือนสภาพอากาศ',
            channelDescription: 'การแจ้งเตือนเมื่อมีสภาพอากาศเสี่ยงภัย',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        alert['type'],
        alert['message'],
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // ===== UI BUILDING FUNCTIONS =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('ข่าวสารสภาพอากาศขั้นสูง'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : fetchAllWeatherData,
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () async {
              print('Location button pressed'); // เพิ่ม debug log
              await getCurrentLocation();
            },
            tooltip: 'ดึงตำแหน่งปัจจุบัน',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.newspaper, size: 20), text: 'ข่าวสาร'),
            Tab(icon: Icon(Icons.warning, size: 20), text: 'แจ้งเตือน'),
            Tab(icon: Icon(Icons.calendar_today, size: 20), text: '7 วัน'),
            Tab(icon: Icon(Icons.air, size: 20), text: 'อากาศ/UV'),
            Tab(icon: Icon(Icons.settings, size: 20), text: 'การตั้งค่า'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (error.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.red[100],
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewsTab(),
                _buildAlertsTab(),
                _buildForecastTab(),
                _buildAirQualityTab(),
                _buildNotificationSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEWS TAB
  Widget _buildNewsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        if (apiKey != 'YOUR_OPENWEATHER_API_KEY') {
          await fetchAllWeatherData();
        } else {
          loadSampleData();
        }
      },
      child: Column(
        children: [
          _buildRegionSelector(),
          Expanded(
            child: isLoading && weatherNews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'กำลังโหลดข้อมูลสำหรับ $selectedRegion...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : weatherNews.isEmpty
                    ? _buildEmptyState(
                        Icons.newspaper,
                        'ไม่มีข่าวสารในขณะนี้',
                        'ลองเลือกภูมิภาคอื่น หรือดึงข้อมูลอีกครั้ง',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: weatherNews.length,
                        itemBuilder: (context, index) {
                          final news = weatherNews[index];
                          return _buildNewsCard(news);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[600], size: 20),
          SizedBox(width: 12),
          Text(
            'เลือกภูมิภาค:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: DropdownButton<String>(
                value: selectedRegion,
                isExpanded: true,
                underline: SizedBox(),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[600]),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != selectedRegion) {
                    setState(() {
                      selectedRegion = newValue;
                      weatherNews.clear();
                      weatherAlerts.clear();
                    });
                    
                    if (apiKey != 'YOUR_OPENWEATHER_API_KEY') {
                      fetchAllWeatherData();
                    } else {
                      loadSampleDataForRegion(newValue);
                    }
                  }
                },
                items: regions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: value == selectedRegion ? Colors.blue[600] : Colors.grey[700],
                        fontWeight: value == selectedRegion ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ALERTS TAB
  Widget _buildAlertsTab() {
    return weatherAlerts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'ไม่มีการแจ้งเตือน',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
                SizedBox(height: 8),
                Text('สภาพอากาศปกติดี', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: () async {
              if (apiKey != 'YOUR_OPENWEATHER_API_KEY') {
                await fetchAllWeatherData();
              } else {
                loadSampleData();
              }
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: weatherAlerts.length,
              itemBuilder: (context, index) {
                final alert = weatherAlerts[index];
                return _buildAlertCard(alert);
              },
            ),
          );
  }

  // FORECAST TAB
  Widget _buildForecastTab() {
    return weeklyForecast.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('ไม่มีข้อมูลพยากรณ์อากาศ'),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: weeklyForecast.length,
            itemBuilder: (context, index) {
              WeatherForecast forecast = weeklyForecast[index];
              bool isToday = index == 0;
              
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: isToday ? 6 : 3,
                color: isToday ? Colors.blue[50] : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isToday 
                      ? BorderSide(color: Colors.blue[200]!, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        child: Column(
                          children: [
                            Text(
                              isToday ? 'วันนี้' : _getDayName(forecast.date),
                              style: TextStyle(
                                fontWeight: isToday 
                                    ? FontWeight.bold 
                                    : FontWeight.w500,
                                color: isToday ? Colors.blue[700] : null,
                              ),
                            ),
                            Text(
                              '${forecast.date.day}/${forecast.date.month}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        _getWeatherIcon(forecast.weather),
                        style: TextStyle(fontSize: 32),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              forecast.description,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.water_drop, 
                                     size: 16, 
                                     color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  '${forecast.pop.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.air, 
                                     size: 16, 
                                     color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  '${forecast.windSpeed.toStringAsFixed(1)} m/s',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${forecast.maxTemp.toStringAsFixed(0)}°',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.blue[700] : null,
                            ),
                          ),
                          Text(
                            '${forecast.minTemp.toStringAsFixed(0)}°',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // AIR QUALITY TAB
  Widget _buildAirQualityTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (airQualityData.containsKey('current'))
          _buildAirQualityCard(airQualityData['current']!),
        SizedBox(height: 16),
        if (uvIndexData.containsKey('current'))
          _buildUVIndexCard(uvIndexData['current']!),
        SizedBox(height: 16),
        _buildHealthAdviceCard(),
      ],
    );
  }

  Widget _buildAirQualityCard(AirQuality airQuality) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: airQuality.color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'คุณภาพอากาศ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: airQuality.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    airQuality.level,
                    style: TextStyle(
                      color: airQuality.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    airQuality.aqi.toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: airQuality.color,
                    ),
                  ),
                  Text(
                    'AQI (Air Quality Index)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'รายละเอียดสารมลพิษ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            ...airQuality.components.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getPollutantName(entry.key)),
                    Text(
                      '${entry.value.toStringAsFixed(2)} μg/m³',
                      style: TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildUVIndexCard(double uvIndex) {
    Color uvColor = _getUVColor(uvIndex);
    String uvLevel = _getUVLevel(uvIndex);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'ดัชนียูวี (UV Index)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: uvColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    uvLevel,
                    style: TextStyle(
                      color: uvColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    uvIndex.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: uvColor,
                    ),
                  ),
                  Text(
                    _getUVRecommendation(uvIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // COMPLETE HEALTH ADVICE CARD
  Widget _buildHealthAdviceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  'คำแนะนำด้านสุขภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildHealthAdviceItem(
              Icons.masks,
              'การใส่หน้ากาก',
              _getMaskRecommendation(),
            ),
            _buildHealthAdviceItem(
              Icons.directions_run,
              'การออกกำลังกาย',
              _getExerciseRecommendation(),
            ),
            _buildHealthAdviceItem(
              Icons.wb_sunny_outlined,
              'การป้องกันแสงแดด',
              _getSunProtectionRecommendation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthAdviceItem(IconData icon, String title, String advice) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  advice,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NOTIFICATION SETTINGS TAB
  Widget _buildNotificationSettingsTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildNotificationCard(
          'การแจ้งเตือนตอนเช้า',
          Icons.alarm,
          Colors.orange,
          [
            SwitchListTile(
              title: Text('เปิดการแจ้งเตือนตอนเช้า'),
              subtitle: Text('ดูสภาพอากาศก่อนเริ่มต้นวัน'),
              value: notificationSettings.morningAlert,
              onChanged: (value) {
                setState(() {
                  notificationSettings = notificationSettings.copyWith(
                    morningAlert: value,
                  );
                });
                saveNotificationSettings();
                if (value) {
                  setupScheduledNotifications();
                } else {
                  scheduledNotificationTimer?.cancel();
                }
              },
            ),
            if (notificationSettings.morningAlert)
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.orange),
                title: Text('เวลาแจ้งเตือน'),
                subtitle: Text(
                  '${notificationSettings.morningTime.hour.toString().padLeft(2, '0')}:${notificationSettings.morningTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: notificationSettings.morningTime,
                  );
                  if (picked != null) {
                    setState(() {
                      notificationSettings = notificationSettings.copyWith(
                        morningTime: picked,
                      );
                    });
                    saveNotificationSettings();
                    setupScheduledNotifications();
                  }
                },
              ),
          ],
        ),
        //
        SizedBox(height: 16),
        _buildNotificationCard(
          'การแจ้งเตือนพิเศษ',
          Icons.warning,
          Colors.red,
          [
            SwitchListTile(
              title: Text('แจ้งเตือนฝนตก'),
              subtitle: Text('เตือนเมื่อมีโอกาสฝนตกสูง'),
              value: notificationSettings.rainAlert,
              onChanged: (value) {
                setState(() {
                  notificationSettings = notificationSettings.copyWith(
                    rainAlert: value,
                  );
                });
                saveNotificationSettings();
              },
            ),
            SwitchListTile(
              title: Text('แจ้งเตือนอุณหภูมิสูง'),
              subtitle: Text('เตือนเมื่ออุณหภูมิเกิน ${notificationSettings.temperatureThreshold.toStringAsFixed(0)}°C'),
              value: notificationSettings.temperatureAlert,
              onChanged: (value) {
                setState(() {
                  notificationSettings = notificationSettings.copyWith(
                    temperatureAlert: value,
                  );
                });
                saveNotificationSettings();
              },
            ),
            SwitchListTile(
              title: Text('แจ้งเตือน UV Index สูง'),
              subtitle: Text('เตือนเมื่อ UV Index เกิน ${notificationSettings.uvThreshold}'),
              value: notificationSettings.uvAlert,
              onChanged: (value) {
                setState(() {
                  notificationSettings = notificationSettings.copyWith(
                    uvAlert: value,
                  );
                });
                saveNotificationSettings();
              },
            ),
            SwitchListTile(
              title: Text('แจ้งเตือนคุณภาพอากาศ'),
              subtitle: Text('เตือนเมื่อคุณภาพอากาศแย่'),
              value: notificationSettings.airQualityAlert,
              onChanged: (value) {
                setState(() {
                  notificationSettings = notificationSettings.copyWith(
                    airQualityAlert: value,
                  );
                });
                saveNotificationSettings();
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildThresholdSettingsCard(),
      ],
    );
  }

  Widget _buildNotificationCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThresholdSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.purple, size: 24),
                SizedBox(width: 12),
                Text(
                  'การตั้งค่าขีดจำกัด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'อุณหภูมิเตือนภัย: ${notificationSettings.temperatureThreshold.toStringAsFixed(0)}°C',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: notificationSettings.temperatureThreshold,
              min: 30,
              max: 45,
              divisions: 15,
              label: '${notificationSettings.temperatureThreshold.toStringAsFixed(0)}°C',
              onChanged: (value) {
                setState(() {
                  notificationSettings = notificationSettings.copyWith(
                    temperatureThreshold: value,
                  );
                });
              },
              onChangeEnd: (value) {
                saveNotificationSettings();
              },
            ),
            SizedBox(height: 16),
            Text(
              'UV Index เตือนภัย: ${notificationSettings.uvThreshold}',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: notificationSettings.uvThreshold.toDouble(),
              min: 3,
              max: 11,
              divisions: 8,
              label: notificationSettings.uvThreshold.toString(),
              onChanged: (value) {
                setState(() {
                  notificationSettings = notificationSettings.copyWith(
                    uvThreshold: value.round(),
                  );
                });
              },
              onChangeEnd: (value) {
                saveNotificationSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== UTILITY FUNCTIONS =====

  String _getDayName(DateTime date) {
    List<String> days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return days[date.weekday - 1];
  }

  String _getPollutantName(String key) {
    switch (key) {
      case 'co': return 'คาร์บอนมอนอกไซด์';
      case 'no2': return 'ไนโตรเจนไดออกไซด์';
      case 'o3': return 'โอโซน';
      case 'pm2_5': return 'PM2.5';
      case 'pm10': return 'PM10';
      default: return key.toUpperCase();
    }
  }

  Color _getUVColor(double uvIndex) {
    if (uvIndex <= 2) return Colors.green;
    if (uvIndex <= 5) return Colors.yellow;
    if (uvIndex <= 7) return Colors.orange;
    if (uvIndex <= 10) return Colors.red;
    return Colors.purple;
  }

  String _getUVLevel(double uvIndex) {
    if (uvIndex <= 2) return 'ต่ำ';
    if (uvIndex <= 5) return 'ปานกลาง';
    if (uvIndex <= 7) return 'สูง';
    if (uvIndex <= 10) return 'สูงมาก';
    return 'อันตราย';
  }

  String _getUVRecommendation(double uvIndex) {
    if (uvIndex <= 2) return 'สามารถอยู่กลางแจ้งได้อย่างปลอดภัย';
    if (uvIndex <= 5) return 'ใส่หมวกและแว่นกันแดด ทาครีมกันแดด';
    if (uvIndex <= 7) return 'หลีกเลี่ยงแสงแดดช่วงเที่ยง ป้องกันตัวให้ดี';
    if (uvIndex <= 10) return 'อยู่ในร่มช่วงเที่ยง ป้องกันตัวเต็มที่';
    return 'หลีกเลี่ยงการออกกลางแจ้งโดยสิ้นเชิง';
  }

  String _getMaskRecommendation() {
    if (airQualityData.containsKey('current')) {
      AirQuality aqi = airQualityData['current']!;
      if (aqi.aqi >= 4) return 'แนะนำใส่หน้ากาก N95 เมื่อออกกลางแจ้ง';
      if (aqi.aqi >= 3) return 'ควรใส่หน้ากากเมื่อออกกลางแจ้งนาน';
      return 'ไม่จำเป็นต้องใส่หน้ากากพิเศษ';
    }
    return 'ไม่มีข้อมูลคุณภาพอากาศ';
  }

  String _getExerciseRecommendation() {
    if (airQualityData.containsKey('current')) {
      AirQuality aqi = airQualityData['current']!;
      if (aqi.aqi >= 4) return 'หลีกเลี่ยงการออกกำลังกายกลางแจ้ง';
      if (aqi.aqi >= 3) return 'ลดความหนักของการออกกำลังกายกลางแจ้ง';
      return 'สามารถออกกำลังกายกลางแจ้งได้ตามปกติ';
    }
    return 'ไม่มีข้อมูลคุณภาพอากาศ';
  }

  String _getSunProtectionRecommendation() {
    if (uvIndexData.containsKey('current')) {
      double uv = uvIndexData['current']!;
      if (uv >= 8) return 'ใส่เสื้อผ้าแขนยาว หมวกปีกกว้าง และแว่นกันแดด';
      if (uv >= 6) return 'ทาครีมกันแดด SPF 30+ ใส่หมวกและแว่นกันแดด';
      if (uv >= 3) return 'ทาครีมกันแดดเมื่อออกกลางแจ้งนาน';
      return 'ไม่จำเป็นป้องกันแสงแดดพิเศษ';
    }
    return 'ไม่มีข้อมูล UV Index';
  }

  String _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      case 'drizzle':
        return '🌦️';
      default:
        return '🌤️';
    }
  }

  // ===== NEWS HELPER FUNCTIONS =====

  Map<String, dynamic> createNewsItem(Map<String, dynamic> data, String city) {
    double temp = data['main']['temp']?.toDouble() ?? 0.0;
    String weatherMain = data['weather'][0]['main'] ?? '';
    String description = data['weather'][0]['description'] ?? '';
    DateTime now = DateTime.now();

    String headline = generateHeadline(temp, weatherMain, city);
    String content = generateNewsContent(data, city);
    String category = categorizeWeather(weatherMain, temp);

    return {
      'id': '${city}_${now.millisecondsSinceEpoch}',
      'headline': headline,
      'content': content,
      'city': city,
      'temperature': temp,
      'weather': weatherMain,
      'description': description,
      'category': category,
      'timestamp': now.toIso8601String(),
      'priority': calculatePriority(temp, weatherMain),
      'icon': _getWeatherIcon(weatherMain),
    };
  }

  String generateHeadline(double temp, String weatherMain, String city) {
    if (temp > 38) {
      return 'อุณหภูมิสูงมากที่ $city ถึง ${temp.toStringAsFixed(1)}°C';
    } else if (temp > 35) {
      return 'อากาศร้อนจัดที่ $city ${temp.toStringAsFixed(1)}°C';
    } else if (weatherMain == 'Thunderstorm') {
      return 'เตือน! พายุฟ้าร้องที่ $city';
    } else if (weatherMain == 'Rain') {
      return 'ฝนตกในพื้นที่ $city';
    } else if (temp < 20) {
      return 'อากาศเย็นที่ $city ${temp.toStringAsFixed(1)}°C';
    } else {
      return 'สภาพอากาศปกติที่ $city ${temp.toStringAsFixed(1)}°C';
    }
  }

  String generateNewsContent(Map<String, dynamic> data, String city) {
    double temp = data['main']['temp']?.toDouble() ?? 0.0;
    double feelsLike = data['main']['feels_like']?.toDouble() ?? 0.0;
    String description = data['weather'][0]['description'] ?? '';
    double humidity = data['main']['humidity']?.toDouble() ?? 0.0;
    double windSpeed = data['wind']?['speed']?.toDouble() ?? 0.0;
    double pressure = data['main']['pressure']?.toDouble() ?? 0.0;

    String content =
        'รายงานสภาพอากาศจาก $city ณ วันที่ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n';
    content += 'สภาพอากาศ: $description\n';
    content +=
        'อุณหภูมิ: ${temp.toStringAsFixed(1)}°C (รู้สึกเหมือน ${feelsLike.toStringAsFixed(1)}°C)\n';
    content += 'ความชื้น: ${humidity.toStringAsFixed(0)}%\n';
    content += 'ความเร็วลม: ${windSpeed.toStringAsFixed(1)} m/s\n';
    content += 'ความกดอากาศ: ${pressure.toStringAsFixed(0)} hPa\n\n';

    if (temp > 35) {
      content +=
          'คำแนะนำ: หลีกเลี่ยงการออกกลางแจ้งในช่วงเที่ยง ดื่มน้ำเพียงพอ สวมหมวกและใช้ครีมกันแดด';
    } else if (data['weather'][0]['main'] == 'Rain') {
      content += 'คำแนะนำ: เตรียมร่มหรือเสื้อกันฝน ระวังการเดินทาง';
    } else if (windSpeed > 10) {
      content +=
          'คำแนะนำ: ระวังวัตถุที่อาจปลิวมา หลีกเลี่ยงการจอดรถใต้ป้ายโฆษณา';
    } else {
      content += 'สภาพอากาศเหมาะสำหรับกิจกรรมกลางแจ้ง';
    }

    return content;
  }

  String categorizeWeather(String weatherMain, double temp) {
    if (temp > 35) return 'อันตราย';
    if (weatherMain == 'Thunderstorm') return 'เตือนภัย';
    if (weatherMain == 'Rain') return 'ฝนตก';
    if (temp < 20) return 'อากาศเย็น';
    return 'ปกติ';
  }

  int calculatePriority(double temp, String weatherMain) {
    if (temp > 38 || weatherMain == 'Thunderstorm') return 3;
    if (temp > 35 || weatherMain == 'Rain') return 2;
    return 1;
  }

  // ===== UI HELPER FUNCTIONS =====

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(news['icon'] ?? '🌤️', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news['headline'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${news['city']} • ${_formatTime(news['timestamp'])}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    news['category'] ?? 'ปกติ',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              news['content'] ?? '',
              style: TextStyle(height: 1.5, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    Color alertColor = _getSeverityColor(alert['severity'] ?? 'low');

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: alertColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: alertColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: alertColor, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert['type'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: alertColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alertColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (alert['severity'] ?? 'low').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              alert['message'] ?? '',
              style: TextStyle(height: 1.5, fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${alert['city']} • ${_formatTime(alert['timestamp'])}',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'ไม่ทราบเวลา';
    }

    try {
      DateTime dateTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();
      Duration difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'เมื่อสักครู่';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} นาทีที่แล้ว';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ชั่วโมงที่แล้ว';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} วันที่แล้ว';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'ไม่ทราบเวลา';
    }
  }

  // ===== DATA MANAGEMENT FUNCTIONS =====

  Future<void> saveNewsData(
    List<Map<String, dynamic>> news,
    List<Map<String, dynamic>> alerts,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_news', json.encode(news));
      await prefs.setString('cached_alerts', json.encode(alerts));
      await prefs.setString('last_update', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  void loadSampleData() {
    setState(() {
      weatherNews = [
        {
          'id': 'sample1',
          'headline': 'อากาศร้อนจัดที่กรุงเทพมหานคร 36.5°C',
          'content':
              'รายงานสภาพอากาศจากกรุงเทพมหานคร ณ วันที่ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\nสภาพอากาศ: แสงแดดจัด\nอุณหภูมิ: 36.5°C (รู้สึกเหมือน 39.2°C)\nความชื้น: 65%\nความเร็วลม: 3.2 m/s\nความกดอากาศ: 1012 hPa\n\nคำแนะนำ: หลีกเลี่ยงการออกกลางแจ้งในช่วงเที่ยง ดื่มน้ำเพียงพอ สวมหมวกและใช้ครีมกันแดด',
          'city': 'กรุงเทพมหานคร',
          'temperature': 36.5,
          'weather': 'Clear',
          'description': 'แสงแดดจัด',
          'category': 'อันตราย',
          'timestamp': DateTime.now().toIso8601String(),
          'priority': 2,
          'icon': '☀️',
        },
        {
          'id': 'sample2',
          'headline': 'ฝนตกในพื้นที่เชียงใหม่',
          'content':
              'รายงานสภาพอากาศจากเชียงใหม่ ณ วันที่ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\nสภาพอากาศ: ฝนฟ้าคะนอง\nอุณหภูมิ: 28.3°C (รู้สึกเหมือน 31.1°C)\nความชื้น: 85%\nความเร็วลม: 5.8 m/s\nความกดอากาศ: 1008 hPa\n\nคำแนะนำ: เตรียมร่มหรือเสื้อกันฝน ระวังการเดินทาง',
          'city': 'เชียงใหม่',
          'temperature': 28.3,
          'weather': 'Rain',
          'description': 'ฝนฟ้าคะนอง',
          'category': 'ฝนตก',
          'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
          'priority': 2,
          'icon': '🌧️',
        },
      ];

      weatherAlerts = [
        {
          'id': 'alert1',
          'type': 'อุณหภูมิสูง',
          'message':
              'อุณหภูมิในพื้นที่กรุงเทพมหานคร สูงถึง 36.5°C โปรดระวังโรคลมแดดและดื่มน้ำเพียงพอ',
          'city': 'กรุงเทพมหานคร',
          'severity': 'medium',
          'timestamp': DateTime.now().toIso8601String(),
        },
        {
          'id': 'alert2',
          'type': 'เตือนฝนตก',
          'message': 'มีฝนตกในพื้นที่เชียงใหม่ อย่าลืมเตรียมร่ม',
          'city': 'เชียงใหม่',
          'severity': 'low',
          'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        },
      ];

      // Sample forecast data
      weeklyForecast = List.generate(7, (index) {
        DateTime date = DateTime.now().add(Duration(days: index));
        return WeatherForecast(
          date: date,
          maxTemp: 34.0 + (index * 0.5) - (index > 3 ? 2 : 0),
          minTemp: 26.0 + (index * 0.3),
          weather: index % 3 == 0 ? 'Rain' : (index % 2 == 0 ? 'Clouds' : 'Clear'),
          description: index % 3 == 0 ? 'ฝนฟ้าคะนอง' : (index % 2 == 0 ? 'เมฆบางส่วน' : 'แสงแดดจัด'),
          icon: '01d',
          humidity: 60 + (index * 3),
          windSpeed: 2.5 + (index * 0.3),
          pop: index % 3 == 0 ? 80 : (index % 2 == 0 ? 30 : 10),
        );
      });

      // Sample air quality data
      airQualityData['current'] = AirQuality(
        aqi: 2,
        level: 'ดี',
        color: Colors.lightGreen,
        components: {
          'co': 200.5,
          'no2': 25.3,
          'o3': 68.2,
          'pm2_5': 15.8,
          'pm10': 22.4,
        },
      );

      // Sample UV data
      uvIndexData['current'] = 7.5;
    });
  }

  void loadSampleDataForRegion(String region) {
    List<String> cities = regionCities[region] ?? ['เมืองตัวอย่าง'];
    
    setState(() {
      weatherNews = cities.asMap().entries.map((entry) {
        int index = entry.key;
        String city = entry.value;
        double temp = 30.0 + (index * 2) + (region == 'ภาคใต้' ? -2 : 0);
        
        return {
          'id': '${city}_sample',
          'headline': temp > 35 ? 'อากาศร้อนจัดที่ $city ${temp.toStringAsFixed(1)}°C' : 'สภาพอากาศปกติที่ $city',
          'content': 'รายงานสภาพอากาศจาก $city ณ วันที่ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n'
                    'สภาพอากาศ: ${temp > 35 ? "แสงแดดจัด" : "เมฆบางส่วน"}\n'
                    'อุณหภูมิ: ${temp.toStringAsFixed(1)}°C\n'
                    'ความชื้น: ${60 + (index * 5)}%\n'
                    'ความเร็วลม: ${2.0 + (index * 0.5)} m/s\n\n'
                    '${temp > 35 ? "คำแนะนำ: หลีกเลี่ยงการออกกลางแจ้งในช่วงเที่ยง" : "สภาพอากาศเหมาะสำหรับกิจกรรมกลางแจ้ง"}',
          'city': city,
          'temperature': temp,
          'weather': temp > 35 ? 'Clear' : 'Clouds',
          'description': temp > 35 ? 'แสงแดดจัด' : 'เมฆบางส่วน',
          'category': temp > 35 ? 'อันตราย' : 'ปกติ',
          'timestamp': DateTime.now().subtract(Duration(minutes: index * 15)).toIso8601String(),
          'priority': temp > 35 ? 2 : 1,
          'icon': temp > 35 ? '☀️' : '☁️',
        };
      }).toList();

      // สร้างการแจ้งเตือนตัวอย่างสำหรับภูมิภาคที่เลือก
      weatherAlerts = [];
      for (int i = 0; i < cities.length; i++) {
        double temp = 30.0 + (i * 2) + (region == 'ภาคใต้' ? -2 : 0);
        if (temp > 35) {
          weatherAlerts.add({
            'id': '${cities[i]}_temp_alert',
            'type': 'อุณหภูมิสูง',
            'message': 'อุณหภูมิในพื้นที่${cities[i]} สูงถึง ${temp.toStringAsFixed(1)}°C โปรดระวังโรคลมแดด',
            'city': cities[i],
            'severity': temp > 38 ? 'high' : 'medium',
            'timestamp': DateTime.now().subtract(Duration(minutes: i * 10)).toIso8601String(),
          });
        }
      }
    });
  }

  @override
  void dispose() {
    newsTimer?.cancel();
    scheduledNotificationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}