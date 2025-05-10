const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const { google } = require("googleapis");
const cors = require("cors");

const CLIENT_ID = defineSecret("CLIENT_ID");
const CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const SENDER_EMAIL = defineSecret("SENDER_EMAIL");

const corsHandler = cors({ origin: true });

const sendUpdatedDetailEmail1 = onRequest(
  {
    allowUnauthenticated: true,
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
  },
  (req, res) => {
    corsHandler(req, res, async () => {
      const { uid, oldEmail, newEmail, updatedFields } = req.body;

      if (!uid || !oldEmail || !updatedFields) {
        return res.status(400).send("Thiếu uid, oldEmail hoặc updatedFields.");
      }

      try {
        // 1. Nếu có thay đổi email, cập nhật auth + Firestore
        let targetEmail = oldEmail;

        if (newEmail && newEmail !== oldEmail) {
          await admin.auth().updateUser(uid, { email: newEmail });
          await admin.firestore().collection("staffs").doc(uid).update({ email: newEmail });
          targetEmail = newEmail;
        }

        // 2. Soạn nội dung thông báo
        const fieldChangesHtml = Object.entries(updatedFields)
          .map(([key, value]) => `<li><strong>${key}:</strong> ${value}</li>`)
          .join("");

        const emailContent = `
          <p>Xin chào,</p>
          <p>Thông tin tài khoản của bạn đã được cập nhật với các nội dung sau:</p>
          <ul>${fieldChangesHtml}</ul>
          <p>Nếu bạn không yêu cầu thay đổi này, vui lòng liên hệ với ban quản lý.</p>
          <p>Trân trọng,<br/>Ban quản lý chung cư</p>
        `;

        // 3. Gửi email
        const oAuth2Client = new google.auth.OAuth2(
          CLIENT_ID.value(),
          CLIENT_SECRET.value(),
          "https://developers.google.com/oauthplayground"
        );

        oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN.value() });
        const accessToken = await oAuth2Client.getAccessToken();

        const transporter = nodemailer.createTransport({
          service: "gmail",
          auth: {
            type: "OAuth2",
            user: SENDER_EMAIL.value(),
            clientId: CLIENT_ID.value(),
            clientSecret: CLIENT_SECRET.value(),
            refreshToken: REFRESH_TOKEN.value(),
            accessToken: accessToken.token,
          },
        });

        await transporter.sendMail({
          from: `Ban quản lý <${SENDER_EMAIL.value()}>`,
          to: targetEmail,
          subject: "Thông báo cập nhật thông tin tài khoản",
          html: emailContent,
        });

        res.status(200).send("Cập nhật thành công và đã gửi email thông báo.");
      } catch (error) {
        console.error("❌ Lỗi khi xử lý:", error);
        res.status(500).send("Lỗi: " + error.message);
      }
    });
  }
);

module.exports = { sendUpdatedDetailEmail1 };
