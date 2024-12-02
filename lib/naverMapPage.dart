import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class NaverMapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('네이버 지도'),
      ),
      body: NaverMap(
        onMapReady: (controller) {
          // 지도 초기화 시 동작
        },
        options: const NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(37.5665, 126.9780), // 서울을 예시로 설정
            zoom: 10,
          ),
          mapType: NMapType.navi,
          locationButtonEnable: true,
        ),
      ),
    );
  }
}
