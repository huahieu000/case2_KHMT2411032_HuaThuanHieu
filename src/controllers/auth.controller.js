const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// ĐĂNG KÝ
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (
      typeof name !== 'string' ||
      !name.trim() ||
      typeof email !== 'string' ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
      typeof password !== 'string' ||
      password.length < 8
    ) {
      return res.status(400).json({
        message: 'Thông tin không hợp lệ hoặc mật khẩu dưới 8 ký tự!'
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({
      email: normalizedEmail
    });

    if (existingUser) {
      return res.status(409).json({
        message: 'Email đã tồn tại!'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword
    });

    return res.status(201).json({
      message: 'Đăng ký thành công!',
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({
        message: 'Email đã tồn tại!'
      });
    }

    console.error('REGISTER ERROR:', err);
    return res.status(500).json({
      message: 'Lỗi server!'
    });
  }
};


// ĐĂNG NHẬP
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (
      typeof email !== 'string' ||
      !email.trim() ||
      typeof password !== 'string' ||
      !password
    ) {
      return res.status(400).json({
        message: 'Email hoặc mật khẩu không hợp lệ!'
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase()
    }).select('+password');

    if (!user) {
      return res.status(401).json({
        message: 'Email hoặc mật khẩu không đúng!'
      });
    }

    const isMatch = await bcrypt.compare(
      password,
      user.password
    );

    if (!isMatch) {
      return res.status(401).json({
        message: 'Email hoặc mật khẩu không đúng!'
      });
    }

    const token = jwt.sign(
      { userId: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );

    return res.status(200).json({
      message: 'Đăng nhập thành công!',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (err) {
    console.error('LOGIN ERROR:', err);
    return res.status(500).json({
      message: 'Lỗi server!'
    });
  }
};