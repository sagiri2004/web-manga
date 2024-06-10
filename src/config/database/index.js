const sql = require("msnodesqlv8");

const connectionString =
  "Driver={ODBC Driver 17 for SQL Server};Server=Elaina\\SQLEXPRESS;Database=sql_manga_3;Trusted_Connection=yes;";

// Function to establish connection to the database
const conn = (callback) => {
  sql.open(connectionString, (err, conn) => {
    if (err) {
      console.error("Error occurred while connecting to the database:", err);
      return callback(err, null);
    }
    callback(null, conn);
  });
};

module.exports = {
  conn: conn,
  sql: sql,
};