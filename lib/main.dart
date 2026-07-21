import 'package:camera_application/home.dart';
import 'package:camera_application/models/camera.dart';
import 'package:camera_application/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

final FlutterSecureStorage secureStorage = FlutterSecureStorage();

Future<bool> _isLoggedIn() async {
  final username = await secureStorage.read(key: 'username');
  final password = await secureStorage.read(key: 'password');
  return username != null && password != null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CameraAdapter());
  await Hive.openBox<Camera>('favoriteCameras');
  await Hive.openBox<Camera>('cameras');

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security Camera',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<bool> (
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            final isLoggedIn = snapshot.data ?? false;
            return isLoggedIn ? MyHomePage(title: 'Security Camera') : LoginScreen();
          }
        },
      )
    );
  }
}