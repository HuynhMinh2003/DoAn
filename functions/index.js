const admin = require("firebase-admin");
admin.initializeApp();

const { createStaffAccount } = require("./staff");
const { createResidentAccount } = require("./resident");
const { createCompanyAccount } = require("./company");
const { deleteResidentAccount } = require("./deleteResident");
const { deleteStaffAccount } = require("./deleteStaff");
const { deleteCompanyAccount } = require("./deleteCompany");
const { sendUpdatedDetailEmail } = require("./sendUpdatedDetailEmail");
const { sendUpdatedDetailEmail1 } = require("./sendUpdatedDetailEmail1");
const { sendUpdatedDetailEmail2 } = require("./sendUpdatedDetailEmail2");
const { convertDocxToPdf } = require("./convertDocxToPdf");
const { sendNotificationToResidents } = require("./sendNotificationToResidents");
const { sendIncidentNotification } = require("./sendIncidentNotification");

// Export tất cả các function Cloud Functions
exports.createStaffAccount = createStaffAccount;
exports.createResidentAccount = createResidentAccount;
exports.createCompanyAccount = createCompanyAccount;
exports.deleteStaffAccount = deleteStaffAccount;
exports.deleteResidentAccount = deleteResidentAccount;
exports.deleteCompanyAccount = deleteCompanyAccount;
exports.sendUpdatedDetailEmail = sendUpdatedDetailEmail;
exports.sendUpdatedDetailEmail1 = sendUpdatedDetailEmail1;
exports.sendUpdatedDetailEmail2 = sendUpdatedDetailEmail2;
exports.convertDocxToPdf = convertDocxToPdf;
exports.sendNotificationToResidents = sendNotificationToResidents;
exports.sendIncidentNotification = sendIncidentNotification;
