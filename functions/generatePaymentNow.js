const { onCall } = require("firebase-functions/v2/https");
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
  const month = targetDate.getMonth();
  const startOfMonth = new Date(year, month, 1);
  const endOfMonth = new Date(year, month + 1, 0);
  const mmYYYY = `${String(month + 1).padStart(2, "0")}-${year}`;

  const contractSnap = await db.collection("contracts").doc(contractId).get();
  const contract = contractSnap.data();
  if (!contract) throw new Error("Contract not found");

  const area = contract.area || 0;

  const mgFeeData = await getFeeForDate("services/managementFee/feeHistory", startOfMonth);
  const feePerM2 = mgFeeData?.feePerM2 || 0;
  const managementFee = Math.round(feePerM2 * area);

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
    const usage = newReading >= oldReading
      ? newReading - oldReading
      : 9999 - oldReading + newReading + 1;
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
    const lastChargeableDay = today < endOfMonth ? today : endOfMonth;

    let activeDays = Math.max(0, (lastChargeableDay - effectiveStart) / (1000 * 60 * 60 * 24) + 1);

    if (today.getDate() === 1) {
      activeDays = 0;
    }

    const fee = Math.round((monthlyFee / totalDaysInMonth) * activeDays);
    parkingTotal += fee;
  }

  // 🧮 TÍNH DEBT THÁNG TRƯỚC
  const prevMonth = new Date(year, month - 1, 1);
  const prevMMYYYY = `${String(prevMonth.getMonth() + 1).padStart(2, "0")}-${prevMonth.getFullYear()}`;
  const prevPaymentDoc = await db.collection(`contracts/${contractId}/payments`).doc(prevMMYYYY).get();
  const debt = prevPaymentDoc.exists ? (prevPaymentDoc.data().debt || 0) : 0;

  const total = managementFee + waterFee + parkingTotal + debt;

  await db.collection(`contracts/${contractId}/payments`).doc(mmYYYY).set({
    managementFee,
    waterFee,
    parkingFee: parkingTotal,
    debt, // 👈 Ghi nhận để hiển thị chi tiết công nợ tháng trước
    total,
    month: mmYYYY,
    waitingForWater,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "Chưa thanh toán",
  }, { merge: true });

  console.log(`✅ Bill generated for ${contractId} - ${mmYYYY} (debt: ${debt})`);
}

// ✅ Cloud Function HTTPS callable
exports.generatePaymentNow = onCall(async (request) => {
  const contractId = request.data?.contractId;
  if (!contractId) {
    throw new Error("Thiếu contractId");
  }

  const now = new Date();
  await generatePaymentForContract(contractId, now);

  return {
    success: true,
    message: `✅ Đã tính lại hóa đơn cho hợp đồng ${contractId}`,
  };
});
