import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  String? _currentAddress;

  // 네이버 API 키
  final String _clientId = 'YOUR_NAVER_CLIENT_ID';
  final String _clientSecret = 'YOUR_NAVER_CLIENT_SECRET';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
    _getAddressFromLatLng(position);
  }

  // 위도와 경도로 주소 얻기
  Future<void> _getAddressFromLatLng(Position position) async {
    final url = Uri.parse(
        'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=${position.longitude},${position.latitude}&output=json');

    final response = await http.get(url, headers: {
      'X-NCP-APIGW-API-KEY-ID': _clientId,
      'X-NCP-APIGW-API-KEY': _clientSecret,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['results'][0]['region']['area1']['name'];
      setState(() {
        _currentAddress = address;
      });
    } else {
      print('Failed to load address');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('현재 위치 표시'),
      ),
      body: Center(
        child: _currentPosition == null
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '위도: ${_currentPosition!.latitude}, 경도: ${_currentPosition!.longitude}',
              style: TextStyle(fontSize: 16),
            ),
            if (_currentAddress != null)
              Text(
                '주소: $_currentAddress',
                style: TextStyle(fontSize: 16),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 네이버 지도 API를 통해 위치 마킹 등 추가 기능을 구현
              },
              child: Text('현재 위치 마킹'),
            ),
          ],
        ),
      ),
    );
  }
}
