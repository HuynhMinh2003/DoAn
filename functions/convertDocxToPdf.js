const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { defineSecret } = require("firebase-functions/params");
const axios = require("axios");
const admin = require("firebase-admin");
const { tmpdir } = require("os");
const { join, dirname } = require("path");
const { mkdirSync, unlinkSync } = require("fs");
const { Storage } = require("@google-cloud/storage");
const FormData = require("form-data");

const CLOUDCONVERT_API_KEY = defineSecret("CLOUDCONVERT_API_KEY");

const storage = new Storage();

const convertDocxToPdf = onObjectFinalized(
  {
    memory: "1GiB",
    timeoutSeconds: 120,
    secrets: [CLOUDCONVERT_API_KEY],
  },
  async (event) => {
    const object = event.data;
    const filePath = object.name;
    const contentType = object.contentType;

    if (!filePath.startsWith("contracts/") || !filePath.endsWith(".docx")) {
      console.log("❌ File không hợp lệ, bỏ qua:", filePath);
      return;
    }

    const contractId = filePath.split("/").pop().split("_")[0];
    const bucket = storage.bucket(object.bucket);
    const tempLocalDir = join(tmpdir(), dirname(filePath));
    mkdirSync(tempLocalDir, { recursive: true });

    const tempDocxPath = join(tmpdir(), filePath);

    // Download file .docx từ bucket
    await bucket.file(filePath).download({ destination: tempDocxPath });
    console.log("📥 Đã tải file .docx về:", tempDocxPath);

    // Lấy API key từ secret (Cloud Functions v2)
    const apiKey = process.env.CLOUDCONVERT_API_KEY;
    if (!apiKey) {
      console.error("❌ CLOUDCONVERT_API_KEY chưa được thiết lập");
      return;
    }

    // 1. Tạo job với các task import/upload, convert, export/url
    let jobRes;
    try {
      jobRes = await axios.post(
        "https://api.cloudconvert.com/v2/jobs",
        {
          tasks: {
            "import-my-file": {
              operation: "import/upload",
            },
            "convert-my-file": {
              operation: "convert",
              input: "import-my-file",
              input_format: "docx",
              output_format: "pdf",
              engine: "office",
            },
            "export-my-file": {
              operation: "export/url",
              input: "convert-my-file",
            },
          },
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
          },
        }
      );
    } catch (e) {
      console.error("❌ Tạo job thất bại:", e.response?.data || e.message);
      return;
    }

    const job = jobRes.data.data;
    console.log("🆔 Job ID:", job.id);

    // 2. Lấy task import/upload để upload file
    const importTask = job.tasks.find((t) => t.name === "import-my-file");
    if (!importTask || !importTask.result || !importTask.result.form) {
      console.error("❌ Task import/upload không đúng định dạng:", importTask);
      return;
    }

    const uploadUrl = importTask.result.form.url;
    const uploadParams = importTask.result.form.parameters;

    // 3. Upload file docx lên CloudConvert
    const form = new FormData();
    for (const key in uploadParams) {
      form.append(key, uploadParams[key]);
    }
    form.append("file", require("fs").createReadStream(tempDocxPath));

    try {
      await axios.post(uploadUrl, form, {
        headers: form.getHeaders(),
        maxContentLength: Infinity,
        maxBodyLength: Infinity,
      });
    } catch (e) {
      console.error("❌ Upload file thất bại:", e.response?.data || e.message);
      return;
    }
    console.log("✅ Upload file .docx lên CloudConvert thành công");

    // 4. Chờ job hoàn thành
    let pdfUrl = "";
    while (true) {
      let jobStatus;
      try {
        jobStatus = await axios.get(`https://api.cloudconvert.com/v2/jobs/${job.id}`, {
          headers: {
            Authorization: `Bearer ${apiKey}`,
          },
        });
      } catch (e) {
        console.error("❌ Lấy trạng thái job lỗi:", e.response?.data || e.message);
        return;
      }

      const status = jobStatus.data.data.status;
      console.log(`⏳ Trạng thái job: ${status}`);

      if (status === "finished") {
        const exportTask = jobStatus.data.data.tasks.find((t) => t.name === "export-my-file");
        if (!exportTask || !exportTask.result || !exportTask.result.files || exportTask.result.files.length === 0) {
          console.error("❌ Không tìm thấy file PDF xuất ra");
          return;
        }
        pdfUrl = exportTask.result.files[0].url;
        break;
      } else if (status === "error") {
        console.error("❌ Job chuyển đổi lỗi");
        return;
      }

      await new Promise((r) => setTimeout(r, 2000));
    }

    // 5. Tải PDF về và upload lên Firebase Storage
    let pdfBuffer;
    try {
      const pdfResp = await axios.get(pdfUrl, { responseType: "arraybuffer" });
      pdfBuffer = pdfResp.data;
    } catch (e) {
      console.error("❌ Tải file PDF lỗi:", e.response?.data || e.message);
      return;
    }

    const pdfPath = filePath.replace(".docx", ".pdf");
    try {
      await bucket.file(pdfPath).save(pdfBuffer, {
        contentType: "application/pdf",
      });
    } catch (e) {
      console.error("❌ Upload PDF lên Firebase lỗi:", e.message);
      return;
    }
    console.log("✅ Upload PDF lên Firebase thành công:", pdfPath);

    // 6. Lấy signed URL và cập nhật Firestore
    try {
      const signedUrlArr = await bucket.file(pdfPath).getSignedUrl({
        action: "read",
        expires: Date.now() + 365 * 24 * 60 * 60 * 1000,
      });

      await admin.firestore().collection("contracts").doc(contractId).update({
        pdfUrl: signedUrlArr[0],
        pdfGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log("✅ Cập nhật Firestore thành công");
    } catch (e) {
      console.error("❌ Cập nhật Firestore lỗi:", e.message);
    }

    // Cleanup file tạm
    unlinkSync(tempDocxPath);
    console.log("🧹 Đã xóa file tạm:", tempDocxPath);
  }
);

module.exports = {
  convertDocxToPdf,
};
