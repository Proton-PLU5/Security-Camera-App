
class DiscoveredCamera {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String version;

  DiscoveredCamera({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.version,
  });
}