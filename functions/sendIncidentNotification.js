const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const sendIncidentNotification = onCall(async (request) => {
  const { fcmTokens, title, body } = request.data;

  if (!Array.isArray(fcmTokens) || fcmTokens.length === 0) {
    throw new Error("Thiếu hoặc sai định dạng fcmTokens");
  }

  if (!title || !body) {
    throw new Error("Thiếu tiêu đề hoặc nội dung thông báo");
  }

  const message = {
    notification: {
      title,
      body,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "incident_assignment",
    },
    tokens: fcmTokens,
  };

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
  sendIncidentNotification,
};
