const admin = require("firebase-admin");
admin.initializeApp();

const { createStaffAccount } = require("./staff");
const { createResidentAccount } = require("./resident");
const { createCompanyAccount } = require("./company");

// Export tất cả các function Cloud Functions
exports.createStaffAccount = createStaffAccount;
exports.createResidentAccount = createResidentAccount;
exports.createCompanyAccount = createCompanyAccount;
