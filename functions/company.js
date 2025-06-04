const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const cors = require("cors");
const nodemailer = require("nodemailer");
const { google } = require("googleapis");
const { generateRandomPassword } = require("./utils");

const CLIENT_ID = defineSecret("CLIENT_ID");
const CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const SENDER_EMAIL = defineSecret("SENDER_EMAIL");

const REDIRECT_URI = "https://developers.google.com/oauthplayground";
const corsHandler = cors({ origin: true });

const createCompanyAccount = onRequest(
  {
    allowUnauthenticated: true,
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
  },
  (req, res) => {
    corsHandler(req, res, async () => {
      const { email, name, phone, type, address, description } = req.body;

      if (!email || !name || !phone || !type || !address || !description) {
        return res.status(400).send("Thiếu thông tin công ty.");
      }

      try {
        const password = generateRandomPassword();

        const userRecord = await admin.auth().createUser({
          email,
          displayName: name,
          password,
        });

        await admin.firestore().collection("companies").doc(userRecord.uid).set({
          name,
          email,
          phone,
          type,
          address,
          fcmTokens: [],
          description,
          imageUrl:"",
          isExit:false,
          leaveAt: null,
          role: 5,
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
          from: `"Apartment Admin" <${await SENDER_EMAIL.value()}>`,
          to: email,
          subject: "Thông tin đăng nhập công ty",
          html: `
            <p>Xin chào ${name},</p>
            <p>Tài khoản công ty của bạn đã được tạo.</p>
            <p>Email: ${email}</p>
            <p>Mật khẩu tạm thời: ${password}</p>
            <p><a href="${resetLink}">Đặt lại mật khẩu</a></p>
          `,
        });

         // Trả về UID của nhân viên vừa tạo
                        res.status(200).send({
                          message: "Tạo tài khoản công ty và gửi email thành công.",
                          uid: userRecord.uid, // Trả về UID của người dùng mới
                        });
                      } catch (error) {
                        console.error("❌ Lỗi tạo tài khoản công ty:", error);
                        res.status(500).send("Lỗi: " + error.message);
                      }
    });
  }
);

module.exports = { createCompanyAccount };
