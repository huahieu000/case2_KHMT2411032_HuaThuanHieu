
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const authRoutes = require('./routes/auth.route');
const userRoutes = require('./routes/user.route');
const taskRoutes = require('./routes/taskRoutes');

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
    });
  } catch (err) {
    console.error('MongoDB connection error:', err);
  }
}

startServer();
