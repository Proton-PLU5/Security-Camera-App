import 'package:camera_application/data/TText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<String> get username async =>
      await secureStorage.read(key: 'username') ?? 'Unknown User';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          SizedBox(height: 16.0),

          // User Profile Section
          const SizedBox(height: 16.0),

          // Divider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Divider(
                  color: Colors.grey,
                  thickness: 1.0,
                  endIndent: 16.0,
                ),
              ),
              Text(
                TText.settingsSectionTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Flexible(
                child: Divider(
                  color: Colors.grey,
                  thickness: 1.0,
                  indent: 16.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
