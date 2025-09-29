// screens/about_screen.dart (อัปเดต)
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("เกี่ยวกับ")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            Icon(Icons.cloud, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              "Weather Forecast App",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("เวอร์ชัน 1.0.0", style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            Text(
              "แอปพลิเคชันพยากรณ์อากาศนี้สร้างขึ้นเพื่อให้ข้อมูลสภาพอากาศปัจจุบันของเมืองต่างๆ ทั่วโลก",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              "แอปพลิเคชันนี้ใช้ API จาก OpenWeatherMap",
              textAlign: TextAlign.center,
            ),
            Spacer(),
            Text("© 2025 Weather App", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
