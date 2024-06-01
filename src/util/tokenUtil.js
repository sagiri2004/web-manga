const jwt = require('jsonwebtoken');
const secretKey = 'mySecretKey'; // Replace with your actual secret key

function createToken(user_id, role) {
    const payload = { user_id, role };
    const token = jwt.sign(payload, secretKey, { expiresIn: '1h' }); // Token expires in 1 hour
    return token;
}

function decodeToken(token) {
    try {
        const decoded = jwt.verify(token, secretKey);
        return { user_id: decoded.user_id, role: decoded.role };
    } catch (error) {
        console.error('Error decoding token:', error);
        return null;
    }
}

module.exports = { createToken, decodeToken };
