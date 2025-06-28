const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { google } = require("googleapis");
const nodemailer = require("nodemailer");

const db = admin.firestore();

const CLIENT_ID = defineSecret("CLIENT_ID");
const CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const SENDER_EMAIL = defineSecret("SENDER_EMAIL");

const monthlyDebtReminder = onSchedule(
  {
    schedule: "0 8 1 * *", // Chạy vào 8h sáng ngày 1 hàng tháng
    secrets: [CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN, SENDER_EMAIL],
    region: "asia-southeast1",
  },
  async () => {
    console.log("🚀 Bắt đầu kiểm tra hợp đồng có nợ công...");

    const contractsSnap = await db
    .collection("contracts")
    .where("isActive", "==", true)
    .get();

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

    for (const contractDoc of contractsSnap.docs) {
      const contractId = contractDoc.id;
      const contractData = contractDoc.data();
      const rep = contractData.representative;

      if (!rep?.id) continue;

      const paymentsSnap = await db
        .collection("contracts")
        .doc(contractId)
        .collection("payments")
        .where("status", "in", ["Chưa thanh toán", "Chưa thanh toán đủ"])
        .get();

      if (paymentsSnap.size >= 3) {
        const residentSnap = await db.collection("residents").doc(rep.id).get();
        const residentEmail = residentSnap.data()?.email;
        if (!residentEmail) continue;

        const fullName = rep.fullName || "Cư dân";

        const emailHtml = `
          <p>Xin chào ${fullName},</p>
          <p>Hệ thống ghi nhận hợp đồng <strong>${contractId}</strong> của bạn có <strong>${paymentsSnap.size}</strong> tháng chưa thanh toán đầy đủ.</p>
          <p>Vui lòng thanh toán sớm để tránh bị ảnh hưởng đến quyền lợi của mình.</p>
          <p>Trân trọng,<br/>Ban quản lý chung cư</p>
        `;

        await transporter.sendMail({
          from: `Ban quản lý <${SENDER_EMAIL.value()}>`,
          to: residentEmail,
          subject: "⚠️ Cảnh báo nợ công quá hạn",
          html: emailHtml,
        });

        console.log(`📧 Đã gửi email cảnh báo đến ${residentEmail} - hợp đồng ${contractId}`);
      }
    }

    console.log("✅ Hoàn tất kiểm tra và gửi cảnh báo.");
  }
);

exports.monthlyDebtReminder = monthlyDebtReminder;
