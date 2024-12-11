import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

class NeighborhoodVerifyScreen extends StatefulWidget {
  final String selectedNeighborhood;

  NeighborhoodVerifyScreen({required this.selectedNeighborhood});

  @override
  _NeighborhoodVerifyScreenState createState() =>
      _NeighborhoodVerifyScreenState();
}

class _NeighborhoodVerifyScreenState extends State<NeighborhoodVerifyScreen> {
  late NaverMapController _mapController;
  bool isVerified = false;
  String verificationMessage = '';
  String currentNeighborhood = '';
  NLatLng? currentPosition;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && (doc.data()?['isNeighborhoodVerified'] ?? false)) {
        setState(() {
          isVerified = true;
          verificationMessage = '동네 인증이 완료되었습니다!';
        });
      } else {
        _getCurrentPosition(); // 인증되지 않은 경우 위치 확인
      }
    }
  }

  Future<void> _getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = NLatLng(position.latitude, position.longitude);
        currentNeighborhood = _getNeighborhoodFromCoordinates(
            position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() {
        verificationMessage = '현재 위치를 가져올 수 없습니다: $e';
      });
    }
  }

  String _getNeighborhoodFromCoordinates(double lat, double lng) {
    if ((lat - 37.5665).abs() < 0.05 && (lng - 126.9780).abs() < 0.05) {
      return '서울특별시';
    }
    return '알 수 없음';
  }

  Future<void> _completeVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'isNeighborhoodVerified': true},
        SetOptions(merge: true),
      );

      setState(() {
        isVerified = true;
        verificationMessage = '동네 인증이 완료되었습니다!';
      });
    } else {
      setState(() {
        verificationMessage = '사용자를 확인할 수 없습니다. 다시 시도해주세요.';
      });
    }
  }

  Future<void> _showVerificationDialog() async {
    if (currentPosition == null || currentNeighborhood.isEmpty) {
      setState(() {
        verificationMessage = '현재 위치를 가져올 수 없습니다.';
      });
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('동네 인증'),
          content: Text(
              '현재 위치는 "$currentNeighborhood" 동입니다. 동네 인증을 완료하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('아니요'),
            ),
            TextButton(
              onPressed: () {
                _completeVerification();
                Navigator.of(context).pop();
              },
              child: Text('예'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('동네 인증하기'),
      ),
      body: Column(
        children: [
          if (isVerified)
            Expanded(
              child: Center(
                child: Text(
                  '동네 인증이 이미 완료되었습니다!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Expanded(
              flex: 3,
              child: currentPosition == null
                  ? Center(child: CircularProgressIndicator())
                  : NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: currentPosition!,
                    zoom: 16,
                  ),
                  locationButtonEnable: true,
                ),
                onMapReady: (controller) {
                  _mapController = controller;
                },
              ),
            ),
          if (!isVerified)
            Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 위치: ${currentNeighborhood.isEmpty ? '알 수 없음' : currentNeighborhood}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showVerificationDialog,
                    child: Text('동네 인증하기'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
