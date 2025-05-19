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
      const { email, fullName, cccd, address, gender, phone, birthDate, apartmentId, contractId } = req.body;

      console.log("📦 Dữ liệu nhận được từ body:", req.body);

      if (!email || !fullName || !cccd || !address || !gender || !phone || !birthDate || !apartmentId || !contractId) {
        return res.status(400).send("Thiếu thông tin.");
      }

      try {
        // ⚠️ Truy vấn nếu có resident nào trùng cccd HOẶC email (chỉ cần 1 trùng)
        const residentQuery = await admin
          .firestore()
          .collection("residents")
          .where("isExit", "==", true)
          .where("cccd", "in", [cccd])
          .get();

        const emailQuery = await admin
          .firestore()
          .collection("residents")
          .where("isExit", "==", true)
          .where("email", "in", [email])
          .get();

        const combinedDocs = [...residentQuery.docs, ...emailQuery.docs];
        const uniqueDocs = Array.from(new Map(combinedDocs.map(doc => [doc.id, doc])).values());

        if (uniqueDocs.length > 0) {
          const residentDoc = uniqueDocs[0];
          const residentId = residentDoc.id;

          // ✅ Cập nhật lại trạng thái
          await admin.firestore().collection("residents").doc(residentId).update({
            isExit: false,
            leaveAt: null,
            lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
            apartmentId,
          });

          // ✅ Ghi nhận lại hợp đồng mới
          await admin
            .firestore()
            .collection("residents")
            .doc(residentId)
            .collection("contractHistory")
            .add({
              contractId,
              apartmentId,
              joinedAt: admin.firestore.FieldValue.serverTimestamp(),
              leftAt: null,
            });

          // ✅ Gửi email khôi phục
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
            from: `"Ban quản lí chung cư" <${await SENDER_EMAIL.value()}>`,
            to: email,
            subject: "Tài khoản cư dân đã được hoạt động lại",
            html: `
              <p>Xin chào ${fullName},</p>
              <p>Tài khoản cư dân của bạn đã được hoạt động trở lại.</p>
              <p>Nếu bạn cần đặt lại mật khẩu, hãy sử dụng tính năng 'Quên mật khẩu' trên ứng dụng.</p>
            `,
          });

          return res.status(200).json({
            message: "Tài khoản đã được khôi phục.",
            residentId,
          });
        }

        // 🔒 Nếu không trùng CCCD hoặc Email nào từng thoát → tạo mới
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
          role: 4,
          isExit: false,
          leaveAt: null,
          fcmTokens: [],
          imageUrl: "",
          lastUpdate: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await admin
          .firestore()
          .collection("residents")
          .doc(userRecord.uid)
          .collection("contractHistory")
          .add({
            contractId,
            apartmentId,
            joinedAt: admin.firestore.FieldValue.serverTimestamp(),
            leftAt: null,
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
          from: `"Ban quản lí chung cư" <${await SENDER_EMAIL.value()}>`,
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

        return res.status(200).json({
          message: "Tạo tài khoản cư dân mới thành công.",
          residentId: userRecord.uid,
        });
      } catch (error) {
        console.error("❌ Lỗi xử lý cư dân:", error);
        return res.status(500).send("Lỗi: " + error.message);
      }
    });
  }
);

module.exports = { createResidentAccount };
