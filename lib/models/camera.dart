import 'package:hive/hive.dart';

part 'camera.g.dart';

@HiveType(typeId: 0)
class Camera extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String location;

  @HiveField(2)
  String imagePath;

  @HiveField(3)
  final String uuid;

  @HiveField(4)
  String ipAddress;

  @HiveField(5)
  int port;

  @HiveField(6)
  String version;

  @HiveField(7)
  bool isFavorite = false;

  Camera(
    {
      required this.uuid,
      required this.name,
      required this.location, 
      required this.ipAddress,
      required this.port,
      this.imagePath = 'assets/placeholder.jpg', 
      required this.version,
    }
  );
}