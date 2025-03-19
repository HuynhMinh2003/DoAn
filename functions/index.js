const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Hàm gửi thông báo khi cập nhật hóa đơn
exports.sendBillingNotification = functions.firestore
    .document("apartments/{apartmentId}/billing/{userId}")
    .onUpdate(async (change, context) => {
        const userId = context.params.userId;
        const apartmentId = context.params.apartmentId;
        const afterData = change.after.data();

        // Lấy thông tin người dùng
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (!userDoc.exists) {
            console.log("User not found:", userId);
            return null;
        }

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            console.log("No FCM Token found for user:", userId);
            return null;
        }

        // Tạo nội dung thông báo
        const message = {
            notification: {
                title: "Cập nhật hóa đơn",
                body: `Hóa đơn của bạn đã được cập nhật. Tổng tiền: ${afterData.totalAmount} VND.`,
            },
            token: fcmToken,
        };

        // Gửi thông báo
        try {
            await admin.messaging().send(message);
            console.log("Notification sent to:", userId);
        } catch (error) {
            console.error("Error sending notification:", error);
        }

        return null;
    });
