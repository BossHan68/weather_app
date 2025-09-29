// Updated screens/search_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String? errorMessage;
  bool isSaving = false;
  String? saveMessage;
  //ค้นหาเมืองและโหลดข้อมูลอากาศ
  void searchCity() async {
    if (_controller.text.isEmpty) {
      setState(() {
        errorMessage = "กรุณาระบุชื่อเมือง";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      saveMessage = null;
    });

    try {
      final data = await ApiService.fetchWeather(_controller.text);
      setState(() {
        weatherData = data;
        isLoading = false;
        if (data == null || data.containsKey('error')) {
          errorMessage = "ไม่พบข้อมูลเมืองนี้";
          weatherData = null;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "เกิดข้อผิดพลาดในการค้นหา: $e";
        weatherData = null;
      });
    }
  }

  //
  void saveCity() async {
    if (weatherData == null || !weatherData!.containsKey('name')) return;

    setState(() {
      isSaving = true;
      saveMessage = null;
    });

    try {
      final success = await ApiService.saveCity(weatherData!['name']);
      setState(() {
        isSaving = false;
        saveMessage =
            success
                ? "บันทึกเมือง ${weatherData!['name']} เรียบร้อยแล้ว"
                : "ไม่สามารถบันทึกเมืองได้";
      });
      //next-saved-cities
      if (success) {
        Navigator.pushReplacementNamed(context, '/saved');
      }
    } catch (e) {
      setState(() {
        isSaving = false;
        saveMessage = "เกิดข้อผิดพลาดในการบันทึก: $e";
      });
    }
  }

  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ค้นหาเมือง")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "ระบุชื่อเมือง",
                hintText: "เช่น Bangkok, London, Tokyo",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              //กด Enter แล้วค้นหา
              onSubmitted: (_) => searchCity(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : searchCity,
              child: Text("ค้นหา"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 8),
            if (isLoading) Center(child: CircularProgressIndicator()),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (weatherData != null)
              Card(
                margin: EdgeInsets.symmetric(vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "${weatherData!['name']}",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${weatherData!['main']['temp']}°C",
                        style: TextStyle(fontSize: 48),
                      ),
                      Text(
                        "${weatherData!['weather'][0]['description']}",
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text("ความชื้น"),
                              Text("${weatherData!['main']['humidity']}%"),
                            ],
                          ),
                          Column(
                            children: [
                              Text("ความเร็วลม"),
                              Text("${weatherData!['wind']['speed']} m/s"),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add_location),
                        label: Text("เพิ่มเมืองนี้"),
                        onPressed: isSaving ? null : saveCity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                      if (isSaving)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (saveMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            saveMessage!,
                            style: TextStyle(
                              color:
                                  saveMessage!.startsWith("บันทึก")
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
