import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';


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
    await _checkLocationService();
    await _requestLocationPermission(); // 권한 요청

    // 위치 서비스가 활성화되지 않으면 경고 메시지 표시
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 서비스가 비활성화 되어 있습니다.')),
      );
      return;
    }
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


  Future<void> _requestLocationPermission() async {
    final requeststatus = await Permission.locationWhenInUse.request();
    var status = await Permission.location.status;
    if (requeststatus.isGranted) {
      debugPrint("Location permission granted.");
    } else if (requeststatus.isDenied) {
      debugPrint("Location permission denied.");
    } else if (requeststatus.isPermanentlyDenied) {
      debugPrint("Location permission permanently denied. Please enable it from settings.");
      await openAppSettings();
    }
  }

  void _startListeningToLocation() {
    const locationSettings = LocationSettings(
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
                activeLayerGroups: const [ // 표시할 정보 레이어 선택하기
                  NLayerGroup.building,
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
                indoorEnable: true,
                scaleBarEnable: true,
                logoClickEnable: false,
                locationButtonEnable: true,
            ),
              onMapReady: (controller) async {
                _mapController = controller;
                _syncMarkersWithFirestore();
              },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스 활성화 요청
      debugPrint("Location services are disabled. Please enable them.");
    }
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


  void _syncMarkersWithFirestore() {
    // Firestore 마커 데이터를 실시간으로 가져오기
    FirebaseFirestore.instance.collection('markers').snapshots().listen((snapshot) {
      // 기존 오버레이 초기화
      _mapController.clearOverlays();

      // 현재 위치가 없는 경우 필터링을 건너뜁니다.
      if (_currentPosition == null) return;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Firestore 데이터에서 위도와 경도 가져오기
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final markerLat = data['latitude'] as double;
          final markerLng = data['longitude'] as double;

          // 사용자 위치와 마커 사이 거리 계산
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            markerLat,
            markerLng,
          );

          // 1km 이내의 마커만 지도에 표시
          if (distance <= 1000) {
            final marker = NMarker(
              id: doc.id,
              position: NLatLng(markerLat, markerLng),
            );
            _mapController.addOverlay(marker);
          }
        }
      }
    });
  }
}
