// functions/sendNotificationToGroup.js
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const sendNotificationToGroup = onCall(async (request) => {
  const { title, body, targetGroup } = request.data;

  if (!title || !body || !targetGroup) {
    throw new Error("Missing title, body, or targetGroup");
  }

  let collectionName;
  switch (targetGroup) {
    case "residents":
      collectionName = "residents";
      break;
    case "staffs":
      collectionName = "staffs"; // collection nhân viên
      break;
    case "companies":
      collectionName = "companies"; // collection công ty
      break;
    default:
      throw new Error("Invalid target group");
  }

  const snapshot = await admin.firestore().collection(collectionName).get();

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
    notification: { title, body },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "broadcast",
    },
    tokens: allTokens,
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
  sendNotificationToGroup,
};
