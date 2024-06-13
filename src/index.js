const path = require("path");
const express = require("express");
const handlebars = require("express-handlebars");
const methodOverride = require("method-override");
const cookieParser = require("cookie-parser");
const cors = require("cors");
const session = require('express-session');

const port = 3000;
const routes = require("./routes/index");

const app = express();


// Set up view engine
app.engine(
  "hbs",
  handlebars.engine({
    extname: ".hbs",
    helpers: {
      sum: (a, b) => a + b,
      eq: function (a, b) {
        return a === b;
      },
      isLogin: function (v1, operator, v2, options) {
        switch (operator) {
          case "==":
            return v1 == v2 ? options.fn(this) : options.inverse(this);
          case "===":
            return v1 === v2 ? options.fn(this) : options.inverse(this);
          default:
            return options.inverse(this);
        }
      },
      isAdmin: function (v1, options) {
        return v1 === "admin" ? options.fn(this) : options.inverse(this);
      },
    },
  })
);

app.set("view engine", "hbs");
app.set("views", path.join(__dirname, "resources", "views"));

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(methodOverride("_method"));
app.use(express.static(path.join(__dirname, "public")));
app.use(cookieParser());
app.use(cors());
app.use(session({
  secret: 'mySecretKey',
  resave: false,
  saveUninitialized: true
}));


// Custom middleware
// app.use((req, res, next) => {
//   const token = req.cookies.token;
//   res.locals.token = token;
//   next();
// });

app.use((req, res, next) => {
  if (req.cookies.token) {
    res.locals.myUser = req.session.myUser;
  }
  next();
});
// Routes
routes(app);

// Start the server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
