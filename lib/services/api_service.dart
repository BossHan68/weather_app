import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost/weather_api";

  // 📌 ดึงข้อมูลสภาพอากาศของเมือง
  static Future<Map<String, dynamic>?> fetchWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/weather_api.php?city=$city"),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print("📌 Weather API Response: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("🚨 HTTP Error: ${response.statusCode}");
        return {"error": "เกิดข้อผิดพลาดในการโหลดข้อมูล"};
      }
    } catch (e) {
      print("🚨 Fetch Weather Error: $e");
      return {"error": "เกิดข้อผิดพลาดในการโหลดข้อมูล"};
    }
  }

  // 📌 ดึงข้อมูลสภาพอากาศของเมือง (alias สำหรับ fetchWeather)
  static Future<Map<String, dynamic>?> getWeatherData(String city) async {
    return await fetchWeather(city);
  }

  // 📌 บันทึกเมืองลงฐานข้อมูล
  static Future<bool> saveCity(String cityName) async {
    try {
      print("📌 Saving city: $cityName"); // Debug log
      
      final response = await http.post(
        Uri.parse("$baseUrl/saved_cities.php"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'city_name': cityName},
      );

      print("📌 Save City Response Status: ${response.statusCode}");
      print("📌 Save City Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          return result['success'] == true || result['message'] != null;
        } catch (e) {
          print("🚨 JSON Decode Error in saveCity: $e");
          return false;
        }
      } else {
        print("🚨 HTTP Error in saveCity: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("🚨 Save City Error: $e");
      return false;
    }
  }

  // 📌 ดึงรายชื่อเมืองที่บันทึกไว้
  static Future<List<String>> getSavedCities() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/saved_cities.php"),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("📌 Get Saved Cities Response Status: ${response.statusCode}");
      print("📌 Get Saved Cities Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final dynamic responseData = json.decode(response.body);
          
          // ตรวจสอบว่าเป็น array หรือไม่
          if (responseData is List) {
            return responseData
                .map((city) => city['city_name'] as String)
                .toList();
          } else if (responseData is Map && responseData.containsKey('error')) {
            print("🚨 API Error: ${responseData['error']}");
            return [];
          } else {
            print("🚨 Unexpected response format: $responseData");
            return [];
          }
        } catch (e) {
          print("🚨 JSON Decode Error in getSavedCities: $e");
          return [];
        }
      } else {
        print("🚨 HTTP Error in getSavedCities: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🚨 Get Saved Cities Error: $e");
      return [];
    }
  }

  // 🔥 ลบเมืองที่บันทึกไว้
  static Future<bool> deleteSavedCity(String cityName) async {
    try {
      print("📌 Deleting city: $cityName"); // Debug log
      
      final response = await http.post(
        Uri.parse("$baseUrl/delete_city.php"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {"city": cityName},
      );

      print("📌 Delete City Response Status: ${response.statusCode}");
      print("📌 Delete City Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          return result['message'] == "ลบเมืองสำเร็จ" || result['success'] == true;
        } catch (e) {
          print("🚨 JSON Decode Error in deleteSavedCity: $e");
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print("🚨 Delete City Error: $e");
      return false;
    }
  }

  // ⭐ บันทึกเมืองไปหน้า Home
  static Future<bool> saveCityToHome(String cityName) async {
    try {
      print("📌 Saving city to home: $cityName"); // Debug log
      
      final response = await http.post(
        Uri.parse("$baseUrl/save_city_to_home.php"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {"city": cityName},
      );

      print("📌 Save City To Home Response Status: ${response.statusCode}");
      print("📌 Save City To Home Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          return result['success'] == true;
        } catch (e) {
          print("🚨 JSON Decode Error in saveCityToHome: $e");
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print("🚨 Save City To Home Error: $e");
      return false;
    }
  }

  // 🏠 ดึงเมืองหลักสำหรับหน้า Home
  static Future<String?> getHomeCity() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_home_city.php"),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("📌 Get Home City Response Status: ${response.statusCode}");
      print("📌 Get Home City Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          if (result['success'] == true && result['city'] != null) {
            return result['city'];
          } else {
            return null; // ไม่มีเมืองหลัก ใช้ default
          }
        } catch (e) {
          print("🚨 JSON Decode Error in getHomeCity: $e");
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("🚨 Get Home City Error: $e");
      return null;
    }
  }
}