<<<<<<< HEAD
# Community
OpenSource_Project_Team_OpenForge
=======
# zipcode_community

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 77a60fc76a822754187e0c25628659e93668b8b6


home: const MapScreen(), // WebView로 지도 출력
home: NaverMapScreen(), // 로그인 화면으로 이동
home: RegisterPage(),// 회원가입 화면

autherservice_.dart = firebase를 사용하여 사용자 등록 처리
    firestore에 user의 id,email, nickname, profile_image을 저장
    profile_image는 이미지 uri만 등록, 실제 이미지는 fire storage에 등록한다.
    
    
authservice_google.dart = 구글 로그인
GetPosition.dart = 위치 서비스 확인
home_screen.dart = 홈 화면 


Login.dart
    실제로 로그인하는 UI
    1. InApp로그인
    2. 회원가입 버튼
        회원가입 페이지로 이동
    3. Google 간편 로그인 버튼
    4. Naver 간편 로그인 버튼
change_password.dart
    "비밀번호 변경: 로그인된 사용자의 updatePassword(String newPassword) 메서드를 사용한다."


구글과 네이버의 간편로그인

authGoogle.dart
    Google로 간편 로그인/로그아웃 하고 정보를 firestore에 저장
    1. Google로 간편 로그인
        signInWithGoogle()
    2. 로그아웃
        GoogleSignIn.signOut() 구글 로그아웃
        FirebaseAuth.signOut() firebase 로그아웃
signInWithGoogle
    Google로 로그인 할 때 UI (참고)
    1. Google로 로그인하면 사용자 ID와 닉네임을 따로 받아 저장한다.
googleAddPage
    Google로 로그인하면 사용자 ID와 닉네임을 따로 받아 저장하는 추가정보입력화면.
signInWithNaver
    naver로 로그인하는 UI (참고)
    1. naver로 로그인하면 사용자 ID와 닉네임을 따로 받아 저장한다.
naverAddPage
    Google로 로그인하면 사용자 ID와 닉네임을 따로 받아 저장하는 추가정보입력화면.


이메일은 fireabase에서 등록하러면 필요하다.
프로필 이미지 등록은 firebase storage에서 등록하고
firestore에서는 storage uri만 등록한다.




비밀번호 재설정: sendPasswordResetEmail 메서드를 사용하여 이메일을 통해 비밀번호를 재설정.