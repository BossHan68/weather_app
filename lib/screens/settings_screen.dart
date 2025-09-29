import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) updateTheme;

  SettingsScreen({this.isDarkMode = false, required this.updateTheme});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Column(
        children: [
          SwitchListTile(
            title: Text("Dark Mode"),
            subtitle: Text("Enable dark theme"),
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
                _savePreferences();
                widget.updateTheme(value);
              });
            },
          ),
        ],
      ),
    );
  }
}
