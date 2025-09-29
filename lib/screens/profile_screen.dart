import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController =
      TextEditingController(); // Changed from email
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? imagePath = prefs.getString('profileImagePath');
      final String name = prefs.getString('userName') ?? '';
      final String studentId =
          prefs.getString('studentId') ?? ''; // Changed from userEmail

      setState(() {
        if (imagePath != null && File(imagePath).existsSync()) {
          _profileImage = File(imagePath);
        }
        _nameController.text = name;
        _studentIdController.text = studentId; // Changed from email
      });
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString(
      'studentId',
      _studentIdController.text,
    ); // Changed from userEmail

    if (_profileImage != null) {
      await prefs.setString('profileImagePath', _profileImage!.path);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')));
  }

  // ฟังก์ชันสำหรับแสดงรูปภาพแบบเต็มจอ
  void _showFullScreenImage() {
    if (_profileImage == null) return; // ไม่ทำอะไรถ้าไม่มีรูปภาพ

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageFile: _profileImage!),
      ),
    );
  }

  // เพิ่มฟังก์ชันสำหรับใส่ที่อยู่ไฟล์รูปโดยตรง
  void _showImagePathInputDialog() {
    final TextEditingController pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("ใส่ที่อยู่ไฟล์รูปภาพ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: 'ที่อยู่ไฟล์รูปภาพ',
                  hintText: '/storage/emulated/0/Download/profile.jpg',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "หมายเหตุ: ต้องเป็นที่อยู่ไฟล์เต็มในเครื่อง",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () async {
                final path = pathController.text.trim();
                if (path.isNotEmpty) {
                  try {
                    final file = File(path);
                    if (await file.exists()) {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final File newImage = await file.copy(
                        '${directory.path}/profile_image_file.jpg',
                      );

                      setState(() {
                        _profileImage = newImage;
                      });
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ไม่พบไฟล์ที่ระบุ')),
                      );
                    }
                  } catch (e) {
                    print('Error loading image from path: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ไม่สามารถโหลดรูปภาพได้: $e')),
                    );
                  }
                }
              },
              child: Text("ยืนยัน"),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("เลือกรูปโปรไฟล์"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.file_present),
                title: Text("ใส่ที่อยู่ไฟล์โดยตรง"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showImagePathInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("โปรไฟล์ของฉัน"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveUserData,
            tooltip: "บันทึกข้อมูล",
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap:
                          _showFullScreenImage, // เพิ่ม event เมื่อกดที่รูปโปรไฟล์
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                            child:
                                _profileImage == null
                                    ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, color: Colors.blue),
                              onPressed: _showImageSourceDialog,
                            ),
                          ),
                          if (_profileImage != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _studentIdController, // Changed from email
                      decoration: InputDecoration(
                        labelText: 'รหัสนักศึกษา', // Changed label
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers), // Changed icon
                      ),
                      keyboardType: TextInputType.number, // Changed to number
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveUserData,
                      child: Text("บันทึกข้อมูล"),
                    ),
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose(); // Changed from email
    super.dispose();
  }
}

// สร้าง Widget ใหม่สำหรับแสดงรูปภาพแบบเต็มจอ
class FullScreenImageView extends StatelessWidget {
  final File imageFile;

  const FullScreenImageView({Key? key, required this.imageFile})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('รูปโปรไฟล์', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
