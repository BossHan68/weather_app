import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState(); // คืนค่าคลาส _LocationScreenState ที่จะจัดการสถานะ
}

class _LocationScreenState extends State<LocationScreen> {
  String location = "Getting location..."; // ตัวแปรเก็บข้อความที่จะแสดงตำแหน่ง

  void getLocation() async {
    // ดึงตำแหน่งที่ตั้ง ปจบ Geolocator
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // (ความแม่นยำสูง)
    );
    setState(() {
      // อัพเดตค่า location ด้วยตำแหน่งที่ได้ (latitude และ longitude)
      location =
          "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });
  }

  //  initState
  @override
  void initState() {
    super.initState(); // เรียก initState
    getLocation(); // เรียกฟังก์ชัน getLocation
  }

  //  build  UI ของหน้าจอ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Current Location"),
      ), // สร้าง AppBar ที่มีข้อความ "Current Location"
      body: Center(
        // แสดงตำแหน่งใน Text widget ที่อยู่ตรงกลางหน้าจอ
        child: Text(location),
      ),
    );
  }
}
