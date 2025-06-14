const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

const db = admin.firestore();

function calculateWaterFee(usage) {
  if (usage <= 10) return usage * 6000;
  if (usage <= 20) return 10 * 6000 + (usage - 10) * 8000;
  return 10 * 6000 + 10 * 8000 + (usage - 20) * 10000;
}

async function getFeeForDate(path, date) {
  const ref = db.collection(path);
  const snapshot = await ref
    .where("effectiveFrom", "<=", admin.firestore.Timestamp.fromDate(date))
    .orderBy("effectiveFrom", "desc")
    .limit(1)
    .get();
  return snapshot.empty ? null : snapshot.docs[0].data();
}

async function generatePaymentForContract(contractId, targetDate) {
  const year = targetDate.getFullYear();
  const month = targetDate.getMonth(); // 0-based
  const startOfMonth = new Date(year, month, 1);
  const endOfMonth = new Date(year, month + 1, 0);
  const mmYYYY = `${String(month + 1).padStart(2, "0")}-${year}`; // 🟢 Định dạng MM-YYYY

  const contractSnap = await db.collection("contracts").doc(contractId).get();
  const contract = contractSnap.data();
  if (!contract) return;

  const area = contract.area || 0;

  // Quản lý
  const mgFeeData = await getFeeForDate(`services/managementFee/feeHistory`, startOfMonth);
  const feePerM2 = mgFeeData?.feePerM2 || 0;
  const managementFee = Math.round(feePerM2 * area);

  // Nước
  const waterSnap = await db.collection(`contracts/${contractId}/waterReadings`)
    .where("timestamp", ">=", startOfMonth)
    .where("timestamp", "<=", endOfMonth)
    .orderBy("timestamp", "desc")
    .limit(1)
    .get();

  let waterFee = 0;
  let waitingForWater = true;

  if (!waterSnap.empty) {
    const data = waterSnap.docs[0].data();
    const oldReading = data.oldReading || 0;
    const newReading = data.newReading || 0;
    const usage = newReading >= oldReading ? newReading - oldReading : 9999 - oldReading + newReading + 1;
    waterFee = calculateWaterFee(usage);
    waitingForWater = false;
  }

    const parkingSnap = await db.collection(`contracts/${contractId}/parkingRegistrations`)
      .where("registeredAt", "<=", endOfMonth)
      .get();

    let parkingTotal = 0;
    const today = new Date();

    for (const p of parkingSnap.docs) {
      const data = p.data();
      const type = data.vehicleType;
      const registeredAt = data.registeredAt.toDate();
      const canceledAt = data.canceledAt?.toDate();

      const effectiveStart = registeredAt < startOfMonth ? startOfMonth : registeredAt;
      const effectiveEnd = !canceledAt || canceledAt > endOfMonth ? endOfMonth : canceledAt;

      if (effectiveEnd < effectiveStart) continue;

      const feeData = await getFeeForDate(
        `services/parking/vehicleTypes/${type}/feeHistory`,
        effectiveStart
      );
      if (!feeData) continue;

      const monthlyFee = feeData.fee || 0;
      const totalDaysInMonth = endOfMonth.getDate();

      // Tính ngày tính phí tối đa (không vượt quá ngày hiện tại nếu còn trong tháng)
      const lastChargeableDay = today < endOfMonth ? today : endOfMonth;

      let activeDays = Math.max(0, (lastChargeableDay - effectiveStart) / (1000 * 60 * 60 * 24) + 1);

      // Nếu là ngày đầu tháng thì không tính phí
      if (today.getDate() === 1) {
        activeDays = 0;
      }

      const fee = Math.round((monthlyFee / totalDaysInMonth) * activeDays);
      parkingTotal += fee;
    }


  const total = managementFee + waterFee + parkingTotal;

  await db.collection(`contracts/${contractId}/payments`).doc(mmYYYY).set(
    {
      managementFee,
      waterFee,
      parkingFee: parkingTotal,
      total,
      month: mmYYYY, // 🟢 Lưu đúng định dạng '06-2025'
      waitingForWater,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "Chưa thanh toán",
    },
    { merge: true }
  );

  console.log(`✅ Bill generated for ${contractId} - ${mmYYYY}`);
}

// 🕐 Tạo bill hằng tháng
const generateMonthlyBill = onSchedule(
  {
    schedule: "0 2 1 * *",
    timeZone: "Asia/Ho_Chi_Minh",
  },
  async () => {
    const contracts = await db.collection("contracts").get();
    const now = new Date();
    for (const contract of contracts.docs) {
      await generatePaymentForContract(contract.id, now);
    }
  }
);

// 💧 Tính lại bill nếu chỉ số nước được cập nhật muộn
const onWaterReadingUpdate = onDocumentWritten(
  "contracts/{contractId}/waterReadings/{readingId}",
  async (event) => {
    const { contractId } = event.params;
    const data = event.data?.after?.data();
    if (!data || !data.timestamp) return;
    const readingDate = data.timestamp.toDate();
    await generatePaymentForContract(contractId, readingDate);
  }
);

module.exports = {
  generateMonthlyBill,
  onWaterReadingUpdate,
};
