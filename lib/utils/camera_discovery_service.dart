import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/discovered_camera.dart';

class CameraDiscoveryService {
  final MDnsClient _mdnsClient = MDnsClient();
  static const String _serviceType = '_camera._tcp.local';
  static const MethodChannel _multicastChannel =
      MethodChannel('camera_application/multicast_lock');

  Future<void> start() async {
    // Android filters Wi-Fi multicast by default. mDNS discovery uses multicast
    // UDP, so keep the platform multicast lock while this service is active.
    if (Platform.isAndroid) {
      await _multicastChannel.invokeMethod<void>('acquire');
    }

    try {
      await _mdnsClient.start(
        interfacesFactory: (type) => NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        ),
      );
    } catch (_) {
      if (Platform.isAndroid) {
        await _multicastChannel.invokeMethod<void>('release');
      }
      rethrow;
    }
  }

  Stream<DiscoveredCamera> discoverCameras() async* {
    final seen = <String>{}; // To avoid duplicates

    await for (final ptr in _mdnsClient.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(_serviceType),
    )) {
      // Lookup the SRV record for the discovered service
      await for (final srv in _mdnsClient.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      )) {
        
        String? ip;
        String? id;
        String? version;

        // Lookup the IP address for the discovered service
        await for (final ip4 in _mdnsClient.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target),
        )) {
          ip = ip4.address.address;
          break; // We only need one IP address
        }

        // Lookup the TXT record for additional information
        await for (final txt in _mdnsClient.lookup<TxtResourceRecord>(
          ResourceRecordQuery.text(ptr.domainName),
        )) {
          // Get the TXT record entries and parse them as needed
          final entries = txt.text.split('\n').where((entry) => entry.contains('='));

          final map = {
            for (final e in entries) e.split('=').first: e.split('=').skip(1).join('='),
          };
          id = map['id'];
          version = map['version'];
          break; // We only need one TXT record
        }

        final key = '$ip:${srv.port}';
        if (seen.contains(key)) continue;

        seen.add(key);

        // Create a DiscoveredCamera instance
        // Populate with the necessary information (id, ip, port, version, etc.)

        yield DiscoveredCamera(
          uuid: id ?? key,
          name: ptr.domainName,
          ip: ip ?? 'Unknown IP',
          port: srv.port,
          version: version ?? 'Unknown Version',
        );
      }
    }
  }

  Future<void> stop() async {
    _mdnsClient.stop();
    if (Platform.isAndroid) {
      await _multicastChannel.invokeMethod<void>('release');
    }
  }
}
