// Import các thư viện Firebase cần thiết
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

// Thay bằng cấu hình Firebase của bạn từ Firebase Console
const firebaseConfig = {
  apiKey: "REDACTED_FIREBASE_API_KEY_2",
  authDomain: "REDACTED_PROJECT_ID.firebaseapp.com",
  databaseURL: "https://REDACTED_PROJECT_ID-default-rtdb.firebaseio.com",
  projectId: "REDACTED_PROJECT_ID",
  storageBucket: "REDACTED_PROJECT_ID.firebasestorage.app",
  messagingSenderId: "REDACTED_MESSAGING_SENDER_ID",
  appId: "REDACTED_APP_ID",
  measurementId: "REDACTED_MEASUREMENT_ID"
};

// Khởi tạo Firebase
firebase.initializeApp(firebaseConfig);

// Khởi tạo Firebase Messaging
const messaging = firebase.messaging();

// Xử lý thông báo khi ứng dụng đang chạy nền
messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);

  // Tùy chỉnh thông báo hiển thị
  const notificationTitle = payload.notification.title || "Thông báo mới";
  const notificationOptions = {
    body: payload.notification.body || "Bạn có thông báo mới.",
    icon: payload.notification.icon || "/default-icon.png", // Thay bằng đường dẫn icon mặc định
  };

  // Hiển thị thông báo
  self.registration.showNotification(notificationTitle, notificationOptions);
});
