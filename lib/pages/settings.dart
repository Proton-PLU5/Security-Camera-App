import 'package:camera_application/data/TText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<String> get username async => await secureStorage.read(key: 'username') ?? 'Unknown User';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [

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
              Text(TText.settingsUserSectionTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
              Flexible(
                child: Divider(
                  color: Colors.grey,
                  thickness: 1.0,
                  indent: 16.0,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.0),

          // User Profile Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16.0),
                FutureBuilder<String>(
                  future: username,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
                    } else {
                      return const Text('Loading...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
                    }
                  },
                )
              ],
            ),
          ),

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
              Text(TText.settingsSectionTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
              Flexible(
                child: Divider(
                  color: Colors.grey,
                  thickness: 1.0,
                  indent: 16.0,
                ),
              ),
            ],
          ),

          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Sign Out'),
            onTap: () {
              // Handle sign out action
              secureStorage.delete(key: 'username');  
              secureStorage.delete(key: 'password');
              Navigator.pushReplacementNamed(context, '/login');  
            },
          ),
        ],
      )
    );
  }
}