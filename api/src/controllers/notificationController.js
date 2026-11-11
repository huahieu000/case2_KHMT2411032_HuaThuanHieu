
const Notification = require('../models/Notification');

// D7 - Lấy danh sách thông báo của người dùng
exports.getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({
      userId: req.userId
    })
      .sort({ createdAt: -1 })
      .limit(100);

    return res.status(200).json({
      success: true,
      notifications
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Không thể lấy danh sách thông báo'
    });
  }
};

// D7 - Đánh dấu thông báo đã đọc
exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      {
        _id: req.params.id,
        userId: req.userId
      },
      {
        $set: {
          isRead: true,
          readAt: new Date()
        }
      },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông báo'
      });
    }

    return res.status(200).json({
      success: true,
      notification
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Không thể đánh dấu đã đọc'
    });
  }
};
