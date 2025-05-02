const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const cors = require("cors");
const nodemailer = require("nodemailer");
const { google } = require("googleapis");

const CLIENT_ID = defineSecret("CLIENT_ID");
const CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const SENDER_EMAIL = defineSecret("SENDER_EMAIL");

admin.initializeApp();

const REDIRECT_URI = "https://developers.google.com/oauthplayground";
const corsHandler = cors({ origin: true });

exports.createStaffAccount = onRequest(
  {
    allowUnauthenticated: true,
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
  },
  (req, res) => {
    corsHandler(req, res, async () => {
      const { email, fullName, phone, position, imageUrl } = req.body;

      if (!email || !fullName || !phone || !position || !imageUrl) {
        return res.status(400).send("Thiếu thông tin nhân viên.");
      }

      try {
        const password = generateRandomPassword();

        // 1️⃣ Tạo tài khoản người dùng Firebase Auth
        const userRecord = await admin.auth().createUser({
          email: email,
          displayName: fullName,
          password: password,
        });

        // 2️⃣ Lưu thông tin nhân viên vào Firestore
        await admin.firestore().collection("staffs").doc(userRecord.uid).set({
          uid: userRecord.uid,
          fullName: fullName,
          email: email,
          phone: phone,
          position: position,
          imageUrl: imageUrl,
          role: 2, // Ví dụ: role = 2 cho nhân viên
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 3️⃣ Tạo link reset mật khẩu
        const resetLink = await admin.auth().generatePasswordResetLink(email);

        // 4️⃣ Cấu hình gửi email
        const oAuth2Client = new google.auth.OAuth2(
          await CLIENT_ID.value(),
          await CLIENT_SECRET.value(),
          REDIRECT_URI
        );
        oAuth2Client.setCredentials({ refresh_token: await REFRESH_TOKEN.value() });
        const accessToken = await oAuth2Client.getAccessToken();

        const transporter = nodemailer.createTransport({
          service: "gmail",
          auth: {
            type: "OAuth2",
            user: await SENDER_EMAIL.value(),
            clientId: await CLIENT_ID.value(),
            clientSecret: await CLIENT_SECRET.value(),
            refreshToken: await REFRESH_TOKEN.value(),
            accessToken: accessToken.token,
          },
        });

        await transporter.sendMail({
          from: `"Apartment Admin" <${await SENDER_EMAIL.value()}>`,
          to: email,
          subject: "Thông tin đăng nhập nhân viên",
          html: `
            <p>Xin chào ${fullName},</p>
            <p>Tài khoản nhân viên của bạn đã được tạo.</p>
            <p>Email: ${email}</p>
            <p>Mật khẩu tạm thời: ${password}</p>
            <p>Vui lòng nhấn vào nút bên dưới để đặt lại mật khẩu:</p>
            <a href="${resetLink}" style="padding: 10px 20px; background-color: #4CAF50; color: white; text-decoration: none;">Đặt lại mật khẩu</a>
            <p>Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>
          `,
        });

        res.status(200).send("Tạo tài khoản nhân viên và gửi email thành công.");
      } catch (error) {
        console.error("❌ Lỗi tạo tài khoản nhân viên:", error);
        res.status(500).send("Lỗi khi tạo tài khoản: " + error.message);
      }
    });
  }
);

// 🔑 Hàm tạo mật khẩu ngẫu nhiên
function generateRandomPassword() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let password = "";
  for (let i = 0; i < 8; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}
