import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class NaverMapWebView extends StatefulWidget {
  final double latitude;
  final double longitude;

  NaverMapWebView({required this.latitude, required this.longitude});

  @override
  _NaverMapWebViewState createState() => _NaverMapWebViewState();
}

class _NaverMapWebViewState extends State<NaverMapWebView> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('네이버 지도'),
      ),
      body: WebView(
        initialUrl: 'assets/naver_map.html',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
          _loadHtmlFromAssets();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 현재 위치 좌표를 JavaScript로 전달하여 마커 설정
          _controller.runJavascript(
              'setMarker(${widget.latitude}, ${widget.longitude});');
        },
        child: Icon(Icons.location_on),
      ),
    );
  }

  // 로컬 HTML 파일 로드
  _loadHtmlFromAssets() async {
    String fileText = await DefaultAssetBundle.of(context)
        .loadString('assets/naver_map.html');
    _controller.loadUrl(Uri.dataFromString(fileText,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }
}
