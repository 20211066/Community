import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NaverMapExample extends StatefulWidget {
  const NaverMapExample({super.key});

  @override
  State<NaverMapExample> createState() => _NaverMapExampleState();
}

class _NaverMapExampleState extends State<NaverMapExample> {
  late NaverMapController _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializePosition() async {
    // 현재 위치 가져오기
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // 실시간 위치 스트림 시작
      _startListeningToLocation();
    } catch (e) {
      debugPrint("Error fetching initial position: $e");
    }
  }

  void _startListeningToLocation() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // 최소 100m 이동 시 업데이트
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position newPosition) {
        // 100m 이상 이동 시 업데이트
        if (_currentPosition != null) {
          double distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            newPosition.latitude,
            newPosition.longitude,
          );

          if (distance > 100) {
            setState(() {
              _currentPosition = newPosition;
            });
            _updateCameraPosition(newPosition);
          }
        }
      },
    );
  }

  void _updateCameraPosition(Position position) {
    if (_mapController != null) {
      final cameraUpdate = NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      );

      _mapController.updateCamera(cameraUpdate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("네이버 지도"),
        ),
        body: _currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          children: [
            NaverMap(
              onMapReady: _onMapCreated,
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 16,
                    bearing: 0,
                    tilt: 0),
                mapType: NMapType.navi,
                nightModeEnable: true,
                activeLayerGroups: [ // 표시할 정보 레이어 선택하기
                  NLayerGroup.building,
                  NLayerGroup.transit,
                  NLayerGroup.traffic
                ],
                //제스처 기능(회전, 스크롤, 기울이기, 줌, 멈춤)
                rotationGesturesEnable: true,
                scrollGesturesEnable: true,
                tiltGesturesEnable: false,
                zoomGesturesEnable: true,
                stopGesturesEnable: true,
                //마찰 계수 0 일수록 부드러움
                scrollGesturesFriction: 0.6,
                zoomGesturesFriction: 0.6,
                rotationGesturesFriction: 0.6,
                // 최대/최소 줌 제한
                minZoom: 10, // default is 0
                maxZoom: 16, // default is 21
                extent: const NLatLngBounds(
                    southWest: NLatLng(31.43, 122.37),
                    northEast: NLatLng(44.35, 132.0),
              ),
                locale: const Locale('kr'),
                locationButtonEnable: true,
            ),
              forceGesture: true,
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: _addMarker,
                    child: const Icon(Icons.add_location),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    onPressed: _moveCameraToCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(NaverMapController controller) {
    _mapController = controller;
    _syncMarkersWithFirestore();
  }

  void _addMarker() async {
    if (_mapController != null && _currentPosition != null) {
      try {
        final marker = NMarker(
          id: "marker_${DateTime.now().millisecondsSinceEpoch}",
          position: NLatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
        );
        _mapController.addOverlay(marker);

        // Firestore에 저장
        FirebaseFirestore.instance.collection('markers').add({
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        });
      } catch (e) {
        debugPrint("Error adding marker: $e");
      }
    }
  }

  void _moveCameraToCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      final cameraUpdate = NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: NLatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 16,
        ),
      );

      // 카메라 위치 업데이트
      _mapController.updateCamera(cameraUpdate);
    }
  }

  void _syncMarkersWithFirestore() {
    FirebaseFirestore.instance.collection('markers').snapshots().listen((snapshot) {
      _mapController.clearOverlays();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final marker = NMarker(
            id: doc.id,
            position: NLatLng(data['latitude'], data['longitude']),
          );
          _mapController.addOverlay(marker);
        }
      }
    });
  }
}
