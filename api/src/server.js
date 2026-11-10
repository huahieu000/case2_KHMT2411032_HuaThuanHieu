
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const authRoutes = require('./routes/auth.route');
const userRoutes = require('./routes/user.route');
const taskRoutes = require('./routes/taskRoutes');
// D3 - Chức năng gửi email nhắc hạn hoàn thành
const { checkDueReminders } = require('./jobs/dueReminderJob');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

if (!process.env.MONGODB_URI || !process.env.JWT_SECRET) {
  throw new Error('Thiếu MONGODB_URI hoặc JWT_SECRET trong .env');
}

// API
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tasks', taskRoutes);

// Kết nối MongoDB trước khi chạy server
async function startServer() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    console.log('MongoDB connected successfully');

    app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);

  // D3 - Kiểm tra công việc sắp đến hạn
  let isCheckingReminders = false;

  const runDueReminderCheck = async () => {
    if (isCheckingReminders) return;

    isCheckingReminders = true;

    try {
      await checkDueReminders();
    } catch (error) {
      console.error('D3 - Lỗi kiểm tra nhắc hạn:', error);
    } finally {
      isCheckingReminders = false;
    }
  };

  // Kiểm tra ngay khi Backend khởi động
  void runDueReminderCheck();

  // Kiểm tra lại mỗi 5 phút
  setInterval(runDueReminderCheck, 5 * 60 * 1000);

  console.log('D3 - Đã kích hoạt kiểm tra hạn mỗi 5 phút');
});
  } catch (err) {
    console.error('MongoDB connection error:', err);
  }
}

startServer();
