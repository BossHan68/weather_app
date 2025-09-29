// screens/weather_details_screen.dart (อัปเดต)
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  WeatherDetailsScreen({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${weatherData['name']} Weather")),
      body: SingleChildScrollView(
        //ลื่อนด
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ข้อมูลหลักของสภาพอากาศ
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "${weatherData['name']}, ${weatherData['sys']['country']}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    //dt
                    Text(
                      "${weatherData['main']['temp']}°C",
                      style: TextStyle(fontSize: 48),
                    ),
                    Text(
                      "${weatherData['weather'][0]['description']}",
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("รู้สึกเหมือน: "),
                        Text(
                          "${weatherData['main']['feels_like']}°C",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "รายละเอียด",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      "อุณหภูมิสูงสุด",
                      "${weatherData['main']['temp_max']}°C",
                    ),
                    _buildDetailRow(
                      "อุณหภูมิต่ำสุด",
                      "${weatherData['main']['temp_min']}°C",
                    ),
                    _buildDetailRow(
                      "ความชื้น",
                      "${weatherData['main']['humidity']}%",
                    ),
                    _buildDetailRow(
                      "ความกดอากาศ",
                      "${weatherData['main']['pressure']} hPa",
                    ),
                    _buildDetailRow(
                      "ความเร็วลม",
                      "${weatherData['wind']['speed']} m/s",
                    ),
                    _buildDetailRow(
                      "ทิศทางลม",
                      "${weatherData['wind']['deg']}°",
                    ),
                    if (weatherData['rain'] != null)
                      _buildDetailRow(
                        "ปริมาณฝน (1h)",
                        "${weatherData['rain']['1h']} mm",
                      ),
                    if (weatherData['clouds'] != null)
                      _buildDetailRow(
                        "เมฆปกคลุม",
                        "${weatherData['clouds']['all']}%",
                      ),
                    _buildDetailRow(
                      "พระอาทิตย์ขึ้น",
                      _formatTime(
                        weatherData['sys']['sunrise'],
                        weatherData['timezone'],
                      ),
                    ),
                    _buildDetailRow(
                      "พระอาทิตย์ตก",
                      _formatTime(
                        weatherData['sys']['sunset'],
                        weatherData['timezone'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add_location),
              label: Text("เพิ่มเมืองนี้"),
              onPressed: () async {
                final success = await ApiService.saveCity(weatherData['name']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "บันทึกเมือง ${weatherData['name']} เรียบร้อยแล้ว"
                          : "ไม่สามารถบันทึกเมืองได้",
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(int timestamp, int timezone) {
    // แปลง timestamp (หน่วยวินาที) เป็น DateTime ในรูปแบบ UTC
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    // ปรับเวลาตาม timezone
    dateTime = dateTime.add(Duration(seconds: timezone));

    // แปลงเป็นรูปแบบ HH:mm เช่น 14:05
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}"; //ทำให้เวลาแสดงเป็น สองหลัก เช่น 09:05 แทน 9:5
  }
}
