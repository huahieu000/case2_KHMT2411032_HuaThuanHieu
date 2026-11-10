
const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/user.model');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authMiddleware);

// LẤY DANH SÁCH NGƯỜI DÙNG
router.get('/', async (req, res) => {
  try {
    const users = await User.find()
      .select('_id name email')
      .sort({ name: 1 });

    return res.status(200).json(users);
  } catch (err) {
    console.error('GET USERS ERROR:', err);
    return res.status(500).json({
      message: 'Không thể lấy danh sách người dùng'
    });
  }
});
// XEM THÔNG TIN CÁ NHÂN
router.get('/me', async (req, res) => {
  try {
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản!'
      });
    }

    res.json({
  id: user._id,
  name: user.name,
  email: user.email,
  createdAt: user.createdAt
});
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server!' });
  }
});

// CẬP NHẬT THÔNG TIN
router.put('/me', async (req, res) => {
  try {
    const { name } = req.body;
    
    if (typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({
        message: 'Họ tên không hợp lệ!'
      });
    }

    const user = await User.findByIdAndUpdate(
      req.userId,
      { name: name.trim() },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản!'
      });
    }

    res.json({
  message: 'Cập nhật thành công!',
  user: {
    id: user._id,
    name: user.name,
    email: user.email
  }
});
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server!' });
  }
});

// ĐỔI MẬT KHẨU
router.put('/change-password', async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (
      typeof oldPassword !== 'string' ||
      typeof newPassword !== 'string' ||
      newPassword.length < 8
    ) {
      return res.status(400).json({
        message: 'Mật khẩu mới phải có ít nhất 8 ký tự!'
      });
    }

    const user = await User.findById(
      req.userId
    ).select('+password');

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản!'
      });
    }

    const isMatch = await bcrypt.compare(
      oldPassword,
      user.password
    );

    if (!isMatch) {
      return res.status(400).json({
        message: 'Mật khẩu cũ không chính xác!'
      });
    }

    user.password = await bcrypt.hash(newPassword, 12);
    await user.save();

    res.json({
      message: 'Đổi mật khẩu thành công!'
    });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server!' });
  }
});

module.exports = router;
