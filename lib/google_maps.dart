import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _currentLocation = LatLng(37.42796133580664, -122.085749655962); // 기본 위치 (구글 위치)
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    _getCurrentLocation();
  }

  // 위치 권한 요청
  Future<void> _getLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted");
    } else {
      print("Location permission denied");
    }
  }

  // 현재 위치 추적
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(Marker(
        markerId: MarkerId('current_location'),
        position: _currentLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
      ));
    });
  }

  // 지도 설정
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Maps with GPS")),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 14.0,
        ),
        markers: _markers,
        myLocationEnabled: true,  // 실시간 위치 표시
        myLocationButtonEnabled: true,  // 내 위치 버튼 활성화
        zoomControlsEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: Icon(Icons.location_searching),
      ),
    );
  }
}

Future<void> requestLocationPermission() async {
  PermissionStatus status = await Permission.location.request();
  if (status.isGranted) {
    print("Location permission granted.");
  } else {
    print("Location permission denied.");
  }
}
