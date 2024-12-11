
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin"; // Firebase Admin SDK import

// Firebase Admin 초기화
admin.initializeApp();

// 예제 함수
export const helloWorld = onRequest((req, res) => {
  logger.info("Hello logs!", { structuredData: true });
  res.send("Hello from Firebase!");
});

export const addData = onRequest(async (req, res) => {
  const db = admin.firestore();
  const data = { message: "Hello, Firestore!" };

  try {
    await db.collection("messages").add(data);
    res.status(200).send("Data added successfully!");
  } catch (error) {
    res.status(500).send(`Error adding data: ${error.message}`);
  }
});

const axios = require('axios');

async function createFirebaseToken(naverAccessToken) {
  // 네이버 사용자 정보 요청
  const userInfoResponse = await axios.get('https://openapi.naver.com/v1/nid/me', {
    headers: {
      Authorization: `Bearer ${naverAccessToken}`,
    },
  });

  const userInfo = userInfoResponse.data.response;

  // Firebase Custom Token 생성
  const firebaseToken = await admin.auth().createCustomToken(userInfo.id, {
    email: userInfo.email,
    name: userInfo.name,
    profileImage: userInfo.profile_image,
  });

  return firebaseToken;
}
