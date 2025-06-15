const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const sendNotificationToOne = onCall(async (request) => {
  const { tokens, title, body } = request.data;

  if (!Array.isArray(tokens) || tokens.length === 0) {
    throw new Error("Thiếu hoặc sai định dạng tokens");
  }
  if (typeof title !== "string" || title.trim() === "") {
    throw new Error("Thiếu tiêu đề thông báo");
  }
  if (typeof body !== "string" || body.trim() === "") {
    throw new Error("Thiếu nội dung thông báo");
  }

  const message = {
    notification: { title, body },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "service_request_update",
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      ...message,
    });

    const successCount = response.responses.filter((r) => r.success).length;
    const failureCount = response.responses.length - successCount;
    const failedTokens = response.responses
      .map((res, i) => (!res.success ? tokens[i] : null))
      .filter((t) => t !== null);

    return {
      success: true,
      sent: successCount,
      failed: failureCount,
      failedTokens,
    };
  } catch (error) {
    console.error("FCM Error:", error);
    throw new Error("Lỗi gửi thông báo: " + error.message);
  }
});

module.exports = { sendNotificationToOne };
