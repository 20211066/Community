import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';


class NaverMapExample extends StatefulWidget {
  const NaverMapExample({super.key});

  @override
  State<NaverMapExample> createState() => _NaverMapExampleState();
}

class _NaverMapExampleState extends State<NaverMapExample> {
  late NaverMapController _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  String markerInfo = '';
  NCircleOverlay? _tempOverlay; // 터치한 위치의 임시 원형 오버레이
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      setState(() => _currentPosition = position);

      // 실시간 위치 스트림 시작
      _startListeningToLocation();
    } catch (e) {
      debugPrint("Error fetching initial position: $e");
    }
  }


  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _startListeningToLocation() {
    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 100);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position newPosition) {
        if (_currentPosition == null ||
            Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              newPosition.latitude,
              newPosition.longitude,
            ) >
                100) {
          setState(() => _currentPosition = newPosition);
          _updateCameraPosition(newPosition);
        }
      },
    );
  }

  void _updateCameraPosition(Position position) {
    if (_mapController != null) {
      final cameraUpdate = NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 18,
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
                    zoom: 18,
                    bearing: 0,
                    tilt: 0),
                mapType: NMapType.navi,
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
                zoomGesturesFriction: 0.4,
                rotationGesturesFriction: 0.6,
                // 최대/최소 줌 제한
                minZoom: 10, // default is 0
                maxZoom: 21, // default is 21
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
                _loadMarkers();
              },
              forceGesture: true,
              onMapTapped: (point, latLng) {
                _addTemporaryOverlay(latLng);
                _showAddMarkerDialog(latLng);
              },

            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed:  () {
                      if (_tempOverlay != null) {
                        final position = _tempOverlay!.center;
                        _showAddMarkerDialog(position);
                      } else {
                        _showSnackBar("마커를 추가할 위치를 먼저 선택하세요.");
                      }
                    },
                    child: const Icon(Icons.add_location),
                  ),
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

  void _addTemporaryOverlay(NLatLng latLng) {
    // 기존의 임시 오버레이를 제거
    setState(() {
      _tempOverlay = NCircleOverlay(
        id: 'temp_overlay',
        center: latLng,
        radius: 15,
        color: Colors.orange.withOpacity(0.5),
        outlineColor: Colors.orange,
        outlineWidth: 2,
      );
    });

    _mapController.addOverlay(_tempOverlay!);
  }

  void _createMarker(NLatLng location, String info) {
    final marker = NMarker(
      id: "marker_${DateTime.now().millisecondsSinceEpoch}",
      position: location,
    );

    _mapController.addOverlay(marker);
    marker.openInfoWindow(
      NInfoWindow.onMap(id: marker.info.id, text: info, position: location),
    );

    FirebaseFirestore.instance.collection('markers').add({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'info': info,
    });

    // 임시 오버레이 제거
    setState(() {
      _tempOverlay = null;
    });
  }
  // Firestore에서 마킹 정보 로드
  Future<void> _showAddMarkerDialog(NLatLng location) async {
    String title = '';
    String details = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('마커 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '제목'),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: '세부 정보'),
                onChanged: (value) => details = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (title.isNotEmpty) {
                  _saveMarker(location, title, details);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMarker(NLatLng location, String title, String details) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final markerData = {
      'title': title,
      'details': details,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'userId': currentUser.uid,
      'isPublic': false,
    };

    await _firestore.collection('markers').add(markerData);
  }
  void _loadMarkers() {
    _firestore.collection('markers').snapshots().listen((snapshot) {
      _mapController.clearOverlays(); // 기존 마커 제거
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final markerLat = data['latitude'] as double;
        final markerLng = data['longitude'] as double;
        final title = data['title'] as String? ?? '제목 없음';
        final details = data['details'] as String? ?? '';
        final userId = data['userId'] as String?;
        final isPublic = data['isPublic'] as bool? ?? false;


        if (_auth.currentUser?.uid == userId || isPublic == true) {
          final marker = NMarker(
            position: NLatLng(markerLat, markerLng),
            id: doc.id,
            caption: NOverlayCaption(text: title),
          );
          marker.setOnTapListener((marker) {
            _showMarkerInfoDialog(title, details);
          });
          _mapController.addOverlay(marker);
          print('Adding Marker at: $markerLat, $markerLng');
        }
      }
    });
  }


  void _showMarkerInfoDialog(String title, String details) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(details),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

}