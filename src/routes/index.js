const siteRouter = require("./site");
const authRouter = require("./auth");
const mangaRouter = require("./manga");
const userRouter = require("./user");
const chapterRouter = require("./chapter");

function routes(app) {
  app.use("/chapter", chapterRouter);
  app.use("/user", userRouter);
  app.use("/auth", authRouter);
  app.use("/manga", mangaRouter);
  app.use("/", siteRouter);
}

module.exports = routes;
