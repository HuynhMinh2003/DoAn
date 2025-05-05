const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const cors = require("cors");

// 🔐 Firebase Secrets (dù không dùng trong hàm này, vẫn cần khai báo nếu khai báo ở entrypoint chính)
const CLIENT_ID = defineSecret("CLIENT_ID");
const CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const SENDER_EMAIL = defineSecret("SENDER_EMAIL");

// ✅ Chỉ khởi tạo Firebase app nếu chưa khởi tạo
if (!admin.apps.length) {
  admin.initializeApp();
}

const corsHandler = cors({ origin: true });

const deleteCompanyAccount = onRequest(
  {
    allowUnauthenticated: true,
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
  },
  (req, res) => {
    corsHandler(req, res, async () => {
      const { uid } = req.body;

      if (!uid) {
        return res.status(400).send("UID của người dùng cần xóa không hợp lệ.");
      }

      try {
        // 🔥 Xóa người dùng khỏi Authentication
        await admin.auth().deleteUser(uid);

        // 🔥 Xóa dữ liệu người dùng khỏi Firestore collection "residents"
        await admin.firestore().collection("companies").doc(uid).delete();

        res.status(200).send({
          message: `Đã xóa tài khoản và dữ liệu người dùng có UID: ${uid}.`,
        });
      } catch (error) {
        console.error("❌ Lỗi khi xóa tài khoản người dùng:", error);
        res.status(500).send("Lỗi: " + error.message);
      }
    });
  }
);

module.exports = { deleteCompanyAccount };
