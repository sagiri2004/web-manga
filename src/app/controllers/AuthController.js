const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { createToken } = require("../../util/tokenUtil");
const { conn } = require("../../config/database");
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "E:\\demo");
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({ storage: storage });

class AuthController {
  getRegister(req, res) {
    res.render("auth/register");
  }

  getLogin(req, res) {
    res.render("auth/login");
  }

  async register(req, res) {
    upload.single("image")(req, res, async (err) => {
      if (err) {
        console.error("Error uploading file:", err);
        return;
      }

      const { name, username, email, password, role = "user" } = req.body;

      const checkUserExistsQuery = `EXEC check_user_exists @username='${username}', @email='${email}'`;
      conn((err, conn) => {
        if (err) {
          console.error(
            "Error occurred while connecting to the database:",
            err
          );
          return;
        }

        conn.query(checkUserExistsQuery, (err, results) => {
          if (results.length > 0) {
            res.render("auth/register", {
              message: "Username or email already exists",
            });
            return;
          }

          let imageBit = null;
          if (req.file) {
            const imageBitPath = path.join("E:\\demo", req.file.filename);
            const imageBitData = fs.readFileSync(imageBitPath);
            imageBit = `0x${imageBitData.toString("hex")}`;

            const insertUserQuery = `EXEC insert_user @name='${name}', @username='${username}', @password='${password}', @email='${email}', @role='${role}', @avatar_image_data=${imageBit}`;
            conn.query(insertUserQuery, () => {
              if (err) {
                console.error("Error executing query:", err);
                return;
              }

              res.redirect("/auth/login");
            });
          }
        });
      });
    });
  }

  async login(req, res) {
    const { username, password } = req.body;
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return res.status(500).json({ message: err.message });
      }

      const query = `EXEC check_user_login @username='${username}', @password='${password}'`;
      conn.query(query, (err, results) => {
        if (err) {
          console.error("Error executing query:", err);
          return res.status(500).json({ message: err.message });
        }

        if (results.length === 0) {
          return res.render("auth/login", {
            message: "Invalid username or password",
          });
        }

        const userDetails = results[0];
        const token = createToken(userDetails.id, userDetails.role);
        res.cookie("token", token);

        const image =
          "data:image/jpeg;base64," +
          Buffer.from(userDetails.avatar_image_data).toString("base64");
        req.session.myUser = {
          name: userDetails.name,
          username: userDetails.username,
          email: userDetails.email,
          role: userDetails.role,
          image: image,
        };

        res.redirect("/");
      });
    });
  }

  logout(req, res) {
    req.session.destroy((err) => {
      if (err) {
        console.error("Error occurred while destroying the session:", err);
      } else {
        res.clearCookie("token");
        res.clearCookie("connect.sid"); // Replace 'connect.sid' with the name of your cookie if it's different
        res.redirect("/");
      }
    });
  }
}

module.exports = new AuthController();
