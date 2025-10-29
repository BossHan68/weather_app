import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';

/// โปรไฟล์ที่รองรับ "ลากไฟล์รูปจาก File Explorer มาวาง" ได้ทันที
/// - Desktop: ลากรูปมาปล่อยที่วงกลมโปรไฟล์ได้เลย (Windows/macOS/Linux)
/// - ทุกแพลตฟอร์ม: แตะปุ่มกล้องเพื่อเลือกไฟล์ด้วยไฟล์พิกเกอร์
/// - แตะรูปเพื่อดูแบบเต็มจอ (ซูม/แพนได้)
/// - เก็บ Path/ชื่อ/รหัสนักศึกษา ไว้ใน SharedPreferences
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  bool _isLoading = true;
  bool _dragging = false;

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final imgPath = prefs.getString('profileImagePath');
      final name = prefs.getString('userName') ?? '';
      final sid = prefs.getString('studentId') ?? '';
      if (imgPath != null) {
        final f = File(imgPath);
        if (await f.exists()) _profileImage = f;
      }
      _name.text = name;
      _studentId.text = sid;
    } catch (e) {
      debugPrint('Load user data error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _name.text.trim());
    await prefs.setString('studentId', _studentId.text.trim());
    if (_profileImage != null) {
      await prefs.setString('profileImagePath', _profileImage!.path);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')),
    );
  }

  Future<void> _setProfileImageFromAnyPath(String path) async {
    final file = File(path);
    if (!(await file.exists())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบไฟล์รูปภาพจากที่อยู่ที่ระบุ')),
      );
      return;
    }
    await _adoptFileAsProfileImage(file);
  }

  Future<void> _adoptFileAsProfileImage(File original) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = original.path.split('.').last.toLowerCase();
      final safeExt = ['png','jpg','jpeg','webp','gif','bmp'].contains(ext) ? ext : 'png';
      final target = File('${dir.path}/profile/avatar.$safeExt');
      await target.parent.create(recursive: true);
      await original.copy(target.path);
      setState(() => _profileImage = target);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', target.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกรูป: $e')),
      );
    }
  }

  Future<void> _pickImageWithFileSelector() async {
    try {
      final typeGroup = XTypeGroup(label: 'images', extensions: ['png','jpg','jpeg','webp','gif','bmp']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      await _adoptFileAsProfileImage(File(file.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เลือกไฟล์ไม่สำเร็จ: $e')),
      );
    }
  }

  void _showFullScreen() {
    if (_profileImage == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageView(imageFile: _profileImage!),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _AvatarStack(
      image: _profileImage,
      isDragging: _dragging,
      onTapImage: _showFullScreen,
      onTapPick: _pickImageWithFileSelector,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, c) {
                final isWide = c.maxWidth >= 720;
                final content = [
                  _buildAvatarSection(avatar),
                  const SizedBox(height: 24),
                  _buildFormCard(),
                ];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: content[0]),
                                const SizedBox(width: 24),
                                Expanded(flex: 6, child: Column(children: content.sublist(2 - 2 + 1)))
                              ],
                            )
                          : Column(crossAxisAlignment: CrossAxisAlignment.center, children: content),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAvatarSection(Widget avatar) {
    final dropChild = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: avatar),
        const SizedBox(height: 12),
        Text(
          _isDesktop
              ? 'ลากรูปจาก File Explorer มาปล่อยที่วงกลม หรือกดปุ่มกล้อง'
              : 'กดปุ่มกล้องเพื่อเลือกรูปจากเครื่อง',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (_isDesktop) {
      return DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) async {
          setState(() => _dragging = false);
          if (details.files.isEmpty) return;
          final first = details.files.first;
          if (first.path == null) return;
          await _adoptFileAsProfileImage(File(first.path!));
        },
        child: dropChild,
      );
    }
    return dropChild;
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'ชื่อ-นามสกุล',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _studentId,
              decoration: const InputDecoration(
                labelText: 'รหัสนักศึกษา',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: _saveUserData,
                    label: const Text('บันทึก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open_outlined),
                    onPressed: () async {
                      // ช่องทางกรอกพาธเอง (กรณีผู้ใช้ต้องการ)
                      final path = await _showEnterPathDialog(context);
                      if (path != null && path.trim().isNotEmpty) {
                        await _setProfileImageFromAnyPath(path.trim());
                      }
                    },
                    label: const Text('กรอกพาธรูปเอง'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showEnterPathDialog(BuildContext context) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ที่อยู่ไฟล์รูปภาพ (Path)'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            hintText: '/Users/me/Pictures/profile.jpg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('ตกลง')),
        ],
      ),
    );
  }
}

/// วงกลมโปรไฟล์ + ปุ่มกล้อง + เอฟเฟกต์เวลา Drag อยู่
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.image,
    required this.isDragging,
    required this.onTapImage,
    required this.onTapPick,
  });
  final File? image;
  final bool isDragging;
  final VoidCallback onTapImage;
  final VoidCallback onTapPick;

  @override
  Widget build(BuildContext context) {
    final border = isDragging
        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3, strokeAlign: BorderSide.strokeAlignOutside)
        : Border.all(color: Colors.transparent, width: 3);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
            boxShadow: [
              if (isDragging)
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: image != null ? onTapImage : onTapPick,
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.grey[200],
              backgroundImage: image != null ? FileImage(image!) : null,
              child: image == null
                  ? const Icon(Icons.person, size: 64, color: Colors.black26)
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Tooltip(
            message: 'เปลี่ยนรูปโปรไฟล์',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapPick,
                borderRadius: BorderRadius.circular(999),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.photo_camera_outlined, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isDragging)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ปล่อยไฟล์รูปที่นี่',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ดูรูปเต็มหน้าจอ + ซูม/แพน
class FullScreenImageView extends StatelessWidget {
  const FullScreenImageView({super.key, required this.imageFile});
  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('รูปโปรไฟล์', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20),
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
