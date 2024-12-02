import 'package:flutter_naver_map/flutter_naver_map.dart';

class MarkerService {
  // 마커 생성 메서드
  static NMarker createMarker(String id, NLatLng position, String infoWindowText) {
    final marker = NMarker(
      id: id,
      position: position,
      onMarkerTab: (overlay) {
        // 마커 클릭 시 콜백 로직
        print('Marker $id clicked!');
      },
    );

    // 마커 정보창 추가
    marker.openInfoWindow(NInfoWindow.onMarker(
      id: marker.info.id,
      text: infoWindowText,
    ));

    return marker;
  }
}
