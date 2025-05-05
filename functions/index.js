const admin = require("firebase-admin");
admin.initializeApp();

const { createStaffAccount } = require("./staff");
const { createResidentAccount } = require("./resident");
const { createCompanyAccount } = require("./company");
const { deleteResidentAccount } = require("./deleteResident");
const { deleteStaffAccount } = require("./deleteStaff");
const { deleteCompanyAccount } = require("./deleteCompany");

// Export tất cả các function Cloud Functions
exports.createStaffAccount = createStaffAccount;
exports.createResidentAccount = createResidentAccount;
exports.createCompanyAccount = createCompanyAccount;
exports.deleteStaffAccount = deleteStaffAccount;
exports.deleteResidentAccount = deleteResidentAccount;
exports.deleteCompanyAccount = deleteCompanyAccount;
