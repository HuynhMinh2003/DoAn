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

const createResidentAccount = onRequest(
  {
    allowUnauthenticated: true,
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
  },
  (req, res) => {
    corsHandler(req, res, async () => {
      const { email, fullName, cccd, address, gender, phone, birthDate, apartmentId } = req.body;

    console.log("📦 Dữ liệu nhận được từ body:", req.body); // Log toàn bộ body

        // Kiểm tra từng trường cụ thể
    if (!email) console.log("❌ Thiếu trường: email");
    if (!fullName) console.log("❌ Thiếu trường: fullName");
    if (!cccd) console.log("❌ Thiếu trường: cccd");
    if (!address) console.log("❌ Thiếu trường: address");
    if (!gender) console.log("❌ Thiếu trường: gender");
    if (!phone) console.log("❌ Thiếu trường: phone");
    if (!birthDate) console.log("❌ Thiếu trường: birthDate");
    if (!apartmentId) console.log("❌ Thiếu trường: apartmentId");

      if (!email || !fullName || !cccd || !address ||!gender ||!phone || !birthDate || !apartmentId) {
        return res.status(400).send("Thiếu thông tin.");
      }

      try {
        const password = generateRandomPassword();

        const userRecord = await admin.auth().createUser({
          email,
          displayName: fullName,
          password,
        });

        await admin.firestore().collection("residents").doc(userRecord.uid).set({
          fullName,
          cccd,
          address,
          gender,
          phone,
          birthDate,
          email,
          apartmentId,
          role: 3,
          fcmTokens: [],
          imageUrl: '',
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
          subject: "Thông tin đăng nhập",
          html: `
            <p>Xin chào ${fullName},</p>
            <p>Tài khoản cư dân của bạn đã được tạo.</p>
            <p>Email: ${email}</p>
            <p>Mật khẩu tạm thời: ${password}</p>
            <p><a href="${resetLink}">Đặt lại mật khẩu</a></p>
          `,
        });

        res.status(200).json({
          message: "Tạo tài khoản cư dân và gửi email thành công.",
          residentId: userRecord.uid, // ID cần dùng trong Flutter
        });
      } catch (error) {
        console.error("❌ Lỗi tạo tài khoản cư dân:", error);
        res.status(500).send("Lỗi: " + error.message);
      }
    });
  }
);

module.exports = { createResidentAccount };
