
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/auth.middleware');
const {
  getNotifications,
  markAsRead
} = require('../controllers/notificationController');

// D7 - Lấy danh sách thông báo của tài khoản đang đăng nhập
router.get('/', authMiddleware, getNotifications);

// D7 - Đánh dấu một thông báo đã đọc
router.patch('/:id/read', authMiddleware, markAsRead);

module.exports = router;
