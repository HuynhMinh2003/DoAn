const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const sendNotificationToOne = onCall(async (request) => {
  const { token, title, body } = request.data;

  // Validate dữ liệu đầu vào
  if (typeof token !== "string" || token.trim() === "") {
    throw new Error("Thiếu hoặc sai định dạng token");
  }
  if (typeof title !== "string" || title.trim() === "") {
    throw new Error("Thiếu tiêu đề thông báo");
  }
  if (typeof body !== "string" || body.trim() === "") {
    throw new Error("Thiếu nội dung thông báo");
  }

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "service_request_update",
    },
  };

  try {
    const response = await admin.messaging().send(message);
    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("FCM Error:", error);
    // Ném lỗi ra ngoài để client biết, hoặc bạn có thể trả về object lỗi
    throw new Error("Lỗi gửi thông báo: " + error.message);
  }
});

module.exports = {
  sendNotificationToOne,
};
