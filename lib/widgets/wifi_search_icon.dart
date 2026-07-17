
import 'dart:async';

import 'package:flutter/material.dart';

class WifiSearchIcon extends StatefulWidget {
  final bool isSearching;
  final VoidCallback onTap;

  const WifiSearchIcon({
    super.key, 
    required this.isSearching, 
    required this.onTap
  });

  @override
  State<WifiSearchIcon> createState() => _WifiSearchIconState();
}

class _WifiSearchIconState extends State<WifiSearchIcon> {
  static const _icons = [
    Icons.wifi_1_bar,
    Icons.wifi_2_bar,
    Icons.wifi,
  ];

  int _barIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isSearching) {
      startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant WifiSearchIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearching && !oldWidget.isSearching) {
      startAnimation();
    } else if (!widget.isSearching && oldWidget.isSearching) {
      stopAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _barIndex = (_barIndex + 1) % _icons.length;
      });
    });
  }

  void stopAnimation() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _barIndex = 0; // Reset to the first icon
    });
  }

  @override
  Widget build(BuildContext context) {

    final icon = Icon(
      widget.isSearching ? _icons[_barIndex] : Icons.wifi_off,
      color: widget.isSearching ? Colors.blue : Colors.red,
      size: 64,
    );

    return IconButton(
      icon: icon,
      onPressed: widget.onTap,
    );
  }
}