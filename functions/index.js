const admin = require("firebase-admin");
admin.initializeApp();

const { createStaffAccount } = require("./staff");
const { createResidentAccount } = require("./resident");
const { createCompanyAccount } = require("./company");
const { sendUpdatedDetailEmail } = require("./sendUpdatedDetailEmail");
const { sendUpdatedDetailEmail1 } = require("./sendUpdatedDetailEmail1");
const { sendUpdatedDetailEmail2 } = require("./sendUpdatedDetailEmail2");
const { convertDocxToPdf } = require("./convertDocxToPdf");
const { sendNotificationToGroup } = require("./sendNotificationToGroup");
const { sendIncidentNotification } = require("./sendIncidentNotification");
const { sendNotificationToOne } = require("./sendNotificationToOne");
const { generateMonthlyBill, onWaterReadingUpdate } = require("./generateBills");
const { generatePaymentNow } = require("./generatePaymentNow");
const { monthlyDebtReminder } = require("./monthlyDebtReminder");

// ✅ Dùng exports từng cái
exports.createStaffAccount = createStaffAccount;
exports.createResidentAccount = createResidentAccount;
exports.createCompanyAccount = createCompanyAccount;
exports.sendUpdatedDetailEmail = sendUpdatedDetailEmail;
exports.sendUpdatedDetailEmail1 = sendUpdatedDetailEmail1;
exports.sendUpdatedDetailEmail2 = sendUpdatedDetailEmail2;
exports.convertDocxToPdf = convertDocxToPdf;
exports.sendNotificationToGroup = sendNotificationToGroup;
exports.sendIncidentNotification = sendIncidentNotification;
exports.sendNotificationToOne = sendNotificationToOne;
exports.generateMonthlyBill = generateMonthlyBill;
exports.onWaterReadingUpdate = onWaterReadingUpdate;
exports.generatePaymentNow = generatePaymentNow;
exports.monthlyDebtReminder = monthlyDebtReminder; // 💡 thêm vào đây
