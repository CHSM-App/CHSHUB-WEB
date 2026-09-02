// middleware/auth.js
const jwt = require('jsonwebtoken');
const dotenv = require('dotenv');
dotenv.config();

module.exports = function (req, res, next) {
  const authHeader = req.header('Authorization');

  if (!authHeader) {
    return res.status(401).json({ msg: 'No token, access denied' });
  }

  const token = authHeader.split(' ')[1]; // Get only the token part

  if (!token) {
    return res.status(401).json({ msg: 'Invalid token format' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);
    // Only tokens minted by the mobile login belong here. A website token
    // (scope 'web') must not be usable against the mobile API, and vice versa.
    if (decoded.scope !== 'mobile') {
      return res.status(401).json({ msg: 'Token is not valid for the mobile API' });
    }
    req.user = decoded; // { mobile, scope, iat, exp }
    return next();
  } catch (err) {
    console.error("JWT verification failed:", err.message);
   return res.status(401).json({ msg: 'Token is not valid' });
  }
};

