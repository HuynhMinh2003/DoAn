// sendNotificationToResidents.js
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const sendNotificationToResidents = onCall(async (request) => {
  const { title, body } = request.data;

  if (!title || !body) {
    throw new Error("Missing title or body");
  }

  const snapshot = await admin.firestore().collection("residents").get();

  const allTokens = [];

  snapshot.forEach(doc => {
    const tokens = doc.data().fcmTokens || [];
    tokens.forEach(token => {
      if (token) allTokens.push(token);
    });
  });

  if (allTokens.length === 0) {
    return { success: false, message: "Không có FCM token nào" };
  }

  const message = {
    notification: {
      title,
      body,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "broadcast",
    },
    tokens: allTokens, // vẫn cần cho sendEachForMulticast
  };

  // ✅ Sử dụng sendEachForMulticast thay cho sendMulticast
  const response = await admin.messaging().sendEachForMulticast(message);

  const successCount = response.responses.filter(r => r.success).length;
  const failureCount = response.responses.length - successCount;

  return {
    success: true,
    sent: successCount,
    failed: failureCount,
  };
});

module.exports = {
  sendNotificationToResidents,
};
