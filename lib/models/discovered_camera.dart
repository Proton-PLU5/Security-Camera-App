
class DiscoveredCamera {
  final String uuid;
  final String name;
  final String ip;
  final int port;
  final String version;

  DiscoveredCamera({
    required this.uuid,
    required this.name,
    required this.ip,
    required this.port,
    required this.version,
  });
}