
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const authRoutes = require('./routes/auth.route');
const userRoutes = require('./routes/user.route');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

if (!process.env.MONGODB_URI || !process.env.JWT_SECRET) {
  throw new Error('Thiếu MONGODB_URI hoặc JWT_SECRET trong .env');
}

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('MongoDB connected successfully'))
  .catch((err) => console.error('MongoDB connection error:', err));

const taskRoutes = require('./routes/taskRoutes');
// API tài khoản
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tasks', taskRoutes);
// Giữ hoặc bổ sung API Task ở đây
// theo đường dẫn đã sử dụng trong Buổi 1.

app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
