const jwt = require("jsonwebtoken");

class UserMiddleware {
  verifyToken(req, res, next) {
    const authHeader = req.headers.token;
    console.log(req.user);
    if (authHeader) {
      const token = authHeader.split(" ")[1];
      jwt.verify(token, "mySecretKey", (err, user) => {
        if (err) return res.status(403).json("Token is not valid!");
        req.user = user;
        next();
      });
    } else {
      return res.status(401).json("You are not authenticated! siu siu");
    }
  }

  verifyTokenAndAuthorization(req, res, next) {
    const authHeader = req.headers.token;
    if (authHeader) {
      const token = authHeader.split(" ")[1];
      jwt.verify(token, "mySecretKey", (err, user) => {
        if (err) return res.status(403).json("Token is not valid!");
        req.user = user;
        if (req.user.id === req.params.id || req.user.isAdmin) {
          next();
        } else {
          res.status(403).json("You are not allowed to do that!");
        }
      });
    }
  }
}

module.exports = new UserMiddleware();
