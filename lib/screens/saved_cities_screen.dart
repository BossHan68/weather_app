import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SavedCitiesScreen extends StatefulWidget {
  @override
  _SavedCitiesScreenState createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends State<SavedCitiesScreen> {
  List<String> savedCities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCities();
  }

  //จัดการข้อมูล
  void _loadSavedCities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      savedCities = await ApiService.getSavedCities();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "ไม่สามารถโหลดข้อมูลเมืองที่บันทึกได้: $e";
      });
    }
  }

  //ใช้ดึงข้อมูลสภาพอากาศของเมืองที่ผู้ใช้เลือก
  //หากโหลดสำเร็จจะไปยังหน้ารายละเอียด (/weather-details)
  void _viewCityWeather(String cityName) async {
    final weatherData = await ApiService.fetchWeather(cityName);
    if (weatherData != null && !weatherData.containsKey('error')) {
      Navigator.pushNamed(context, '/weather-details', arguments: weatherData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถโหลดข้อมูลสำหรับเมือง $cityName")),
      );
    }
  }

  //_deleteCity(String cityName)
  //เรียก _showDeleteConfirmationDialog() เพื่อยืนยันก่อนลบ
  void _deleteCity(String cityName) async {
    bool confirmDelete = await _showDeleteConfirmationDialog(cityName);
    if (confirmDelete) {
      try {
        await ApiService.deleteSavedCity(cityName);
        setState(() {
          savedCities.remove(cityName);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ลบ $cityName ออกจากรายการเรียบร้อยแล้ว")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ไม่สามารถลบ $cityName ได้: $e")),
        );
      }
    }
  }

  //m UI (Dialog & Navigation)
  //ใช้แสดง AlertDialog เพื่อยืนยันว่าผู้ใช้ต้องการลบเมืองหรือไม่
  Future<bool> _showDeleteConfirmationDialog(String cityName) async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text("ลบเมือง"),
                content: Text(
                  "คุณแน่ใจหรือไม่ว่าต้องการลบ $cityName ออกจากรายการ?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("ยกเลิก"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text("ลบ", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
        ) ??
        false;
  }

  //ใช้บันทึกเมืองที่เลือกเป็นเมืองหลักในหน้า Home
  void _saveCityToHome(String cityName) async {
    try {
      await ApiService.saveCityToHome(cityName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$cityName ถูกเพิ่มไปยังหน้าแรกแล้ว")),
      );
      // ไปยังหน้า Home หลังจากบันทึกเมืองสำเร็จ
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถเพิ่ม $cityName ไปยังหน้าแรกได้: $e")),
      );
    }
  }

  //Widget (onPressed & onTap)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("เมืองที่บันทึกไว้"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedCities,
            tooltip: "รีเฟรช",
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : savedCities.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_city, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "ยังไม่มีเมืองที่บันทึกไว้",
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.search),
                      label: Text("ค้นหาและเพิ่มเมืองใหม่"),
                      onPressed: () => Navigator.pushNamed(context, '/search'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: savedCities.length,
                itemBuilder: (context, index) {
                  String city = savedCities[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.location_city),
                      title: Text(city),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: Icon(Icons.star, color: Colors.amber),
                            onPressed: () => _saveCityToHome(city),
                            tooltip: "บันทึกไปหน้า Home",
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCity(city),
                            tooltip: "ลบเมือง",
                          ),
                        ],
                      ),
                      onTap: () => _viewCityWeather(city),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/search'),
        child: Icon(Icons.add),
        tooltip: "เพิ่มเมืองใหม่",
      ),
    );
  }
}
