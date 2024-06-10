// hashUtil.js
const bcrypt = require('bcryptjs');

// Hàm để mã hóa mật khẩu
async function hashPassword(password) {
    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        return hashedPassword;
    } catch (error) {
        console.error('Error hashing password:', error);
        throw error;
    }
}

// Hàm để giải mã và xác thực mật khẩu
async function checkPassword(password, hashedPassword) {
    try {
        const isMatch = await bcrypt.compare(password, hashedPassword);
        return isMatch;
    } catch (error) {
        console.error('Error checking password:', error);
        throw error;
    }
}

module.exports = {
    hashPassword,
    checkPassword
};
