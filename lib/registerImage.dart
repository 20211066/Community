import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


Future<String> uploadProfileImage(File imageFile) async {
  try {
    // Firebase Storage에 이미지 업로드
    Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/${DateTime.now().toString()}.png');
    UploadTask uploadTask = storageRef.putFile(imageFile);

    // 업로드 완료 후 다운로드 URL 얻기
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    return downloadUrl; // Firebase Storage에서 이미지 URL을 반환
  } catch (e) {
    print("이미지 업로드 실패: $e");
    return '';
  }
}
