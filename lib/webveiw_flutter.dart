import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapWithLocation extends StatefulWidget {
  @override
  _MapWithLocationState createState() => _MapWithLocationState();
}

class _MapWithLocationState extends State<MapWithLocation> {
  late final WebViewController controller;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _fetchCurrentLocation(),
        ),
      )
      ..loadFlutterAsset('assets/naver_map.html');
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      await controller.runJavaScript(
          'initializeMap(${position.latitude}, ${position.longitude});');
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("네이버 지도 - 현재 위치"),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}