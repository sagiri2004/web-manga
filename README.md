# Project

Dự án này được tạo bởi Sagiri và team.

## Công nghệ sử dụng

- Node.js
- JavaScript
- MSSQL
- Các thư viện liên quan

## Hướng dẫn cài đặt

1. Mặc định bạn đã tải Node.js. Hãy chạy lệnh sau để tải toàn bộ thư viện sử dụng: npm install

2. Sử dụng file sql_manga_backup.bak trong thư mục sql để restore database SQL Server hoặc tự chạy file manga_database_copy.sql.

3. Hãy tải ODBC Driver 17 for SQL Server và cấu hình lại trong file src/config/database/index.js bằng cách thay đổi tên server và tên database.

4. Chạy npm start để bắt đầu chương trình