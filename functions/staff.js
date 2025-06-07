const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const cors = require("cors");
const nodemailer = require("nodemailer");
const { google } = require("googleapis");
const { generateRandomPassword } = require("./utils");

// 🔐 Firebase Secrets
const CLIENT_ID = defineSecret("CLIENT_ID");
const CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const SENDER_EMAIL = defineSecret("SENDER_EMAIL");

const REDIRECT_URI = "https://developers.google.com/oauthplayground";
const corsHandler = cors({ origin: true });

const createStaffAccount = onRequest(
  {
    allowUnauthenticated: true,
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
  },
  (req, res) => {
    corsHandler(req, res, async () => {
      const { email, fullName, address, birthDate, gender, cccd, phone, position } = req.body;

      if (!email || !fullName || !address || !birthDate || !gender || !cccd || !phone || !position) {
        return res.status(400).send("Thiếu thông tin nhân viên.");
      }

      // Xác định role dựa theo vị trí
      let role;
      if (position === "Kĩ thuật viên") {
        role = 2;
      } else if (position === "Nhân viên ghi chỉ số nước") {
        role = 3;
      } else {
        return res.status(400).send("Vị trí không hợp lệ.");
      }

      try {
        const password = generateRandomPassword();

        const userRecord = await admin.auth().createUser({
          email,
          displayName: fullName,
          password,
        });

        await admin.firestore().collection("staffs").doc(userRecord.uid).set({
          fullName,
          email,
          fcmTokens: [],
          phone,
          cccd,
          birthDate,
          gender,
          address,
          position,
          imageUrl: "",
          isExit: false,
          leaveAt: null,
          isFree: true,
          role: role, // Gán role theo position
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const resetLink = await admin.auth().generatePasswordResetLink(email);

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
          from: `"Bản quản lý chung cư" <${await SENDER_EMAIL.value()}>`,
          to: email,
          subject: "Thông tin đăng nhập nhân viên",
          html: `
            <p>Xin chào ${fullName},</p>
            <p>Tài khoản nhân viên của bạn đã được tạo.</p>
            <p>Email: ${email}</p>
            <p>Mật khẩu tạm thời: ${password}</p>
            <p><a href="${resetLink}">Đặt lại mật khẩu</a></p>
          `,
        });

        res.status(200).send({
          message: "Tạo tài khoản nhân viên và gửi email thành công.",
          uid: userRecord.uid,
        });
      } catch (error) {
        console.error("❌ Lỗi tạo tài khoản nhân viên:", error);
        res.status(500).send("Lỗi: " + error.message);
      }
    });
  }
);

module.exports = { createStaffAccount };
