const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const cors = require("cors");
const nodemailer = require("nodemailer");
const { google } = require("googleapis");

// ⚙️ Khai báo Firebase Secrets
const CLIENT_ID = defineSecret("CLIENT_ID");
const CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const SENDER_EMAIL = defineSecret("SENDER_EMAIL");

admin.initializeApp();

const REDIRECT_URI = "https://developers.google.com/oauthplayground";

// CORS middleware
const corsHandler = cors({ origin: true });

exports.sendResetPasswordEmail = onRequest(
  {
    allowUnauthenticated: true,
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
  },
  (req, res) => {
    corsHandler(req, res, async () => {
      const { email, name } = req.body;

      if (!email) {
        return res.status(400).send("Email is required");
      }

      try {
        // ⚙️ Lấy giá trị từ Firebase Secret
        const clientId = CLIENT_ID.value();
        const clientSecret = CLIENT_SECRET.value();
        const refreshToken = REFRESH_TOKEN.value();
        const senderEmail = SENDER_EMAIL.value();

        console.log("REFRESH_TOKEN:", refreshToken ); // debug
        console.log("CLIENT_ID:", clientId  );
        console.log("CLIENT_SECRET:", clientSecret );
        console.log("REFRESH_TOKEN:", refreshToken );

        // OAuth2 client
        const oAuth2Client = new google.auth.OAuth2(
          clientId,
          clientSecret,
          REDIRECT_URI
        );
        oAuth2Client.setCredentials({ refresh_token: refreshToken });

        // Tạo link reset mật khẩu Firebase
        const resetLink = await admin.auth().generatePasswordResetLink(email);

        // Lấy access token từ refresh token
        const accessToken = await oAuth2Client.getAccessToken();

        // Gửi email qua Gmail OAuth2
        const transporter = nodemailer.createTransport({
          service: "gmail",
          auth: {
            type: "OAuth2",
            user: senderEmail,
            clientId: clientId,
            clientSecret: clientSecret,
            refreshToken: refreshToken,
            accessToken: accessToken.token,
          },
        });

        const mailOptions = {
          from: `"Apartment Admin" <${senderEmail}>`,
          to: email,
          subject: "Thông tin đăng nhập tài khoản",
          html: `
            <p>Xin chào ${name || "bạn"},</p>
            <p>Tài khoản của bạn đã được tạo. Vui lòng nhấn vào nút bên dưới để đặt mật khẩu:</p>
            <a href="${resetLink}" style="padding: 10px 20px; background-color: #4CAF50; color: white;">Đặt lại mật khẩu</a>
            <p>Nếu bạn không yêu cầu, bạn có thể bỏ qua email này.</p>
          `,
        };

        await transporter.sendMail(mailOptions);
        res.status(200).send("Email đặt lại mật khẩu đã được gửi.");
      } catch (error) {
        console.error("Error sending email:", error);
        res.status(500).send("Lỗi khi gửi email: " + error.message);
      }
    });
  }
);
